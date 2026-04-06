import SwiftUI

/// Shows the user's remaining free analyses for the week.
struct UsageBadgeView: View {
    let usageTracker: UsageTracker

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            Image(systemName: "sparkles")
                .foregroundStyle(AppDesign.Color.accent)

            Text("Calm tone always free · Upgrade for all 6 + insights")
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
    UsageBadgeView(usageTracker: UsageTracker())
        .padding()
        .background(AppDesign.Color.background)
}
