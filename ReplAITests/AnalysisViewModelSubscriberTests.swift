import Testing
import UIKit
@testable import ReplAI

// MARK: - Mock services (reused pattern)

private struct MockVisionService: TextExtracting {
    let extractedText: String
    func extractText(from image: UIImage) async throws -> String { extractedText }
}

private struct MockAICoachService: ConversationAnalyzing {
    let analysis: ConversationAnalysis
    func analyze(conversationText: String) async throws -> ConversationAnalysis { analysis }
}

private struct ThrowingVisionService: TextExtracting {
    let error: Error
    func extractText(from image: UIImage) async throws -> String { throw error }
}

private enum TestError: Error { case mock }

private extension ConversationAnalysis {
    static let stub = ConversationAnalysis(
        emotionalSummary: "stub-summary",
        calmReply:        "stub-calm",
        assertiveReply:   "stub-assertive",
        vulnerableReply:  "stub-vulnerable",
        humorousReply:    "stub-humorous",
        dominantReply:    "stub-dominant",
        submissiveReply:  "stub-submissive"
    )
}

@MainActor
private func makeTracker() -> UsageTracker {
    let suiteName = "replai.test.\(UUID().uuidString)"
    let defaults  = UserDefaults(suiteName: suiteName) ?? .standard
    return UsageTracker(defaults: defaults)
}

// MARK: - Subscriber-specific tests

@Suite("AnalysisViewModel — subscriber behaviour")
@MainActor
struct AnalysisViewModelSubscriberTests {

    // MARK: - isSubscribed skips usage tracking

    @Test("analyze() does NOT increment usage count when isSubscribed is true")
    func subscriberSkipsUsageTracking() async {
        let tracker = makeTracker()
        let vm = AnalysisViewModel(
            visionService:  MockVisionService(extractedText: "Hello"),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: tracker, isSubscribed: true)
        #expect(tracker.analysisCount == 0)
    }

    @Test("analyze() still reaches .complete when isSubscribed is true")
    func subscriberReachesComplete() async {
        let vm = AnalysisViewModel(
            visionService:  MockVisionService(extractedText: "Hello"),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: makeTracker(), isSubscribed: true)
        #expect(vm.state == .complete)
        #expect(vm.analysis == .stub)
    }

    @Test("analyze() increments usage count when isSubscribed is false (default)")
    func freeUserIncrementsUsage() async {
        let tracker = makeTracker()
        let vm = AnalysisViewModel(
            visionService:  MockVisionService(extractedText: "Hello"),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: tracker)
        #expect(tracker.analysisCount == 1)
    }

    @Test("multiple subscriber analyses never increment usage")
    func multipleSubscriberAnalyses() async {
        let tracker = makeTracker()
        let vm = AnalysisViewModel(
            visionService:  MockVisionService(extractedText: "Hello"),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: tracker, isSubscribed: true)
        vm.reset()
        await vm.analyze(image: UIImage(), usageTracker: tracker, isSubscribed: true)
        vm.reset()
        await vm.analyze(image: UIImage(), usageTracker: tracker, isSubscribed: true)
        #expect(tracker.analysisCount == 0)
    }

    @Test("subscriber failure does not increment usage")
    func subscriberFailureNoIncrement() async {
        let tracker = makeTracker()
        let vm = AnalysisViewModel(
            visionService:  ThrowingVisionService(error: TestError.mock),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: tracker, isSubscribed: true)
        #expect(tracker.analysisCount == 0)
    }
}
