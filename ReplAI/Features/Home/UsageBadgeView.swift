import SwiftUI

/// Informs free users that Calm tone is always available and prompts an upgrade.
struct UsageBadgeView: View {
    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            Image(systemName: "sparkles")
                .foregroundStyle(AppDesign.Color.accent)

            // Derived from PaywallGate / ReplyTone so copy stays correct if
            // the free tone or total tone count ever changes.
            Text("\(PaywallGate.freeTone.displayName) tone always free · Upgrade for all \(ReplyTone.allCases.count) + insights")
                .font(AppDesign.Font.subhead)
                .foregroundStyle(AppDesign.Color.textSecondary)
        }
        .padding(.horizontal, AppDesign.Spacing.md)
        .padding(.vertical, AppDesign.Spacing.sm)
        .background(AppDesign.Color.surface)
        .clipShape(.rect(cornerRadius: AppDesign.Radius.sm))
        .overlay {
            RoundedRectangle(cornerRadius: AppDesign.Radius.sm)
                .strokeBorder(AppDesign.Color.border, lineWidth: 1)
        }
    }
}

#Preview {
    UsageBadgeView()
        .padding()
        .background(AppDesign.Color.background)
}
