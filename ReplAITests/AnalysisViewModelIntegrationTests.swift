import Testing
import UIKit
@testable import ReplAI

// MARK: - Mock service implementations
//
// These private types satisfy the TextExtracting and ConversationAnalyzing
// protocols without touching real Vision OCR or Foundation Models, making
// the tests fast, deterministic, and runnable without a device.

private struct MockVisionService: TextExtracting {
    let extractedText: String
    func extractText(from image: UIImage) async throws -> String { extractedText }
}

private struct ThrowingVisionService: TextExtracting {
    let error: Error
    func extractText(from image: UIImage) async throws -> String { throw error }
}

private struct MockAICoachService: ConversationAnalyzing {
    let analysis: ConversationAnalysis
    func analyze(conversationText: String) async throws -> ConversationAnalysis { analysis }
}

private struct ThrowingAICoachService: ConversationAnalyzing {
    let error: Error
    func analyze(conversationText: String) async throws -> ConversationAnalysis { throw error }
}

// MARK: - Helpers

private enum TestError: Error { case vision, ai }

private extension ConversationAnalysis {
    /// Deterministic stub used across integration tests.
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

/// Creates an isolated UsageTracker backed by a unique in-process UserDefaults
/// suite so each test starts from zero without touching the App Group store.
@MainActor
private func makeTracker() -> UsageTracker {
    let suiteName = "replai.test.\(UUID().uuidString)"
    let defaults  = UserDefaults(suiteName: suiteName) ?? .standard
    return UsageTracker(defaults: defaults)
}

// MARK: - Integration tests

@Suite("AnalysisViewModel — analyze() integration")
@MainActor
struct AnalysisViewModelIntegrationTests {

    // MARK: - Happy path: state and data

    @Test("analyze() ends in .complete on success")
    func happyPathState() async {
        let vm = AnalysisViewModel(
            visionService:  MockVisionService(extractedText: "Hello"),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: makeTracker())
        #expect(vm.state == .complete)
    }

    @Test("analyze() populates analysis with the service result on success")
    func happyPathAnalysis() async {
        let vm = AnalysisViewModel(
            visionService:  MockVisionService(extractedText: "Hello"),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: makeTracker())
        #expect(vm.analysis == .stub)
    }

    // MARK: - Failure paths: state

    @Test("analyze() ends in .failed when VisionService throws")
    func visionServiceFailure() async {
        let vm = AnalysisViewModel(
            visionService:  ThrowingVisionService(error: TestError.vision),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: makeTracker())
        guard case .failed = vm.state else {
            Issue.record("Expected .failed, got \(vm.state)")
            return
        }
    }

    @Test("analyze() ends in .failed when AICoachService throws")
    func aiServiceFailure() async {
        let vm = AnalysisViewModel(
            visionService:  MockVisionService(extractedText: "Hello"),
            aiCoachService: ThrowingAICoachService(error: TestError.ai)
        )
        await vm.analyze(image: UIImage(), usageTracker: makeTracker())
        guard case .failed = vm.state else {
            Issue.record("Expected .failed, got \(vm.state)")
            return
        }
    }

    @Test("analysis is nil after a failed run")
    func analysisNilOnFailure() async {
        let vm = AnalysisViewModel(
            visionService:  ThrowingVisionService(error: TestError.vision),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: makeTracker())
        #expect(vm.analysis == nil)
    }

    // MARK: - UsageTracker side effects
    //
    // recordAnalysis() must be called only after a successful run.
    // Recording before success would inflate the weekly count for failed attempts.

    @Test("analyze() increments usage count by 1 on success")
    func usageIncrementedOnSuccess() async {
        let tracker = makeTracker()
        let vm = AnalysisViewModel(
            visionService:  MockVisionService(extractedText: "Hello"),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: tracker)
        #expect(tracker.analysisCount == 1)
    }

    @Test("analyze() does NOT increment usage count when VisionService throws")
    func usageNotIncrementedOnVisionFailure() async {
        let tracker = makeTracker()
        let vm = AnalysisViewModel(
            visionService:  ThrowingVisionService(error: TestError.vision),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: tracker)
        #expect(tracker.analysisCount == 0)
    }

    @Test("analyze() does NOT increment usage count when AICoachService throws")
    func usageNotIncrementedOnAIFailure() async {
        let tracker = makeTracker()
        let vm = AnalysisViewModel(
            visionService:  MockVisionService(extractedText: "Hello"),
            aiCoachService: ThrowingAICoachService(error: TestError.ai)
        )
        await vm.analyze(image: UIImage(), usageTracker: tracker)
        #expect(tracker.analysisCount == 0)
    }

    // MARK: - State after reset

    @Test("reset() after a successful run returns to idle and clears analysis")
    func resetAfterSuccess() async {
        let vm = AnalysisViewModel(
            visionService:  MockVisionService(extractedText: "Hello"),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: makeTracker())
        vm.reset()
        #expect(vm.state    == .idle)
        #expect(vm.analysis == nil)
    }

    @Test("reset() after a failed run returns to idle")
    func resetAfterFailure() async {
        let vm = AnalysisViewModel(
            visionService:  ThrowingVisionService(error: TestError.vision),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: makeTracker())
        vm.reset()
        #expect(vm.state == .idle)
    }

    // MARK: - Sequential runs

    @Test("sequential successful analyses accumulate usage count")
    func sequentialUsageCount() async {
        let tracker = makeTracker()
        let vm = AnalysisViewModel(
            visionService:  MockVisionService(extractedText: "Hello"),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await vm.analyze(image: UIImage(), usageTracker: tracker)
        vm.reset()
        await vm.analyze(image: UIImage(), usageTracker: tracker)
        #expect(tracker.analysisCount == 2)
    }

    @Test("failed run followed by successful run increments count exactly once")
    func failureThenSuccessCount() async {
        let tracker = makeTracker()

        let failingVM = AnalysisViewModel(
            visionService:  ThrowingVisionService(error: TestError.vision),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await failingVM.analyze(image: UIImage(), usageTracker: tracker)

        let successVM = AnalysisViewModel(
            visionService:  MockVisionService(extractedText: "Hello"),
            aiCoachService: MockAICoachService(analysis: .stub)
        )
        await successVM.analyze(image: UIImage(), usageTracker: tracker)

        #expect(tracker.analysisCount == 1)
    }
}
