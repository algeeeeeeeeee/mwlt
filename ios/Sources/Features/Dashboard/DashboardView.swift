import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_username") private var userName = ""
    @AppStorage("gm_income") private var incomeRaw = "5000000"

    private var isEnglish: Bool { language == "en" }
    private var income: Int64 { Int64(incomeRaw) ?? 0 }
    private var spent: Int64 { store.expenses() }
    private var remaining: Int64 { income - spent }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(isEnglish ? "Hello, \(userName.isEmpty ? "there" : userName)" : "Halo, \(userName.isEmpty ? "Meow" : userName)")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                        Text(isEnglish ? "Here is your money overview." : "Ini ringkasan keuanganmu.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text(isEnglish ? "REMAINING THIS MONTH" : "SISA BULAN INI")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.75))
                        Text(rupiah(remaining))
                            .font(.system(size: 31, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        HStack(spacing: 0) {
                            summaryValue(title: isEnglish ? "Income" : "Pemasukan", value: income)
                            Spacer()
                            summaryValue(title: isEnglish ? "Expenses" : "Pengeluaran", value: spent)
                        }
                    }
                    .padding(20)
                    .background(LinearGradient(colors: [AppAppearance.accent, AppAppearance.primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))

                    HStack {
                        Text(isEnglish ? "Recent transactions" : "Transaksi terbaru")
                            .font(.headline)
                        Spacer()
                        Text("\(store.transactions.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    if store.transactions.isEmpty {
                        ContentUnavailableView(
                            isEnglish ? "No transactions yet" : "Belum ada transaksi",
                            systemImage: "wallet.bifold",
                            description: Text(isEnglish ? "Add your first transaction from the Transactions tab." : "Tambahkan transaksi pertama dari tab Transaksi.")
                        )
                    } else {
                        ForEach(store.transactions.prefix(5)) { transaction in
                            TransactionRow(transaction: transaction, language: language)
                        }
                    }
                }
                .padding(18)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Meowlett")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func summaryValue(title: String, value: Int64) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
            Text(rupiah(value))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
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
