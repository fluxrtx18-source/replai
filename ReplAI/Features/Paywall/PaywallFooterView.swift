import SwiftUI

struct PaywallFooterView: View {
    let purchaseError: String?
    let isRestoring: Bool
    let onRestore: () -> Void

    private static let privacyURL = URL(string: "https://fluxrtx18-source.github.io/replai/privacy")!
    private static let termsURL   = URL(string: "https://fluxrtx18-source.github.io/replai/terms")!

    var body: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            if let error = purchaseError {
                Text(error)
                    .font(AppDesign.Font.subhead)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: onRestore) {
                if isRestoring {
                    HStack(spacing: AppDesign.Spacing.xs) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(AppDesign.Color.textSecondary)
                        Text("Restoring...")
                    }
                } else {
                    Text("Restore Purchases")
                }
            }
            .font(AppDesign.Font.subhead)
            .foregroundStyle(AppDesign.Color.textSecondary)
            .disabled(isRestoring)

            Text("Subscription auto-renews. Cancel anytime in Settings.")
                .font(.caption)
                .foregroundStyle(AppDesign.Color.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)

            HStack(spacing: AppDesign.Spacing.md) {
                Link("Privacy Policy", destination: Self.privacyURL)
                Text("·")
                    .foregroundStyle(AppDesign.Color.textSecondary.opacity(0.5))
                Link("Terms of Service", destination: Self.termsURL)
            }
            .font(.caption)
            .foregroundStyle(AppDesign.Color.textSecondary.opacity(0.7))
        }
        .padding(.bottom, AppDesign.Spacing.lg)
    }
}
