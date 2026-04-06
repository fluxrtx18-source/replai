import SwiftUI

struct HomeActionSection: View {
    let onImage: (UIImage) -> Void

    var body: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            MainActionButton(onImage: onImage)

            Label("Your data never leaves your device", systemImage: "lock.shield.fill")
                .font(AppDesign.Font.subhead)
                .foregroundStyle(AppDesign.Color.textSecondary)
        }
    }
}
