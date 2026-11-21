import SwiftUI

struct ReportsView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_income") private var incomeRaw = "5000000"

    private var isEnglish: Bool { language == "en" }
    private var income: Int64 { Int64(incomeRaw) ?? 0 }

    var body: some View {
        NavigationStack {
            List {
                Section(isEnglish ? "This month" : "Bulan ini") {
                    reportValue(isEnglish ? "Income" : "Pemasukan", value: income, color: .green)
                    reportValue(isEnglish ? "Expenses" : "Pengeluaran", value: store.expenses(), color: .red)
                    reportValue(isEnglish ? "Remaining" : "Sisa", value: income - store.expenses(), color: .primary)
                }

                Section(isEnglish ? "By category" : "Per kategori") {
                    let totals = store.expensesByCategory()
                    if totals.isEmpty {
                        Text(isEnglish ? "No data yet" : "Belum ada data")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(totals.enumerated()), id: \.offset) { item in
                            HStack {
                                Text(MeowlettCategory.name(for: item.element.0, language: language))
                                Spacer()
                                Text(rupiah(item.element.1))
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEnglish ? "Reports" : "Laporan")
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func reportValue(_ title: String, value: Int64, color: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(rupiah(value))
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
    }

    private func rupiah(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp \(value)"
    }
}
