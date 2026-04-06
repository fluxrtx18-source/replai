import Testing
@testable import ReplAI

// MARK: - ConversationAnalysis Tests

@Suite("ConversationAnalysis")
struct ConversationAnalysisTests {

    /// A known analysis used across tests, with unique strings per field
    /// so each tone can be verified independently.
    private static let sample = ConversationAnalysis(
        emotionalSummary: "summary-text",
        calmReply:        "calm-reply",
        assertiveReply:   "assertive-reply",
        vulnerableReply:  "vulnerable-reply",
        humorousReply:    "humorous-reply",
        dominantReply:    "dominant-reply",
        submissiveReply:  "submissive-reply"
    )

    // MARK: - reply(for:) dispatcher

    @Test("reply(for:) returns the correct field for each tone", arguments: [
        (ReplyTone.calm,       "calm-reply"),
        (.assertive,  "assertive-reply"),
        (.vulnerable, "vulnerable-reply"),
        (.humorous,   "humorous-reply"),
        (.dominant,   "dominant-reply"),
        (.submissive, "submissive-reply"),
    ])
    func replyDispatcher(_ tone: ReplyTone, expected: String) {
        #expect(Self.sample.reply(for: tone) == expected)
    }

    // MARK: - Emotional summary is separate from replies

    @Test("Emotional summary is not returned by any reply(for:) call")
    func summaryIsNotAReply() {
        for tone in ReplyTone.allCases {
            #expect(Self.sample.reply(for: tone) != Self.sample.emotionalSummary)
        }
    }

    // MARK: - Equatable conformance

    @Test("Two identical analyses are equal")
    func equatable() {
        let a = Self.sample
        let b = ConversationAnalysis(
            emotionalSummary: "summary-text",
            calmReply:        "calm-reply",
            assertiveReply:   "assertive-reply",
            vulnerableReply:  "vulnerable-reply",
            humorousReply:    "humorous-reply",
            dominantReply:    "dominant-reply",
            submissiveReply:  "submissive-reply"
        )
        #expect(a == b)
    }

    @Test("Analyses with different summaries are not equal")
    func notEqual() {
        var modified = Self.sample
        modified.emotionalSummary = "different"
        #expect(modified != Self.sample)
    }

    // MARK: - All reply fields are populated

    @Test("Every tone returns a non-empty reply", arguments: ReplyTone.allCases)
    func allRepliesNonEmpty(tone: ReplyTone) {
        #expect(!Self.sample.reply(for: tone).isEmpty)
    }
}
