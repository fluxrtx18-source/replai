import SwiftUI

struct PaywallFeaturesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
            FeatureRowView(icon: "infinity",          text: "Unlimited analyses every week")
            FeatureRowView(icon: "lock.shield.fill",  text: "100% on-device — fully private")
            FeatureRowView(icon: "text.bubble.fill",  text: "6 tone-matched reply options")
            FeatureRowView(icon: "doc.on.doc.fill",   text: "Tap any reply to copy instantly")
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
