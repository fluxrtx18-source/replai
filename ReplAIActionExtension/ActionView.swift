import SwiftUI
import UIKit

/// Full analysis sheet presented *over* the host app via the Action Extension.
///
/// Unlike the Share Extension (which saves an image and opens the main app),
/// this view runs Vision OCR and Foundation Models entirely inside the extension
/// process and shows results inline — the user never leaves their conversation.
///
/// ⚠️  FoundationModels in extension processes: the extension memory budget
/// (typically 50–120 MB) may block on-device LLM inference. If the AI step
/// throws, AnalysisViewModel transitions to .failed and the user sees the
/// retry screen rather than a crash. Monitor memory usage in Instruments if
/// inference fails consistently on lower-memory devices.
struct ActionView: View {
    let context: NSExtensionContext?

    @State private var viewModel = AnalysisViewModel()
    @State private var usageTracker = UsageTracker()

    /// Subscription state read once from the App Group cache written by the main
    /// app's SubscriptionManager on every entitlement refresh. StoreKit cannot
    /// be invoked from an extension process.
    ///
    /// `@State` (loaded at first render) avoids a coordinated App Group
    /// UserDefaults read on every SwiftUI body evaluation — the value is stable
    /// for the lifetime of the extension sheet, so reading once is sufficient.
    @State private var isSubscribed: Bool = UserDefaults(suiteName: AppDesign.appGroupID)?
        .bool(forKey: AppDesign.isSubscribedKey) ?? false

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
                    Button("Done") {
                        nonisolated(unsafe) let ctx = context
                        ctx?.completeRequest(returningItems: nil)
                    }
                    .foregroundStyle(AppDesign.Color.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await loadAndAnalyze() }
    }

    // MARK: - State switching

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
                    isSubscribed: isSubscribed,
                    onCopy: { viewModel.copyReply(for: $0) },
                    onUpgrade: openPaywallInMainApp
                )
            }

        case .failed(let message):
            AnalysisErrorView(message: message) {
                viewModel.reset()
                Task { await loadAndAnalyze() }
            }
        }
    }

    // MARK: - Image loading

    private func loadAndAnalyze() async {
        guard let items = context?.inputItems as? [NSExtensionItem] else {
            viewModel.fail(with: String(localized: "No image found in the share sheet."))
            return
        }

        for item in items {
            for provider in (item.attachments ?? []) {
                guard provider.hasItemConformingToTypeIdentifier("public.image") else { continue }
                guard let image = await loadImage(from: provider) else { continue }
                await viewModel.analyze(image: image, usageTracker: usageTracker,
                                        isSubscribed: isSubscribed)
                return
            }
        }

        viewModel.fail(with: String(localized: "Couldn't find an image to analyse. Make sure you're sharing a screenshot."))
    }

    /// Loads a UIImage from an NSItemProvider using the Swift-concurrency-native
    /// async/throws overload — consistent with ShareView and aligned with Swift 6.
    /// Provider errors (unsupported type, permission denied) degrade to `nil`
    /// so the caller's `guard let image` path handles them uniformly.
    private func loadImage(from provider: NSItemProvider) async -> UIImage? {
        do {
            let result = try await provider.loadItem(forTypeIdentifier: "public.image")
            return switch result {
            case let url  as URL:     UIImage(contentsOfFile: url.path)
            case let img  as UIImage: img
            case let data as Data:    UIImage(data: data)
            default:                  nil
            }
        } catch {
            return nil
        }
    }

    // MARK: - Upgrade CTA

    /// Opens the main app's paywall screen. The nonce check does not apply to
    /// the /paywall route — it is not an image-loading path.
    private func openPaywallInMainApp() {
        guard let url = URL(string: "replai://paywall") else { return }
        nonisolated(unsafe) let ctx = context
        ctx?.open(url) { _ in
            MainActor.assumeIsolated {
                ctx?.completeRequest(returningItems: nil)
            }
        }
    }
}
