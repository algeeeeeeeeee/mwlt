import SwiftUI

struct ReportsView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_categories") private var categoriesJSON = ""
    @AppStorage("gm_income") private var incomeRaw = "5000000"
    @AppStorage("gm_budgets") private var budgetsRaw = "{}"
    @Environment(\.colorScheme) private var colorScheme

    @State private var reportDate = Date.now
    @State private var selectedTrendCategory = "food"
    @State private var trendMode = "line"

    private var isEnglish: Bool { language == "en" }
    private var isDark: Bool { colorScheme == .dark }
    private var income: Int64 { Int64(incomeRaw) ?? 0 }
    private var accent: Color { Color(hex: AppAppearance.accentHex) }
    private var primary: Color { Color(hex: AppAppearance.primaryHex) }

    private var currentMonthTransactions: [MeowlettTransaction] {
        store.transactions.filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }
    private var previousMonthDate: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    }
    private var previousMonthTransactions: [MeowlettTransaction] {
        store.transactions.filter { Calendar.current.isDate($0.date, equalTo: previousMonthDate, toGranularity: .month) }
    }
    private var currentMonthLabel: String {
        Date.now.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: language == "en" ? "en_GB" : "id_ID")))
    }
    private var previousMonthLabel: String {
        previousMonthDate.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: language == "en" ? "en_GB" : "id_ID")))
    }
    private var budgets: [String: Int64] {
        guard let data = budgetsRaw.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: Int64].self, from: data)) ?? [:]
    }
    private var reportTransactions: [MeowlettTransaction] {
        store.transactions.filter { Calendar.current.isDate($0.date, inSameDayAs: reportDate) }.sorted { $0.date > $1.date }
    }
    private var reportTotal: Int64 {
        reportTransactions.reduce(Int64(0)) { $0 + $1.amount }
    }
    private var currentMonthTotal: Int64 {
        currentMonthTransactions.reduce(Int64(0)) { $0 + $1.amount }
    }
    private var categoryComparisons: [(String, Int64, Int64)] {
        MeowlettCategory.all.compactMap { category in
            let current = currentMonthTransactions.filter { $0.category == category.id }.reduce(Int64(0)) { $0 + $1.amount }
            let previous = previousMonthTransactions.filter { $0.category == category.id }.reduce(Int64(0)) { $0 + $1.amount }
            return current == 0 && previous == 0 ? nil : (category.id, current, previous)
        }
        .sorted { $0.1 > $1.1 }
    }
    private var budgetWarnings: [(String, Int64, Int64)] {
        MeowlettCategory.all.compactMap { category in
            guard let limit = budgets[category.id], limit > 0 else { return nil }
            let spent = currentMonthTransactions.filter { $0.category == category.id }.reduce(Int64(0)) { $0 + $1.amount }
            return Double(spent) / Double(limit) >= 0.8 ? (category.id, spent, limit) : nil
        }
    }
    private var insights: [(String, Int)] {
        MeowlettCategory.all.compactMap { category in
            let current = currentMonthTransactions.filter { $0.category == category.id }.reduce(Int64(0)) { $0 + $1.amount }
            let previous = previousMonthTransactions.filter { $0.category == category.id }.reduce(Int64(0)) { $0 + $1.amount }
            guard previous > 0 else { return nil }
            let change = Int(((Double(current - previous) / Double(previous)) * 100).rounded())
            return abs(change) >= 20 ? (category.id, change) : nil
        }
        .sorted { abs($0.1) > abs($1.1) }
        .prefix(4)
        .map { $0 }
    }
    private var selectedCategoryTrend: [(Date, Int64)] {
        let calendar = Calendar.current
        return (0..<4).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: .now) else { return nil }
            let sum = store.transactions.filter {
                $0.category == selectedTrendCategory && calendar.isDate($0.date, equalTo: date, toGranularity: .month)
            }.reduce(Int64(0)) { $0 + $1.amount }
            return (date, sum)
        }
    }
    private var weeklyTrend: [(Date, Int64)] {
        let calendar = Calendar.current
        return (0..<8).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .weekOfYear, value: -offset, to: .now),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return nil }
            let sum = store.transactions.filter { interval.contains($0.date) }.reduce(Int64(0)) { $0 + $1.amount }
            return (interval.start, sum)
        }
    }
    private var dailyCategoryTotals: [(String, Int64)] {
        MeowlettCategory.all.compactMap { category in
            let total = reportTransactions.filter { $0.category == category.id }.reduce(Int64(0)) { $0 + $1.amount }
            return total > 0 ? (category.id, total) : nil
        }
        .sorted { $0.1 > $1.1 }
    }
    private var dayLabel: String {
        reportDate.formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(Locale(identifier: language == "en" ? "en_GB" : "id_ID")))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                if !budgetWarnings.isEmpty { budgetWarningCard }
                categoryComparisonCard
                if !insights.isEmpty { insightsCard }
                categoryTrendCard
                weeklyTrendCard
                weeklyInsightCard
                exportCard
                selectedDayReportCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(AppAppearance.background(dark: isDark))
        .toolbar(.hidden, for: .navigationBar)
    }

    private var budgetWarningCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeading(isEnglish ? "Budget warnings" : "Peringatan Budget", symbol: "exclamationmark.triangle.fill")
            ForEach(Array(budgetWarnings.enumerated()), id: \.offset) { _, warning in
                let category = MeowlettCategory.all.first(where: { $0.id == warning.0 })
                let over = warning.1 >= warning.2
                let color = over ? Color(hex: "#ef4444") : Color(hex: "#f59e0b")
                HStack(spacing: 9) {
                    RoundedRectangle(cornerRadius: 9).fill(Color(hex: category?.color ?? "#94a3b8").opacity(0.14))
                        .frame(width: 34, height: 34)
                        .overlay(Image(systemName: category?.icon ?? "tag").font(.system(size: 15)).foregroundStyle(Color(hex: category?.color ?? "#94a3b8")))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(over ? (isEnglish ? "Exceeded" : "Terlampaui") : (isEnglish ? "Near limit" : "Mendekati limit")): \(MeowlettCategory.name(for: warning.0, language: language))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(color)
                        Text("\(rupiah(warning.1)) / \(rupiah(warning.2))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(min(100, Int((Double(warning.1) / Double(warning.2) * 100).rounded())))%")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(color)
                }
                .padding(10)
                .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .cardStyle()
    }

    private var categoryComparisonCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeading(isEnglish ? "Per Category — This vs Last Month" : "Per Kategori — Bulan Ini vs Lalu", symbol: "chart.bar.xaxis")
            HStack {
                Text(currentMonthLabel)
                Spacer()
                Text(previousMonthLabel)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.secondary)
            if categoryComparisons.isEmpty {
                emptyMessage(isEnglish ? "No spending data yet." : "Belum ada data pengeluaran.")
            } else {
                ForEach(Array(categoryComparisons.enumerated()), id: \.offset) { _, item in
                    let current = item.1
                    let previous = item.2
                    let maxValue = max(categoryComparisons.map { max($0.1, $0.2) }.max() ?? 1, 1)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Circle().fill(MeowlettCategory.color(for: item.0)).frame(width: 7, height: 7)
                            Text(MeowlettCategory.name(for: item.0, language: language))
                                .font(.system(size: 12, weight: .bold))
                            Spacer()
                            Text(rupiah(current))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.primary)
                            Text(rupiah(previous))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary.opacity(0.7))
                        }
                        GeometryReader { proxy in
                            VStack(spacing: 3) {
                                Capsule().fill(MeowlettCategory.color(for: item.0))
                                    .frame(width: proxy.size.width * CGFloat(current) / CGFloat(maxValue), height: 5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Capsule().fill(Color.secondary.opacity(0.35))
                                    .frame(width: proxy.size.width * CGFloat(previous) / CGFloat(maxValue), height: 5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: 13)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeading(isEnglish ? "AI Insights" : "Insight Pengeluaran", symbol: "sparkles")
            ForEach(Array(insights.enumerated()), id: \.offset) { _, insight in
                let up = insight.1 > 0
                HStack(spacing: 9) {
                    Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(up ? Color(hex: "#f87171") : Color(hex: "#16a34a"))
                        .frame(width: 28, height: 28)
                        .background((up ? Color(hex: "#f87171") : Color(hex: "#16a34a")).opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                    Text("\(MeowlettCategory.name(for: insight.0, language: language)) \(up ? (isEnglish ? "increased" : "naik") : (isEnglish ? "decreased" : "turun")) \(abs(insight.1))% \(isEnglish ? "compared with last month" : "dibanding bulan lalu")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(isDark ? Color(hex: "#d1fae5") : Color(hex: "#166534"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(Color(hex: "#22c55e").opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .cardStyle()
    }

    private var categoryTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(isEnglish ? "Category Trend (4 months)" : "Tren Kategori (4 bulan)", symbol: "chart.xyaxis.line")
            HStack {
                Menu {
                    ForEach(MeowlettCategory.all, id: \.id) { category in
                        Button {
                            selectedTrendCategory = category.id
                        } label: {
                            if selectedTrendCategory == category.id {
                                Label(language == "en" ? category.enName : category.idName, systemImage: "checkmark")
                            } else {
                                Text(language == "en" ? category.enName : category.idName)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle().fill(MeowlettCategory.color(for: selectedTrendCategory)).frame(width: 7, height: 7)
                        Text(MeowlettCategory.name(for: selectedTrendCategory, language: language))
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "chevron.down").font(.system(size: 9, weight: .black))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(AppAppearance.card2(dark: isDark), in: Capsule())
                }
                Spacer()
                Picker("", selection: $trendMode) {
                    Text(isEnglish ? "Line" : "Garis").tag("line")
                    Text(isEnglish ? "Bar" : "Batang").tag("bar")
                }
                .pickerStyle(.segmented)
                .frame(width: 126)
            }
            if selectedCategoryTrend.allSatisfy({ $0.1 == 0 }) {
                emptyMessage(isEnglish ? "No data for this category." : "Belum ada data kategori ini.")
                    .frame(height: 115)
            } else {
                NativeReportChart(values: selectedCategoryTrend, color: MeowlettCategory.color(for: selectedTrendCategory), mode: trendMode)
                    .frame(height: 145)
            }
            HStack {
                ForEach(Array(selectedCategoryTrend.enumerated()), id: \.offset) { _, item in
                    Text(item.0.formatted(.dateTime.month(.abbreviated).locale(Locale(identifier: language == "en" ? "en_GB" : "id_ID"))))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    private var weeklyTrendCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeading(isEnglish ? "Weekly spending trend" : "Tren Pengeluaran Mingguan", symbol: "chart.xyaxis.line")
            if weeklyTrend.allSatisfy({ $0.1 == 0 }) {
                emptyMessage(isEnglish ? "No weekly data yet." : "Belum ada data mingguan.")
                    .frame(height: 115)
            } else {
                NativeReportChart(values: weeklyTrend, color: accent, mode: "line")
                    .frame(height: 145)
            }
            HStack {
                ForEach(Array(weeklyTrend.enumerated()), id: \.offset) { index, item in
                    if index == 0 || index == 3 || index == 7 {
                        Text(item.0.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: language == "en" ? "en_GB" : "id_ID"))))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    } else {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var weeklyInsightCard: some View {
        let thisWeek = weeklyTrend.last?.1 ?? 0
        let lastWeek = weeklyTrend.dropLast().last?.1 ?? 0
        let change = lastWeek > 0 ? Int(((Double(thisWeek - lastWeek) / Double(lastWeek)) * 100).rounded()) : 0
        let top = currentMonthTransactions.reduce(into: [String: Int64]()) { result, tx in result[tx.category, default: 0] += tx.amount }.max { $0.value < $1.value }
        return VStack(alignment: .leading, spacing: 10) {
            sectionHeading(isEnglish ? "Weekly insight" : "Insight Mingguan", symbol: "lightbulb")
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(primary)
                    .frame(width: 38, height: 38)
                    .background(primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text((isEnglish ? "This week: " : "Minggu ini: ") + rupiah(thisWeek))
                        .font(.system(size: 13, weight: .bold))
                    if lastWeek > 0 {
                        Text("\(change >= 0 ? (isEnglish ? "More spending" : "Lebih banyak") : (isEnglish ? "Less spending" : "Lebih hemat")) \(rupiah(abs(thisWeek - lastWeek))) \(isEnglish ? "vs last week" : "dibanding minggu lalu")")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(change > 0 ? Color(hex: "#f87171") : Color(hex: "#16a34a"))
                    }
                    if let top {
                        Text((isEnglish ? "Top category: " : "Kategori teratas: ") + MeowlettCategory.name(for: top.key, language: language))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(15)
        .background(primary.opacity(isDark ? 0.15 : 0.07), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(primary.opacity(0.14), lineWidth: 1))
    }

    private var exportCard: some View {
        HStack(spacing: 10) {
            ShareLink(item: reportCSV) {
                Label(isEnglish ? "Export CSV" : "Ekspor CSV", systemImage: "tablecells")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            }
            ShareLink(item: reportSummary) {
                Label(isEnglish ? "Share summary" : "Bagikan ringkasan", systemImage: "square.and.arrow.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(13)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 16))
    }

    private var selectedDayReportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(isEnglish ? "Daily report" : "Laporan Harian", symbol: "calendar")
            DatePicker(isEnglish ? "Choose date" : "Pilih tanggal", selection: $reportDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(primary)
                .font(.system(size: 12, weight: .semibold))
            VStack(alignment: .leading, spacing: 3) {
                Text(isEnglish ? "TOTAL EXPENSE" : "TOTAL PENGELUARAN")
                    .font(.system(size: 10, weight: .heavy)).tracking(1).foregroundStyle(.secondary)
                Text(reportTotal > 0 ? "-\(rupiah(reportTotal))" : rupiah(0))
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(reportTotal > 0 ? Color(hex: "#f87171") : Color.secondary)
                Text("\(dayLabel) · \(reportTransactions.count) \(isEnglish ? "transactions" : "transaksi")")
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#f87171").opacity(0.07), in: RoundedRectangle(cornerRadius: 14))

            if dailyCategoryTotals.isEmpty {
                emptyMessage(isEnglish ? "No transactions on this date." : "Tidak ada transaksi pada tanggal ini.")
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(isEnglish ? "Per category" : "Per kategori")
                        .font(.system(size: 13, weight: .heavy))
                    ForEach(Array(dailyCategoryTotals.enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 8) {
                            Circle().fill(MeowlettCategory.color(for: item.0)).frame(width: 8, height: 8)
                            Text(MeowlettCategory.name(for: item.0, language: language))
                                .font(.system(size: 12, weight: .semibold))
                            Spacer()
                            Text(rupiah(item.1)).font(.system(size: 12, weight: .bold))
                        }
                    }
                }
                Divider().opacity(0.5)
                VStack(alignment: .leading, spacing: 9) {
                    Text(isEnglish ? "Transaction details" : "Detail transaksi")
                        .font(.system(size: 13, weight: .heavy))
                    ForEach(reportTransactions) { transaction in
                        HStack(spacing: 9) {
                            RoundedRectangle(cornerRadius: 9).fill(MeowlettCategory.color(for: transaction.category).opacity(0.15))
                                .frame(width: 32, height: 32)
                                .overlay(Image(systemName: MeowlettCategory.all.first(where: { $0.id == transaction.category })?.icon ?? "tag")
                                    .font(.system(size: 13)).foregroundStyle(MeowlettCategory.color(for: transaction.category)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(transaction.description).font(.system(size: 12, weight: .bold))
                                if !transaction.location.isEmpty { Text(transaction.location).font(.system(size: 10)).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            Text("-\(rupiah(transaction.amount))")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundStyle(Color(hex: "#f87171"))
                        }
                    }
                }
            }
            if !reportTransactions.isEmpty {
                Divider().opacity(0.5)
                VStack(alignment: .leading, spacing: 5) {
                    sectionHeading(isEnglish ? "Daily insight" : "Insight Hari Ini", symbol: "sparkles")
                    if let top = dailyCategoryTotals.first {
                        Text((isEnglish ? "Top spending: " : "Pengeluaran tertinggi: ") + MeowlettCategory.name(for: top.0, language: language) + " — " + rupiah(top.1))
                            .font(.system(size: 11, weight: .medium))
                    }
                    Text((isEnglish ? "Average per transaction: " : "Rata-rata per transaksi: ") + rupiah(reportTotal / Int64(max(reportTransactions.count, 1))))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle()
    }

    private var reportCSV: String {
        var output = "Date,Description,Category,Location,Note,Amount\n"
        for item in store.transactions.sorted(by: { $0.date < $1.date }) {
            let fields = [
                item.date.formatted(.iso8601.year().month().day()),
                item.description,
                MeowlettCategory.name(for: item.category, language: language),
                item.location,
                item.note,
                String(item.amount)
            ]
            output += fields.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: ",") + "\n"
        }
        return output
    }

    private var reportSummary: String {
        "\(isEnglish ? "Meowlett report" : "Laporan Meowlett") · \(currentMonthLabel)\n\(isEnglish ? "Income" : "Pemasukan"): \(rupiah(income))\n\(isEnglish ? "Expenses" : "Pengeluaran"): \(rupiah(currentMonthTotal))\n\(isEnglish ? "Remaining" : "Sisa"): \(rupiah(income - currentMonthTotal))"
    }

    private func sectionHeading(_ title: String, symbol: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
            Text(title).font(.system(size: 13, weight: .heavy)).foregroundStyle(.primary)
        }
    }

    private func emptyMessage(_ text: String) -> some View {
        Text(text).font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
    }

    private func rupiah(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        return "Rp" + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

private struct NativeReportChart: View {
    let values: [(Date, Int64)]
    let color: Color
    let mode: String

    var body: some View {
        GeometryReader { proxy in
            let maxValue = max(Double(values.map { $0.1 }.max() ?? 1), 1)
            let points = values.enumerated().map { index, item in
                CGPoint(
                    x: values.count > 1 ? proxy.size.width * CGFloat(index) / CGFloat(values.count - 1) : proxy.size.width / 2,
                    y: proxy.size.height * (1 - CGFloat(Double(item.1) / maxValue) * 0.88) - 4
                )
            }
            ZStack {
                VStack {
                    ForEach(0..<4, id: \.self) { _ in
                        Rectangle().fill(Color.primary.opacity(0.07)).frame(height: 1)
                        Spacer(minLength: 0)
                    }
                }
                if mode == "bar" {
                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(Array(values.enumerated()), id: \.offset) { _, item in
                            VStack {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(color.opacity(0.85))
                                    .frame(height: max(3, proxy.size.height * CGFloat(Double(item.1) / maxValue) * 0.88))
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                } else {
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: first)
                        for point in points.dropFirst() { path.addLine(to: point) }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        Circle().fill(color).frame(width: 7, height: 7).position(point)
                    }
                }
            }
        }
    }
}
