import SwiftUI

struct LoadingView: View {
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: AppDesign.Spacing.lg) {
            ProgressView()
                .controlSize(.large)
                .tint(AppDesign.Color.accent)

            Text(message)
                .font(AppDesign.Font.body)
                .foregroundStyle(AppDesign.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
