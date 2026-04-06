import SwiftUI

struct StepRowView: View {
    let number: Int
    let icon: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: AppDesign.Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppDesign.Color.accent.opacity(0.2))
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(AppDesign.Font.subhead)
                    .bold()
                    .foregroundStyle(AppDesign.Color.accent)
            }

            Label(text, systemImage: icon)
                .font(AppDesign.Font.body)
                .foregroundStyle(AppDesign.Color.textSecondary)
        }
    }
}
