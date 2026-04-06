import SwiftUI

struct FeatureRowView: View {
    let icon: String
    let text: LocalizedStringKey

    var body: some View {
        Label(text, systemImage: icon)
            .font(AppDesign.Font.body)
            .foregroundStyle(AppDesign.Color.textPrimary)
    }
}
