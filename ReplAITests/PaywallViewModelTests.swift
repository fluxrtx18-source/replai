import Testing
@testable import ReplAI

// MARK: - PaywallViewModel Tests

@Suite("PaywallViewModel")
@MainActor
struct PaywallViewModelTests {

    // MARK: - Initial state

    @Test("Starts with no selected product")
    func initialSelection() {
        let vm = PaywallViewModel()
        #expect(vm.selectedProduct == nil)
    }

    @Test("Starts not purchasing")
    func initialPurchasing() {
        let vm = PaywallViewModel()
        #expect(!vm.isPurchasing)
    }

    // MARK: - Purchase without selection

    @Test("Purchase does nothing when no product selected")
    func purchaseWithoutSelection() async {
        let vm = PaywallViewModel()
        let manager = SubscriptionManager()
        await vm.purchase(using: manager)
        #expect(!vm.isPurchasing)
    }
}
