import SwiftUI

private struct TransactionSortGlyph: View {
    let kind: String
    let ascending: Bool
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width, geometry.size.height) / 24
            Path { path in
                func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                    CGPoint(x: x * scale, y: y * scale)
                }

                if kind == "calendar" {
                    path.addRoundedRect(
                        in: CGRect(x: 3 * scale, y: 4 * scale, width: 18 * scale, height: 18 * scale),
                        cornerSize: CGSize(width: 2 * scale, height: 2 * scale)
                    )
                    path.move(to: point(16, 2))
                    path.addLine(to: point(16, 6))
                    path.move(to: point(8, 2))
                    path.addLine(to: point(8, 6))
                    path.move(to: point(3, 10))
                    path.addLine(to: point(21, 10))

                    if ascending {
                        path.move(to: point(12, 14))
                        path.addLine(to: point(12, 18))
                        path.addLine(to: point(15, 18))
                    } else {
                        path.move(to: point(15, 14))
                        path.addLine(to: point(12, 14))
                        path.addLine(to: point(12, 18))
                    }
                } else {
                    let lines: [(CGFloat, CGFloat, CGFloat, CGFloat)] = ascending
                        ? [(4, 18, 20, 18), (4, 14, 16, 14), (4, 10, 12, 10), (4, 6, 8, 6)]
                        : [(4, 6, 20, 6), (4, 10, 16, 10), (4, 14, 12, 14), (4, 18, 8, 18)]
                    for line in lines {
                        path.move(to: point(line.0, line.1))
                        path.addLine(to: point(line.2, line.3))
                    }
                }
            }
            .stroke(
                color,
                style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: 14, height: 14)
    }
}

struct TransactionsView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_categories") private var categoriesJSON = ""
    @AppStorage("gm_tx_receipts") private var receiptsRaw = "{}"
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchQuery = ""
    @State private var period = "monthly"
    @State private var sortOrder = "date-desc"
    @State private var filterPayment = "all"
    @State private var activeTransactionID: UUID?
    @State private var showEditor = false
    @State private var isRecurringUtilityPresented = false
    @State private var editingTransaction: MeowlettTransaction?
    @State private var recentlyDeletedTransaction: MeowlettTransaction?
    @State private var showUndoToast = false
    @State private var undoTask: Task<Void, Never>?

    private var isEnglish: Bool { language == "en" }
    private var isDark: Bool { colorScheme == .dark }
    private var accent: Color { Color(hex: AppAppearance.accentHex) }
    private var primary: Color { Color(hex: AppAppearance.primaryHex) }

    private var currentWeekBounds: (start: Date, end: Date) {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday, matching getWeek() in the PWA.
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today) // Sunday = 1
        let daysSinceMonday = (weekday + 5) % 7
        let start = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? today
        return (start, end)
    }

    private var filtered: [MeowlettTransaction] {
        var items = store.transactions
        let calendar = Calendar.current
        switch period {
        case "daily":
            items = items.filter { calendar.isDateInToday($0.date) }
        case "weekly":
            let bounds = currentWeekBounds
            items = items.filter { $0.date >= bounds.start && $0.date < bounds.end }
        default:
            items = items.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }
        }
        if filterPayment != "all" {
            items = items.filter { ($0.paymentMethod.isEmpty ? "cash" : $0.paymentMethod) == filterPayment }
        }
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchQuery.lowercased()
            items = items.filter {
                $0.description.lowercased().contains(query) ||
                $0.location.lowercased().contains(query) ||
                $0.note.lowercased().contains(query)
            }
        }
        let indexed = items.enumerated().sorted { lhs, rhs in
            switch sortOrder {
            case "amt-desc":
                return lhs.element.amount == rhs.element.amount
                    ? lhs.offset < rhs.offset
                    : lhs.element.amount > rhs.element.amount
            case "amt-asc":
                return lhs.element.amount == rhs.element.amount
                    ? lhs.offset < rhs.offset
                    : lhs.element.amount < rhs.element.amount
            case "date-asc":
                return lhs.element.date == rhs.element.date
                    ? lhs.offset < rhs.offset
                    : lhs.element.date < rhs.element.date
            default:
                return lhs.element.date == rhs.element.date
                    ? lhs.offset < rhs.offset
                    : lhs.element.date > rhs.element.date
            }
        }
        return indexed.map(\.element)
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
                paymentFilterRow
                HStack {
                    Text("\(filtered.count) \(isEnglish ? "transactions" : "transaksi")")
                        .font(MeowlettTypography.font(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("-\(rupiah(filteredTotal))")
                        .font(MeowlettTypography.font(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "#f87171"))
                        .contentTransition(.numericText())
                }
                .padding(.bottom, 10)

                if filtered.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(grouped.enumerated()), id: \.element.date) { index, group in
                            dateGroup(group.date, transactions: group.items, groupIndex: index)
                        }
                    }
                }
                RecurringTransactionsSection(isUtilitySheetPresented: $isRecurringUtilityPresented)
                    .environmentObject(store)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 90)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(AppAppearance.background(dark: isDark))
        .blur(radius: (showEditor || isRecurringUtilityPresented) ? 8 : 0)
        .animation(.easeInOut(duration: 0.2), value: showEditor || isRecurringUtilityPresented)
        .overlay(alignment: .bottom) {
            if showUndoToast, let deleted = recentlyDeletedTransaction {
                undoToast(for: deleted)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
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
                .font(MeowlettTypography.font(size: 16, weight: .regular))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchQuery.isEmpty {
                Button { searchQuery = "" } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 46)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppAppearance.border(dark: isDark), lineWidth: 1.5))
        .padding(.bottom, 10)
    }

    private var filterControls: some View {
        HStack(spacing: 6) {
            Menu {
                Button(isEnglish ? "Today" : "Hari ini") { period = "daily" }
                Button(isEnglish ? "This week" : "Minggu ini") { period = "weekly" }
                Button(isEnglish ? "This month" : "Bulan ini") { period = "monthly" }
            } label: {
                HStack(spacing: 7) {
                    Text(periodTitle)
                        .font(MeowlettTypography.font(size: 12, weight: .bold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(primary, in: Capsule())
            }
            Spacer(minLength: 4)
            sortButton(
                symbol: "calendar",
                active: sortOrder.hasPrefix("date"),
                ascending: sortOrder == "date-asc"
            ) {
                sortOrder = sortOrder == "date-desc" ? "date-asc" : "date-desc"
            }
            sortButton(
                symbol: "text.alignleft",
                active: sortOrder.hasPrefix("amt"),
                ascending: sortOrder == "amt-asc"
            ) {
                sortOrder = sortOrder == "amt-desc" ? "amt-asc" : "amt-desc"
            }
        }
        .padding(.bottom, 8)
    }

    private var periodTitle: String {
        switch period {
        case "daily": return isEnglish ? "Today" : "Hari ini"
        case "weekly": return isEnglish ? "This week" : "Minggu ini"
        default: return isEnglish ? "This month" : "Bulan ini"
        }
    }

    private func sortButton(symbol: String, active: Bool, ascending: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(active ? accent.opacity(0.08) : Color.primary.opacity(0.05))
                Circle()
                    .stroke(active ? accent.opacity(0.38) : Color.primary.opacity(0.10), lineWidth: 1.2)
                TransactionSortGlyph(
                    kind: symbol,
                    ascending: ascending,
                    color: active ? accent : AppAppearance.textSub(dark: isDark)
                )
            }
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }

    private var paymentFilterRow: some View {
        HStack(spacing: 6) {
            paymentFilterChip("all", title: isEnglish ? "All" : "Semua", symbol: "line.3.horizontal")
            paymentFilterChip("cash", title: isEnglish ? "Cash" : "Tunai", symbol: "banknote")
            paymentFilterChip("transfer", title: isEnglish ? "Transfer" : "Transfer", symbol: "building.columns")
            paymentFilterChip("qris", title: "QRIS", symbol: "qrcode")
        }
        .padding(.bottom, 10)
    }

    private func paymentFilterChip(_ value: String, title: String, symbol: String) -> some View {
        let selected = filterPayment == value
        return Button {
            filterPayment = value
        } label: {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(MeowlettTypography.font(size: 11, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? accent : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(selected ? accent.opacity(0.08) : Color.primary.opacity(0.04), in: Capsule())
            .overlay(Capsule().stroke(selected ? accent.opacity(0.38) : Color.primary.opacity(0.08), lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            if searchQuery.isEmpty {
                RoundedRectangle(cornerRadius: 26)
                    .fill(accent.opacity(0.08))
                    .frame(width: 88, height: 88)
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(accent.opacity(0.18), lineWidth: 1.5))
                    .overlay(
                        Image(systemName: "plus.circle")
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(accent)
                    )
                    .padding(.bottom, 16)

                Text(isEnglish ? "No transactions yet" : "Belum ada transaksi")
                    .font(MeowlettTypography.font(size: 18, weight: .black))
                    .foregroundStyle(.primary)
                    .padding(.bottom, 8)

                Text(isEnglish
                     ? "Start tracking your spending today."
                     : "Yuk mulai catat pengeluaran hari ini.")
                    .font(MeowlettTypography.font(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.bottom, 24)

                Button {
                    editingTransaction = nil
                    showEditor = true
                } label: {
                    Label(isEnglish ? "Add first transaction" : "Catat transaksi pertama", systemImage: "plus")
                        .font(MeowlettTypography.font(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(colors: [accent, primary], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                }
                .buttonStyle(.plain)
            } else {
                Circle()
                    .fill(LinearGradient(colors: [accent.opacity(0.10), primary.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(accent.opacity(0.16), lineWidth: 1.5))
                    .overlay(
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(isDark ? Color(hex: AppAppearance.lighten(AppAppearance.accentHex, ratio: 0.45)) : AppAppearance.accent)
                    )
                    .padding(.bottom, 16)

                Text(isEnglish ? "Not found" : "Tidak ditemukan")
                    .font(MeowlettTypography.font(size: 16, weight: .black))
                    .foregroundStyle(.primary)
                    .padding(.bottom, 6)

                Text((isEnglish ? "No results for " : "Tidak ada hasil untuk ") + "\"\(searchQuery)\"")
                    .font(MeowlettTypography.font(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 48)
        .padding(.bottom, 40)
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
    }

    private func dateGroup(_ date: Date, transactions: [MeowlettTransaction], groupIndex: Int) -> some View {
        let dateLabel: String = {
            if Calendar.current.isDateInToday(date) {
                return isEnglish ? "TODAY" : "HARI INI"
            }
            if Calendar.current.isDateInYesterday(date) {
                return isEnglish ? "YESTERDAY" : "KEMARIN"
            }
            return date.formatted(
                .dateTime.weekday(.wide).day().month(.wide)
                    .locale(Locale(identifier: language == "en" ? "en_GB" : "id_ID"))
            ).uppercased()
        }()

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(dateLabel)
                    .font(MeowlettTypography.font(size: 12, weight: .heavy))
                    .tracking(0.3)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Rectangle().fill(AppAppearance.border(dark: isDark)).frame(height: 1)
                Text("\(transactions.count) \(isEnglish ? "transactions" : "transaksi")")
                    .font(MeowlettTypography.font(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
            VStack(spacing: 8) {
                ForEach(transactions) { transaction in
                    transactionCard(transaction)
                }
            }
        }
        .padding(.top, groupIndex > 0 ? 16 : 0)
        .padding(.bottom, 8)
    }

    private func transactionCard(_ transaction: MeowlettTransaction) -> some View {
        let active = activeTransactionID == transaction.id
        let category = MeowlettCategory.all.first(where: { $0.id == transaction.category })
        let categoryColor = Color(hex: category?.color ?? "#94a3b8")
        let method = transaction.paymentMethod.isEmpty ? "cash" : transaction.paymentMethod
        let methodColor = method == "cash"
            ? Color(hex: "#4ade80")
            : method == "qris" ? Color(hex: "#8b5cf6") : Color(hex: "#3b82f6")
        let methodName = method == "cash"
            ? (isEnglish ? "Cash" : "Tunai")
            : method == "qris" ? "QRIS" : "Transfer"
        let methodIcon = method == "cash" ? "dollarsign.circle" : method == "qris" ? "qrcode" : "building.columns"
        let secondary = [
            MeowlettCategory.name(for: transaction.category, language: language),
            transaction.location,
            transaction.note
        ].filter { !$0.isEmpty }.joined(separator: " · ")

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeTransactionID = active ? nil : transaction.id
                }
            } label: {
                HStack(spacing: 11) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(categoryColor.opacity(0.145))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: category?.icon ?? "shippingbox")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundStyle(categoryColor)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.description)
                            .font(MeowlettTypography.font(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Text(secondary)
                                .font(MeowlettTypography.font(size: 11, weight: .regular))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .layoutPriority(0)
                            HStack(spacing: 2) {
                                Image(systemName: methodIcon)
                                    .font(.system(size: 8, weight: .regular))
                                Text(methodName)
                                    .font(MeowlettTypography.font(size: 9, weight: .heavy))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(methodColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(methodColor.opacity(0.12), in: Capsule())
                            .overlay(Capsule().stroke(methodColor.opacity(0.25), lineWidth: 1))
                            .fixedSize()
                        }

                        if hasReceipt(transaction) {
                            Label(isEnglish ? "Receipt photo" : "Foto struk", systemImage: "photo")
                                .font(MeowlettTypography.font(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.05), in: Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("-\(rupiah(transaction.amount))")
                            .font(MeowlettTypography.font(size: 13, weight: .heavy))
                            .foregroundStyle(Color(hex: "#f87171"))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .regular))
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
                            .font(MeowlettTypography.font(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(AppAppearance.input(dark: isDark), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppAppearance.border(dark: isDark), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)

                    Button {
                        deleteTransactionWithUndo(transaction)
                        activeTransactionID = nil
                    } label: {
                        Label(isEnglish ? "Delete" : "Hapus", systemImage: "trash")
                            .font(MeowlettTypography.font(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "#f87171"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color(hex: isDark ? "#1f0a0a" : "#fff1f2"), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: isDark ? "#3d1414" : "#fecdd3"), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .overlay(alignment: .top) { Rectangle().fill(AppAppearance.border(dark: isDark)).frame(height: 1) }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(active ? AppAppearance.accent.opacity(0.4) : AppAppearance.border(dark: isDark), lineWidth: 1))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(categoryColor)
                .frame(width: 3)
                .padding(.vertical, 1)
        }
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private func undoToast(for transaction: MeowlettTransaction) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "trash")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "#ef4444"))
            Text(isEnglish ? "Transaction deleted" : "Transaksi dihapus")
                .font(MeowlettTypography.font(size: 13, weight: .semibold))
                .foregroundStyle(isDark ? Color(hex: "#fca5a5") : Color(hex: "#b91c1c"))
                .lineLimit(1)
            Spacer(minLength: 4)
            Button(isEnglish ? "Undo" : "Batal") {
                undoDeletedTransaction()
            }
            .font(MeowlettTypography.font(size: 12, weight: .heavy))
            .foregroundStyle(Color(hex: "#ef4444"))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color(hex: "#ef4444").opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#ef4444").opacity(0.40), lineWidth: 1))
            .buttonStyle(.plain)
            .accessibilityLabel(isEnglish ? "Undo delete" : "Batalkan penghapusan")
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: 320)
        .background(Color(hex: isDark ? "#1a0d0d" : "#fff5f5"), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#ef4444").opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
        .accessibilityElement(children: .contain)
    }

    private func deleteTransactionWithUndo(_ transaction: MeowlettTransaction) {
        undoTask?.cancel()
        recentlyDeletedTransaction = transaction
        store.delete(transaction)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            showUndoToast = true
        }
        undoTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                showUndoToast = false
            }
            recentlyDeletedTransaction = nil
        }
    }

    private func undoDeletedTransaction() {
        guard let transaction = recentlyDeletedTransaction else { return }
        undoTask?.cancel()
        store.restore(transaction)
        withAnimation(.easeOut(duration: 0.2)) {
            showUndoToast = false
        }
        recentlyDeletedTransaction = nil
    }

    private func hasReceipt(_ transaction: MeowlettTransaction) -> Bool {
        guard let data = receiptsRaw.data(using: .utf8),
              let receipts = try? JSONDecoder().decode([String: String].self, from: data) else { return false }
        return receipts[transaction.id.uuidString] != nil
    }

    private func rupiah(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        return "Rp" + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }
}
