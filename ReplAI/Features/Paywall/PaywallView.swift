import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss)               private var dismiss

    @State private var viewModel = PaywallViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppDesign.Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppDesign.Spacing.xl) {
                        PaywallHeaderView()
                        PaywallFeaturesCard()
                        plansSection
                        PaywallFooterView(
                            purchaseError: subscriptionManager.purchaseError,
                            isRestoring: subscriptionManager.isRestoring,
                            onRestore: { Task { await subscriptionManager.restore() } }
                        )
                    }
                    .padding(AppDesign.Spacing.md)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", action: dismiss.callAsFunction)
                        .foregroundStyle(AppDesign.Color.textSecondary)
                }
            }
            .task {
                if subscriptionManager.products.isEmpty {
                    await subscriptionManager.loadProducts()
                }
                selectYearlyIfNeeded()
            }
            // Guard against the race where ReplAIApp's launch-time loadProducts()
            // is already in progress when the paywall appears.
            // PaywallView.task calls loadProducts(), hits the guard (isLoadingProducts
            // == true), returns immediately with an empty products array, and never
            // sets viewModel.selectedProduct. When products finally arrive, this
            // observer fires and performs the selection that the task missed.
            .onChange(of: subscriptionManager.products.count) {
                selectYearlyIfNeeded()
            }
            .onChange(of: subscriptionManager.isSubscribed) {
                if subscriptionManager.isSubscribed { dismiss() }
            }
        }
    }

    // MARK: - Helpers

    private var canPurchase: Bool {
        viewModel.selectedProduct != nil && !viewModel.isPurchasing
    }

    /// Auto-selects the yearly plan when no plan is selected yet.
    /// Called both from `.task` (normal path) and `.onChange(of: products.count)`
    /// (race-condition path where products arrived after the task returned early).
    private func selectYearlyIfNeeded() {
        guard viewModel.selectedProduct == nil,
              let yearly = subscriptionManager.products.first(where: { $0.id == SubscriptionManager.yearlyID })
        else { return }
        viewModel.selectProduct(yearly)
    }

    // MARK: - Plans

    @ViewBuilder
    private var plansSection: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            if subscriptionManager.isLoadingProducts {
                ProgressView().tint(AppDesign.Color.accent)
            } else if subscriptionManager.products.isEmpty {
                // Products failed to load (network error, or StoreKit sandbox not configured).
                VStack(spacing: AppDesign.Spacing.sm) {
                    Text("Could not load plans")
                        .font(AppDesign.Font.subhead)
                        .foregroundStyle(AppDesign.Color.textSecondary)
                    Button("Retry") {
                        Task { await subscriptionManager.loadProducts() }
                    }
                    .font(AppDesign.Font.subhead)
                    .foregroundStyle(AppDesign.Color.accent)
                }
                .frame(maxWidth: .infinity)
                .padding(AppDesign.Spacing.md)
            } else {
                ForEach(subscriptionManager.products) { product in
                    PlanRowView(
                        product: product,
                        isSelected: viewModel.selectedProduct?.id == product.id,
                        weeklyProduct: subscriptionManager.products.first(where: { $0.id == SubscriptionManager.weeklyID }),
                        onSelect: { viewModel.selectProduct(product) }
                    )
                }
            }

            Button {
                Task { await viewModel.purchase(using: subscriptionManager) }
            } label: {
                Group {
                    if viewModel.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Continue")
                            .font(AppDesign.Font.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    canPurchase
                        ? AnyShapeStyle(AppDesign.Color.accentGradient)
                        : AnyShapeStyle(AppDesign.Color.textSecondary.opacity(0.3))
                )
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: AppDesign.Radius.md))
            }
            .disabled(!canPurchase)
            .opacity(canPurchase ? 1 : 0.6)
            .animation(AppDesign.Anim.snappy, value: canPurchase)
            .padding(.top, AppDesign.Spacing.xs)
        }
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionManager())
}
