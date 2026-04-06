import SwiftUI

struct AnalysisResultsView: View {
    let analysis: ConversationAnalysis
    let copiedTone: ReplyTone?
    /// D1 + D2 gate: false = Calm tone only + no emotional summary.
    var isSubscribed: Bool = false
    let onCopy: (ReplyTone) -> Void
    /// Called when the user taps a locked element to open the paywall.
    var onUpgrade: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: AppDesign.Spacing.md) {
                // D2: Emotional summary is a paid feature.
                // Free users see a blurred teaser so they understand what they're missing.
                if !PaywallGate.isSummaryLocked(isSubscribed: isSubscribed) {
                    AnalysisSummaryCard(summary: analysis.emotionalSummary)
                } else {
                    lockedSummaryCard
                }

                Text("Choose your reply")
                    .font(AppDesign.Font.headline)
                    .foregroundStyle(AppDesign.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // D1: Only PaywallGate.freeTone is available without a subscription.
                ForEach(ReplyTone.allCases) { tone in
                    let locked = PaywallGate.isLocked(tone: tone, isSubscribed: isSubscribed)
                    ReplyCardView(
                        tone: tone,
                        replyText: analysis.reply(for: tone),
                        isCopied: copiedTone == tone,
                        isRecommended: tone == analysis.recommendedTone,
                        isLocked: locked,
                        onCopy: locked ? onUpgrade : { onCopy(tone) }
                    )
                }

                Spacer(minLength: AppDesign.Spacing.xxl)
            }
            .padding(AppDesign.Spacing.md)
        }
        .scrollIndicators(.hidden)
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Locked summary teaser (D2)

    /// Shows the real summary blurred behind a frosted upgrade prompt.
    /// The content is rendered but obscured so the user can sense its presence.
    private var lockedSummaryCard: some View {
        ZStack {
            AnalysisSummaryCard(summary: analysis.emotionalSummary)
                .blur(radius: 8)
                .allowsHitTesting(false)
                // Hide from VoiceOver — the real summary is a paid feature.
                // The overlay button below provides the accessible upgrade affordance.
                .accessibilityHidden(true)

            Button(action: onUpgrade) {
                VStack(spacing: AppDesign.Spacing.xs) {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundStyle(AppDesign.Color.accent)

                    Text("Emotional insight")
                        .font(AppDesign.Font.headline)
                        .foregroundStyle(AppDesign.Color.textPrimary)

                    Text("See what's really happening in this conversation")
                        .font(AppDesign.Font.subhead)
                        .foregroundStyle(AppDesign.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppDesign.Spacing.md)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md, style: .continuous))
            }
            .accessibilityLabel("Emotional insight — upgrade to unlock")
            .accessibilityHint("Double-tap to view upgrade options")
        }
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md, style: .continuous))
    }
}
