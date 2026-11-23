import SwiftUI

struct TransactionRow: View {
    let transaction: MeowlettTransaction
    let language: String

    var body: some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 12)
                .fill(MeowlettCategory.color(for: transaction.category).opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    MeowIcon(key: MeowlettCategory.all.first(where: { $0.id == transaction.category })?.icon ?? "shippingbox", size: 18)
                        .foregroundStyle(MeowlettCategory.color(for: transaction.category))
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.description)
                    .font(MeowlettTypography.font(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                let details = [
                    MeowlettCategory.name(for: transaction.category, language: language),
                    transaction.location,
                    transaction.note
                ].filter { !$0.isEmpty }.joined(separator: " · ")
                Text(details)
                    .font(MeowlettTypography.font(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text("-\(rupiah(transaction.amount))")
                .font(MeowlettTypography.font(size: 13, weight: .heavy))
                .foregroundStyle(Color(hex: "#f87171"))
                .lineLimit(1)
        }
        .padding(.vertical, 3)
    }

    private func rupiah(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        return "Rp" + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }
}
