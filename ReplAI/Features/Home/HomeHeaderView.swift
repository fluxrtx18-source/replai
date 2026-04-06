import SwiftUI

struct HomeHeaderView: View {
    var body: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            Text("ReplAI")
                .font(AppDesign.Font.largeTitle)
                .foregroundStyle(AppDesign.Color.accentGradient)

            Text("Know what to say.")
                .font(AppDesign.Font.title2)
                .foregroundStyle(AppDesign.Color.textPrimary)

            Text("Share a screenshot of your conversation and get six reply options — crafted for the moment.")
                .font(AppDesign.Font.body)
                .foregroundStyle(AppDesign.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppDesign.Spacing.lg)
    }
}
