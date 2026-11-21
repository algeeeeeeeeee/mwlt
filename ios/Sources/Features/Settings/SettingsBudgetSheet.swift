import SwiftUI

struct SettingsBudgetSheet: View {
    let isEnglish: Bool

    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("gm_budgets") private var budgetsRaw = "{}"
    @State private var budgets: [String: Int64] = [:]
    @State private var drafts: [String: String] = [:]
    @State private var loaded = false

    private var isDark: Bool { colorScheme == .dark }
    private var accent: Color { AppAppearance.accent }
    private var monthTransactions: [MeowlettTransaction] {
        store.transactions.filter {
            Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEnglish ? "Spending Limits" : "Batas Pengeluaran")
                    .font(MeowlettTypography.font(size: 16, weight: .black))
                    .foregroundStyle(.primary)
                Spacer()
                Button(isEnglish ? "Done" : "Selesai") { dismiss() }
                    .font(MeowlettTypography.font(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 8)

            Text(isEnglish
                 ? "Set a monthly spending limit for each category."
                 : "Atur batas pengeluaran bulanan untuk setiap kategori.")
                .font(MeowlettTypography.font(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(MeowlettCategory.all, id: \.id) { category in
                        budgetRow(category)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 26)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(AppAppearance.modal(dark: isDark))
        .onAppear(perform: loadBudgets)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private func budgetRow(_ category: (id: String, idName: String, enName: String, icon: String, color: String)) -> some View {
        let spent = monthTransactions
            .filter { $0.category == category.id }
            .reduce(Int64(0)) { $0 + $1.amount }
        let limit = budgets[category.id] ?? 0
        let percent = limit > 0
            ? min(100, Int((Double(spent) / Double(limit) * 100).rounded()))
            : 0
        let over = limit > 0 && spent >= limit
        let warningColor: Color = over
            ? Color(hex: "#ef4444")
            : percent > 80 ? Color(hex: "#f59e0b") : accent

        return VStack(spacing: limit > 0 ? 10 : 0) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: category.color).opacity(0.13))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: category.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(hex: category.color))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(isEnglish ? category.enName : category.idName)
                        .font(MeowlettTypography.font(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if limit > 0 {
                        Text("\(rupiah(spent)) / \(rupiah(limit)) · \(percent)%")
                            .font(MeowlettTypography.font(size: 10, weight: .semibold))
                            .foregroundStyle(over ? Color(hex: "#ef4444") : Color.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TextField(isEnglish ? "Set limit" : "Atur limit", text: Binding(
                    get: { drafts[category.id] ?? "" },
                    set: { updateLimit($0, for: category.id) }
                ))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .frame(width: 110, height: 38)
                .background(AppAppearance.input(dark: isDark), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(over ? Color(hex: "#f87171") : AppAppearance.inputBorder(dark: isDark), lineWidth: 1.3)
                )
            }

            if limit > 0 {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppAppearance.card2(dark: isDark))
                        Capsule()
                            .fill(warningColor)
                            .frame(width: proxy.size.width * CGFloat(percent) / 100)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(14)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(over ? Color(hex: "#f87171") : AppAppearance.border(dark: isDark), lineWidth: 1.3)
        )
    }

    private func loadBudgets() {
        guard !loaded else { return }
        let data = budgetsRaw.data(using: .utf8) ?? Data("{}".utf8)
        budgets = (try? JSONDecoder().decode([String: Int64].self, from: data)) ?? [:]
        drafts = budgets.mapValues { value in
            value > 0 ? NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal) : ""
        }
        loaded = true
    }

    private func updateLimit(_ text: String, for key: String) {
        drafts[key] = text
        let digits = text.filter(\.isNumber)
        budgets[key] = Int64(digits) ?? 0
        guard let data = try? JSONEncoder().encode(budgets),
              let encoded = String(data: data, encoding: .utf8) else { return }
        budgetsRaw = encoded
    }

    private func rupiah(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        return "Rp" + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }
}
