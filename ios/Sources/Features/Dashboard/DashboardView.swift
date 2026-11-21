import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_username") private var userName = ""
    @AppStorage("gm_income") private var incomeRaw = "5000000"
    @State private var showIncomeEditor = false
    @State private var incomeDraft = ""
    @State private var recentCount = 5

    private var isEnglish: Bool { language == "en" }
    private var income: Int64 { Int64(incomeRaw) ?? 0 }
    private var monthTransactions: [MeowlettTransaction] {
        store.transactions.filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }
    private var spent: Int64 { monthTransactions.reduce(0) { $0 + $1.amount } }
    private var remaining: Int64 { income - spent }
    private var todaySpent: Int64 {
        store.transactions.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.amount }
    }
    private var expensePercent: Int {
        guard income > 0 else { return 0 }
        return min(100, Int((Double(spent) / Double(income) * 100).rounded()))
    }
    private var progressColor: Color {
        if remaining < 0 || expensePercent > 85 { return Color(hex: "#f87171") }
        if expensePercent > 65 { return Color(hex: "#fbbf24") }
        return .white.opacity(0.85)
    }
    private var isDark: Bool { colorScheme == .dark }
    private var categoryTotals: [(category: String, amount: Int64)] {
        let grouped = Dictionary(grouping: monthTransactions, by: \.category)
        return grouped.map { key, values in
            (key, values.reduce(Int64(0)) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }
    private var dailyTotals: [Int64] {
        let calendar = Calendar.current
        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: -(6 - offset), to: .now) else { return 0 }
            return store.transactions.filter { calendar.isDate($0.date, inSameDayAs: day) }.reduce(Int64(0)) { $0 + $1.amount }
        }
    }
    private var currentMonthLabel: String {
        Date.now.formatted(.dateTime.month(.abbreviated).year().locale(Locale(identifier: isEnglish ? "en_GB" : "id_ID")))
    }
    private var dateLabel: String {
        Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year().locale(Locale(identifier: isEnglish ? "en_GB" : "id_ID")))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    balanceCard

                    HStack(spacing: 8) {
                        streakCard
                        weeklyInsightCard
                    }

                    predictionCard
                    categoryBreakdownCard
                    recentTransactionsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showIncomeEditor) {
                NavigationStack {
                    Form {
                        Section(isEnglish ? "Monthly income" : "Pemasukan bulanan") {
                            TextField(isEnglish ? "Amount (IDR)" : "Jumlah (Rupiah)", text: $incomeDraft)
                                .keyboardType(.numberPad)
                        }
                    }
                    .navigationTitle(isEnglish ? "Edit income" : "Ubah pemasukan")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(isEnglish ? "Cancel" : "Batal") { showIncomeEditor = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(isEnglish ? "Save" : "Simpan") {
                                incomeRaw = String(Int64(incomeDraft.filter(\.isNumber)) ?? 0)
                                showIncomeEditor = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private var balanceCard: some View {
        let primary = Color(hex: AppAppearance.primaryHex)
        let accent = Color(hex: AppAppearance.accentHex)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Button {
                    incomeDraft = income == 0 ? "" : String(income)
                    showIncomeEditor = true
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Text(isEnglish ? "INCOME" : "PEMASUKAN")
                                .font(.system(size: 7, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(.white.opacity(0.42))
                            Image(systemName: "pencil")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.white.opacity(0.42))
                        }
                        Text(rupiah(income))
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currentMonthLabel.uppercased())
                        .font(.system(size: 7, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.4))
                    Text(Date.now.formatted(.dateTime.day()))
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .padding(.bottom, 20)

            Text(isEnglish ? "MONTHLY EXPENSE" : "PENGELUARAN BULAN INI")
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.45))
            Text(rupiah(spent))
                .font(.system(size: 32, weight: .black, design: .rounded))
                .tracking(-1.5)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 2)
            HStack(spacing: 4) {
                Text(isEnglish ? "Today" : "Hari ini")
                    .foregroundStyle(.white.opacity(0.4))
                Text(rupiah(todaySpent))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .font(.system(size: 10))
            .padding(.top, 4)
            .padding(.bottom, 20)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule()
                        .fill(progressColor)
                        .frame(width: proxy.size.width * min(CGFloat(expensePercent) / 100, 1))
                        .shadow(color: .white.opacity(0.25), radius: 5)
                }
            }
            .frame(height: 3)
            .padding(.bottom, 12)

            HStack {
                HStack(spacing: 4) {
                    Text(isEnglish ? "Remaining" : "Sisa")
                        .foregroundStyle(.white.opacity(0.42))
                    Text(rupiah(max(0, remaining)))
                        .fontWeight(.bold)
                        .foregroundStyle(progressColor)
                }
                Spacer()
                Text("\(max(0, 100 - expensePercent))% " + (isEnglish ? "left" : "tersisa"))
                    .fontWeight(.bold)
                    .foregroundStyle(progressColor)
            }
            .font(.system(size: 10))
            if remaining < 0 {
                Text(isEnglish ? "You have exceeded your income" : "Pengeluaran sudah melebihi pemasukan")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "#fecaca"))
                    .padding(.top, 12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .background {
            ZStack {
                LinearGradient(colors: [primary.opacity(0.55), primary.opacity(0.78), primary], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(primary.opacity(0.55)).frame(width: 240, height: 240).offset(x: 150, y: 110)
                RoundedRectangle(cornerRadius: 52).fill(accent.opacity(0.18)).frame(width: 160, height: 250).rotationEffect(.degrees(-22)).offset(x: 135, y: -105)
                Circle().fill(accent.opacity(0.10)).frame(width: 145, height: 145).offset(x: -155, y: -115)
                Circle().fill(primary.opacity(0.25)).frame(width: 90, height: 90).offset(x: -25, y: 15)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.16), radius: 8, x: 0, y: 2)
    }

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "flame.fill").foregroundStyle(Color(hex: "#fb923c"))
                Text(isEnglish ? "STREAK" : "STREAK")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 9, weight: .heavy))
            let activeDays = Set(store.transactions.map { Calendar.current.startOfDay(for: $0.date) }).count
            Text("\(activeDays)")
                .font(.system(size: 24, weight: .black, design: .rounded))
            Text(isEnglish ? "active days recorded" : "hari aktif tercatat")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var weeklyInsightCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: "chart.line.uptrend.xyaxis").foregroundStyle(Color(hex: "#60a5fa"))
                Text(isEnglish ? "7-DAY SPENDING" : "PENGELUARAN 7 HARI")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 9, weight: .heavy))
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(rupiah(dailyTotals.reduce(0, +)))
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            Sparkline(values: dailyTotals.map(Double.init))
                .frame(height: 25)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var predictionCard: some View {
        let daysPassed = max(Calendar.current.component(.day, from: .now), 1)
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: .now)?.count ?? 30
        let prediction = Int64(Double(spent) / Double(daysPassed) * Double(daysInMonth))
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color(hex: AppAppearance.accentHex))
                Text(isEnglish ? "END-OF-MONTH PREDICTION" : "PREDIKSI AKHIR BULAN")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(0.5)
            }
            Text(rupiah(prediction))
                .font(.system(size: 23, weight: .black, design: .rounded))
            Text(isEnglish ? "Based on your average daily spending" : "Berdasarkan rata-rata pengeluaran harianmu")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(isEnglish ? "Category breakdown" : "Pengeluaran per Kategori", icon: "chart.bar.fill")
            if categoryTotals.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie").font(.system(size: 28)).foregroundStyle(Color(hex: AppAppearance.accentHex))
                    Text(isEnglish ? "No data yet" : "Belum ada data").font(.system(size: 15, weight: .bold))
                    Text(isEnglish ? "Add transactions to see your breakdown." : "Tambahkan transaksi untuk melihat rinciannya.")
                        .font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                HStack(spacing: 18) {
                    DonutBreakdown(values: categoryTotals)
                        .frame(width: 126, height: 126)
                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(categoryTotals.prefix(5), id: \.category) { item in
                            HStack(spacing: 6) {
                                Circle().fill(MeowlettCategory.color(for: item.category)).frame(width: 7, height: 7)
                                Text(MeowlettCategory.name(for: item.category, language: language))
                                    .font(.system(size: 10, weight: .semibold))
                                    .lineLimit(1)
                                Spacer(minLength: 2)
                                Text(rupiah(item.amount))
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private var recentTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeading(isEnglish ? "Recent transactions" : "Transaksi Terbaru", icon: "clock.arrow.circlepath")
                Spacer()
                Text("\(store.transactions.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            if store.transactions.isEmpty {
                Text(isEnglish ? "Your recent transactions will appear here." : "Transaksi terbarumu akan muncul di sini.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(store.transactions.prefix(recentCount)) { transaction in
                    TransactionRow(transaction: transaction, language: language)
                    if transaction.id != store.transactions.prefix(recentCount).last?.id {
                        Divider().opacity(0.55)
                    }
                }
                if store.transactions.count > recentCount {
                    Button(isEnglish ? "Show more" : "Tampilkan lainnya") {
                        recentCount += 5
                    }
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func sectionHeading(_ title: String, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: AppAppearance.accentHex))
                .frame(width: 28, height: 28)
                .background(Color(hex: AppAppearance.accentHex).opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
            Text(title).font(.system(size: 14, weight: .heavy))
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

private struct Sparkline: View {
    let values: [Double]
    var body: some View {
        GeometryReader { proxy in
            let maxValue = max(values.max() ?? 1, 1)
            let points = values.enumerated().map { index, value in
                CGPoint(x: proxy.size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1)), y: proxy.size.height * (1 - CGFloat(value / maxValue)))
            }
            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
            }
            .stroke(Color(hex: AppAppearance.accentHex), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct DonutBreakdown: View {
    let values: [(category: String, amount: Int64)]
    private var total: Double { Double(values.reduce(Int64(0)) { $0 + $1.amount }) }
    var body: some View {
        ZStack {
            Circle().stroke(Color.primary.opacity(0.06), lineWidth: 15)
            ForEach(Array(values.enumerated()), id: \.element.category) { index, item in
                let previous = values.prefix(index).reduce(Int64(0)) { $0 + $1.amount }
                Circle()
                    .trim(from: total > 0 ? CGFloat(Double(previous) / total) : 0,
                          to: total > 0 ? CGFloat(Double(previous + item.amount) / total) : 0)
                    .stroke(MeowlettCategory.color(for: item.category), style: StrokeStyle(lineWidth: 15, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 1) {
                Text("TOTAL").font(.system(size: 7, weight: .heavy)).foregroundStyle(.secondary)
                Text("\(values.count)").font(.system(size: 19, weight: .black, design: .rounded))
            }
        }
    }
}
