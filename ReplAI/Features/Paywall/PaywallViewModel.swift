import StoreKit

@MainActor
@Observable
final class PaywallViewModel {

    private(set) var selectedProduct: Product?
    private(set) var isPurchasing = false

    func selectProduct(_ product: Product) {
        selectedProduct = product
    }

    func purchase(using manager: SubscriptionManager) async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        await manager.purchase(product)
    }
}
