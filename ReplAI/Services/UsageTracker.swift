import Foundation

/// Tracks how many analyses the user has run this calendar week.
/// The count is shared via App Group UserDefaults so the Action Extension sees
/// the same value without needing to re-read from StoreKit.
@MainActor
@Observable
final class UsageTracker {

    // MARK: - Constants
    private static let suiteID      = AppDesign.appGroupID
    private static let countKey     = "weeklyAnalysisCount"
    private static let weekStartKey = "weekStartDate"

    // MARK: - Observed state
    private(set) var analysisCount: Int = 0

    // MARK: - Private
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: Self.suiteID) ?? .standard
        refresh()
    }

    /// Test-only initializer that accepts a custom UserDefaults instance.
    init(defaults: UserDefaults) {
        self.defaults = defaults
        refresh()
    }

    /// Call after a successful analysis to increment the weekly count.
    func recordAnalysis() {
        resetIfNewWeek()
        analysisCount += 1
        defaults.set(analysisCount, forKey: Self.countKey)
    }

    /// Re-reads from UserDefaults (call on foreground or after extension returns).
    func refresh() {
        resetIfNewWeek()
        analysisCount = defaults.integer(forKey: Self.countKey)
    }

    // MARK: - Private helpers
    private func resetIfNewWeek() {
        let now = Date.now
        if let weekStart = defaults.object(forKey: Self.weekStartKey) as? Date,
           Calendar.current.isDate(now, equalTo: weekStart, toGranularity: .weekOfYear) {
            return
        }
        defaults.set(0,   forKey: Self.countKey)
        defaults.set(now, forKey: Self.weekStartKey)
        analysisCount = 0
    }
}
