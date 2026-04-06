import SwiftUI

/// Displays the emotional-dynamic analysis at the top of the results screen.
struct AnalysisSummaryCard: View {
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            Label("What's happening", systemImage: "brain.head.profile")
                .font(AppDesign.Font.headline)
                .foregroundStyle(AppDesign.Color.accent)

            Text(summary)
                .font(AppDesign.Font.body)
                .foregroundStyle(AppDesign.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppDesign.Spacing.md)
        .background(AppDesign.Color.surface)
        .clipShape(.rect(cornerRadius: AppDesign.Radius.md))
        .overlay {
            RoundedRectangle(cornerRadius: AppDesign.Radius.md)
                .strokeBorder(AppDesign.Color.accent.opacity(0.35), lineWidth: 1)
        }
    }
}

#Preview {
    AnalysisSummaryCard(
        summary: "Your partner seems frustrated and unheard. Your last message came across as dismissive, even if that wasn't your intention. There's an underlying fear of disconnection on both sides."
    )
    .padding()
    .background(AppDesign.Color.background)
}
