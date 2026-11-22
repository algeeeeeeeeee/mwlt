import SwiftUI
import UIKit

private enum DashboardPresentedSheet: String, Identifiable {
    case overallBudget, goalEditor, incomeEditor
    var id: String { rawValue }
}

struct DashboardView: View {
    var onSeeAllTransactions: () -> Void = {}
    var onAddTransaction: () -> Void = {}

    @EnvironmentObject private var store: FinanceStore
    @EnvironmentObject private var modalBlurCoordinator: ModalBlurCoordinator
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_categories") private var categoriesJSON = ""
    @AppStorage("gm_username") private var userName = ""
    @AppStorage("gm_income") private var incomeRaw = "5000000"
    @State private var activeSheet: DashboardPresentedSheet?
    @State private var incomeDraft = ""
    @State private var recentCount = 5
    @AppStorage("gm_streak") private var streakRaw = "{\"count\":0,\"lastDate\":\"\"}"
    @AppStorage("gm_budgets") private var budgetsRaw = "{}"
    @AppStorage("gm_overall_budget") private var overallBudgetRaw = "0"
    @AppStorage("gm_savings_goals") private var savingsGoalsRaw = "[]"
    @AppStorage("gm_cicilan") private var installmentsRaw = "[]"
    @State private var budgets: [String: Int64] = [:]
    @State private var savingsGoals: [DashboardSavingsGoal] = []
    @State private var storageLoaded = false
    @State private var editingGoal: DashboardSavingsGoal?
    @State private var quickAddGoalID: Int64?
    @State private var quickAddAmount = ""
    @State private var quickAddAmountDisplay = ""

    private var isEnglish: Bool { language == "en" }
    private var income: Int64 { Int64(incomeRaw) ?? 0 }
    private var monthTransactions: [MeowlettTransaction] {
        store.transactions.filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }
    private var spent: Int64 { monthTransactions.reduce(0) { $0 + $1.amount } }
    private var totalCicilanMonthly: Int64 {
        guard let data = installmentsRaw.data(using: .utf8),
              let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return 0 }
        return items.reduce(Int64(0)) { total, item in
            let value: Int64
            if let number = item["monthly"] as? NSNumber {
                value = number.int64Value
            } else if let string = item["monthly"] as? String {
                value = Int64(string.filter(\\.isNumber)) ?? 0
            } else {
                value = 0
            }
            return total + value
        }
    }
    private var remaining: Int64 { income - spent - totalCicilanMonthly }
    private var todaySpent: Int64 {
        store.transactions.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.amount }
    }
    private var currentStreak: Int {
        guard let data = streakRaw.data(using: .utf8),
              let state = try? JSONDecoder().decode(DashboardStreakData.self, from: data) else { return 0 }
        return state.count
    }
    private var thisWeekStart: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today) // Sunday = 1
        let daysSinceMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) ?? today
    }
    private var tomorrowStart: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
    }
    private var thisWeekTransactions: [MeowlettTransaction] {
        store.transactions.filter { $0.date >= thisWeekStart && $0.date < tomorrowStart }
    }
    private var lastWeekTransactions: [MeowlettTransaction] {
        let previousStart = Calendar.current.date(byAdding: .day, value: -7, to: thisWeekStart) ?? thisWeekStart
        return store.transactions.filter { $0.date >= previousStart && $0.date < thisWeekStart }
    }
    private var thisWeekSpent: Int64 {
        thisWeekTransactions.reduce(Int64(0)) { $0 + $1.amount }
    }
    private var lastWeekSpent: Int64 {
        lastWeekTransactions.reduce(Int64(0)) { $0 + $1.amount }
    }
    private var topWeeklyCategory: String? {
        let grouped = Dictionary(grouping: thisWeekTransactions, by: \.category)
        return grouped.map { key, values in
            (key, values.reduce(Int64(0)) { $0 + $1.amount })
        }.max { $0.1 < $1.1 }?.0
    }
    private var averageMonthlySaved: Int64 {
        let calendar = Calendar.current
        let previousMonths = (1...3).compactMap { offset -> Int64? in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: .now) else { return nil }
            let expenses = store.transactions.filter {
                calendar.isDate($0.date, equalTo: date, toGranularity: .month)
            }.reduce(Int64(0)) { $0 + $1.amount }
            return expenses > 0 ? max(0, income - expenses) : nil
        }
        guard !previousMonths.isEmpty else { return 0 }
        return previousMonths.reduce(Int64(0), +) / Int64(previousMonths.count)
    }
    private var financialHealth: (score: Int, label: String, color: Color) {
        let ratio = income > 0 ? Double(spent) / Double(income) : 1
        let ratioPoints = income <= 0 ? 0 : ratio <= 0.5 ? 30 : ratio <= 0.7 ? 20 : ratio <= 0.9 ? 10 : 0
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: .now)?.count ?? 30
        let daysPassed = Calendar.current.component(.day, from: .now)
        let activeDays = Set(monthTransactions.map { Calendar.current.startOfDay(for: $0.date) }).count
        let consistencyPoints = Int((Double(activeDays) / Double(max(1, min(daysPassed, daysInMonth))) * 25).rounded())
        let streakPoints = min(15, Int((Double(currentStreak) / 7 * 15).rounded()))
        let goalPoints = savingsGoals.isEmpty ? 0 : (savingsGoals.contains(where: { $0.saved > 0 }) ? 15 : 8)
        let overBudgetCount = budgets.filter { key, limit in
            let categorySpent = monthTransactions.filter { $0.category == key }.reduce(Int64(0)) { $0 + $1.amount }
            return categorySpent > limit
        }.count
        let budgetPoints = overBudgetCount == 0 ? 15 : overBudgetCount == 1 ? 8 : 0
        let score = min(100, ratioPoints + consistencyPoints + streakPoints + goalPoints + budgetPoints)
        let label: String = score >= 80 ? (isEnglish ? "Excellent" : "Sangat Baik")
            : score >= 60 ? (isEnglish ? "Good" : "Baik")
            : score >= 40 ? (isEnglish ? "Fair" : "Cukup")
            : (isEnglish ? "Need Attention" : "Perlu Perhatian")
        let hex = score >= 80 ? "#4ade80" : score >= 60 ? AppAppearance.accentHex : score >= 40 ? "#fbbf24" : "#f87171"
        return (score, label, Color(hex: hex))
    }
    private var dailyHealthTip: String {
        let tipsID = [
            "Coba keluarkan di bawah 70% pemasukan",
            "Catat setiap transaksi hari ini",
            "Buat target tabungan untuk naikkan skor",
            "Buka app tiap hari untuk jaga streak",
            "Atur budget per kategori supaya terkontrol"
        ]
        let tipsEN = [
            "Try spending under 70% of income",
            "Record every transaction today",
            "Set a savings target to boost score",
            "Open the app daily to build your streak",
            "Set category budgets to stay on track"
        ]
        let day = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        let tips = isEnglish ? tipsEN : tipsID
        return tips[day % tips.count]
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
    private var dailySparklinePoints: [DashboardSparklinePoint] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -(6 - offset), to: .now) else { return nil }
            let total = store.transactions
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(Int64(0)) { $0 + $1.amount }
            let label = day.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "id_ID")))
            return DashboardSparklinePoint(
                total: total,
                dayLabel: label,
                isToday: calendar.isDateInToday(day)
            )
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

                    DashboardWeightedRow(weights: [1, 2], spacing: 12) {
                        streakCard
                        weeklyInsightCard
                    }

                    financialHealthCard
                    predictionCard
                    budgetCard
                    savingsGoalsCard
                    recentTransactionsCard
                    categoryBreakdownCard
                    paymentMethodStatsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 90)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(AppAppearance.background(dark: isDark))
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                loadPersistedDashboardData()
                updateStreak()
            }
            .onChange(of: budgets) { _, value in persistBudgets(value) }
            .onChange(of: savingsGoals) { _, value in persistSavingsGoals(value) }
            .onChange(of: activeSheet != nil) { _, presented in
                modalBlurCoordinator.set("dashboard", isPresented: presented)
            }
            .onDisappear { modalBlurCoordinator.set("dashboard", isPresented: false) }
                        .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .overallBudget:
                    NativeMoneyEntrySheet(
                        title: isEnglish ? "Monthly budget" : "Budget bulanan",
                        initialValue: Int64(overallBudgetRaw) ?? 0,
                        accent: Color(hex: AppAppearance.accentHex),
                        onSave: { overallBudgetRaw = String($0) }
                    )
                case .goalEditor:
                    DashboardGoalEditorSheet(goal: editingGoal) { saved in
                        if let index = savingsGoals.firstIndex(where: { $0.id == saved.id }) {
                            savingsGoals[index] = saved
                        } else {
                            savingsGoals.append(saved)
                        }
                        editingGoal = nil
                    }
                case .incomeEditor:
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
                                Button(isEnglish ? "Cancel" : "Batal") { activeSheet = nil }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button(isEnglish ? "Save" : "Simpan") {
                                    incomeRaw = String(Int64(incomeDraft.filter(\.isNumber)) ?? 0)
                                    activeSheet = nil
                                }
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }
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
                    activeSheet = .incomeEditor
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Text(isEnglish ? "INCOME" : "PEMASUKAN")
                                .font(MeowlettTypography.font(size: 7, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(.white.opacity(0.42))
                            Image(systemName: "pencil")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.white.opacity(0.42))
                        }
                        Text(rupiah(income))
                            .font(MeowlettTypography.font(size: 13, weight: .black))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currentMonthLabel.uppercased())
                        .font(MeowlettTypography.font(size: 7, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.4))
                    Text(Date.now.formatted(.dateTime.day()))
                        .font(MeowlettTypography.font(size: 22, weight: .black))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .padding(.bottom, 20)

            Text(isEnglish ? "MONTHLY EXPENSE" : "PENGELUARAN BULAN INI")
                .font(MeowlettTypography.font(size: 8, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.45))
            Text(rupiah(spent))
                .font(MeowlettTypography.font(size: 32, weight: .black))
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
            .font(MeowlettTypography.font(size: 10, weight: .regular))
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
            .font(MeowlettTypography.font(size: 10, weight: .regular))
            if remaining < 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#fca5a5"))
                    Text(isEnglish
                         ? "Spending exceeds income by \(rupiah(abs(remaining)))"
                         : "Pengeluaran melebihi pemasukan sebesar \(rupiah(abs(remaining)))")
                        .font(MeowlettTypography.font(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: "#fca5a5"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#ef4444").opacity(0.20), in: RoundedRectangle(cornerRadius: 12))
                .padding(.top, 12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .background {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: AppAppearance.darken(AppAppearance.primaryHex, ratio: 0.5)),
                            Color(hex: AppAppearance.darken(AppAppearance.primaryHex, ratio: 0.25)),
                            primary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Circle()
                        .fill(primary.opacity(0.55))
                        .frame(width: 240, height: 240)
                        .position(x: geometry.size.width - 55, y: geometry.size.height - 55)
                    RoundedRectangle(cornerRadius: 52)
                        .fill(accent.opacity(0.18))
                        .frame(width: 160, height: 250)
                        .rotationEffect(.degrees(-22))
                        .position(x: geometry.size.width - 65, y: 70)
                    Circle()
                        .fill(accent.opacity(0.10))
                        .frame(width: 145, height: 145)
                        .position(x: 32.5, y: 32.5)
                    Circle()
                        .fill(primary.opacity(0.25))
                        .frame(width: 90, height: 90)
                        .position(x: geometry.size.width * 0.33 + 45, y: geometry.size.height * 0.36 + 45)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 2)
    }

    private var streakCard: some View {
        let factsID = [
            "ATM pertama dipasang London 1967.",
            "Uang kertas pertama dari Tiongkok abad ke-7.",
            "'Salary' dari Latin — Romawi digaji garam.",
            "Warren Buffett beli saham pertama usia 11 tahun.",
            "Koin pertama dicetak di Lydia (Turki) ~600 SM.",
            "Orang 12-18% lebih boros bayar kartu vs tunai.",
            "Belanja pengalaman lebih membahagiakan dari beli barang.",
            "Simbol '$' dari singkatan peso Spanyol.",
            "Penny AS biaya produksi > nilai nominalnya.",
            "Uang Monopoly dicetak lebih banyak dari dolar asli.",
            "Swedia hampir jadi negara cashless pertama.",
            "Bunga majemuk = keajaiban ke-8 dunia (Einstein).",
            "Dana darurat ideal 3-6 bulan pengeluaran.",
            "Aturan 50/30/20: kebutuhan/keinginan/tabungan.",
            "Inflasi 5%/tahun buat Rp1jt jadi Rp614rb dalam 10 tahun.",
            "Aturan 72: bagi 72 dgn bunga = tahun uang berlipat.",
            "Jeff Bezos mulai Amazon dari garasi, modal $250rb.",
            "Bitcoin pertama ditambang 3 Januari 2009.",
            "Bursa saham pertama di Amsterdam tahun 1602.",
            "Pasar saham global tak pernah rugi dalam 20 tahun mana pun.",
            "1,7 miliar orang dewasa dunia tak punya rekening bank.",
            "Rata-rata orang kaya punya 7 sumber pendapatan.",
            "Index fund kalahkan fund aktif 85% waktu dalam 15 tahun.",
            "Dollar Cost Averaging lebih baik dari timing pasar.",
            "Stres finansial = penyebab konflik #1 dalam hubungan.",
            "Kaya bukan soal berapa banyak kamu hasilkan tapi yang disimpan.",
            "Waktu terbaik investasi: 20 tahun lalu. Kedua: sekarang.",
            "Orang kaya beli aset, bukan liabilitas.",
            "Dana pensiun Indonesia rata-rata hanya cukup 3-5 tahun.",
            "QRIS diluncurkan Bank Indonesia tahun 2019."
        ]
        let factsEN = [
            "First ATM installed London 1967.",
            "Paper money originated China 7th century.",
            "'Salary' from Latin — Romans paid in salt.",
            "Warren Buffett bought first stock at age 11.",
            "World's first coin minted Lydia (Turkey) ~600 BC.",
            "People spend 12-18% more paying by card vs cash.",
            "Experiences bring more happiness than buying things.",
            "'$' symbol from Spanish peso abbreviation.",
            "US penny costs more to make than its face value.",
            "More Monopoly money printed annually than real dollars.",
            "Sweden close to becoming first cashless society.",
            "Compound interest = 8th wonder of world (Einstein).",
            "Ideal emergency fund: 3-6 months expenses.",
            "50/30/20 rule: needs/wants/savings.",
            "5% annual inflation turns $1,000 into $614 over 10 years.",
            "Rule of 72: divide 72 by rate = years to double.",
            "Jeff Bezos started Amazon in garage with $250k.",
            "Bitcoin first mined January 3, 2009.",
            "World's first stock exchange founded Amsterdam 1602.",
            "Global stock market never lost money over any 20-year period.",
            "1.7 billion adults worldwide lack bank accounts.",
            "Average wealthy person has 7 income streams.",
            "Index funds beat active funds 85% of the time.",
            "Dollar Cost Averaging beats market timing consistently.",
            "Financial stress = #1 cause of relationship conflict.",
            "Wealth is not how much you earn but how much you keep.",
            "Best time to invest: 20 years ago. Second best: now.",
            "Rich people buy assets, not liabilities.",
            "FOMO is one of the leading causes of poor investment decisions.",
            "Paying yourself first is the #1 wealth-building habit."
        ]
        let today = Calendar.current.dateComponents([.day, .month], from: .now)
        let index = ((today.day ?? 1) + ((today.month ?? 1) - 1) * 31 + currentStreak) % 30
        let fact = (isEnglish ? factsEN : factsID)[index]

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: AppAppearance.accentHex).opacity(0.13))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(systemName: "flame")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: AppAppearance.accentHex))
                    )
                Text("STREAK")
                    .font(MeowlettTypography.font(size: 11, weight: .heavy))
                    .tracking(0.3)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(currentStreak)")
                    .font(MeowlettTypography.font(size: 28, weight: .black))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(isEnglish ? " days" : " hari")
                    .font(MeowlettTypography.font(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Image(systemName: currentStreak >= 7 ? "flame" : currentStreak >= 3 ? "diamond" : "calendar")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(currentStreak >= 7 ? Color(hex: AppAppearance.accentHex) : Color(hex: "#4ade80"))
                Text(currentStreak >= 7 ? (isEnglish ? "On fire!" : "Konsisten!") : currentStreak >= 3 ? (isEnglish ? "Keep going!" : "Teruskan!") : (isEnglish ? "Open daily" : "Buka tiap hari"))
                    .font(MeowlettTypography.font(size: 10, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 6)

            Text("\"\(fact)\"")
                .font(MeowlettTypography.font(size: 9, weight: .regular))
                .italic()
                .foregroundStyle(.secondary)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private var weeklyInsightCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: AppAppearance.accentHex).opacity(0.13))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(systemName: "bolt")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: AppAppearance.accentHex))
                    )
                Text(isEnglish ? "THIS WEEK" : "MINGGU INI")
                    .font(MeowlettTypography.font(size: 11, weight: .heavy))
                    .tracking(0.3)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 6)

            if thisWeekSpent == 0 {
                Text(isEnglish ? "No spending this week yet." : "Belum ada transaksi minggu ini.")
                    .font(MeowlettTypography.font(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            } else {
                Text(rupiah(thisWeekSpent))
                    .font(MeowlettTypography.font(size: 18, weight: .black))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.bottom, 3)

                if lastWeekSpent > 0 && thisWeekSpent != lastWeekSpent {
                    let difference = thisWeekSpent - lastWeekSpent
                    Text("\(difference > 0 ? "▲" : "▼") \(rupiah(abs(difference))) " + (isEnglish ? "vs last week" : "vs minggu lalu"))
                        .font(MeowlettTypography.font(size: 11, weight: .bold))
                        .foregroundStyle(difference > 0 ? Color(hex: "#f87171") : Color(hex: "#4ade80"))
                        .padding(.bottom, 3)
                }

                if let topWeeklyCategory {
                    (
                        Text(isEnglish ? "Most: " : "Terbanyak: ")
                            .foregroundColor(AppAppearance.textSub(dark: isDark))
                        + Text(MeowlettCategory.name(for: topWeeklyCategory, language: language))
                            .fontWeight(.bold)
                            .foregroundColor(MeowlettCategory.color(for: topWeeklyCategory))
                    )
                    .font(MeowlettTypography.font(size: 11, weight: .regular))
                    .lineLimit(1)
                    .padding(.bottom, 6)
                }

                DashboardWeeklySparkline(
                    values: dailySparklinePoints,
                    accent: Color(hex: AppAppearance.accentHex),
                    card: AppAppearance.card(dark: isDark),
                    textSub: AppAppearance.textSub(dark: isDark)
                )
                .padding(.top, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    @ViewBuilder
    private var predictionCard: some View {
        let dayOfMonth = Calendar.current.component(.day, from: .now)
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: .now)?.count ?? 30
        if dayOfMonth >= 3 && spent > 0 && income > 0 {
            let predicted = Int64((Double(spent) / Double(dayOfMonth) * Double(daysInMonth)).rounded())
            let isOver = predicted > income
            let stateColor = isOver ? Color(hex: "#f87171") : Color(hex: AppAppearance.accentHex)
            HStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(stateColor)
                    .frame(width: 36, height: 36)
                    .background(stateColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(isEnglish ? "MONTH PREDICTION" : "PREDIKSI AKHIR BULAN")
                        .font(MeowlettTypography.font(size: 11, weight: .heavy))
                        .tracking(0.3)
                        .foregroundStyle(.secondary)
                    (
                        Text(isEnglish ? "Est. spending: " : "Est. pengeluaran: ")
                            .foregroundColor(AppAppearance.text(dark: isDark))
                        + Text(rupiah(predicted))
                            .fontWeight(.black)
                            .foregroundColor(stateColor)
                    )
                    .font(MeowlettTypography.font(size: 13, weight: .bold))
                    .lineSpacing(1)
                    HStack(spacing: 4) {
                        Image(systemName: isOver ? "exclamationmark.triangle" : "checkmark.circle")
                            .font(.system(size: 11, weight: .semibold))
                        Text(isOver
                             ? (isEnglish ? "Over budget this month" : "Kemungkinan over budget bulan ini")
                             : (isEnglish ? "On track · est. saving " + rupiah(income - predicted) : "Aman · estimasi sisa " + rupiah(income - predicted)))
                            .font(MeowlettTypography.font(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(stateColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
            .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
        }
    }

    private var financialHealthCard: some View {
        let score = financialHealth
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(score.color)
                        .frame(width: 28, height: 28)
                        .background(score.color.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
                    Text(isEnglish ? "FINANCIAL HEALTH" : "KESEHATAN FINANSIAL")
                        .font(MeowlettTypography.font(size: 12, weight: .heavy))
                        .tracking(0.5)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(score.score)")
                        .font(MeowlettTypography.font(size: 26, weight: .black))
                        .foregroundStyle(score.color)
                    Text("/100")
                        .font(MeowlettTypography.font(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 10)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(isDark ? 0.08 : 0.07))
                    Capsule()
                        .fill(LinearGradient(colors: [score.color.opacity(0.53), score.color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * CGFloat(score.score) / 100)
                }
            }
            .frame(height: 8)
            .padding(.bottom, 8)

            HStack(alignment: .center, spacing: 8) {
                Text(score.label)
                    .font(MeowlettTypography.font(size: 12, weight: .bold))
                    .foregroundStyle(score.color)
                Spacer(minLength: 3)
                Text(dailyHealthTip)
                    .font(MeowlettTypography.font(size: 10, weight: .bold))
                    .foregroundStyle(score.color)
                    .multilineTextAlignment(.trailing)
                    .lineSpacing(1)
                    .lineLimit(2)
                    .frame(maxWidth: 190, alignment: .trailing)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(score.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private var budgetCard: some View {
        let overall = Int64(overallBudgetRaw) ?? 0
        let entries = MeowlettCategory.all.compactMap { category -> (String, Int64)? in
            guard let limit = budgets[category.id], limit > 0 else { return nil }
            return (category.id, limit)
        }
        let primary = Color(hex: AppAppearance.primaryHex)
        let accent = Color(hex: AppAppearance.accentHex)
        let readablePrimary = isDark
            ? Color(hex: AppAppearance.lighten(AppAppearance.primaryHex, ratio: 0.45))
            : AppAppearance.readablePrimaryOnLight()

        return Group {
            if entries.isEmpty && overall <= 0 {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(readablePrimary.opacity(0.10))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "wallet")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(readablePrimary)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isEnglish ? "Monthly budget" : "Budget Bulanan")
                            .font(MeowlettTypography.font(size: 13, weight: .heavy))
                            .foregroundStyle(.primary)
                        Text(isEnglish
                             ? "No budget set yet. Tap to set one."
                             : "Belum ada anggaran. Tap untuk mengatur.")
                            .font(MeowlettTypography.font(size: 11, weight: .regular))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    Button {
                        activeSheet = .overallBudget
                    } label: {
                        Text(isEnglish ? "Set Budget" : "Atur Anggaran")
                            .font(MeowlettTypography.font(size: 11, weight: .heavy))
                            .foregroundStyle(readablePrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(readablePrimary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(readablePrimary.opacity(0.20), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 7) {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(readablePrimary.opacity(0.10))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(readablePrimary)
                            )
                        Text(isEnglish ? "Monthly budget" : "Budget Bulanan")
                            .font(MeowlettTypography.font(size: 14, weight: .heavy))
                            .foregroundStyle(.primary)
                        Spacer()
                        Button { activeSheet = .overallBudget } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.secondary)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        if overall > 0 {
                            budgetProgressRow(
                                title: isEnglish ? "Total Monthly" : "Total Bulanan",
                                spent: spent,
                                limit: overall,
                                color: accent,
                                showIcon: false
                            )
                        }
                        ForEach(Array(entries.prefix(4).enumerated()), id: \.offset) { _, entry in
                            categoryBudgetRow(entry.0, limit: entry.1)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private func categoryBudgetRow(_ key: String, limit: Int64) -> some View {
        let category = MeowlettCategory.all.first(where: { $0.id == key })
        let spent = monthTransactions.filter { $0.category == key }.reduce(Int64(0)) { $0 + $1.amount }
        let percentage = limit > 0 ? min(100, Int((Double(spent) / Double(limit) * 100).rounded())) : 0
        let over = percentage >= 100
        let warning = percentage >= 80
        let color = Color(hex: category?.color ?? "#94a3b8")
        let stateColor = over ? Color(hex: "#ef4444") : warning ? Color(hex: "#f59e0b") : Color(hex: AppAppearance.accentHex)
        let barColors = over
            ? [Color(hex: "#ef4444"), Color(hex: "#fca5a5")]
            : warning
                ? [Color(hex: "#f59e0b"), Color(hex: "#fcd34d")]
                : [Color(hex: AppAppearance.primaryHex), Color(hex: AppAppearance.accentHex)]

        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: category?.icon ?? "tag")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(color)
                Text(MeowlettCategory.name(for: key, language: language))
                    .font(MeowlettTypography.font(size: 12, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 3)
                Button {
                    budgets[key] = 0
                } label: {
                    Text("✕")
                        .font(MeowlettTypography.font(size: 11, weight: .medium))
                        .foregroundStyle(.secondary.opacity(0.6))
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
                Button {
                    budgets[key] = (budgets[key] ?? limit) + 50_000
                } label: {
                    HStack(spacing: 3) {
                        Text("\(percentage)%")
                            .font(MeowlettTypography.font(size: 12, weight: .heavy))
                        if over {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .foregroundStyle(stateColor)
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(isDark ? 0.06 : 0.06))
                    Capsule()
                        .fill(LinearGradient(colors: barColors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * CGFloat(percentage) / 100)
                }
            }
            .frame(height: 6)

            Text("\(rupiah(spent)) / \(rupiah(limit))")
                .font(MeowlettTypography.font(size: 10, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.top, -2)
        }
    }

    private func budgetProgressRow(title: String, spent: Int64, limit: Int64, color: Color, showIcon: Bool) -> some View {
        let percentage = limit > 0 ? min(100, Int((Double(spent) / Double(limit) * 100).rounded())) : 0
        let over = percentage >= 100
        let warning = percentage >= 80
        let stateColor = over ? Color(hex: "#ef4444") : warning ? Color(hex: "#f59e0b") : Color(hex: AppAppearance.accentHex)
        let barColors = over
            ? [Color(hex: "#ef4444"), Color(hex: "#fca5a5")]
            : warning
                ? [Color(hex: "#f59e0b"), Color(hex: "#fcd34d")]
                : [Color(hex: AppAppearance.primaryHex), Color(hex: AppAppearance.accentHex)]

        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                if showIcon { Circle().fill(color).frame(width: 7, height: 7) }
                Text(title)
                    .font(MeowlettTypography.font(size: 12, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                HStack(spacing: 3) {
                    Text("\(percentage)%")
                        .font(MeowlettTypography.font(size: 12, weight: .heavy))
                    if over {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .foregroundStyle(stateColor)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(isDark ? 0.06 : 0.06))
                    Capsule()
                        .fill(LinearGradient(colors: barColors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * CGFloat(percentage) / 100)
                }
            }
            .frame(height: 6)
            Text("\(rupiah(spent)) / \(rupiah(limit))")
                .font(MeowlettTypography.font(size: 10, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.top, -2)
        }
    }

    private var savingsGoalsCard: some View {
        let primaryText = isDark
            ? Color(hex: AppAppearance.lighten(AppAppearance.primaryHex, ratio: 0.45))
            : AppAppearance.readablePrimaryOnLight()
        let accent = Color(hex: AppAppearance.accentHex)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(primaryText.opacity(0.10))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "banknote")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(primaryText)
                    )
                Text(isEnglish ? "Savings goals" : "Target Tabungan")
                    .font(MeowlettTypography.font(size: 14, weight: .heavy))
                    .foregroundStyle(.primary)
                Spacer()
                if !savingsGoals.isEmpty {
                    Button {
                        editingGoal = nil
                        activeSheet = .goalEditor
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text(isEnglish ? "Add" : "Tambah")
                                .font(MeowlettTypography.font(size: 12, weight: .bold))
                        }
                        .foregroundStyle(primaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 14)

            if savingsGoals.isEmpty {
                VStack(spacing: 0) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.13), Color(hex: AppAppearance.primaryHex).opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(accent.opacity(0.22), lineWidth: 1.5))
                        .overlay(
                            Image(systemName: "rocket")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(primaryText)
                        )
                        .padding(.bottom, 10)

                    Text(isEnglish ? "No savings goals yet" : "Belum ada target tabungan")
                        .font(MeowlettTypography.font(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                        .padding(.bottom, 4)

                    Text(isEnglish ? "Create your first savings goal!" : "Yuk, buat target pertamamu!")
                        .font(MeowlettTypography.font(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 14)

                    Button {
                        editingGoal = nil
                        activeSheet = .goalEditor
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text(isEnglish ? "Add goal" : "Tambah target")
                                .font(MeowlettTypography.font(size: 13, weight: .heavy))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 8)
            } else {
                VStack(spacing: 14) {
                    ForEach(savingsGoals) { goal in
                        savingsGoalRow(goal)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private func savingsGoalRow(_ goal: DashboardSavingsGoal) -> some View {
        let percentage = goal.target > 0 ? min(100, Int((Double(goal.saved) / Double(goal.target) * 100).rounded())) : 0
        let remaining = max(0, goal.target - goal.saved)
        let color = Color(hex: goal.color)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: goal.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.label).font(MeowlettTypography.font(size: 13, weight: .bold))
                    Text("\(rupiah(goal.saved)) / \(rupiah(goal.target))")
                        .font(MeowlettTypography.font(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(percentage)%")
                    .font(MeowlettTypography.font(size: 13, weight: .black))
                    .foregroundStyle(percentage >= 100 ? Color(hex: "#4ade80") : color)
                Button {
                    editingGoal = goal
                    activeSheet = .goalEditor
                } label: {
                    Image(systemName: "pencil").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Button {
                    savingsGoals.removeAll { $0.id == goal.id }
                } label: {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            if percentage >= 100 {
                GoalConfettiStrip(goalColor: color)
                    .frame(height: 20)
                    .padding(.bottom, 2)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(isDark ? 0.06 : 0.06))
                    Capsule().fill(percentage >= 100 ? Color(hex: "#4ade80") : color)
                        .frame(width: proxy.size.width * CGFloat(percentage) / 100)
                }
            }
            .frame(height: 6)
            .padding(.bottom, 4)
            if remaining > 0 {
                HStack(spacing: 4) {
                    Text((isEnglish ? "Remaining " : "Sisa ") + rupiah(remaining))
                        .font(MeowlettTypography.font(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    if let deadline = goal.deadline, let date = dateFromISO(deadline) {
                        let days = Calendar.current.dateComponents(
                            [.day],
                            from: Calendar.current.startOfDay(for: .now),
                            to: Calendar.current.startOfDay(for: date)
                        ).day ?? 0
                        Text("·").foregroundStyle(.secondary)
                        Text(days < 0
                             ? (isEnglish ? "Overdue" : "Terlambat")
                             : days <= 7
                                ? "\(days) " + (isEnglish ? "days left" : "hari lagi")
                                : date.formatted(.dateTime.day().month(.abbreviated).year()))
                            .font(MeowlettTypography.font(size: 10, weight: .semibold))
                            .foregroundStyle(days < 0 ? Color(hex: "#f87171") : days <= 7 ? Color(hex: "#f59e0b") : Color.secondary)
                    }
                }
            } else {
                Label(isEnglish ? "Goal reached" : "Target tercapai", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: AppAppearance.accentHex))
            }
            if percentage < 100 && remaining > 0 && averageMonthlySaved > 0 {
                let months = Int(ceil(Double(remaining) / Double(averageMonthlySaved)))
                let estimate: String = {
                    if months <= 1 { return isEnglish ? "< 1 month away" : "< 1 bulan lagi" }
                    if months < 12 { return isEnglish ? "\(months) months away" : "\(months) bulan lagi" }
                    let years = months / 12
                    let extraMonths = months % 12
                    return isEnglish
                        ? "\(years)y\(extraMonths > 0 ? " \(extraMonths)m" : "") away"
                        : "\(years)th\(extraMonths > 0 ? " \(extraMonths)bl" : "") lagi"
                }()
                Text("Est. " + estimate)
                    .font(MeowlettTypography.font(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            if percentage < 100 {
                if quickAddGoalID == goal.id {
                    HStack(spacing: 6) {
                        TextField(isEnglish ? "Savings amount" : "Nominal tabungan", text: Binding(
                            get: { quickAddAmountDisplay },
                            set: { value in
                                let digits = value.filter(\.isNumber)
                                quickAddAmount = digits
                                quickAddAmountDisplay = formattedNumber(digits)
                            }
                        ))
                        .keyboardType(.numberPad)
                        .font(MeowlettTypography.font(size: 13, weight: .regular))
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(AppAppearance.input(dark: isDark), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.27), lineWidth: 1.5))

                        Button {
                            let value = Int64(quickAddAmount) ?? 0
                            guard value > 0, let index = savingsGoals.firstIndex(where: { $0.id == goal.id }) else {
                                quickAddGoalID = nil
                                quickAddAmount = ""
                                quickAddAmountDisplay = ""
                                return
                            }
                            savingsGoals[index].saved += value
                            quickAddGoalID = nil
                            quickAddAmount = ""
                            quickAddAmountDisplay = ""
                        } label: {
                            Text(isEnglish ? "Save" : "Simpan")
                                .font(MeowlettTypography.font(size: 12, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(color, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        Button {
                            quickAddGoalID = nil
                            quickAddAmount = ""
                            quickAddAmountDisplay = ""
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(AppAppearance.textSub(dark: isDark))
                                .frame(width: 34, height: 38)
                                .background(AppAppearance.input(dark: isDark), in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        quickAddGoalID = goal.id
                        quickAddAmount = ""
                        quickAddAmountDisplay = ""
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .semibold))
                            Text(isEnglish ? "Add savings" : "Tambah tabungan")
                                .font(MeowlettTypography.font(size: 11, weight: .bold))
                        }
                        .foregroundStyle(color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.27), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func formattedNumber(_ digits: String) -> String {
        guard let value = Int64(digits), value > 0 else { return "" }
        return NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
    }

    private func dateFromISO(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    private func updateStreak() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: .now)
        guard let data = streakRaw.data(using: .utf8),
              var state = try? JSONDecoder().decode(DashboardStreakData.self, from: data) else { return }
        guard state.lastDate != today else { return }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now).map { formatter.string(from: $0) } ?? ""
        state.count = state.lastDate == yesterday ? state.count + 1 : 1
        state.lastDate = today
        if let encoded = try? JSONEncoder().encode(state),
           let value = String(data: encoded, encoding: .utf8) {
            streakRaw = value
        }
    }

    private func loadPersistedDashboardData() {
        guard !storageLoaded else { return }
        if let data = budgetsRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: Int64].self, from: data) {
            budgets = decoded
        }
        if let data = savingsGoalsRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([DashboardSavingsGoal].self, from: data) {
            savingsGoals = decoded
        }
        storageLoaded = true
    }

    private func persistBudgets(_ value: [String: Int64]) {
        guard storageLoaded, let data = try? JSONEncoder().encode(value),
              let string = String(data: data, encoding: .utf8) else { return }
        budgetsRaw = string
    }

    private func persistSavingsGoals(_ value: [DashboardSavingsGoal]) {
        guard storageLoaded, let data = try? JSONEncoder().encode(value),
              let string = String(data: data, encoding: .utf8) else { return }
        savingsGoalsRaw = string
    }

    private var paymentMethodStatsCard: some View {
        let primaryText = isDark
            ? Color(hex: AppAppearance.lighten(AppAppearance.primaryHex, ratio: 0.45))
            : AppAppearance.readablePrimaryOnLight()
        let trackColor = isDark ? AppAppearance.card2(dark: true) : AppAppearance.input(dark: false)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(primaryText.opacity(0.10))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "wallet.bifold")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(primaryText)
                    )
                Text(isEnglish ? "Payment Method" : "Metode Bayar")
                    .font(MeowlettTypography.font(size: 14, weight: .heavy))
                    .foregroundStyle(.primary)
            }
            .padding(.bottom, 12)

            let total = monthTransactions.reduce(Int64(0)) { $0 + $1.amount }
            VStack(spacing: 10) {
                ForEach(["cash", "transfer", "qris"], id: \.self) { method in
                    let values = monthTransactions.filter { ($0.paymentMethod.isEmpty ? "cash" : $0.paymentMethod) == method }
                    let amount = values.reduce(Int64(0)) { $0 + $1.amount }
                    let percentage = total > 0 ? Int((Double(amount) / Double(total) * 100).rounded()) : 0
                    let color = method == "cash"
                        ? Color(hex: "#4ade80")
                        : method == "transfer" ? Color(hex: "#3b82f6") : Color(hex: "#8b5cf6")
                    let title = method == "cash"
                        ? (isEnglish ? "Cash" : "Tunai")
                        : method == "transfer" ? "Transfer" : "QRIS"
                    let symbol = method == "cash"
                        ? "dollarsign.circle"
                        : method == "transfer" ? "building.columns" : "qrcode"

                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: symbol)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(color)
                                Text(title)
                                    .font(MeowlettTypography.font(size: 13, weight: .bold))
                                    .foregroundStyle(.primary)
                                Text("\(values.count)x")
                                    .font(MeowlettTypography.font(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("-\(rupiah(amount))")
                                    .font(MeowlettTypography.font(size: 13, weight: .heavy))
                                    .foregroundStyle(Color(hex: "#f87171"))
                                Text("\(percentage)%")
                                    .font(MeowlettTypography.font(size: 10, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule().fill(trackColor)
                                Capsule()
                                    .fill(color)
                                    .frame(width: proxy.size.width * CGFloat(percentage) / 100)
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private var categoryBreakdownCard: some View {
        let primaryText = isDark
            ? Color(hex: AppAppearance.lighten(AppAppearance.primaryHex, ratio: 0.45))
            : AppAppearance.readablePrimaryOnLight()

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(primaryText.opacity(0.10))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "chart.pie")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(primaryText)
                    )
                Text(isEnglish ? "Category Breakdown" : "Rincian Kategori")
                    .font(MeowlettTypography.font(size: 14, weight: .heavy))
                    .foregroundStyle(.primary)
            }
            .padding(.bottom, 4)

            if categoryTotals.isEmpty {
                VStack(spacing: 0) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: AppAppearance.accentHex).opacity(0.13),
                                    Color(hex: AppAppearance.primaryHex).opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(Color(hex: AppAppearance.accentHex).opacity(0.22), lineWidth: 1.5))
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(primaryText)
                        )
                        .padding(.bottom, 14)

                    Text(isEnglish ? "No data" : "Belum ada data")
                        .font(MeowlettTypography.font(size: 16, weight: .heavy))
                        .foregroundStyle(.primary)
                        .padding(.bottom, 8)

                    Text(isEnglish
                         ? "Start recording expenses to see your breakdown."
                         : "Mulai catat pengeluaran untuk melihat rinciannya.")
                        .font(MeowlettTypography.font(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            } else {
                HStack(alignment: .center, spacing: 16) {
                    let chartSize = min(170, max(130, UIScreen.main.bounds.width * 0.36))
                    ZStack {
                        DonutBreakdown(
                            values: categoryTotals,
                            totalText: rupiah(spent),
                            textSub: AppAppearance.textSub(dark: isDark),
                            textColor: AppAppearance.text(dark: isDark),
                            size: chartSize
                        )
                        // Match the PWA SVG's 90% outer diameter, 58% inner diameter,
                        // and 11.2pt ring thickness at a 140pt rendered chart.
                        .frame(width: chartSize * 104 / 140, height: chartSize * 104 / 140)
                    }
                    .frame(width: chartSize, height: chartSize)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categoryTotals, id: \.category) { item in
                            let share = spent > 0
                                ? Int((Double(item.amount) / Double(spent) * 100).rounded())
                                : 0
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(MeowlettCategory.color(for: item.category))
                                    .frame(width: 9, height: 9)
                                Text(MeowlettCategory.name(for: item.category, language: language))
                                    .font(MeowlettTypography.font(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Spacer(minLength: 2)
                                Text("\(share)%")
                                    .font(MeowlettTypography.font(size: 13, weight: .heavy))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private var recentTransactionsCard: some View {
        let recent = Array(store.transactions.sorted {
            let left = $0.createdAt ?? $0.date
            let right = $1.createdAt ?? $1.date
            if left == right { return $0.id.uuidString > $1.id.uuidString }
            return left > right
        }.prefix(recentCount))
        let primaryText = isDark
            ? Color(hex: AppAppearance.lighten(AppAppearance.primaryHex, ratio: 0.45))
            : AppAppearance.readablePrimaryOnLight()

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(primaryText.opacity(0.10))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "receipt")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(primaryText)
                    )
                Text(isEnglish ? "Recent Transactions" : "Transaksi Terbaru")
                    .font(MeowlettTypography.font(size: 14, weight: .heavy))
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: onSeeAllTransactions) {
                    HStack(spacing: 3) {
                        Text(isEnglish ? "See All" : "Lihat Semua")
                            .font(MeowlettTypography.font(size: 12, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(primaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 14)

            if recent.isEmpty {
                VStack(spacing: 0) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: AppAppearance.accentHex).opacity(0.13),
                                    Color(hex: AppAppearance.primaryHex).opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(Color(hex: AppAppearance.accentHex).opacity(0.22), lineWidth: 1.5))
                        .overlay(
                            Image(systemName: "hand.coins")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(primaryText)
                        )
                        .padding(.bottom, 14)

                    Text(isEnglish ? "No transactions yet" : "Belum ada transaksi")
                        .font(MeowlettTypography.font(size: 15, weight: .black))
                        .foregroundStyle(.primary)
                        .padding(.bottom, 6)

                    Text(isEnglish
                         ? "Start recording your first transaction today!"
                         : "Yuk, mulai catat pengeluaran pertamamu hari ini!")
                        .font(MeowlettTypography.font(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.bottom, 18)

                    Button(action: onAddTransaction) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text(isEnglish ? "Record Now" : "Catat Sekarang")
                                .font(MeowlettTypography.font(size: 13, weight: .heavy))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(Color(hex: AppAppearance.accentHex), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 10) {
                    ForEach(recent) { transaction in
                        recentTransactionRow(transaction)
                    }
                }
            }

            if store.transactions.count > recentCount {
                Button {
                    recentCount += 5
                } label: {
                    Text(isEnglish ? "Show More" : "Lihat Lebih")
                        .font(MeowlettTypography.font(size: 14, weight: .bold))
                        .foregroundStyle(isDark ? Color(hex: "#e5e7eb") : Color(hex: "#374151"))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 13)
                        .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppAppearance.border(dark: isDark), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
        }
        .padding(16)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private func recentTransactionRow(_ transaction: MeowlettTransaction) -> some View {
        let category = MeowlettCategory.all.first(where: { $0.id == transaction.category })
        let categoryColor = Color(hex: category?.color ?? "#94a3b8")
        let dateText: String = {
            if Calendar.current.isDateInToday(transaction.date) {
                return isEnglish ? "Today" : "Hari ini"
            }
            if Calendar.current.isDateInYesterday(transaction.date) {
                return isEnglish ? "Yesterday" : "Kemarin"
            }
            return transaction.date.formatted(
                .dateTime.weekday(.wide).day().month(.wide)
                    .locale(Locale(identifier: isEnglish ? "en_GB" : "id_ID"))
            )
        }()

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(categoryColor.opacity(0.10))
                .frame(width: 40, height: 40)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(categoryColor.opacity(0.15), lineWidth: 1))
                .overlay(
                    Image(systemName: category?.icon ?? "shippingbox")
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(categoryColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(MeowlettTypography.font(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(MeowlettCategory.name(for: transaction.category, language: language)) · \(dateText)")
                    .font(MeowlettTypography.font(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("-\(rupiah(transaction.amount))")
                .font(MeowlettTypography.font(size: 13, weight: .heavy))
                .foregroundStyle(Color(hex: "#f87171"))
                .lineLimit(1)
        }
    }

    private func sectionHeading(_ title: String, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: AppAppearance.accentHex))
                .frame(width: 28, height: 28)
                .background(Color(hex: AppAppearance.accentHex).opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
            Text(title).font(MeowlettTypography.font(size: 14, weight: .heavy))
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

private struct DashboardStreakData: Codable {
    var count: Int
    var lastDate: String
}

private struct DashboardSavingsGoal: Identifiable, Codable, Equatable {
    var id: Int64
    var label: String
    var target: Int64
    var saved: Int64
    var color: String
    var icon: String
    var deadline: String?

    var symbol: String {
        switch icon {
        case "phone": return "iphone"
        case "laptop": return "laptopcomputer"
        case "car": return "car.fill"
        case "home": return "house.fill"
        case "plane": return "airplane"
        case "gift": return "gift.fill"
        case "camera": return "camera.fill"
        case "book": return "book.fill"
        case "music": return "music.note"
        case "game": return "gamecontroller.fill"
        case "heart": return "heart.fill"
        case "shopping": return "bag.fill"
        case "dumbbell": return "dumbbell.fill"
        case "wallet": return "wallet.bifold"
        case "star": return "sparkles"
        default: return "banknote"
        }
    }
}

private struct NativeMoneyEntrySheet: View {
    let title: String
    let initialValue: Int64
    let accent: Color
    let onSave: (Int64) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("gm_lang") private var language = "id"
    @State private var amountText = ""
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(MeowlettTypography.font(size: 17, weight: .black))
            Text(language == "en" ? "Enter an amount in Indonesian rupiah." : "Masukkan nominal dalam Rupiah.")
                .font(MeowlettTypography.font(size: 12, weight: .regular)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Text("Rp").font(MeowlettTypography.font(size: 15, weight: .bold)).foregroundStyle(.secondary)
                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .font(MeowlettTypography.font(size: 21, weight: .black))
                    .onChange(of: amountText) { _, value in
                        let digits = String(value.filter(\.isNumber))
                        if digits != value {
                            let formatter = NumberFormatter()
                            formatter.locale = Locale(identifier: "id_ID")
                            formatter.numberStyle = .decimal
                            amountText = formatter.string(from: NSNumber(value: Int64(digits) ?? 0)) ?? ""
                        }
                    }
            }
            .padding(14)
            .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.55), lineWidth: 1.5))
            HStack(spacing: 10) {
                Button(language == "en" ? "Cancel" : "Batal") { dismiss() }
                    .foregroundStyle(.primary).frame(maxWidth: .infinity).frame(height: 45)
                    .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 13))
                Button(language == "en" ? "Save" : "Simpan") {
                    onSave(Int64(amountText.filter(\.isNumber)) ?? 0)
                    dismiss()
                }
                .fontWeight(.heavy).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 45)
                .background(accent, in: RoundedRectangle(cornerRadius: 13))
            }
        }
        .padding(20)
        .background(AppAppearance.modal(dark: isDark))
        .presentationDetents([.height(250)])
        .presentationDragIndicator(.visible)
        .onAppear {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "id_ID")
            formatter.numberStyle = .decimal
            amountText = initialValue > 0 ? (formatter.string(from: NSNumber(value: initialValue)) ?? String(initialValue)) : ""
        }
    }
}

private struct GoalConfettiStrip: View {
    let goalColor: Color
    private let confettiColors: [Color] = [
        Color(hex: "#fbbf24"),
        Color(hex: "#34d399"),
        Color(hex: "#f87171"),
        Color(hex: "#c084fc")
    ]
    @State private var falling = false

    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index == 0 ? goalColor : confettiColors[(index - 1) % confettiColors.count])
                    .frame(width: 6, height: 6)
                    .rotationEffect(.degrees(falling ? 720 : 0))
                    .position(
                        x: geometry.size.width * CGFloat(0.08 + Double(index) * 0.18),
                        y: falling ? 54 : 0
                    )
                    .opacity(falling ? 0 : 1)
                    .animation(
                        .easeOut(duration: 0.8)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.12),
                        value: falling
                    )
            }
        }
        .onAppear { falling = true }
    }
}

private struct DashboardSparklinePoint {
    let total: Int64
    let dayLabel: String
    let isToday: Bool
}

private struct DashboardWeeklySparkline: View {
    let values: [DashboardSparklinePoint]
    let accent: Color
    let card: Color
    let textSub: Color

    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { proxy in
                let maximum = Double(max(values.map(\.total).max() ?? 0, 1))
                let points = values.enumerated().map { index, item in
                    CGPoint(
                        x: proxy.size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1)),
                        y: 28 - CGFloat(Double(item.total) / maximum) * 28
                    )
                }

                ZStack {
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: first)
                        for point in points.dropFirst() { path.addLine(to: point) }
                    }
                    .stroke(accent.opacity(0.7), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

                    ForEach(Array(values.enumerated()), id: \.offset) { index, item in
                        if item.total > 0 {
                            let point = points[index]
                            Circle()
                                .fill(item.isToday ? accent : card)
                                .frame(width: item.isToday ? 6 : 4, height: item.isToday ? 6 : 4)
                                .overlay(Circle().stroke(accent, lineWidth: 1.5))
                                .position(point)
                        }
                    }
                }
            }
            .frame(height: 30)

            HStack(spacing: 0) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, item in
                    Text(String(item.dayLabel.prefix(2)))
                        .font(MeowlettTypography.font(size: 8, weight: item.isToday ? .heavy : .semibold))
                        .foregroundStyle(item.isToday ? accent : textSub.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct DashboardWeightedRow: Layout {
    let weights: [CGFloat]
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? subviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width } + spacing * CGFloat(max(0, subviews.count - 1))
        let gaps = spacing * CGFloat(max(0, subviews.count - 1))
        let available = max(0, width - gaps)
        let totalWeight = weights.prefix(subviews.count).reduce(0, +)
        var heights: [CGFloat] = []

        for (index, subview) in subviews.enumerated() {
            let weight = index < weights.count ? weights[index] : 1
            let childWidth = totalWeight > 0 ? available * weight / totalWeight : available / CGFloat(max(1, subviews.count))
            heights.append(subview.sizeThatFits(ProposedViewSize(width: childWidth, height: proposal.height)).height)
        }

        return CGSize(width: width, height: heights.max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let gaps = spacing * CGFloat(max(0, subviews.count - 1))
        let available = max(0, bounds.width - gaps)
        let totalWeight = weights.prefix(subviews.count).reduce(0, +)
        var x = bounds.minX

        for (index, subview) in subviews.enumerated() {
            let weight = index < weights.count ? weights[index] : 1
            let width = totalWeight > 0 ? available * weight / totalWeight : available / CGFloat(max(1, subviews.count))
            subview.place(
                at: CGPoint(x: x, y: bounds.minY),
                proposal: ProposedViewSize(width: width, height: bounds.height)
            )
            x += width + spacing
        }
    }
}

private struct DashboardGoalEditorSheet: View {
    let goal: DashboardSavingsGoal?
    let onSave: (DashboardSavingsGoal) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("gm_lang") private var language = "id"
    @State private var label = ""
    private var isDark: Bool { colorScheme == .dark }
    @State private var target = ""
    @State private var saved = ""
    @State private var color = "#60a5fa"
    @State private var icon = "piggy"
    @State private var deadline = ""

    private let colors = ["#60a5fa","#c084fc","#f87171","#4ade80","#fbbf24","#fb923c","#34d399","#e879f9","#38bdf8","#a3e635"]
    private let icons: [(String,String)] = [
        ("piggy","banknote"),("phone","iphone"),("laptop","laptopcomputer"),("car","car.fill"),
        ("home","house.fill"),("plane","airplane"),("gift","gift.fill"),("camera","camera.fill"),
        ("book","book.fill"),("music","music.note"),("game","gamecontroller.fill"),("heart","heart.fill"),
        ("shopping","bag.fill"),("dumbbell","dumbbell.fill"),("wallet","wallet.bifold"),("star","sparkles")
    ]
    private var isEnglish: Bool { language == "en" }

    var body: some View {
        NavigationStack {
            Form {
                Section(isEnglish ? "Goal" : "Target tabungan") {
                    TextField(isEnglish ? "Goal name" : "Nama target", text: $label)
                    TextField(isEnglish ? "Target amount" : "Nominal target", text: $target).keyboardType(.numberPad)
                    TextField(isEnglish ? "Already saved" : "Sudah ditabung", text: $saved).keyboardType(.numberPad)
                    DatePicker(isEnglish ? "Deadline" : "Batas waktu", selection: deadlineBinding, displayedComponents: .date)
                }
                Section(isEnglish ? "Icon" : "Ikon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(icons, id: \.0) { item in
                            Button { icon = item.0 } label: {
                                Image(systemName: item.1).font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Color(hex: color))
                                    .frame(maxWidth: .infinity).frame(height: 42)
                                    .background(icon == item.0 ? Color(hex: color).opacity(0.16) : AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(icon == item.0 ? Color(hex: color) : .clear, lineWidth: 1.5))
                            }.buttonStyle(.plain)
                        }
                    }
                }
                Section(isEnglish ? "Color" : "Warna") {
                    HStack {
                        ForEach(colors, id: \.self) { value in
                            Circle().fill(Color(hex: value)).frame(width: 23, height: 23)
                                .overlay(Circle().stroke(color == value ? Color.primary : .clear, lineWidth: 2).padding(-3))
                                .onTapGesture { color = value }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle(goal == nil ? (isEnglish ? "New goal" : "Target baru") : (isEnglish ? "Edit goal" : "Edit target"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEnglish ? "Cancel" : "Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEnglish ? "Save" : "Simpan") {
                        guard !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                              let targetValue = Int64(target.filter(\.isNumber)), targetValue > 0 else { return }
                        onSave(DashboardSavingsGoal(
                            id: goal?.id ?? Int64(Date().timeIntervalSince1970 * 1000),
                            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
                            target: targetValue,
                            saved: Int64(saved.filter(\.isNumber)) ?? 0,
                            color: color,
                            icon: icon,
                            deadline: deadline.isEmpty ? nil : deadline
                        ))
                        dismiss()
                    }
                    .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Int64(target.filter(\.isNumber)) ?? 0) <= 0)
                }
            }
        }
        .onAppear {
            guard let goal else { return }
            label = goal.label
            target = String(goal.target)
            saved = String(goal.saved)
            color = goal.color
            icon = goal.icon
            deadline = goal.deadline ?? ""
        }
    }

    private var deadlineBinding: Binding<Date> {
        Binding(
            get: {
                guard let date = ISO8601DateFormatter().date(from: deadline + "T00:00:00Z") else { return .now }
                return date
            },
            set: { deadline = ISO8601DateFormatter().string(from: $0).prefix(10).description }
        )
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
    let totalText: String
    let textSub: Color
    let textColor: Color
    let size: CGFloat

    private var total: Double {
        Double(values.reduce(Int64(0)) { $0 + $1.amount })
    }

    var body: some View {
        ZStack {
            ForEach(Array(values.enumerated()), id: \.offset) { index, item in
                let previous = values.prefix(index).reduce(Int64(0)) { $0 + $1.amount }
                let start = total > 0 ? CGFloat(Double(previous) / total) : 0
                let end = total > 0 ? CGFloat(Double(previous + item.amount) / total) : 0
                let gap: CGFloat = values.count > 1 ? 0.0032 : 0
                Circle()
                    .trim(from: start, to: max(start, end - gap))
                    .stroke(
                        MeowlettCategory.color(for: item.category).opacity(0.92),
                        style: StrokeStyle(lineWidth: size * 0.16, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 0) {
                Text("Total")
                    .font(MeowlettTypography.font(size: size * 13 / 200, weight: .semibold))
                    .foregroundStyle(textSub)
                Text(totalText)
                    .font(MeowlettTypography.font(size: size * 15 / 200, weight: .heavy))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 4)
        }
    }
}
