import SwiftUI

struct PaywallFeaturesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
            FeatureRowView(icon: "text.bubble.fill",   text: "All 6 tone-matched reply styles")
            FeatureRowView(icon: "brain.head.profile", text: "Emotional insight for every conversation")
            FeatureRowView(icon: "lock.shield.fill",   text: "100% on-device — fully private")
            FeatureRowView(icon: "doc.on.doc.fill",    text: "Tap any reply to copy instantly")
        }
        .padding(AppDesign.Spacing.md)
        .background(AppDesign.Color.surface)
        .clipShape(.rect(cornerRadius: AppDesign.Radius.md))
        .overlay {
            RoundedRectangle(cornerRadius: AppDesign.Radius.md)
                .strokeBorder(AppDesign.Color.border, lineWidth: 1)
        }
    }
}
