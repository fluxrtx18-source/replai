import StoreKit

/// Manages StoreKit 2 products, purchases, and entitlement verification.
@MainActor
@Observable
final class SubscriptionManager {

    // MARK: - Product IDs (must match App Store Connect)
    static let weeklyID  = "com.replai.weekly"
    static let monthlyID = "com.replai.monthly"
    static let yearlyID  = "com.replai.yearly"

    static let productIDs = [weeklyID, monthlyID, yearlyID]

    // MARK: - Observed state
    private(set) var products: [Product] = []
    private(set) var activeSubscription: Product?
    private(set) var isLoadingProducts = false
    private(set) var purchaseError: String?
    private(set) var isRestoring = false

    var isSubscribed: Bool { activeSubscription != nil }

    // MARK: - Private
    @ObservationIgnored
    private nonisolated(unsafe) var transactionListenerTask: Task<Void, Error>?

    init() {
        transactionListenerTask = startTransactionListener()
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Public API

    func loadProducts() async {
        guard !isLoadingProducts else { return } // Prevent concurrent calls
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
            await refreshEntitlements()
        } catch {
            purchaseError = "Could not load subscription plans. Please check your connection."
        }
    }

    func purchase(_ product: Product) async {
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshEntitlements()
                await transaction.finish()
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    /// Refreshes subscription status without re-fetching product metadata.
    ///
    /// Call on app foreground to catch subscriptions that expired while the app
    /// was backgrounded. `Transaction.updates` handles new purchases/renewals
    /// in real-time, but Apple only pushes expiry events intermittently — a
    /// foreground check closes the gap so `isSubscribed` never stays stale.
    func refresh() async {
        await refreshEntitlements()
    }

    func restore() async {
        isRestoring = true
        purchaseError = nil
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if activeSubscription == nil {
                purchaseError = "No active subscription found for this Apple ID."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Private helpers

    private func refreshEntitlements() async {
        var validProductIDs: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productType == .autoRenewable,
                  transaction.revocationDate == nil else { continue }

            if let expirationDate = transaction.expirationDate,
               expirationDate < Date.now {
                continue
            }

            validProductIDs.insert(transaction.productID)
        }

        // Prefer the highest-tier (most expensive) active subscription in case of overlap.
        activeSubscription = products
            .filter { validProductIDs.contains($0.id) }
            .max(by: { $0.price < $1.price })

        // Cache the result in the App Group so the Action Extension can read it
        // without running StoreKit (which is unavailable in extension processes).
        UserDefaults(suiteName: AppDesign.appGroupID)?
            .set(activeSubscription != nil, forKey: AppDesign.isSubscribedKey)
    }

    private func startTransactionListener() -> Task<Void, Error> {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await refreshEntitlements()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw PurchaseError.verificationFailed
        case .verified(let value): return value
        }
    }

    enum PurchaseError: LocalizedError {
        case verificationFailed
        var errorDescription: String? { "Purchase verification failed. Please try again." }
    }
}
