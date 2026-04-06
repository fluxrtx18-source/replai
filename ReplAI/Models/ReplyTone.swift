import SwiftUI

enum ReplyTone: String, CaseIterable, Identifiable {
    case calm       = "Calm"
    case assertive  = "Assertive"
    case vulnerable = "Vulnerable"
    case humorous   = "Humorous"
    case dominant   = "Dominant"
    case submissive = "Submissive"

    var id: String { rawValue }

    /// User-facing label. Intentionally separated from rawValue so the
    /// internal identifier stays stable while display copy can evolve freely.
    var displayName: String {
        switch self {
        case .calm:       String(localized: "Calm")
        case .assertive:  String(localized: "Assertive")
        case .vulnerable: String(localized: "Heartfelt")
        case .humorous:   String(localized: "Playful")
        case .dominant:   String(localized: "Firm")
        case .submissive: String(localized: "Gentle")
        }
    }

    var color: Color {
        switch self {
        case .calm:       Color(red: 0.357, green: 0.608, blue: 0.835)
        case .assertive:  Color(red: 0.906, green: 0.298, blue: 0.235)
        case .vulnerable: Color(red: 0.608, green: 0.349, blue: 0.714)
        case .humorous:   Color(red: 0.953, green: 0.612, blue: 0.071)
        case .dominant:   Color(red: 0.8,   green: 0.8,   blue: 0.8)
        case .submissive: Color(red: 0.914, green: 0.118, blue: 0.549)
        }
    }

    var icon: String {
        switch self {
        case .calm:       "wind"
        case .assertive:  "bolt.fill"
        case .vulnerable: "heart.fill"
        case .humorous:   "face.smiling.fill"
        case .dominant:   "crown.fill"
        case .submissive: "leaf.fill"
        }
    }
}
