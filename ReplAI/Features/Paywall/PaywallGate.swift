/// Encodes the D1 + D2 paywall gate rules as pure functions so they can be
/// unit-tested independently of the SwiftUI view layer.
///
/// **D1** (tone gate): Only `.calm` is available to free users.
/// All other tones require an active subscription.
///
/// **D2** (summary gate): The emotional insight card is a paid feature.
/// Free users see a blurred teaser that communicates the value without
/// revealing the content.
///
/// Centralising both rules here means the invariants are expressed and
/// tested in exactly one place — a typo in `AnalysisResultsView` cannot
/// accidentally unlock paid content without a test breaking.
enum PaywallGate {

    // MARK: - Free tier constant

    /// The single tone available without a subscription (D1).
    /// Changing this value automatically updates every gate check and test.
    static let freeTone: ReplyTone = .calm

    // MARK: - D1: Tone locking

    /// Returns `true` when `tone` should be locked for the given subscription state.
    ///
    /// Free users may only access `freeTone`; all others require a subscription.
    static func isLocked(tone: ReplyTone, isSubscribed: Bool) -> Bool {
        !isSubscribed && tone != freeTone
    }

    // MARK: - D2: Summary locking

    /// Returns `true` when the emotional summary card should be locked.
    ///
    /// The summary is a paid-only feature regardless of which tone is shown.
    static func isSummaryLocked(isSubscribed: Bool) -> Bool {
        !isSubscribed
    }
}
