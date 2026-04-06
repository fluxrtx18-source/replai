import Testing
@testable import ReplAI

// MARK: - ConversationAnalysis recommendedTone Tests

@Suite("ConversationAnalysis — recommendedTone parsing")
struct ConversationAnalysisRecommendedToneTests {

    // MARK: - Helpers

    /// Creates a ConversationAnalysis with the given recommendedToneName,
    /// using placeholder strings for all other fields.
    private static func make(recommendedToneName: String?) -> ConversationAnalysis {
        ConversationAnalysis(
            emotionalSummary: "summary",
            calmReply:        "calm",
            assertiveReply:   "assertive",
            vulnerableReply:  "vulnerable",
            humorousReply:    "humorous",
            dominantReply:    "dominant",
            submissiveReply:  "submissive",
            recommendedToneName: recommendedToneName
        )
    }

    // MARK: - Exact-case matching

    @Test("recommendedTone returns correct tone for each exact raw value", arguments: [
        ("Calm",       ReplyTone.calm),
        ("Assertive",  ReplyTone.assertive),
        ("Vulnerable", ReplyTone.vulnerable),
        ("Humorous",   ReplyTone.humorous),
        ("Dominant",   ReplyTone.dominant),
        ("Submissive", ReplyTone.submissive),
    ])
    func exactCaseMatch(name: String, expected: ReplyTone) {
        let analysis = Self.make(recommendedToneName: name)
        #expect(analysis.recommendedTone == expected)
    }

    // MARK: - Case-insensitive matching

    @Test("recommendedTone is case-insensitive", arguments: [
        ("calm",       ReplyTone.calm),
        ("CALM",       ReplyTone.calm),
        ("assertive",  ReplyTone.assertive),
        ("ASSERTIVE",  ReplyTone.assertive),
        ("vulnerable", ReplyTone.vulnerable),
        ("humorous",   ReplyTone.humorous),
        ("dominant",   ReplyTone.dominant),
        ("submissive", ReplyTone.submissive),
    ])
    func caseInsensitiveMatch(name: String, expected: ReplyTone) {
        let analysis = Self.make(recommendedToneName: name)
        #expect(analysis.recommendedTone == expected)
    }

    // MARK: - nil when name is nil

    @Test("recommendedTone is nil when recommendedToneName is nil")
    func nilWhenNameNil() {
        let analysis = Self.make(recommendedToneName: nil)
        #expect(analysis.recommendedTone == nil)
    }

    // MARK: - nil for unrecognised values

    @Test("recommendedTone is nil for unrecognised values", arguments: [
        "",
        "angry",
        "happy",
        "Calm ",       // trailing space
        " Calm",       // leading space
        "calm-reply",
        "123",
    ])
    func nilForUnrecognised(name: String) {
        let analysis = Self.make(recommendedToneName: name)
        #expect(analysis.recommendedTone == nil)
    }

    // MARK: - Default value

    @Test("recommendedToneName defaults to nil when omitted from initializer")
    func defaultIsNil() {
        let analysis = ConversationAnalysis(
            emotionalSummary: "s",
            calmReply:        "c",
            assertiveReply:   "a",
            vulnerableReply:  "v",
            humorousReply:    "h",
            dominantReply:    "d",
            submissiveReply:  "sub"
        )
        #expect(analysis.recommendedToneName == nil)
        #expect(analysis.recommendedTone == nil)
    }
}
