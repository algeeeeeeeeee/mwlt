import SwiftUI
import UniformTypeIdentifiers
import UIKit

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
    @State private var showStoryCard = false
    @State private var showExporter = false
    @State private var exportData = Data()
    @State private var exportContentType: UTType = .html
    @State private var exportFilename = "laporan"

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
            guard let start = calendar.date(byAdding: .day, value: -7 * offset, to: thisWeekStart),
                  let end = calendar.date(byAdding: .day, value: 7, to: start) else { return nil }
            let sum = store.transactions.filter { $0.date >= start && $0.date < end }.reduce(Int64(0)) { $0 + $1.amount }
            return (start, sum)
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
                if !categoryComparisons.isEmpty { categoryComparisonCard }
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
        .overlay {
            if showStoryCard {
                storyCardModal
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: ReportExportDocument(data: exportData),
            contentType: exportContentType,
            defaultFilename: exportFilename
        ) { _ in }
    }

    private var budgetWarningCard: some View {
        VStack(spacing: 8) {
            ForEach(Array(budgetWarnings.enumerated()), id: \.offset) { _, warning in
                let over = warning.1 >= warning.2
                let foreground = over ? Color(hex: "#b91c1c") : Color(hex: "#92400e")
                let detail = over ? Color(hex: "#ef4444") : Color(hex: "#f59e0b")
                let background = over ? Color(hex: "#fef2f2") : Color(hex: "#fffbeb")
                let border = over ? Color(hex: "#fca5a5") : Color(hex: "#fde68a")
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(over ? Color(hex: "#ef4444") : Color(hex: "#f59e0b"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(over ? (isEnglish ? "Exceeded" : "Terlampaui") : (isEnglish ? "Near limit" : "Mendekati batas")): \(MeowlettCategory.name(for: warning.0, language: language))")
                            .font(MeowlettTypography.font(size: 13, weight: .bold))
                            .foregroundStyle(foreground)
                        Text("\(rupiah(warning.1)) / \(rupiah(warning.2))")
                            .font(MeowlettTypography.font(size: 11, weight: .regular))
                            .foregroundStyle(detail)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(background, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: 1.5))
            }
        }
    }

    private var categoryComparisonCard: some View {
        let maxValue = max(categoryComparisons.map { max($0.1, $0.2) }.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(primary.opacity(0.10))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "list.bullet")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(primary)
                    )
                Text(isEnglish ? "Per Category — This vs Last Month" : "Per Kategori — Bulan Ini vs Lalu")
                    .font(MeowlettTypography.font(size: 13, weight: .heavy))
                    .foregroundStyle(.primary)
            }

            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 3).fill(primary).frame(width: 10, height: 10)
                    Text(isEnglish ? "This month" : "Bulan ini")
                        .font(MeowlettTypography.font(size: 10, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.25)).frame(width: 10, height: 10)
                    Text(isEnglish ? "Last month" : "Bulan lalu")
                        .font(MeowlettTypography.font(size: 10, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }

            if categoryComparisons.isEmpty {
                emptyMessage(isEnglish ? "No spending data yet." : "Belum ada data pengeluaran.")
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(categoryComparisons.enumerated()), id: \.offset) { _, item in
                        let current = item.1
                        let previous = item.2
                        let difference = current - previous
                        let percent = previous > 0
                            ? Int((Double(difference) / Double(previous) * 100).rounded())
                            : nil
                        let catColor = MeowlettCategory.color(for: item.0)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(catColor.opacity(0.14))
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Image(systemName: MeowlettCategory.all.first(where: { $0.id == item.0 })?.icon ?? "tag")
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundStyle(catColor)
                                    )
                                Text(MeowlettCategory.name(for: item.0, language: language))
                                    .font(MeowlettTypography.font(size: 12, weight: .bold))
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 4)
                                if let percent {
                                    HStack(spacing: 3) {
                                        Text(percent > 0 ? "▲" : "▼")
                                            .font(MeowlettTypography.font(size: 9, weight: .bold))
                                        Text("\(abs(percent))%")
                                            .font(MeowlettTypography.font(size: 11, weight: .bold))
                                    }
                                    .foregroundStyle(percent > 0 ? Color(hex: "#f87171") : Color(hex: "#4ade80"))
                                }
                            }

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.primary.opacity(isDark ? 0.07 : 0.07))
                                    Capsule()
                                        .fill(LinearGradient(colors: [primary, accent], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: proxy.size.width * CGFloat(current) / CGFloat(maxValue))
                                }
                            }
                            .frame(height: 7)
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.primary.opacity(isDark ? 0.04 : 0.04))
                                    Capsule()
                                        .fill(Color.primary.opacity(isDark ? 0.20 : 0.12))
                                        .frame(width: proxy.size.width * CGFloat(previous) / CGFloat(maxValue))
                                }
                            }
                            .frame(height: 4)
                            HStack {
                                Text(rupiah(current))
                                Spacer()
                                Text(rupiah(previous))
                                    .opacity(0.5)
                            }
                            .font(MeowlettTypography.font(size: 10, weight: .regular))
                            .foregroundStyle(.secondary)
                        }
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
            sectionHeading(isEnglish ? "8-Week Trend" : "Tren 8 Minggu", symbol: "chart.xyaxis.line")
            if weeklyTrend.allSatisfy({ $0.1 == 0 }) {
                emptyMessage(isEnglish ? "No data" : "Belum ada data bulan ini")
                    .frame(height: 115)
            } else {
                NativeReportChart(values: weeklyTrend, color: accent, pointColor: primary, mode: "line")
                    .frame(height: 110)
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { index in
                        Text("\(isEnglish ? "W" : "M")\(index + 1)")
                            .font(MeowlettTypography.font(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
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
                    exportData = Data(reportHTML.utf8)
                    exportContentType = .html
                    exportFilename = "laporan-\(Date.now.formatted(.iso8601.year().month()))"
                    showExporter = true
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
            Button {
                showStoryCard = true
            } label: {
                Label(isEnglish ? "Export as Image" : "Ekspor sebagai Gambar", systemImage: "arrow.down.to.line")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppAppearance.border(dark: isDark), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .padding(13)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 16))
    }

    private var selectedDayReportCard: some View {
        VStack(spacing: 12) {
            selectedDayPickerCard
            selectedDayTotalCard

            if reportTransactions.isEmpty {
                selectedDayEmptyCard
            } else {
                selectedDayCategoryCard
                selectedDayTransactionsCard
                selectedDayInsightCard
            }
        }
    }

    private var selectedDayPickerCard: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 9)
                .fill(primary.opacity(0.10))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(primary)
                )
            Text(isEnglish ? "Pick Date" : "Pilih Tanggal")
                .font(MeowlettTypography.font(size: 13, weight: .heavy))
                .foregroundStyle(.primary)
            Spacer()
            DatePicker("", selection: $reportDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(primary)
                .font(MeowlettTypography.font(size: 12, weight: .semibold))
        }
        .padding(16)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private var selectedDayTotalCard: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(isEnglish ? "TOTAL SPENDING" : "TOTAL PENGELUARAN")
                .font(MeowlettTypography.font(size: 11, weight: .bold))
                .foregroundStyle(AppAppearance.textSub(dark: isDark))
                .tracking(0.7)
            Text(reportTotal > 0 ? "-\(rupiah(reportTotal))" : rupiah(0))
                .font(MeowlettTypography.font(size: 30, weight: .black))
                .foregroundStyle(reportTotal > 0 ? Color(hex: "#f87171") : AppAppearance.textSub(dark: isDark))
                .padding(.vertical, 1)
            Text("\(dayLabel) · \(reportTransactions.count) \(isEnglish ? "transactions" : "transaksi")")
                .font(MeowlettTypography.font(size: 12, weight: .regular))
                .foregroundStyle(AppAppearance.textSub(dark: isDark))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            isDark
                ? Color(hex: AppAppearance.darken(AppAppearance.primaryHex, ratio: 0.55)).opacity(0.80)
                : primary.opacity(0.07),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(primary.opacity(isDark ? 0.27 : 0.20), lineWidth: 1)
        )
    }

    private var selectedDayEmptyCard: some View {
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
                .frame(width: 60, height: 60)
                .overlay(Circle().stroke(accent.opacity(0.30), lineWidth: 1.5))
                .overlay(
                    Image(systemName: "nosign")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(isDark ? Color(hex: AppAppearance.lighten(AppAppearance.accentHex, ratio: 0.45)) : primary)
                )
                .padding(.bottom, 10)
            Text(isEnglish ? "No transactions on this date" : "Tidak ada transaksi pada tanggal ini")
                .font(MeowlettTypography.font(size: 14, weight: .medium))
                .foregroundStyle(AppAppearance.textSub(dark: isDark))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private var selectedDayCategoryCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(isEnglish ? "By Category" : "Per Kategori")
                .font(MeowlettTypography.font(size: 13, weight: .heavy))
                .foregroundStyle(.primary)

            ForEach(Array(dailyCategoryTotals.enumerated()), id: \.offset) { _, item in
                let categoryColor = MeowlettCategory.color(for: item.0)
                let percent = reportTotal > 0
                    ? Int((Double(item.1) / Double(reportTotal) * 100).rounded())
                    : 0
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(categoryColor.opacity(0.14))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: MeowlettCategory.all.first(where: { $0.id == item.0 })?.icon ?? "tag")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(categoryColor)
                            )
                        Text(MeowlettCategory.name(for: item.0, language: language))
                            .font(MeowlettTypography.font(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text("\(percent)% · \(rupiah(item.1))")
                            .font(MeowlettTypography.font(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppAppearance.background(dark: isDark))
                            Capsule()
                                .fill(categoryColor)
                                .frame(width: proxy.size.width * CGFloat(percent) / 100)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(16)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private var selectedDayTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(isEnglish ? "Transactions" : "Detail Transaksi")
                .font(MeowlettTypography.font(size: 13, weight: .heavy))
                .foregroundStyle(.primary)
                .padding(.bottom, 10)

            ForEach(Array(reportTransactions.enumerated()), id: \.element.id) { index, transaction in
                let color = MeowlettCategory.color(for: transaction.category)
                HStack(spacing: 9) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: MeowlettCategory.all.first(where: { $0.id == transaction.category })?.icon ?? "tag")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(color)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.description)
                            .font(MeowlettTypography.font(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        if !transaction.location.isEmpty {
                            Text(transaction.location)
                                .font(MeowlettTypography.font(size: 10, weight: .regular))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 4)
                    Text("-\(rupiah(transaction.amount))")
                        .font(MeowlettTypography.font(size: 12, weight: .heavy))
                        .foregroundStyle(Color(hex: "#f87171"))
                        .lineLimit(1)
                }
                .padding(.vertical, 9)
                .overlay(alignment: .bottom) {
                    if index < reportTransactions.count - 1 {
                        Rectangle().fill(AppAppearance.border(dark: isDark)).frame(height: 0.7)
                    }
                }
            }

            HStack {
                Text(isEnglish ? "TODAY'S TOTAL" : "TOTAL HARI INI")
                    .font(MeowlettTypography.font(size: 11, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("-\(rupiah(reportTotal))")
                    .font(MeowlettTypography.font(size: 14, weight: .heavy))
                    .foregroundStyle(Color(hex: "#f87171"))
            }
            .padding(.top, 13)
        }
        .padding(16)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private var selectedDayInsightCard: some View {
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: reportDate)?.count ?? 30
        let averageDailyAllowance = income > 0
            ? Int64((Double(income) / Double(max(daysInMonth, 1))).rounded())
            : 0
        let aboveDailyAverage = reportTotal > averageDailyAllowance
        let tint = isDark
            ? Color(hex: AppAppearance.darken(AppAppearance.primaryHex, ratio: 0.55)).opacity(0.80)
            : primary.opacity(0.07)
        let tintBorder = primary.opacity(isDark ? 0.27 : 0.20)
        let labelColor = isDark
            ? Color(hex: AppAppearance.lighten(AppAppearance.accentHex, ratio: 0.30))
            : primary
        let top = dailyCategoryTotals.first
        let averageTransaction = Int64((Double(reportTotal) / Double(max(reportTransactions.count, 1))).rounded())

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(primary.opacity(isDark ? 0.25 : 0.10))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(labelColor)
                    )
                Text(isEnglish ? "Today's Insight" : "Insight Hari Ini")
                    .font(MeowlettTypography.font(size: 13, weight: .heavy))
                    .foregroundStyle(labelColor)
            }
            if let top {
                HStack(spacing: 8) {
                    Circle()
                        .fill(MeowlettCategory.color(for: top.0).opacity(0.14))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: MeowlettCategory.all.first(where: { $0.id == top.0 })?.icon ?? "tag")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(MeowlettCategory.color(for: top.0))
                        )
                    (
                        Text(isEnglish ? "Top: " : "Terbanyak: ")
                            .foregroundColor(labelColor)
                        + Text(MeowlettCategory.name(for: top.0, language: language))
                            .fontWeight(.bold)
                            .foregroundColor(MeowlettCategory.color(for: top.0))
                        + Text(" — \(rupiah(top.1))")
                            .foregroundColor(labelColor)
                    )
                    .font(MeowlettTypography.font(size: 12, weight: .regular))
                    .lineLimit(1)
                }
            }
            HStack(spacing: 8) {
                Circle()
                    .fill((aboveDailyAverage ? Color(hex: "#ef4444") : Color(hex: "#16a34a")).opacity(0.15))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: aboveDailyAverage ? "exclamationmark.triangle" : "checkmark.circle")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(aboveDailyAverage ? Color(hex: "#ef4444") : Color(hex: "#16a34a"))
                    )
                Text("\(aboveDailyAverage ? (isEnglish ? "Above daily average" : "Melebihi rata-rata harian") : (isEnglish ? "Below daily average" : "Di bawah rata-rata harian")) (\(rupiah(averageDailyAllowance)))")
                    .font(MeowlettTypography.font(size: 12, weight: .regular))
                    .foregroundStyle(aboveDailyAverage ? Color(hex: "#ef4444") : (isDark ? Color(hex: "#86efac") : Color(hex: "#16a34a")))
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 8) {
                Circle()
                    .fill(primary.opacity(isDark ? 0.15 : 0.10))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: "function")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(labelColor)
                    )
                (
                    Text(isEnglish ? "Average per transaction: " : "Rata-rata per transaksi: ")
                        .foregroundColor(labelColor)
                    + Text(rupiah(averageTransaction))
                        .fontWeight(.bold)
                        .foregroundColor(labelColor)
                )
                .font(MeowlettTypography.font(size: 12, weight: .regular))
            }
        }
        .padding(16)
        .background(tint, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(tintBorder, lineWidth: 1))
    }

    private var storyTopCategories: [(String, Int64)] {
        Dictionary(grouping: currentMonthTransactions, by: \.category)
            .map { key, values in
                (key, values.reduce(Int64(0)) { $0 + $1.amount })
            }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0 }
    }

    private var storyPercentage: Int {
        income > 0 ? Int((Double(currentMonthTotal) / Double(income) * 100).rounded()) : 0
    }

    private var storyRemaining: Int64 {
        income - currentMonthTotal
    }

    private var storyCardModal: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.75))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { showStoryCard = false }

            VStack(spacing: 14) {
                ReportStoryCardView(
                    month: currentMonthLabel,
                    percentUsed: storyPercentage,
                    totalExpense: currentMonthTotal,
                    income: income,
                    remaining: storyRemaining,
                    topCategories: storyTopCategories,
                    themePrimary: primary,
                    themeAccent: accent,
                    isEnglish: isEnglish,
                    language: language
                )

                HStack(spacing: 10) {
                    Button {
                        showStoryCard = false
                    } label: {
                        Text(isEnglish ? "Cancel" : "Batal")
                            .font(MeowlettTypography.font(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.20), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)

                    Button {
                        exportStoryImage()
                    } label: {
                        Label(isEnglish ? "Download Image" : "Unduh Gambar", systemImage: "arrow.down.to.line")
                            .font(MeowlettTypography.font(size: 13, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(LinearGradient(colors: [accent, primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }

                Text(isEnglish ? "Tap outside to close" : "Tap di luar untuk tutup")
                    .font(MeowlettTypography.font(size: 11, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
            .frame(maxWidth: 380)
            .padding(20)
        }
        .transition(.opacity)
        .zIndex(100)
    }

    @MainActor
    private func exportStoryImage() {
        let renderer = ImageRenderer(content: ReportStoryCardView(
            month: currentMonthLabel,
            percentUsed: storyPercentage,
            totalExpense: currentMonthTotal,
            income: income,
            remaining: storyRemaining,
            topCategories: storyTopCategories,
            themePrimary: primary,
            themeAccent: accent,
            isEnglish: isEnglish,
            language: language
        ).frame(width: 380))
        renderer.scale = 3
        guard let data = renderer.uiImage?.pngData() else { return }
        exportData = data
        exportContentType = .png
        exportFilename = "meowlett-\(Date.now.formatted(.iso8601.year().month()))"
        showExporter = true
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

private struct ReportExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.html, .png] }
    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
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
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: dark), lineWidth: 1))
            .shadow(color: .black.opacity(dark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }
}

private struct NativeReportChart: View {
    let values: [(Date, Int64)]
    let color: Color
    let pointColor: Color
    let mode: String

    var body: some View {
        Canvas { context, size in
            let padding: CGFloat = 12
            let bottom = size.height - 8
            let top: CGFloat = 12
            let plotHeight = max(bottom - top, 1)
            let maxValue = max(Double(values.map { $0.1 }.max() ?? 1), 1)
            let points = values.enumerated().map { index, item in
                CGPoint(
                    x: values.count > 1
                        ? padding + (size.width - padding * 2) * CGFloat(index) / CGFloat(values.count - 1)
                        : size.width / 2,
                    y: bottom - CGFloat(Double(item.1) / maxValue) * plotHeight
                )
            }

            var baseline = Path()
            baseline.move(to: CGPoint(x: padding, y: bottom))
            baseline.addLine(to: CGPoint(x: size.width - padding, y: bottom))
            context.stroke(baseline, with: .color(Color.primary.opacity(0.10)), lineWidth: 1)

            if mode == "bar" {
                let groupWidth = (size.width - padding * 2) / CGFloat(max(values.count, 1))
                for (index, item) in values.enumerated() {
                    let barHeight = max(2, CGFloat(Double(item.1) / maxValue) * plotHeight)
                    let rect = CGRect(
                        x: padding + CGFloat(index) * groupWidth + groupWidth * 0.18,
                        y: bottom - barHeight,
                        width: groupWidth * 0.64,
                        height: barHeight
                    )
                    context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(color.opacity(0.88)))
                }
            } else if let first = points.first, let last = points.last {
                var line = Path()
                line.move(to: first)
                for point in points.dropFirst() { line.addLine(to: point) }

                var area = line
                area.addLine(to: CGPoint(x: last.x, y: bottom))
                area.addLine(to: CGPoint(x: first.x, y: bottom))
                area.closeSubpath()

                context.fill(
                    area,
                    with: .linearGradient(
                        Gradient(colors: [color.opacity(0.30), color.opacity(0)]),
                        startPoint: CGPoint(x: 0, y: top),
                        endPoint: CGPoint(x: 0, y: bottom)
                    )
                )
                context.stroke(
                    line,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )

                for point in points {
                    let dot = CGRect(x: point.x - 4.5, y: point.y - 4.5, width: 9, height: 9)
                    let shape = Path(ellipseIn: dot)
                    context.fill(shape, with: .color(pointColor))
                    context.stroke(shape, with: .color(color), lineWidth: 2)
                }
            }
        }
    }
}

private struct ReportStoryCardView: View {
    let month: String
    let percentUsed: Int
    let totalExpense: Int64
    let income: Int64
    let remaining: Int64
    let topCategories: [(String, Int64)]
    let themePrimary: Color
    let themeAccent: Color
    let isEnglish: Bool
    let language: String

    private func rupiah(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        return "Rp" + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MEOWLETT")
                        .font(MeowlettTypography.font(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text(month)
                        .font(MeowlettTypography.font(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                }
                Spacer()
                Text("\(percentUsed)% \(isEnglish ? "used" : "terpakai")")
                    .font(MeowlettTypography.font(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.bottom, 24)

            Text(isEnglish ? "TOTAL SPENDING" : "TOTAL PENGELUARAN")
                .font(MeowlettTypography.font(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color.white.opacity(0.5))
                .padding(.bottom, 4)

            Text(rupiah(totalExpense))
                .font(MeowlettTypography.font(size: 36, weight: .black))
                .tracking(-1)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.bottom, 4)

            Text(isEnglish ? "of \(rupiah(income)) income" : "dari \(rupiah(income)) pemasukan")
                .font(MeowlettTypography.font(size: 12, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.45))
                .padding(.bottom, 24)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.10))
                    Capsule()
                        .fill(Color.white.opacity(0.70))
                        .frame(width: proxy.size.width * CGFloat(min(100, max(0, percentUsed))) / 100)
                }
            }
            .frame(height: 6)
            .padding(.bottom, 24)

            if !topCategories.isEmpty {
                Text(isEnglish ? "TOP CATEGORIES" : "KATEGORI TERBESAR")
                    .font(MeowlettTypography.font(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.bottom, 10)

                VStack(spacing: 8) {
                    ForEach(Array(topCategories.enumerated()), id: \.offset) { _, item in
                        HStack {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(MeowlettCategory.color(for: item.0))
                                    .frame(width: 8, height: 8)
                                Text(MeowlettCategory.name(for: item.0, language: language))
                                    .font(MeowlettTypography.font(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                            Spacer()
                            Text(rupiah(item.1))
                                .font(MeowlettTypography.font(size: 12, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }

            HStack {
                Text(isEnglish ? "Remaining" : "Sisa")
                    .font(MeowlettTypography.font(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.5))
                Spacer()
                Text(remaining >= 0 ? rupiah(remaining) : "-\(rupiah(abs(remaining)))")
                    .font(MeowlettTypography.font(size: 15, weight: .black))
                    .foregroundStyle(remaining >= 0 ? Color.white.opacity(0.9) : Color(hex: "#f87171"))
            }
            .padding(.top, 16)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1)
            }
            .padding(.top, 20)
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [themePrimary, themePrimary.opacity(0.80), Color(hex: "#0d0d0d")], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 160, height: 160)
                .offset(x: 40, y: -40)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 100, height: 100)
                .offset(x: -20, y: 20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
