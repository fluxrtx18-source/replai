import SwiftUI
import StoreKit

struct PlanRowView: View {
    let product: Product
    let isSelected: Bool
    let weeklyProduct: Product?
    let onSelect: () -> Void

    // MARK: - Computed helpers

    /// Calculates savings % compared to weekly pricing, for both monthly and yearly.
    private var savingsPercent: Int? {
        guard let weekly = weeklyProduct,
              product.id != "com.replai.weekly" else { return nil }
        let weeksInPeriod: Decimal = product.id == "com.replai.yearly" ? 52 : Decimal(52) / Decimal(12)
        let equivalentWeekly = weekly.price * weeksInPeriod
        guard equivalentWeekly > 0 else { return nil }
        let savings = ((equivalentWeekly - product.price) / equivalentWeekly * 100) as NSDecimalNumber
        return savings.intValue
    }

    private var periodLabel: String {
        switch product.id {
        case "com.replai.weekly":  String(localized: "/week")
        case "com.replai.monthly": String(localized: "/month")
        case "com.replai.yearly":  String(localized: "/year")
        default: ""
        }
    }

    private var isBestValue: Bool { product.id == "com.replai.yearly" }

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
                    HStack(spacing: AppDesign.Spacing.sm) {
                        Text(product.displayName)
                            .font(AppDesign.Font.headline)
                            .foregroundStyle(AppDesign.Color.textPrimary)

                        if isBestValue {
                            BadgeView(text: "Best Value", color: AppDesign.Color.accent)
                        }

                        if let pct = savingsPercent {
                            BadgeView(text: String(format: String(localized: "save.percent"), pct), color: Color(red: 0.2, green: 0.7, blue: 0.4))
                        }
                    }

                    HStack(spacing: 2) {
                        Text(product.displayPrice)
                            .font(AppDesign.Font.subhead)
                            .foregroundStyle(AppDesign.Color.textSecondary)
                        Text(periodLabel)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(AppDesign.Color.textSecondary.opacity(0.7))
                    }
                }

                Spacer()

                SelectionIndicator(isSelected: isSelected)
            }
            .padding(AppDesign.Spacing.md)
            .background(AppDesign.Color.surface)
            .clipShape(.rect(cornerRadius: AppDesign.Radius.md))
            .overlay {
                RoundedRectangle(cornerRadius: AppDesign.Radius.md)
                    .strokeBorder(
                        isSelected ? AppDesign.Color.accent : AppDesign.Color.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .animation(AppDesign.Anim.snappy, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Private helpers

private struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(.capsule)
    }
}

private struct SelectionIndicator: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isSelected ? AppDesign.Color.accent : AppDesign.Color.border,
                    lineWidth: 2
                )
                .frame(width: 22, height: 22)

            if isSelected {
                Circle()
                    .fill(AppDesign.Color.accent)
                    .frame(width: 12, height: 12)
            }
        }
    }
}
