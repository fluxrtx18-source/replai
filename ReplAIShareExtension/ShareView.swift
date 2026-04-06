import SwiftUI

/// The UI shown inside the iOS Share Sheet.
/// Immediately saves the image to the App Group container and opens the main app.
struct ShareView: View {
    let context: NSExtensionContext?

    @State private var statusMessage = String(localized: "Opening ReplAI...")

    var body: some View {
        ZStack {
            AppDesign.Color.background.ignoresSafeArea()

            VStack(spacing: AppDesign.Spacing.lg) {
                Image(systemName: "arrow.up.forward.app.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppDesign.Color.accentGradient)

                Text(statusMessage)
                    .font(AppDesign.Font.headline)
                    .foregroundStyle(AppDesign.Color.textPrimary)

                ProgressView()
                    .tint(AppDesign.Color.accent)
            }
        }
        .task {
            await processSharedItems()
        }
    }

    // MARK: - Processing

    @MainActor
    private func processSharedItems() async {
        guard let items = context?.inputItems as? [NSExtensionItem] else {
            cancel()
            return
        }

        for item in items {
            for provider in (item.attachments ?? []) {
                if provider.hasItemConformingToTypeIdentifier("public.image") {
                    await loadAndHandleImage(from: provider)
                    return
                }
            }
        }

        cancel()
    }

    @MainActor
    private func loadAndHandleImage(from provider: NSItemProvider) async {
        do {
            let result = try await provider.loadItem(forTypeIdentifier: "public.image")

            let image: UIImage? = switch result {
            case let url as URL:     UIImage(contentsOfFile: url.path)
            case let img as UIImage: img
            case let data as Data:   UIImage(data: data)
            default:                 nil
            }

            guard let image,
                  let data = image.jpegData(compressionQuality: 0.85) else {
                cancel()
                return
            }

            // Save to shared App Group file container (UserDefaults has ~1 MB limit)
            guard let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppDesign.appGroupID
            ) else {
                cancel()
                return
            }
            let fileURL = containerURL.appendingPathComponent(AppDesign.pendingImageFilename)
            // .completeFileProtection encrypts the file when the device is locked,
            // protecting conversation screenshots that contain personal messages.
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])

            // Write a one-time nonce so the main app can confirm this URL open
            // was initiated by our Share Extension and not a third-party app.
            let nonce = UUID().uuidString
            let sharedDefaults = UserDefaults(suiteName: AppDesign.appGroupID)
            sharedDefaults?.set(nonce, forKey: AppDesign.pendingNonceKey)
            // CRITICAL: Extensions are killed immediately after completeRequest().
            // Without an explicit synchronize(), the coalesced write may not reach
            // the shared file before the main app process reads it — causing the
            // nonce guard to fail and loadSharedImage() to be silently skipped.
            sharedDefaults?.synchronize()

            // Open main app
            openMainApp()

        } catch {
            cancel()
        }
    }

    @MainActor
    private func openMainApp() {
        guard let context,
              let url = URL(string: "replai://analyze") else { return }
        nonisolated(unsafe) let ctx = context
        ctx.open(url) { success in
            // NSExtensionContext completion handlers are documented to run on the main
            // thread. assumeIsolated asserts that guarantee at runtime (debug crash if
            // Apple ever breaks it) and removes the need for unsafe cross-thread access.
            MainActor.assumeIsolated {
                if !success {
                    // URL open failed — clean up the pending image so it doesn't
                    // reappear stale, and surface the failure so the user knows.
                    if let containerURL = FileManager.default.containerURL(
                        forSecurityApplicationGroupIdentifier: AppDesign.appGroupID
                    ) {
                        try? FileManager.default.removeItem(
                            at: containerURL.appendingPathComponent(AppDesign.pendingImageFilename)
                        )
                    }
                    UserDefaults(suiteName: AppDesign.appGroupID)?
                        .removeObject(forKey: AppDesign.pendingNonceKey)
                    statusMessage = String(localized: "Couldn't open ReplAI. Please launch the app first.")
                }
                ctx.completeRequest(returningItems: nil)
            }
        }
    }

    @MainActor
    private func cancel() {
        statusMessage = String(localized: "Couldn't load image.")
        context?.cancelRequest(withError: NSError(domain: "ReplAI", code: -1))
    }
}
