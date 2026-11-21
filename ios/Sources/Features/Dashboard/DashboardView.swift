import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_categories") private var categoriesJSON = ""
    @AppStorage("gm_username") private var userName = ""
    @AppStorage("gm_income") private var incomeRaw = "5000000"
    @State private var showIncomeEditor = false
    @State private var incomeDraft = ""
    @State private var recentCount = 5
    @AppStorage("gm_budgets") private var budgetsRaw = "{}"
    @AppStorage("gm_overall_budget") private var overallBudgetRaw = "0"
    @AppStorage("gm_savings_goals") private var savingsGoalsRaw = "[]"
    @State private var budgets: [String: Int64] = [:]
    @State private var savingsGoals: [DashboardSavingsGoal] = []
    @State private var storageLoaded = false
    @State private var showOverallBudgetEditor = false
    @State private var showGoalEditor = false
    @State private var editingGoal: DashboardSavingsGoal?
    @State private var quickSaveGoal: DashboardSavingsGoal?

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
                    budgetCard
                    savingsGoalsCard
                    recentTransactionsCard
                    categoryBreakdownCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .onAppear(perform: loadPersistedDashboardData)
            .onChange(of: budgets) { _, value in persistBudgets(value) }
            .onChange(of: savingsGoals) { _, value in persistSavingsGoals(value) }
            .sheet(isPresented: $showOverallBudgetEditor) {
                NativeMoneyEntrySheet(
                    title: isEnglish ? "Monthly budget" : "Budget bulanan",
                    initialValue: Int64(overallBudgetRaw) ?? 0,
                    accent: Color(hex: AppAppearance.accentHex),
                    onSave: { overallBudgetRaw = String($0) }
                )
            }
            .sheet(isPresented: $showGoalEditor) {
                DashboardGoalEditorSheet(goal: editingGoal) { saved in
                    if let index = savingsGoals.firstIndex(where: { $0.id == saved.id }) {
                        savingsGoals[index] = saved
                    } else {
                        savingsGoals.append(saved)
                    }
                    editingGoal = nil
                }
            }
            .sheet(item: $quickSaveGoal) { goal in
                NativeMoneyEntrySheet(
                    title: isEnglish ? "Add savings · \\(goal.label)" : "Tambah tabungan · \\(goal.label)",
                    initialValue: 0,
                    accent: Color(hex: goal.color),
                    onSave: { amount in
                        guard let index = savingsGoals.firstIndex(where: { $0.id == goal.id }) else { return }
                        savingsGoals[index].saved += amount
                    }
                )
            }
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

    private var budgetCard: some View {
        let overall = Int64(overallBudgetRaw) ?? 0
        let entries = MeowlettCategory.all.compactMap { category -> (String, Int64)? in
            guard let limit = budgets[category.id], limit > 0 else { return nil }
            return (category.id, limit)
        }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "wallet.bifold")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: AppAppearance.primaryHex))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: AppAppearance.primaryHex).opacity(0.10), in: RoundedRectangle(cornerRadius: 9))
                Text(isEnglish ? "Monthly budget" : "Budget Bulanan")
                    .font(.system(size: 14, weight: .heavy))
                Spacer()
                Button { showOverallBudgetEditor = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(5)
                }
                .buttonStyle(.plain)
            }

            if overall <= 0 && entries.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "wallet.pass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(hex: AppAppearance.primaryHex))
                        .frame(width: 44, height: 44)
                        .background(Color(hex: AppAppearance.primaryHex).opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isEnglish ? "No limits set" : "Belum ada limit")
                            .font(.system(size: 13, weight: .heavy))
                        Text(isEnglish ? "Set one to stay on track." : "Atur budget supaya pengeluaran terkontrol.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 2)
                    Button(isEnglish ? "Set budget" : "Atur") { showOverallBudgetEditor = true }
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Color(hex: AppAppearance.primaryHex))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: AppAppearance.primaryHex).opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                }
            } else {
                VStack(spacing: 11) {
                    if overall > 0 {
                        budgetProgressRow(
                            title: isEnglish ? "Total monthly" : "Total Bulanan",
                            spent: spent,
                            limit: overall,
                            color: Color(hex: AppAppearance.accentHex),
                            showIcon: false
                        )
                    }
                    ForEach(Array(entries.prefix(4).enumerated()), id: \.offset) { _, entry in
                        budgetProgressRow(
                            title: MeowlettCategory.name(for: entry.0, language: language),
                            spent: monthTransactions.filter { $0.category == entry.0 }.reduce(Int64(0)) { $0 + $1.amount },
                            limit: entry.1,
                            color: MeowlettCategory.color(for: entry.0),
                            showIcon: true
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func budgetProgressRow(title: String, spent: Int64, limit: Int64, color: Color, showIcon: Bool) -> some View {
        let percentage = limit > 0 ? min(100, Int((Double(spent) / Double(limit) * 100).rounded())) : 0
        let over = percentage >= 100
        let warning = percentage >= 80
        let barColor: Color = over ? Color(hex: "#ef4444") : warning ? Color(hex: "#f59e0b") : color
        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                if showIcon {
                    Circle().fill(color).frame(width: 7, height: 7)
                }
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\\(percentage)%")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(barColor)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(isDark ? 0.07 : 0.06))
                    Capsule().fill(LinearGradient(colors: [barColor, barColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * CGFloat(percentage) / 100)
                }
            }
            .frame(height: 6)
            Text("\\(rupiah(spent)) / \\(rupiah(limit))")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var savingsGoalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: "banknote")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: AppAppearance.primaryHex))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: AppAppearance.primaryHex).opacity(0.10), in: RoundedRectangle(cornerRadius: 9))
                Text(isEnglish ? "Savings goals" : "Target Tabungan")
                    .font(.system(size: 14, weight: .heavy))
                Spacer()
                if !savingsGoals.isEmpty {
                    Button {
                        editingGoal = nil
                        showGoalEditor = true
                    } label: {
                        Label(isEnglish ? "Add" : "Tambah", systemImage: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: AppAppearance.primaryHex))
                    }
                    .buttonStyle(.plain)
                }
            }

            if savingsGoals.isEmpty {
                VStack(spacing: 9) {
                    Image(systemName: "banknote")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Color(hex: AppAppearance.accentHex))
                        .frame(width: 72, height: 72)
                        .background(Color(hex: AppAppearance.accentHex).opacity(0.12), in: Circle())
                        .overlay(Circle().stroke(Color(hex: AppAppearance.accentHex).opacity(0.2), lineWidth: 1.5))
                    Text(isEnglish ? "No savings goals yet" : "Belum ada target tabungan")
                        .font(.system(size: 14, weight: .bold))
                    Text(isEnglish ? "Create your first target." : "Yuk, buat target pertamamu!")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Button {
                        editingGoal = nil
                        showGoalEditor = true
                    } label: {
                        Label(isEnglish ? "Add goal" : "Tambah target", systemImage: "plus")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: AppAppearance.primaryHex), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
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
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
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
                    Text(goal.label).font(.system(size: 13, weight: .bold))
                    Text("\\(rupiah(goal.saved)) / \\(rupiah(goal.target))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\\(percentage)%")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(percentage >= 100 ? Color(hex: "#4ade80") : color)
                Button {
                    editingGoal = goal
                    showGoalEditor = true
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
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(isDark ? 0.07 : 0.06))
                    Capsule().fill(percentage >= 100 ? Color(hex: "#4ade80") : color)
                        .frame(width: proxy.size.width * CGFloat(percentage) / 100)
                }
            }
            .frame(height: 6)
            if remaining > 0 {
                Text((isEnglish ? "Remaining " : "Sisa ") + rupiah(remaining))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            } else {
                Label(isEnglish ? "Goal reached" : "Target tercapai", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: AppAppearance.accentHex))
            }
            if percentage < 100 {
                Button {
                    quickSaveGoal = goal
                } label: {
                    Label(isEnglish ? "Add savings" : "Tambah tabungan", systemImage: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
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
    @AppStorage("gm_lang") private var language = "id"
    @State private var amountText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.system(size: 17, weight: .black))
            Text(language == "en" ? "Enter an amount in Indonesian rupiah." : "Masukkan nominal dalam Rupiah.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Text("Rp").font(.system(size: 15, weight: .bold)).foregroundStyle(.secondary)
                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .font(.system(size: 21, weight: .black, design: .rounded))
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
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.55), lineWidth: 1.5))
            HStack(spacing: 10) {
                Button(language == "en" ? "Cancel" : "Batal") { dismiss() }
                    .foregroundStyle(.primary).frame(maxWidth: .infinity).frame(height: 45)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 13))
                Button(language == "en" ? "Save" : "Simpan") {
                    onSave(Int64(amountText.filter(\.isNumber)) ?? 0)
                    dismiss()
                }
                .fontWeight(.heavy).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 45)
                .background(accent, in: RoundedRectangle(cornerRadius: 13))
            }
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
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

private struct DashboardGoalEditorSheet: View {
    let goal: DashboardSavingsGoal?
    let onSave: (DashboardSavingsGoal) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("gm_lang") private var language = "id"
    @State private var label = ""
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
                                    .background(icon == item.0 ? Color(hex: color).opacity(0.16) : Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
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
    private var total: Double { Double(values.reduce(Int64(0)) { $0 + $1.amount }) }
    var body: some View {
        ZStack {
            Circle().stroke(Color.primary.opacity(0.06), lineWidth: 15)
            ForEach(Array(values.enumerated()), id: \.offset) { index, item in
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
