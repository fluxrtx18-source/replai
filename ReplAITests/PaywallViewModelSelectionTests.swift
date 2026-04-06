import Testing
@testable import ReplAI

// MARK: - PaywallViewModel Selection & State Tests

@Suite("PaywallViewModel — selection and state")
@MainActor
struct PaywallViewModelSelectionTests {

    // MARK: - selectProduct

    @Test("isPurchasing starts false and stays false without purchase call")
    func purchasingDefaultState() {
        let vm = PaywallViewModel()
        #expect(!vm.isPurchasing)
    }

    @Test("purchase(using:) with no selection keeps isPurchasing false")
    func purchaseWithoutSelectionKeepsFalse() async {
        let vm = PaywallViewModel()
        let manager = SubscriptionManager()
        await vm.purchase(using: manager)
        #expect(!vm.isPurchasing)
        #expect(vm.selectedProduct == nil)
    }

    @Test("Multiple purchase calls without selection are safe")
    func multiplePurchasesWithoutSelection() async {
        let vm = PaywallViewModel()
        let manager = SubscriptionManager()
        await vm.purchase(using: manager)
        await vm.purchase(using: manager)
        await vm.purchase(using: manager)
        #expect(!vm.isPurchasing)
    }
}
