import Testing
import Foundation
@testable import ReplAI

// MARK: - UsageTracker Tests

/// Tests run on MainActor because UsageTracker is @MainActor-isolated.
/// Each test gets a fresh ephemeral UserDefaults via a unique suite name.
@Suite("UsageTracker", .serialized)
@MainActor
struct UsageTrackerTests {

    private static func makeTracker() -> (UsageTracker, UserDefaults) {
        let suite = "com.replai.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let tracker = UsageTracker(defaults: defaults)
        return (tracker, defaults)
    }

    // MARK: - Initial state

    @Test("Starts with zero analyses")
    func initialCount() {
        let (tracker, _) = Self.makeTracker()
        #expect(tracker.analysisCount == 0)
    }

    // MARK: - Recording analyses

    @Test("Recording an analysis increments the count")
    func recordIncrements() {
        let (tracker, _) = Self.makeTracker()
        tracker.recordAnalysis()
        #expect(tracker.analysisCount == 1)
    }

    @Test("Recording multiple analyses tracks correctly")
    func multipleRecords() {
        let (tracker, _) = Self.makeTracker()
        tracker.recordAnalysis()
        tracker.recordAnalysis()
        #expect(tracker.analysisCount == 2)
    }

    // MARK: - Persistence via refresh

    @Test("Refresh reads persisted count from UserDefaults")
    func refreshReadsPersisted() {
        let (tracker, defaults) = Self.makeTracker()
        // Simulate external write (e.g. from Share Extension)
        defaults.set(2, forKey: "weeklyAnalysisCount")
        tracker.refresh()
        #expect(tracker.analysisCount == 2)
    }

}
