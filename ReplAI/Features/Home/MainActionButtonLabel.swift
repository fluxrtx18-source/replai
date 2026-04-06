import SwiftUI

/// The visual label for MainActionButton, extracted to satisfy Sendable closure requirements.
struct MainActionButtonLabel: View {
    let isLoading: Bool

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                Text("Choose Screenshot")
                    .font(AppDesign.Font.headline)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(AppDesign.Color.accentGradient)
        .foregroundStyle(.white)
        .clipShape(.rect(cornerRadius: AppDesign.Radius.md))
    }
}
