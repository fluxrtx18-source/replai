import Testing
import Foundation
@testable import ReplAI

// MARK: - UsageTracker Week-Boundary Reset Tests

/// Tests the calendar-week reset logic in UsageTracker.
/// When a new calendar week starts, the count should reset to 0.
@Suite("UsageTracker — week boundary reset", .serialized)
@MainActor
struct UsageTrackerWeekResetTests {

    private static func makeTracker() -> (UsageTracker, UserDefaults) {
        let suite = "com.replai.weektest.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let tracker = UsageTracker(defaults: defaults)
        return (tracker, defaults)
    }

    // MARK: - Week reset via simulated date change

    @Test("Recording after a simulated new week resets the count")
    func weekResetClearsCount() {
        let (tracker, defaults) = Self.makeTracker()

        // Record 2 analyses in the "current" week
        tracker.recordAnalysis()
        tracker.recordAnalysis()
        #expect(tracker.analysisCount == 2)

        // Simulate that the stored week-start is from a previous week
        // by setting it to 8 days ago
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: .now)!
        defaults.set(eightDaysAgo, forKey: "weekStartDate")

        // Recording now should trigger resetIfNewWeek, clearing the count first
        tracker.recordAnalysis()
        #expect(tracker.analysisCount == 1)
    }

    @Test("refresh() after a simulated new week resets the count to zero")
    func refreshResetsOnNewWeek() {
        let (tracker, defaults) = Self.makeTracker()

        tracker.recordAnalysis()
        tracker.recordAnalysis()
        #expect(tracker.analysisCount == 2)

        // Simulate a week boundary crossing
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -15, to: .now)!
        defaults.set(twoWeeksAgo, forKey: "weekStartDate")

        tracker.refresh()
        #expect(tracker.analysisCount == 0)
    }

    @Test("hasReachedLimit resets after week boundary")
    func limitResetsOnNewWeek() {
        let (tracker, defaults) = Self.makeTracker()

        // Exhaust the free limit
        for _ in 0..<UsageTracker.freeWeeklyLimit {
            tracker.recordAnalysis()
        }
        #expect(tracker.hasReachedLimit)

        // Simulate new week
        let lastWeek = Calendar.current.date(byAdding: .day, value: -8, to: .now)!
        defaults.set(lastWeek, forKey: "weekStartDate")

        tracker.refresh()
        #expect(!tracker.hasReachedLimit)
        #expect(tracker.remaining == UsageTracker.freeWeeklyLimit)
    }

    @Test("Same-week refresh does not reset count")
    func sameWeekRefreshPreservesCount() {
        let (tracker, _) = Self.makeTracker()

        tracker.recordAnalysis()
        tracker.recordAnalysis()
        tracker.refresh()

        #expect(tracker.analysisCount == 2)
    }

    @Test("Week reset persists the new week-start date")
    func weekResetPersistsNewDate() {
        let (tracker, defaults) = Self.makeTracker()

        tracker.recordAnalysis()

        // Simulate old week
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: .now)!
        defaults.set(oldDate, forKey: "weekStartDate")

        tracker.recordAnalysis() // triggers reset

        let storedDate = defaults.object(forKey: "weekStartDate") as? Date
        #expect(storedDate != nil)

        // The stored date should be recent (within last minute), not the old date
        if let stored = storedDate {
            let secondsAgo = Date.now.timeIntervalSince(stored)
            #expect(secondsAgo < 60)
        }
    }
}
