import Testing
@testable import ReplAI

// MARK: - SubscriptionManager Tests

@Suite("SubscriptionManager")
@MainActor
struct SubscriptionManagerTests {

    // MARK: - Initial state

    @Test("Starts with no products")
    func initialProducts() {
        let manager = SubscriptionManager()
        #expect(manager.products.isEmpty)
    }

    @Test("Starts with no active subscription")
    func initialSubscription() {
        let manager = SubscriptionManager()
        #expect(manager.activeSubscription == nil)
    }

    @Test("isSubscribed is false initially")
    func initialIsSubscribed() {
        let manager = SubscriptionManager()
        #expect(!manager.isSubscribed)
    }

    @Test("isLoadingProducts is false initially")
    func initialLoading() {
        let manager = SubscriptionManager()
        #expect(!manager.isLoadingProducts)
    }

    @Test("isRestoring is false initially")
    func initialRestoring() {
        let manager = SubscriptionManager()
        #expect(!manager.isRestoring)
    }

    @Test("No purchase error initially")
    func initialError() {
        let manager = SubscriptionManager()
        #expect(manager.purchaseError == nil)
    }

    // MARK: - Product IDs

    @Test("Has exactly 3 product IDs")
    func productIDCount() {
        #expect(SubscriptionManager.productIDs.count == 3)
    }

    @Test("Product IDs contain expected values", arguments: [
        "com.replai.weekly",
        "com.replai.monthly",
        "com.replai.yearly",
    ])
    func productIDExists(id: String) {
        #expect(SubscriptionManager.productIDs.contains(id))
    }

    @Test("All product IDs are unique")
    func uniqueProductIDs() {
        let ids = SubscriptionManager.productIDs
        #expect(Set(ids).count == ids.count)
    }
}
