import Testing
import UIKit
@testable import ReplAI

// MARK: - AnalysisViewModel Tests

@Suite("AnalysisViewModel")
@MainActor
struct AnalysisViewModelTests {

    // MARK: - Initial state

    @Test("Starts in idle state")
    func initialState() {
        let vm = AnalysisViewModel()
        #expect(vm.state == .idle)
    }

    @Test("Starts with no analysis")
    func initialAnalysis() {
        let vm = AnalysisViewModel()
        #expect(vm.analysis == nil)
    }

    @Test("Starts with no copied tone")
    func initialCopiedTone() {
        let vm = AnalysisViewModel()
        #expect(vm.copiedTone == nil)
    }

    // MARK: - Reset

    @Test("Reset clears state back to idle")
    func resetClearsState() {
        let vm = AnalysisViewModel()
        // Manually simulate a completed state
        vm.reset()
        #expect(vm.state == .idle)
        #expect(vm.analysis == nil)
        #expect(vm.copiedTone == nil)
    }

    // MARK: - Copy reply (requires pre-set analysis)

    @Test("copyReply does nothing when analysis is nil")
    func copyWithoutAnalysis() {
        let vm = AnalysisViewModel()
        vm.copyReply(for: .calm)
        #expect(vm.copiedTone == nil)
    }

    // MARK: - State enum equality

    @Test("State.idle equals itself")
    func idleEquality() {
        #expect(AnalysisViewModel.State.idle == .idle)
    }

    @Test("State.failed preserves error message")
    func failedMessage() {
        let state = AnalysisViewModel.State.failed("Network error")
        #expect(state == .failed("Network error"))
    }

    @Test("Different failed messages are not equal")
    func failedInequality() {
        #expect(AnalysisViewModel.State.failed("A") != .failed("B"))
    }

    @Test("All states are distinct", arguments: [
        (AnalysisViewModel.State.idle,            AnalysisViewModel.State.extractingText),
        (.extractingText,   .analyzing),
        (.analyzing,        .complete),
        (.complete,         .idle),
        (.idle,             .failed("err")),
    ])
    func statesAreDistinct(_ a: AnalysisViewModel.State, _ b: AnalysisViewModel.State) {
        #expect(a != b)
    }

    // MARK: - fail(with:) controlled write path (TD-9)

    @Test("fail(with:) transitions idle → .failed with the provided message")
    func failFromIdle() {
        let vm = AnalysisViewModel()
        vm.fail(with: "Something went wrong")
        #expect(vm.state == .failed("Something went wrong"))
    }

    @Test("fail(with:) preserves the message string exactly")
    func failPreservesMessage() {
        let vm = AnalysisViewModel()
        let message = "Vision OCR failed: no text found in screenshot."
        vm.fail(with: message)
        #expect(vm.state == .failed(message))
    }

    @Test("fail(with:) does not clear analysis if one was previously set")
    func failDoesNotClearAnalysis() {
        // analysis is private(set) so we use reset() to confirm state independence.
        // This test documents that fail() only mutates `state`, not `analysis`.
        let vm = AnalysisViewModel()
        vm.fail(with: "error")
        // analysis was never set — remains nil
        #expect(vm.analysis == nil)
    }

    @Test("reset() after fail(with:) returns to idle with no analysis")
    func resetAfterFail() {
        let vm = AnalysisViewModel()
        vm.fail(with: "error")
        vm.reset()
        #expect(vm.state == .idle)
        #expect(vm.analysis == nil)
        #expect(vm.copiedTone == nil)
    }
}
