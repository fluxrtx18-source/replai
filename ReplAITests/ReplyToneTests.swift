import Testing
@testable import ReplAI

// MARK: - ReplyTone Tests

@Suite("ReplyTone")
struct ReplyToneTests {

    // MARK: - Raw values (stable internal identifiers, not user-facing)

    @Test("Each tone has the correct internal identifier", arguments: [
        (ReplyTone.calm,       "Calm"),
        (.assertive,  "Assertive"),
        (.vulnerable, "Vulnerable"),
        (.humorous,   "Humorous"),
        (.dominant,   "Dominant"),
        (.submissive, "Submissive"),
    ])
    func internalIdentifier(_ tone: ReplyTone, expected: String) {
        #expect(tone.rawValue == expected)
    }

    // MARK: - Display names (user-facing labels shown in the UI)

    @Test("Each tone has the correct display name", arguments: [
        (ReplyTone.calm,       "Calm"),
        (.assertive,  "Assertive"),
        (.vulnerable, "Heartfelt"),
        (.humorous,   "Playful"),
        (.dominant,   "Firm"),
        (.submissive, "Gentle"),
    ])
    func displayName(_ tone: ReplyTone, expected: String) {
        #expect(tone.displayName == expected)
    }

    // MARK: - Icon mapping (SF Symbol names must be valid)

    @Test("Each tone has a non-empty SF Symbol icon name", arguments: ReplyTone.allCases)
    func iconIsNotEmpty(tone: ReplyTone) {
        #expect(!tone.icon.isEmpty)
    }

    @Test("Each tone maps to the correct icon", arguments: [
        (ReplyTone.calm,       "wind"),
        (.assertive,  "bolt.fill"),
        (.vulnerable, "heart.fill"),
        (.humorous,   "face.smiling.fill"),
        (.dominant,   "crown.fill"),
        (.submissive, "leaf.fill"),
    ])
    func iconMapping(_ tone: ReplyTone, expected: String) {
        #expect(tone.icon == expected)
    }

    // MARK: - Identifiable conformance

    @Test("id equals rawValue for all tones", arguments: ReplyTone.allCases)
    func identifiable(tone: ReplyTone) {
        #expect(tone.id == tone.rawValue)
    }

    // MARK: - CaseIterable completeness

    @Test("There are exactly 6 tones")
    func toneCount() {
        #expect(ReplyTone.allCases.count == 6)
    }

    // MARK: - All tones are unique

    @Test("All tone raw values are unique")
    func uniqueRawValues() {
        let values = ReplyTone.allCases.map(\.rawValue)
        #expect(Set(values).count == values.count)
    }
}
