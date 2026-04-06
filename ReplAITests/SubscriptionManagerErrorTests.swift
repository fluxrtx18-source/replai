import Testing
@testable import ReplAI

// MARK: - SubscriptionManager.PurchaseError Tests

@Suite("SubscriptionManager.PurchaseError")
struct SubscriptionManagerErrorTests {

    @Test("verificationFailed has a user-facing error description")
    func verificationFailedDescription() {
        let error = SubscriptionManager.PurchaseError.verificationFailed
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("verificationFailed mentions verification or purchase")
    func descriptionMentionsVerification() {
        let desc = SubscriptionManager.PurchaseError.verificationFailed
            .errorDescription!.lowercased()
        #expect(desc.contains("verification") || desc.contains("purchase"))
    }

    @Test("Error conforms to LocalizedError")
    func conformsToLocalizedError() {
        let error: any Error = SubscriptionManager.PurchaseError.verificationFailed
        #expect(!error.localizedDescription.isEmpty)
    }

    // MARK: - Product ID format validation

    @Test("All product IDs follow reverse-domain format", arguments:
        SubscriptionManager.productIDs
    )
    func productIDFormat(id: String) {
        let components = id.split(separator: ".")
        #expect(components.count >= 3, "Product ID should have at least 3 dot-separated components")
    }

    @Test("Product IDs all share the same prefix")
    func sharedPrefix() {
        let prefix = "com.replai."
        for id in SubscriptionManager.productIDs {
            #expect(id.hasPrefix(prefix))
        }
    }

    @Test("Weekly, monthly, yearly IDs are distinct constants")
    func distinctConstants() {
        #expect(SubscriptionManager.weeklyID != SubscriptionManager.monthlyID)
        #expect(SubscriptionManager.monthlyID != SubscriptionManager.yearlyID)
        #expect(SubscriptionManager.weeklyID != SubscriptionManager.yearlyID)
    }
}
