import SwiftUI
import UniformTypeIdentifiers

struct ReportsView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_categories") private var categoriesJSON = ""
    @AppStorage("gm_income") private var incomeRaw = "5000000"
    @AppStorage("gm_budgets") private var budgetsRaw = "{}"
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    @State private var reportDate = Date.now
    @State private var trendMode = "bar"
    @State private var showHTMLExport = false

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
        var result: [(String, Int)] = []
        let currentTotal = currentMonthTotal
        let previousTotal = previousMonthTransactions.reduce(Int64(0)) { $0 + $1.amount }

        if previousTotal > 0 {
            let change = Int(((Double(currentTotal - previousTotal) / Double(previousTotal)) * 100).rounded())
            result.append(("__total__", change))
        }

        var seen = Set<String>()
        let orderedKeys = store.transactions.compactMap { transaction -> String? in
            guard seen.insert(transaction.category).inserted else { return nil }
            return transaction.category
        }
        for key in orderedKeys {
            let current = currentMonthTransactions.filter { $0.category == key }.reduce(Int64(0)) { $0 + $1.amount }
            let previous = previousMonthTransactions.filter { $0.category == key }.reduce(Int64(0)) { $0 + $1.amount }
            guard previous > 0, current > 0 else { continue }
            let change = Int(((Double(current - previous) / Double(previous)) * 100).rounded())
            if abs(change) >= 20 {
                result.append((key, change))
            }
        }
        return Array(result.prefix(4))
    }

    private var thisWeekStart: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let offset = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -offset, to: today) ?? today
    }
    private var tomorrowStart: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
    }
    private var lastWeekStart: Date {
        Calendar.current.date(byAdding: .day, value: -7, to: thisWeekStart) ?? thisWeekStart
    }
    private var thisWeekTransactions: [MeowlettTransaction] {
        store.transactions.filter { $0.date >= thisWeekStart && $0.date < tomorrowStart }
    }
    private var lastWeekTransactions: [MeowlettTransaction] {
        store.transactions.filter { $0.date >= lastWeekStart && $0.date < thisWeekStart }
    }
    private var thisWeekTotal: Int64 {
        thisWeekTransactions.reduce(Int64(0)) { $0 + $1.amount }
    }
    private var lastWeekTotal: Int64 {
        lastWeekTransactions.reduce(Int64(0)) { $0 + $1.amount }
    }
    private var weeklyInsightTopCategory: (String, Int64)? {
        let totals = Dictionary(grouping: thisWeekTransactions, by: \.category)
            .mapValues { $0.reduce(Int64(0)) { $0 + $1.amount } }
        guard let top = totals.max(by: { $0.value < $1.value }) else { return nil }
        return (top.key, top.value)
    }
    private var categoryTrendMonths: [Date] {
        let calendar = Calendar.current
        return (0..<4).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: .now),
                  let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return nil }
            return start
        }
    }
    private var categoryTrendSeries: [ReportTrendSeries] {
        MeowlettCategory.all.compactMap { category in
            let values = categoryTrendMonths.map { month in
                currentOrHistoricalMonthTotal(category: category.id, month: month)
            }
            guard values.contains(where: { $0 > 0 }) else { return nil }
            return ReportTrendSeries(id: category.id, color: MeowlettCategory.color(for: category.id), values: values)
        }
    }
    private func currentOrHistoricalMonthTotal(category: String, month: Date) -> Int64 {
        store.transactions.filter {
            $0.category == category && Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month)
        }.reduce(Int64(0)) { $0 + $1.amount }
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
                if !categoryTrendSeries.isEmpty { categoryTrendCard }
                weeklyTrendCard
                weeklyInsightCard
                exportCard
                selectedDayReportCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 90)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(AppAppearance.background(dark: isDark))
        .toolbar(.hidden, for: .navigationBar)
        .fileExporter(
            isPresented: $showHTMLExport,
            document: ReportHTMLDocument(html: reportHTML),
            contentType: .html,
            defaultFilename: "laporan-\(Date.now.formatted(.iso8601.year().month()))"
        ) { _ in }
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
                            .font(MeowlettTypography.font(size: 12, weight: .bold))
                            .foregroundStyle(color)
                        Text("\(rupiah(warning.1)) / \(rupiah(warning.2))")
                            .font(MeowlettTypography.font(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(min(100, Int((Double(warning.1) / Double(warning.2) * 100).rounded())))%")
                        .font(MeowlettTypography.font(size: 12, weight: .black))
                        .foregroundStyle(color)
                }
                .padding(10)
                .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .cardStyle(dark: isDark)
    }

    private var categoryComparisonCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeading(isEnglish ? "Per Category — This vs Last Month" : "Per Kategori — Bulan Ini vs Lalu", symbol: "chart.bar.xaxis")
            HStack {
                Text(currentMonthLabel)
                Spacer()
                Text(previousMonthLabel)
            }
            .font(MeowlettTypography.font(size: 10, weight: .bold))
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
                                .font(MeowlettTypography.font(size: 12, weight: .bold))
                            Spacer()
                            Text(rupiah(current))
                                .font(MeowlettTypography.font(size: 10, weight: .bold))
                                .foregroundStyle(.primary)
                            Text(rupiah(previous))
                                .font(MeowlettTypography.font(size: 10, weight: .semibold))
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
        .cardStyle(dark: isDark)
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color(hex: isDark ? "#1a3a1a" : "#bbf7d0").opacity(isDark ? 1 : 0.45))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "bolt")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(isDark ? Color(hex: "#4ade80") : Color(hex: "#166534"))
                    )
                Text(isEnglish ? "Monthly Insights" : "Insight Bulanan")
                    .font(MeowlettTypography.font(size: 13, weight: .heavy))
                    .foregroundStyle(isDark ? Color(hex: "#4ade80") : Color(hex: "#166534"))
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(insights.enumerated()), id: \.offset) { _, insight in
                    let up = insight.1 > 0
                    let iconColor = up ? Color(hex: "#ef4444") : Color(hex: "#16a34a")
                    let message: String = {
                        if insight.0 == "__total__" {
                            return "\(up ? (isEnglish ? "More spending" : "Lebih banyak") : (isEnglish ? "Less spending" : "Lebih hemat")) \(abs(insight.1))% \(isEnglish ? "last month" : "dari bulan lalu")"
                        }
                        return "\(MeowlettCategory.name(for: insight.0, language: language)) \(up ? (isEnglish ? "up" : "naik") : (isEnglish ? "down" : "turun")) \(abs(insight.1))% \(isEnglish ? "last month" : "dari bulan lalu")"
                    }()
                    HStack(spacing: 8) {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(iconColor)
                                    .rotationEffect(.degrees(up ? 0 : 180))
                            )
                        Text(message)
                            .font(MeowlettTypography.font(size: 12, weight: .medium))
                            .foregroundStyle(isDark ? Color(hex: "#d1fae5") : Color(hex: "#166534"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(isDark ? Color(hex: "#0d1a0d") : Color(hex: "#f0fdf4"), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(isDark ? Color(hex: "#1a3a1a") : Color(hex: "#bbf7d0"), lineWidth: 1))
    }

    private var categoryTrendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeading(isEnglish ? "Category Trend (4 months)" : "Tren Kategori (4 bulan)", symbol: "chart.bar.xaxis")
            HStack(spacing: 4) {
                Text(isEnglish ? "Bar" : "Batang")
                    .font(MeowlettTypography.font(size: 11, weight: .bold))
                    .foregroundStyle(trendMode == "bar" ? accent : Color.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(trendMode == "bar" ? accent.opacity(0.13) : .clear, in: Capsule())
                    .overlay(Capsule().stroke(trendMode == "bar" ? accent : Color.secondary.opacity(0.18), lineWidth: 1.2))
                    .contentShape(Capsule())
                    .onTapGesture { trendMode = "bar" }
                Text(isEnglish ? "Line" : "Garis")
                    .font(MeowlettTypography.font(size: 11, weight: .bold))
                    .foregroundStyle(trendMode == "line" ? accent : Color.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(trendMode == "line" ? accent.opacity(0.13) : .clear, in: Capsule())
                    .overlay(Capsule().stroke(trendMode == "line" ? accent : Color.secondary.opacity(0.18), lineWidth: 1.2))
                    .contentShape(Capsule())
                    .onTapGesture { trendMode = "line" }
                Spacer()
            }
            HStack {
                ForEach(Array(categoryTrendMonths.enumerated()), id: \.offset) { _, month in
                    Text(month.formatted(.dateTime.month(.abbreviated).locale(Locale(identifier: language == "en" ? "en_GB" : "id_ID"))))
                        .font(MeowlettTypography.font(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            NativeCategoryTrendChart(series: categoryTrendSeries, mode: trendMode)
                .frame(height: 150)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), alignment: .leading)], alignment: .leading, spacing: 7) {
                ForEach(categoryTrendSeries) { item in
                    HStack(spacing: 5) {
                        Circle().fill(item.color).frame(width: 8, height: 8)
                        Text(MeowlettCategory.name(for: item.id, language: language))
                            .font(MeowlettTypography.font(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .cardStyle(dark: isDark)
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
                            .font(MeowlettTypography.font(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    } else {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .cardStyle(dark: isDark)
    }

    private var weeklyInsightCard: some View {
        let difference = thisWeekTotal - lastWeekTotal
        let themeTint = isDark
            ? Color(hex: AppAppearance.darken(AppAppearance.primaryHex, ratio: 0.55)).opacity(0.80)
            : Color(hex: AppAppearance.primaryHex).opacity(0.07)
        let textTint = isDark
            ? Color(hex: AppAppearance.lighten(AppAppearance.accentHex, ratio: 0.30))
            : primary
        return Group {
            if thisWeekTotal > 0 {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 7) {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(primary.opacity(isDark ? 0.25 : 0.10))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "bolt")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(textTint)
                            )
                        Text(isEnglish ? "Weekly Insight" : "Insight Mingguan")
                            .font(MeowlettTypography.font(size: 13, weight: .heavy))
                            .foregroundStyle(textTint)
                    }
                    HStack(spacing: 8) {
                        Circle()
                            .fill(primary.opacity(0.15))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(textTint)
                            )
                        (
                            Text(isEnglish ? "This week: " : "Total minggu ini: ")
                                .foregroundColor(textTint)
                            + Text(rupiah(thisWeekTotal))
                                .fontWeight(.heavy)
                                .foregroundColor(textTint)
                        )
                        .font(MeowlettTypography.font(size: 12, weight: .medium))
                    }

                    if lastWeekTotal > 0 && difference != 0 {
                        let changeColor = difference > 0 ? Color(hex: "#ef4444") : Color(hex: "#16a34a")
                        HStack(spacing: 8) {
                            Circle()
                                .fill(changeColor.opacity(0.15))
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundStyle(changeColor)
                                        .rotationEffect(.degrees(difference > 0 ? 0 : 180))
                                )
                            Text("\(difference > 0 ? (isEnglish ? "More spending" : "Lebih boros") : (isEnglish ? "Less spending" : "Lebih hemat")) \(rupiah(abs(difference))) \(isEnglish ? "vs last week" : "dibanding minggu lalu")")
                                .font(MeowlettTypography.font(size: 12, weight: .medium))
                                .foregroundStyle(textTint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let top = weeklyInsightTopCategory {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(primary.opacity(0.15))
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Image(systemName: MeowlettCategory.all.first(where: { $0.id == top.0 })?.icon ?? "tag")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(textTint)
                                )
                            (
                                Text(isEnglish ? "Top category: " : "Kategori teratas: ")
                                    .foregroundColor(textTint)
                                + Text(MeowlettCategory.name(for: top.0, language: language))
                                    .fontWeight(.heavy)
                                    .foregroundColor(MeowlettCategory.color(for: top.0))
                            )
                            .font(MeowlettTypography.font(size: 12, weight: .medium))
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(themeTint, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(primary.opacity(isDark ? 0.27 : 0.20), lineWidth: 1))
            }
        }
    }

    private var exportCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ShareLink(item: reportCSV) {
                    Label(isEnglish ? "Export CSV" : "Ekspor CSV", systemImage: "tablecells")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                }
                Button {
                    showHTMLExport = true
                } label: {
                    Label(isEnglish ? "Export report" : "Ekspor laporan", systemImage: "doc.text")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            ShareLink(item: reportSummary) {
                Label(isEnglish ? "Share summary" : "Bagikan ringkasan", systemImage: "square.and.arrow.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LinearGradient(colors: [accent, primary], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 13))
            }
            Button {
                var components = URLComponents()
                components.scheme = "https"
                components.host = "wa.me"
                components.path = "/"
                components.queryItems = [URLQueryItem(name: "text", value: reportSummary)]
                if let url = components.url { openURL(url) }
            } label: {
                Label(isEnglish ? "Share to WhatsApp" : "Bagikan ke WhatsApp", systemImage: "message.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(accent.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)
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
                    .font(MeowlettTypography.font(size: 10, weight: .heavy)).tracking(1).foregroundStyle(.secondary)
                Text(reportTotal > 0 ? "-\(rupiah(reportTotal))" : rupiah(0))
                    .font(MeowlettTypography.font(size: 30, weight: .black))
                    .foregroundStyle(reportTotal > 0 ? Color(hex: "#f87171") : Color.secondary)
                Text("\(dayLabel) · \(reportTransactions.count) \(isEnglish ? "transactions" : "transaksi")")
                    .font(MeowlettTypography.font(size: 11, weight: .medium)).foregroundStyle(.secondary)
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
                        .font(MeowlettTypography.font(size: 13, weight: .heavy))
                    ForEach(Array(dailyCategoryTotals.enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 8) {
                            Circle().fill(MeowlettCategory.color(for: item.0)).frame(width: 8, height: 8)
                            Text(MeowlettCategory.name(for: item.0, language: language))
                                .font(MeowlettTypography.font(size: 12, weight: .semibold))
                            Spacer()
                            Text(rupiah(item.1)).font(MeowlettTypography.font(size: 12, weight: .bold))
                        }
                    }
                }
                Divider().opacity(0.5)
                VStack(alignment: .leading, spacing: 9) {
                    Text(isEnglish ? "Transaction details" : "Detail transaksi")
                        .font(MeowlettTypography.font(size: 13, weight: .heavy))
                    ForEach(reportTransactions) { transaction in
                        HStack(spacing: 9) {
                            RoundedRectangle(cornerRadius: 9).fill(MeowlettCategory.color(for: transaction.category).opacity(0.15))
                                .frame(width: 32, height: 32)
                                .overlay(Image(systemName: MeowlettCategory.all.first(where: { $0.id == transaction.category })?.icon ?? "tag")
                                    .font(.system(size: 13)).foregroundStyle(MeowlettCategory.color(for: transaction.category)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(transaction.description).font(MeowlettTypography.font(size: 12, weight: .bold))
                                if !transaction.location.isEmpty { Text(transaction.location).font(MeowlettTypography.font(size: 10, weight: .regular)).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            Text("-\(rupiah(transaction.amount))")
                                .font(MeowlettTypography.font(size: 12, weight: .heavy))
                                .foregroundStyle(Color(hex: "#f87171"))
                        }
                    }
                }
            }
            if !reportTransactions.isEmpty {
                let daysInMonth = Calendar.current.range(of: .day, in: .month, for: reportDate)?.count ?? 30
                let averageDailyAllowance = income > 0 ? income / Int64(max(daysInMonth, 1)) : 0
                let aboveDailyAverage = reportTotal > averageDailyAllowance
                Divider().opacity(0.5)
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeading(isEnglish ? "Daily insight" : "Insight Hari Ini", symbol: "sparkles")
                    if let top = dailyCategoryTotals.first {
                        Text((isEnglish ? "Top spending: " : "Pengeluaran tertinggi: ") + MeowlettCategory.name(for: top.0, language: language) + " — " + rupiah(top.1))
                            .font(MeowlettTypography.font(size: 11, weight: .medium))
                            .foregroundStyle(primary)
                    }
                    Label(
                        (aboveDailyAverage ? (isEnglish ? "Above daily average" : "Di atas rata-rata harian") : (isEnglish ? "Below daily average" : "Di bawah rata-rata harian"))
                            + " (\(rupiah(averageDailyAllowance)))",
                        systemImage: aboveDailyAverage ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
                    )
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(aboveDailyAverage ? Color(hex: "#ef4444") : Color(hex: "#16a34a"))
                    Text((isEnglish ? "Average per transaction: " : "Rata-rata per transaksi: ") + rupiah(reportTotal / Int64(max(reportTransactions.count, 1))))
                        .font(MeowlettTypography.font(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(primary.opacity(isDark ? 0.12 : 0.06), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .cardStyle(dark: isDark)
    }

    private var reportCSV: String {
        var output = "Tanggal,Keterangan,Kategori,Lokasi,Jumlah\n"
        for item in store.transactions.sorted(by: { $0.date > $1.date }) {
            let fields = [
                item.date.formatted(.iso8601.year().month().day()),
                item.description,
                MeowlettCategory.name(for: item.category, language: language),
                item.location,
                String(item.amount)
            ]
            output += fields.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: ",") + "\n"
        }
        return output
    }

    private var reportHTML: String {
        let monthKey = Date.now.formatted(.iso8601.year().month())
        let monthTransactions = currentMonthTransactions.sorted { $0.date > $1.date }
        let categoryRows = Dictionary(grouping: monthTransactions, by: \.category)
            .map { key, values in (key, values.reduce(Int64(0)) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
        let total = monthTransactions.reduce(Int64(0)) { $0 + $1.amount }
        let remaining = income - total
        func escaped(_ value: String) -> String {
            value.replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
        }
        let transactionsHTML = monthTransactions.map { item in
            """
            <tr><td>\(item.date.formatted(.iso8601.year().month().day()))</td><td>\(escaped(item.description))</td><td>\(escaped(MeowlettCategory.name(for: item.category, language: language)))</td><td class="amount">\(escaped(rupiah(item.amount)))</td></tr>
            """
        }.joined()
        let categoryHTML = categoryRows.map { key, amount in
            let percent = total > 0 ? Int((Double(amount) / Double(total) * 100).rounded()) : 0
            return "<tr><td>\(escaped(MeowlettCategory.name(for: key, language: language)))</td><td class=\"amount\">\(escaped(rupiah(amount)))</td><td class=\"amount\">\(percent)%</td></tr>"
        }.joined()
        let title = isEnglish ? "Meowlett Finance Report" : "Laporan Keuangan Meowlett"
        let incomeTitle = isEnglish ? "INCOME" : "PEMASUKAN"
        let expenseTitle = isEnglish ? "EXPENSES" : "PENGELUARAN"
        let remainingTitle = isEnglish ? "REMAINING" : "SISA"
        return """
        <!doctype html><html lang="\(language)"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>\(title) · \(monthKey)</title>
        <style>
        body{font-family:-apple-system,BlinkMacSystemFont,Arial,sans-serif;max-width:800px;margin:32px auto;padding:0 18px;color:#111;background:#fff}
        h1{font-size:24px;color:#166534;margin-bottom:4px}.meta{color:#6b7280;font-size:13px}
        .summary{display:flex;flex-wrap:wrap;gap:28px;background:#f0fdf4;border-radius:12px;padding:18px;margin:22px 0}
        .label{font-size:10px;color:#6b7280;font-weight:800;letter-spacing:1px}.value{font-size:21px;font-weight:900;color:#166534;margin-top:5px}
        h2{font-size:16px;color:#166534;margin:25px 0 10px}table{width:100%;border-collapse:collapse}
        th{background:#f0fdf4;color:#166534;text-align:left;font-size:12px;padding:10px}
        td{border-bottom:1px solid #e5e7eb;padding:9px 10px;font-size:12px}.amount{text-align:right;white-space:nowrap}
        @media print{body{margin:0;max-width:none}}
        </style></head><body>
        <h1>\(title)</h1><p class="meta">\(monthKey) · \(Date.now.formatted(date: .long, time: .omitted))</p>
        <div class="summary">
          <div><div class="label">\(incomeTitle)</div><div class="value">\(escaped(rupiah(income)))</div></div>
          <div><div class="label">\(expenseTitle)</div><div class="value" style="color:#ef4444">\(escaped(rupiah(total)))</div></div>
          <div><div class="label">\(remainingTitle)</div><div class="value" style="color:\(remaining >= 0 ? "#16a34a" : "#ef4444")">\(escaped(rupiah(remaining)))</div></div>
        </div>
        <h2>\(isEnglish ? "Category breakdown" : "Rincian Kategori")</h2>
        <table><thead><tr><th>\(isEnglish ? "Category" : "Kategori")</th><th class="amount">\(isEnglish ? "Amount" : "Jumlah")</th><th class="amount">%</th></tr></thead><tbody>\(categoryHTML)</tbody></table>
        <h2>\(isEnglish ? "Transactions" : "Detail Transaksi") (\(monthTransactions.count))</h2>
        <table><thead><tr><th>\(isEnglish ? "Date" : "Tanggal")</th><th>\(isEnglish ? "Description" : "Keterangan")</th><th>\(isEnglish ? "Category" : "Kategori")</th><th class="amount">\(isEnglish ? "Amount" : "Jumlah")</th></tr></thead><tbody>\(transactionsHTML)</tbody></table>
        </body></html>
        """
    }

    private var reportSummary: String {
        let topCategory = Dictionary(grouping: currentMonthTransactions, by: \.category)
            .map { key, values in (key, values.reduce(Int64(0)) { $0 + $1.amount }) }
            .max { $0.1 < $1.1 }
        let topLabel = topCategory.map { MeowlettCategory.name(for: $0.0, language: language) } ?? "-"
        let month = Date.now.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: isEnglish ? "en_GB" : "id_ID")))
        if isEnglish {
            return "*Finance Report — \(month)*\n\nExpenses: \(rupiah(currentMonthTotal))\nIncome: \(rupiah(income))\nRemaining: \(rupiah(max(0, income - currentMonthTotal)))\n\nBiggest: \(topLabel)\(topCategory.map { " (\(rupiah($0.1)))" } ?? "")\n\n_Made with Meowlett_"
        }
        return "*Laporan Keuangan — \(month)*\n\nPengeluaran: \(rupiah(currentMonthTotal))\nPemasukan: \(rupiah(income))\nSisa: \(rupiah(max(0, income - currentMonthTotal)))\n\nTerbesar: \(topLabel)\(topCategory.map { " (\(rupiah($0.1)))" } ?? "")\n\n_Dibuat dengan Meowlett_"
    }

    private func sectionHeading(_ title: String, symbol: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
            Text(title).font(MeowlettTypography.font(size: 13, weight: .heavy)).foregroundStyle(.primary)
        }
    }

    private func emptyMessage(_ text: String) -> some View {
        Text(text).font(MeowlettTypography.font(size: 12, weight: .regular)).foregroundStyle(.secondary).multilineTextAlignment(.center)
    }

    private func rupiah(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        return "Rp" + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }
}

private struct ReportHTMLDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.html] }
    let html: String

    init(html: String) { self.html = html }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        html = String(data: data, encoding: .utf8) ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(html.utf8))
    }
}

private struct ReportTrendSeries: Identifiable {
    let id: String
    let color: Color
    let values: [Int64]
}

private struct NativeCategoryTrendChart: View {
    let series: [ReportTrendSeries]
    let mode: String

    var body: some View {
        Canvas { context, size in
            let padding: CGFloat = 10
            let chartHeight = size.height - 8
            let monthCount = max(series.first?.values.count ?? 4, 1)
            let maxAmount = CGFloat(max(series.flatMap(\.values).max() ?? 1, 1))

            var baseline = Path()
            baseline.move(to: CGPoint(x: padding, y: chartHeight))
            baseline.addLine(to: CGPoint(x: size.width - padding, y: chartHeight))
            context.stroke(baseline, with: .color(Color.primary.opacity(0.10)), lineWidth: 1)

            if mode == "bar" {
                let groupWidth = (size.width - padding * 2) / CGFloat(monthCount)
                let slotWidth = groupWidth * 0.72 / CGFloat(max(series.count, 1))
                for (categoryIndex, item) in series.enumerated() {
                    for (monthIndex, amount) in item.values.enumerated() {
                        let barHeight = max(2, CGFloat(amount) / maxAmount * (chartHeight - 16))
                        let x = padding + CGFloat(monthIndex) * groupWidth + groupWidth * 0.14 + CGFloat(categoryIndex) * slotWidth
                        let rect = CGRect(x: x, y: chartHeight - barHeight, width: max(2, slotWidth - 1), height: barHeight)
                        context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(item.color.opacity(0.9)))
                    }
                }
            } else {
                for item in series {
                    var path = Path()
                    var points: [CGPoint] = []
                    for (index, amount) in item.values.enumerated() {
                        let x = padding + CGFloat(index) / CGFloat(max(monthCount - 1, 1)) * (size.width - padding * 2)
                        let y = chartHeight - padding - CGFloat(amount) / maxAmount * (chartHeight - padding * 2)
                        let point = CGPoint(x: x, y: y)
                        points.append(point)
                        if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                    }
                    context.stroke(path, with: .color(item.color), lineWidth: 2)
                    for (index, point) in points.enumerated() where item.values[index] > 0 {
                        let dot = CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)
                        context.fill(Path(ellipseIn: dot), with: .color(item.color))
                    }
                }
            }
        }
    }
}

private extension View {
    func cardStyle(dark: Bool) -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppAppearance.card(dark: dark), in: RoundedRectangle(cornerRadius: 18))
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
