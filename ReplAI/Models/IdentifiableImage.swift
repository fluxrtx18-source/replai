import UIKit

/// Thin wrapper so UIImage can be used with sheet(item:) and NavigationStack.
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
