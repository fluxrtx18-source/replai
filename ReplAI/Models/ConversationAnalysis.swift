import FoundationModels

/// The structured output the on-device LLM produces for each screenshot.
/// @Generable tells Foundation Models exactly which fields to populate,
/// and @Guide gives natural-language instructions for each field.
@Generable
struct ConversationAnalysis: Sendable, Equatable {

    @Guide(description: "A 2–3 sentence emotional analysis: what each person seems to be feeling and how the messages are landing.")
    var emotionalSummary: String

    @Guide(description: "A reply in a calm, de-escalating tone (1–3 sentences).")
    var calmReply: String

    @Guide(description: "A reply in a firm, confident, assertive tone that clearly states a position (1–3 sentences).")
    var assertiveReply: String

    @Guide(description: "A reply in a vulnerable, emotionally open, honest tone that shows real feelings (1–3 sentences).")
    var vulnerableReply: String

    @Guide(description: "A reply using light humour to gently ease tension (1–3 sentences).")
    var humorousReply: String

    @Guide(description: "A reply in a commanding, dominant tone that sets strong limits (1–3 sentences).")
    var dominantReply: String

    @Guide(description: "A reply in a soft, conciliatory, agreeable tone (1–3 sentences).")
    var submissiveReply: String

    /// The tone the model considers the best fit for this specific conversation.
    /// Optional so that the UI degrades gracefully if the model omits it.
    @Guide(description: "The single tone name that best fits this conversation. Must be exactly one of the following strings: 'Calm', 'Assertive', 'Vulnerable', 'Humorous', 'Dominant', 'Submissive'.")
    var recommendedToneName: String? = nil

    /// Parsed from `recommendedToneName`; nil if the model returned an unrecognised value.
    ///
    /// Case-insensitive so that model variance ("calm" vs "Calm") degrades
    /// gracefully to the correct tone rather than silently returning nil and
    /// dropping the "Suggested" badge with no user-visible indication.
    var recommendedTone: ReplyTone? {
        guard let name = recommendedToneName else { return nil }
        return ReplyTone.allCases.first { $0.rawValue.lowercased() == name.lowercased() }
    }

    func reply(for tone: ReplyTone) -> String {
        switch tone {
        case .calm:       calmReply
        case .assertive:  assertiveReply
        case .vulnerable: vulnerableReply
        case .humorous:   humorousReply
        case .dominant:   dominantReply
        case .submissive: submissiveReply
        }
    }
}
