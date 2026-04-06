import SwiftUI
import UIKit

/// Full-screen sheet that processes the screenshot and shows the results.
struct AnalysisView: View {
    let image: UIImage

    @Environment(UsageTracker.self)        private var usageTracker
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss)               private var dismiss

    @State private var viewModel = AnalysisViewModel()
    @State private var showPaywall = false
    /// Toggled on each retry to re-trigger `.task(id:)`.
    /// SwiftUI cancels the previous task automatically before starting the new
    /// one — and cancels on view disappearance — so no manual Task handle needed.
    @State private var analysisTrigger = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppDesign.Color.background.ignoresSafeArea()
                content
            }
            .navigationTitle("ReplAI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", action: dismiss.callAsFunction)
                        .foregroundStyle(AppDesign.Color.textSecondary)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            // `.task(id:)` fires on first appear and whenever `analysisTrigger`
            // changes. SwiftUI automatically cancels the in-flight task before
            // starting the next one, and on view dismissal — replacing the
            // unstructured `Task { }` that would otherwise outlive the sheet.
            .task(id: analysisTrigger) {
                await startAnalysis()
            }
        }
    }

    // MARK: - Content switching

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()

        case .extractingText:
            LoadingView(message: "Reading your conversation...")

        case .analyzing:
            LoadingView(message: "Finding the right words...")

        case .complete:
            if let analysis = viewModel.analysis {
                AnalysisResultsView(
                    analysis: analysis,
                    copiedTone: viewModel.copiedTone,
                    isSubscribed: subscriptionManager.isSubscribed,
                    onCopy: { viewModel.copyReply(for: $0) },
                    onUpgrade: { showPaywall = true }
                )
            }

        case .failed(let message):
            AnalysisErrorView(message: message) {
                viewModel.reset()
                analysisTrigger.toggle() // cancels previous task, starts fresh
            }
        }
    }

    // MARK: - Logic

    private func startAnalysis() async {
        // Analysis always runs — the paywall gate is now inside the results view
        // (Calm tone free, all others + emotional summary require subscription).
        await viewModel.analyze(image: image, usageTracker: usageTracker,
                                isSubscribed: subscriptionManager.isSubscribed)
    }
}

#Preview {
    AnalysisView(image: UIImage(systemName: "photo")!)
        .environment(UsageTracker())
        .environment(SubscriptionManager())
}
