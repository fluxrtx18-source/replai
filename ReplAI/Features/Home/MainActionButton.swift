import SwiftUI
import PhotosUI

/// The primary CTA on the HomeView.
/// Presents a PhotosPicker when tapped; calls back with the chosen image.
struct MainActionButton: View {
    let onImage: (UIImage) -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var isLoading = false

    var body: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            // Empty label — the visible UI is the overlay below,
            // avoiding a @Sendable closure capturing @State.
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .overlay {
            MainActionButtonLabel(isLoading: isLoading)
                .allowsHitTesting(false)
        }
        .onChange(of: pickerItem) {
            loadImage()
        }
    }

    private func loadImage() {
        guard let item = pickerItem else { return }
        isLoading = true

        Task { @MainActor in
            defer { isLoading = false }
            if let data  = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                onImage(image)
            }
            pickerItem = nil
        }
    }
}

#Preview {
    MainActionButton { _ in }
        .padding()
        .background(AppDesign.Color.background)
}
