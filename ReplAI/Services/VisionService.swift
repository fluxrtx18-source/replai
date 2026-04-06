import Vision
import UIKit

protocol TextExtracting: Sendable {
    func extractText(from image: UIImage) async throws -> String
}

/// Extracts readable text from a UIImage using Apple's Vision framework (on-device OCR).
/// Uses the native async API available on iOS 26+.
actor VisionService: TextExtracting {

    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        // Run synchronous Vision OCR on a non-cooperative thread to avoid
        // starving the Swift concurrency thread pool with a 100–2000ms blocking
        // call. DispatchQueue.global() is correct for single-at-a-time usage.
        //
        // ⚠️  THREAD-EXPLOSION RISK (P-01): if rapid retries are added (e.g. a
        // batch-analyse flow), switch to Task.detached(priority: .userInitiated)
        // so blocked work stays within the cooperative pool instead of spawning
        // a new GCD thread per request. Profile with Instruments → Threads before
        // making that change; the current pattern is fine for single analyses.
        let text: String = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Pin to the latest revision available on the running OS.
                    // Explicit pinning prevents a silent model swap on future
                    // OS updates from altering OCR output in production —
                    // especially important when OCR quality directly feeds
                    // the Foundation Model prompt.
                    let request = VNRecognizeTextRequest()
                    request.revision = VNRecognizeTextRequest.currentRevision
                    request.recognitionLevel = .accurate

                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    try handler.perform([request])

                    let result = (request.results ?? [])
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")

                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        guard !text.isEmpty else { throw VisionError.noTextFound }
        return text
    }

    enum VisionError: LocalizedError {
        case invalidImage
        case noTextFound

        var errorDescription: String? {
            switch self {
            case .invalidImage:  "Could not read the image. Try again with a clear screenshot."
            case .noTextFound:   "No text was found in the screenshot. Make sure it contains readable messages."
            }
        }
    }
}
