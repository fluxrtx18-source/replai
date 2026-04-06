import Testing
@testable import ReplAI

// MARK: - VisionService Error Tests

@Suite("VisionService.VisionError")
struct VisionServiceErrorTests {

    @Test("invalidImage has a user-facing error description")
    func invalidImageDescription() {
        let error = VisionService.VisionError.invalidImage
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("noTextFound has a user-facing error description")
    func noTextFoundDescription() {
        let error = VisionService.VisionError.noTextFound
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("invalidImage mentions screenshot or image")
    func invalidImageMentionsImage() {
        let desc = VisionService.VisionError.invalidImage.errorDescription!.lowercased()
        #expect(desc.contains("image") || desc.contains("screenshot"))
    }

    @Test("noTextFound mentions text or messages")
    func noTextFoundMentionsText() {
        let desc = VisionService.VisionError.noTextFound.errorDescription!.lowercased()
        #expect(desc.contains("text") || desc.contains("message"))
    }

    @Test("The two error cases are distinct")
    func errorsDistinct() {
        let a = VisionService.VisionError.invalidImage.errorDescription
        let b = VisionService.VisionError.noTextFound.errorDescription
        #expect(a != b)
    }

    @Test("Error conforms to LocalizedError")
    func conformsToLocalizedError() {
        let error: any Error = VisionService.VisionError.invalidImage
        // LocalizedError provides localizedDescription via errorDescription
        #expect(!error.localizedDescription.isEmpty)
    }
}
