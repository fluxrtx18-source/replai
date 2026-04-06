import SwiftUI

struct PaywallHeaderView: View {
    var body: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            Image(systemName: "heart.text.clipboard.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppDesign.Color.accentGradient)
                .accessibilityHidden(true)

            Text("Unlock ReplAI")
                .font(AppDesign.Font.title)
                .foregroundStyle(AppDesign.Color.textPrimary)

            Text("Unlimited analyses. Always the right words.")
                .font(AppDesign.Font.body)
                .foregroundStyle(AppDesign.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppDesign.Spacing.md)
    }
}
