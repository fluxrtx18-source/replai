import Vision
import UIKit

protocol TextExtracting: Sendable {
    func extractText(from image: UIImage) async throws -> String
}

/// Extracts readable text from a UIImage using Apple's Vision framework (on-device OCR).
/// Uses the native async API available on iOS 26+.
actor VisionService: TextExtracting {

    // Cap applied before .cgImage extraction so we never decompress a full
    // 48 MP ProRAW frame into memory (~192 MB as a raw CGImage bitmap).
    private static let maxOCRDimension: CGFloat = 2048

    func extractText(from image: UIImage) async throws -> String {
        // Scale down before extracting pixels. VNRecognizeTextRequest with
        // .accurate on large camera frames can spike RAM well above the
        // extension process budget (~50 MB). Screenshot text is fully legible
        // at 2048 px; downscaling preserves all readable content.
        let scaledImage = downscaled(image, toMaxDimension: Self.maxOCRDimension)
        guard let cgImage = scaledImage.cgImage else {
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

    // MARK: - Private helpers

    /// Returns the image scaled down so its longest edge ≤ `maxDimension` points,
    /// preserving aspect ratio. Returns the original unchanged if already within
    /// bounds. `UIGraphicsImageRenderer` is thread-safe on iOS 10+.
    private func downscaled(_ image: UIImage, toMaxDimension maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let targetSize = CGSize(
            width:  (image.size.width  * scale).rounded(),
            height: (image.size.height * scale).rounded()
        )
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: targetSize)) }
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
