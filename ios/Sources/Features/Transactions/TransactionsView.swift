import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_categories") private var categoriesJSON = ""
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchQuery = ""
    @State private var period = "monthly"
    @State private var sortOrder = "date-desc"
    @State private var categoryFilter = "all"
    @State private var activeTransactionID: UUID?
    @State private var showEditor = false
    @State private var editingTransaction: MeowlettTransaction?

    private var isEnglish: Bool { language == "en" }
    private var isDark: Bool { colorScheme == .dark }
    private var accent: Color { Color(hex: AppAppearance.accentHex) }
    private var primary: Color { Color(hex: AppAppearance.primaryHex) }

    private var filtered: [MeowlettTransaction] {
        var items = store.transactions
        let calendar = Calendar.current
        switch period {
        case "daily":
            items = items.filter { calendar.isDateInToday($0.date) }
        case "weekly":
            items = items.filter {
                calendar.component(.weekOfYear, from: $0.date) == calendar.component(.weekOfYear, from: .now) &&
                calendar.component(.yearForWeekOfYear, from: $0.date) == calendar.component(.yearForWeekOfYear, from: .now)
            }
        default:
            items = items.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }
        }
        if categoryFilter != "all" { items = items.filter { $0.category == categoryFilter } }
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchQuery.lowercased()
            items = items.filter {
                $0.description.lowercased().contains(query) ||
                $0.location.lowercased().contains(query) ||
                $0.note.lowercased().contains(query)
            }
        }
        switch sortOrder {
        case "amt-desc": items.sort { $0.amount > $1.amount }
        case "amt-asc": items.sort { $0.amount < $1.amount }
        case "date-asc": items.sort { $0.date < $1.date }
        default: items.sort { $0.date > $1.date }
        }
        return items
    }

    private var grouped: [(date: Date, items: [MeowlettTransaction])] {
        let map = Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.date) }
        return map.keys.sorted(by: sortOrder == "date-asc" ? (<) : (>)).map { key in
            let values = map[key] ?? []
            return (key, values)
        }
    }

    private var filteredTotal: Int64 {
        filtered.reduce(Int64(0)) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                searchField
                filterControls
                HStack {
                    Text("\(filtered.count) \(isEnglish ? "transactions" : "transaksi")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("-\(rupiah(filteredTotal))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "#f87171"))
                        .contentTransition(.numericText())
                }
                .padding(.bottom, 10)

                if filtered.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(grouped, id: \.date) { group in
                            dateGroup(group.date, transactions: group.items)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEditor) {
            TransactionEditorSheet(transaction: editingTransaction)
                .environmentObject(store)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField(isEnglish ? "Search transactions..." : "Cari transaksi...", text: $searchQuery)
                .font(.system(size: 15))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchQuery.isEmpty {
                Button { searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 46)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.08), lineWidth: 1.5))
        .padding(.bottom, 10)
    }

    private var filterControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                filterMenu(
                    title: periodTitle,
                    active: true,
                    options: [
                        ("daily", isEnglish ? "Today" : "Hari ini"),
                        ("weekly", isEnglish ? "This week" : "Minggu ini"),
                        ("monthly", isEnglish ? "This month" : "Bulan ini")
                    ],
                    selection: $period
                )
                filterMenu(
                    title: amountSortTitle,
                    active: sortOrder.hasPrefix("amt"),
                    options: [
                        ("amt-desc", isEnglish ? "Highest amount" : "Nominal terbesar"),
                        ("amt-asc", isEnglish ? "Lowest amount" : "Nominal terkecil")
                    ],
                    selection: $sortOrder
                )
                filterMenu(
                    title: dateSortTitle,
                    active: sortOrder.hasPrefix("date"),
                    options: [
                        ("date-desc", isEnglish ? "Newest date" : "Tanggal terbaru"),
                        ("date-asc", isEnglish ? "Oldest date" : "Tanggal terlama")
                    ],
                    selection: $sortOrder
                )
            }
        }
        .padding(.bottom, 10)
    }

    private var periodTitle: String {
        switch period {
        case "daily": return isEnglish ? "Today" : "Hari ini"
        case "weekly": return isEnglish ? "This week" : "Minggu ini"
        default: return isEnglish ? "This month" : "Bulan ini"
        }
    }
    private var amountSortTitle: String {
        sortOrder == "amt-asc" ? (isEnglish ? "Lowest" : "Terkecil") : (isEnglish ? "Highest" : "Terbesar")
    }
    private var dateSortTitle: String {
        sortOrder == "date-asc" ? (isEnglish ? "Oldest" : "Terlama") : (isEnglish ? "Newest" : "Terbaru")
    }

    private func filterMenu(title: String, active: Bool, options: [(String, String)], selection: Binding<String>) -> some View {
        Menu {
            ForEach(options, id: \.0) { option in
                Button {
                    selection.wrappedValue = option.0
                } label: {
                    if selection.wrappedValue == option.0 {
                        Label(option.1, systemImage: "checkmark")
                    } else {
                        Text(option.1)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .black))
            }
            .foregroundStyle(active ? .white : Color.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(active ? primary : Color.primary.opacity(isDark ? 0.07 : 0.05), in: Capsule())
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(LinearGradient(colors: [accent.opacity(0.13), primary.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 88, height: 88)
                    .overlay(Circle().stroke(accent.opacity(0.25), lineWidth: 1.5))
                Image(systemName: searchQuery.isEmpty ? "plus.circle" : "magnifyingglass")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(accent)
            }
            .padding(.bottom, 6)
            Text(searchQuery.isEmpty
                 ? (isEnglish ? "No transactions yet" : "Belum ada transaksi")
                 : (isEnglish ? "No transactions found" : "Transaksi tidak ditemukan"))
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.primary)
            Text(searchQuery.isEmpty
                 ? (isEnglish ? "Start tracking your spending today." : "Yuk mulai catat pengeluaran hari ini.")
                 : (isEnglish ? "Try another search term." : "Coba kata pencarian lainnya."))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
            if searchQuery.isEmpty {
                Button {
                    editingTransaction = nil
                    showEditor = true
                } label: {
                    Label(isEnglish ? "Add first transaction" : "Catat transaksi pertama", systemImage: "plus")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 13)
                        .background(LinearGradient(colors: [accent, primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 38)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.primary.opacity(0.07), lineWidth: 1))
    }

    private func dateGroup(_ date: Date, transactions: [MeowlettTransaction]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: language == "en" ? "en_GB" : "id_ID"))).uppercased())
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(0.3)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Rectangle().fill(Color.primary.opacity(0.10)).frame(height: 1)
                Text("\(transactions.count) \(isEnglish ? "transactions" : "transaksi")")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
            VStack(spacing: 8) {
                ForEach(transactions) { transaction in
                    transactionCard(transaction)
                }
            }
        }
        .padding(.top, 5)
        .padding(.bottom, 10)
    }

    private func transactionCard(_ transaction: MeowlettTransaction) -> some View {
        let active = activeTransactionID == transaction.id
        let categoryColor = MeowlettCategory.color(for: transaction.category)
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeTransactionID = active ? nil : transaction.id
                }
            } label: {
                HStack(spacing: 11) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: MeowlettCategory.all.first(where: { $0.id == transaction.category })?.icon ?? "shippingbox")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(categoryColor)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.description)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        let categoryName = MeowlettCategory.name(for: transaction.category, language: language)
                        let secondary = [categoryName, transaction.location, transaction.note].filter { !$0.isEmpty }.joined(separator: " · ")
                        Text(secondary)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("-\(rupiah(transaction.amount))")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(Color(hex: "#f87171"))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.secondary.opacity(0.55))
                            .rotationEffect(.degrees(active ? 180 : 0))
                    }
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if active {
                HStack(spacing: 8) {
                    Button {
                        editingTransaction = transaction
                        showEditor = true
                        activeTransactionID = nil
                    } label: {
                        Label("Edit", systemImage: "pencil")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.09), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    Button {
                        store.delete(transaction)
                        activeTransactionID = nil
                    } label: {
                        Label(isEnglish ? "Delete" : "Hapus", systemImage: "trash")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "#f87171"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.25), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .overlay(alignment: .top) { Rectangle().fill(Color.primary.opacity(0.08)).frame(height: 1) }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5).fill(categoryColor).frame(width: 3).padding(.vertical, 1)
        }
        .shadow(color: .black.opacity(isDark ? 0 : 0.025), radius: 4, x: 0, y: 1)
    }

    private func rupiah(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        return "Rp" + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }
}
