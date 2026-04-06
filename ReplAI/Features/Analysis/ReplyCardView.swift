import SwiftUI

/// A single tone-specific reply card. Tap anywhere to copy the reply text.
struct ReplyCardView: View {
    let tone: ReplyTone
    let replyText: String
    let isCopied: Bool
    var isRecommended: Bool = false
    var isLocked: Bool = false
    let onCopy: () -> Void

    var body: some View {
        Button(action: onCopy) {
            cardContent
        }
        .buttonStyle(.plain)
        // Locked cards must never announce the actual reply text.
        // The label is kept generic so VoiceOver users know the tone exists
        // and what action is available, without exposing paid content.
        .accessibilityLabel(isLocked
            ? "\(tone.displayName) reply — locked"
            : "\(tone.displayName) reply: \(replyText)")
        .accessibilityHint(isLocked
            ? Text("Double-tap to upgrade")
            : isCopied ? Text("Copied to clipboard") : Text("Double-tap to copy"))
        .sensoryFeedback(.success, trigger: isCopied)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
            headerRow
            
            if isLocked {
                // Blurred reply preview + lock badge to surface the upgrade prompt
                // without hiding that there is content behind the gate.
                ZStack {
                    Text(replyText)
                        .font(AppDesign.Font.body)
                        .foregroundStyle(AppDesign.Color.textPrimary.opacity(0.95))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .blur(radius: 5)
                        // Rasterise the blurred text into a single Metal texture.
                        // Without drawingGroup(), the GPU re-runs the Gaussian blur
                        // kernel every frame during scroll and copy-feedback animation
                        // — once per locked card (up to 5 simultaneous). With it, the
                        // cost is paid once on first render and the bitmap is reused.
                        .drawingGroup()
                        .allowsHitTesting(false)
                        // Hide from VoiceOver — the reply text is a paid feature.
                        // The parent Button's accessibilityLabel is set conditionally
                        // below so locked cards never announce the actual reply.
                        .accessibilityHidden(true)

                    HStack(spacing: AppDesign.Spacing.xs) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                        Text("Upgrade to unlock")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(AppDesign.Color.accent)
                    .padding(.horizontal, AppDesign.Spacing.md)
                    .padding(.vertical, AppDesign.Spacing.sm)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(replyText)
                    .font(AppDesign.Font.body)
                    .foregroundStyle(AppDesign.Color.textPrimary.opacity(0.95))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppDesign.Spacing.md)
        // Background mixing surface color with a subtle tone glow
        .background(
            ZStack {
                AppDesign.Color.surface
                
                LinearGradient(
                    colors: [tone.color.opacity(isCopied ? 0.35 : 0.08), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        // Elegant glass finish
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppDesign.Radius.lg, style: .continuous)
                .strokeBorder(
                    isCopied ? tone.color : AppDesign.Color.border.opacity(0.5),
                    lineWidth: isCopied ? 2 : 1
                )
        }
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        .animation(AppDesign.Anim.snappy, value: isCopied)
    }

    private var headerRow: some View {
        HStack {
            // Tone Badge
            HStack(spacing: AppDesign.Spacing.xs) {
                Image(systemName: tone.icon)
                Text(tone.displayName.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.5)
            }
            .padding(.horizontal, AppDesign.Spacing.sm)
            .padding(.vertical, 6)
            .background(tone.color.opacity(isCopied ? 0.25 : 0.15))
            .foregroundStyle(tone.color)
            .clipShape(.capsule)
            .overlay(
                Capsule().strokeBorder(tone.color.opacity(isCopied ? 0.6 : 0.3), lineWidth: 1)
            )

            // Suggested badge — shown when the model recommends this tone
            if isRecommended {
                HStack(spacing: 3) {
                    Image(systemName: "sparkles")
                    Text("Suggested")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(AppDesign.Color.accent)
                .padding(.horizontal, AppDesign.Spacing.sm)
                .padding(.vertical, 4)
                .background(AppDesign.Color.accent.opacity(0.12))
                .clipShape(.capsule)
                .overlay(Capsule().strokeBorder(AppDesign.Color.accent.opacity(0.3), lineWidth: 1))
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Copy Action Label
            HStack(spacing: AppDesign.Spacing.xs) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                Text(isCopied ? "Copied" : "Copy")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isCopied ? tone.color : AppDesign.Color.textSecondary)
            .padding(.horizontal, AppDesign.Spacing.sm)
            .padding(.vertical, 6)
            .background(isCopied ? tone.color.opacity(0.12) : Color.white.opacity(0.04))
            .clipShape(.capsule)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: AppDesign.Spacing.md) {
        ReplyCardView(
            tone: .calm,
            replyText: "I hear you. Can we slow down for a moment? I want to understand what you're feeling.",
            isCopied: false,
            onCopy: {}
        )
        ReplyCardView(
            tone: .assertive,
            replyText: "I need you to stop raising your voice before we can continue this conversation.",
            isCopied: true,
            onCopy: {}
        )
    }
    .padding()
    .background(AppDesign.Color.background)
}
