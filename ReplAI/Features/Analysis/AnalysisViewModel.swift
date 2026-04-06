import SwiftUI
import UIKit

@MainActor
@Observable
final class AnalysisViewModel {

    // MARK: - State machine
    enum State: Equatable {
        case idle
        case extractingText
        case analyzing
        case complete
        case failed(String)
    }

    // MARK: - Observed properties
    private(set) var state: State = .idle
    private(set) var analysis: ConversationAnalysis?
    private(set) var copiedTone: ReplyTone?

    // MARK: - Services
    private let visionService:  any TextExtracting
    private let aiCoachService: any ConversationAnalyzing

    init(
        visionService:  some TextExtracting      = VisionService(),
        aiCoachService: some ConversationAnalyzing = AICoachService()
    ) {
        self.visionService  = visionService
        self.aiCoachService = aiCoachService
    }

    // MARK: - Analysis

    func analyze(image: UIImage, usageTracker: UsageTracker, isSubscribed: Bool = false) async {
        state = .extractingText

        do {
            let text    = try await visionService.extractText(from: image)
            state       = .analyzing
            let result  = try await aiCoachService.analyze(conversationText: text)
            analysis    = result
            // Only count against the free-tier limit for non-subscribers.
            if !isSubscribed { usageTracker.recordAnalysis() }
            state       = .complete
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Private
    @ObservationIgnored
    private var copyFeedbackTask: Task<Void, Never>?

    // MARK: - Copy

    func copyReply(for tone: ReplyTone) {
        guard let text = analysis?.reply(for: tone) else { return }
        UIPasteboard.general.string = text
        copiedTone = tone

        copyFeedbackTask?.cancel()
        copyFeedbackTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if copiedTone == tone {
                copiedTone = nil
            }
        }
    }

    /// Transitions to the failed state from outside the view model.
    /// Use when a caller encounters an error before `analyze(image:usageTracker:)`
    /// can be invoked — e.g. the Action Extension fails to load an image from
    /// NSExtensionContext before any Vision or AI work has started.
    func fail(with message: String) {
        state = .failed(message)
    }

    // MARK: - Reset

    func reset() {
        copyFeedbackTask?.cancel()
        copyFeedbackTask = nil
        state      = .idle
        analysis   = nil
        copiedTone = nil
    }
}
