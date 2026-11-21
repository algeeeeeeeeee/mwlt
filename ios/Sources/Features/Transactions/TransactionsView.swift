import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_categories") private var categoriesJSON = ""
    @AppStorage("gm_recurring") private var recurringRaw = "[]"
    @AppStorage("gm_tx_receipts") private var receiptsRaw = "{}"
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchQuery = ""
    @State private var period = "monthly"
    @State private var sortOrder = "date-desc"
    @State private var filterPayment = "all"
    @State private var activeTransactionID: UUID?
    @State private var showEditor = false
    @State private var editingTransaction: MeowlettTransaction?
    @State private var recurringItems: [MeowlettRecurringTransaction] = []
    @State private var recurringLoaded = false
    @State private var showRecurringPanel = false
    @State private var recurringDescription = ""
    @State private var recurringAmount = ""
    @State private var recurringDay = "1"
    @State private var recurringCategory = "food"
    @State private var recurringAutoApply = true
    @State private var editingRecurringID: Int64?

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
                paymentFilterRow
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
                recurringSection
                    .padding(.top, 10)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(AppAppearance.background(dark: isDark))
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEditor) {
            TransactionEditorSheet(transaction: editingTransaction)
                .environmentObject(store)
        }
        .onAppear(perform: loadRecurring)
        .onChange(of: recurringItems) { _, value in persistRecurring(value) }
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
        .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.08), lineWidth: 1.5))
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
                        .font(.system(size: 12, weight: .bold))
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
                    .fill(active ? accent.opacity(0.13) : Color.primary.opacity(isDark ? 0.06 : 0.045))
                Circle()
                    .stroke(active ? accent.opacity(0.55) : Color.primary.opacity(0.10), lineWidth: 1.2)
                VStack(spacing: -3) {
                    Image(systemName: symbol)
                        .font(.system(size: 10, weight: .bold))
                    Image(systemName: ascending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8, weight: .black))
                }
                .foregroundStyle(active ? accent : Color.secondary)
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
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? accent : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(selected ? accent.opacity(0.12) : Color.primary.opacity(isDark ? 0.045 : 0.035), in: Capsule())
            .overlay(Capsule().stroke(selected ? accent.opacity(0.55) : Color.primary.opacity(0.08), lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
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
        .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
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
                        HStack(spacing: 5) {
                            let method = transaction.paymentMethod.isEmpty ? "cash" : transaction.paymentMethod
                            let methodColor = method == "cash" ? Color(hex: "#4ade80") : method == "qris" ? Color(hex: "#8b5cf6") : Color(hex: "#3b82f6")
                            Image(systemName: method == "cash" ? "banknote" : method == "qris" ? "qrcode" : "building.columns")
                                .font(.system(size: 8, weight: .semibold))
                            Text(method == "cash" ? (isEnglish ? "Cash" : "Tunai") : method == "qris" ? "QRIS" : "Transfer")
                                .font(.system(size: 9, weight: .heavy))
                            .lineLimit(1)
                        }
                        .foregroundStyle(Color(hex: transaction.paymentMethod == "cash" || transaction.paymentMethod.isEmpty ? "#4ade80" : transaction.paymentMethod == "qris" ? "#8b5cf6" : "#3b82f6"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: transaction.paymentMethod == "cash" || transaction.paymentMethod.isEmpty ? "#4ade80" : transaction.paymentMethod == "qris" ? "#8b5cf6" : "#3b82f6").opacity(0.12), in: Capsule())
                        if hasReceipt(transaction) {
                            Label(isEnglish ? "Receipt photo" : "Foto struk", systemImage: "photo")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.05), in: Capsule())
                        }
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
        .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5).fill(categoryColor).frame(width: 3).padding(.vertical, 1)
        }
        .shadow(color: .black.opacity(isDark ? 0 : 0.025), radius: 4, x: 0, y: 1)
    }

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showRecurringPanel.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Rectangle().fill(Color.primary.opacity(0.10)).frame(height: 1)
                    Image(systemName: "repeat").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                    Text(isEnglish ? "RECURRING TRANSACTIONS" : "TRANSAKSI RUTIN")
                        .font(.system(size: 10, weight: .heavy)).tracking(1.1).foregroundStyle(.secondary).fixedSize()
                    if recurringItems.contains(where: { !$0.autoApply }) {
                        Text("\(recurringItems.filter { !$0.autoApply }.count)")
                            .font(.system(size: 9, weight: .black)).foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color(hex: "#ef4444"), in: Capsule())
                    }
                    Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showRecurringPanel ? 180 : 0))
                    Rectangle().fill(Color.primary.opacity(0.10)).frame(height: 1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showRecurringPanel {
                recurringFormCard
                if recurringItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "repeat.circle")
                            .font(.system(size: 29, weight: .light)).foregroundStyle(accent)
                        Text(isEnglish ? "No recurring transactions" : "Belum ada transaksi rutin")
                            .font(.system(size: 13, weight: .bold))
                        Text(isEnglish ? "Add a payment that repeats every month." : "Tambahkan pembayaran yang berulang setiap bulan.")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 24)
                    .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(spacing: 0) {
                        ForEach(recurringItems) { item in
                            recurringRow(item)
                            if item.id != recurringItems.last?.id {
                                Rectangle().fill(Color.primary.opacity(0.07)).frame(height: 1).padding(.leading, 60)
                            }
                        }
                    }
                    .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.07), lineWidth: 1))
                }
            }
        }
    }

    private var recurringFormCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label(isEnglish ? "Add recurring" : "Tambah transaksi rutin", systemImage: "repeat")
                    .font(.system(size: 13, weight: .heavy)).foregroundStyle(.primary)
                Spacer()
                if editingRecurringID != nil {
                    Button(isEnglish ? "Cancel edit" : "Batal edit") { resetRecurringForm() }
                        .font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                }
            }
            TextField(isEnglish ? "Transaction name" : "Nama transaksi", text: $recurringDescription)
                .font(.system(size: 14)).padding(12)
                .background(AppAppearance.input(dark: isDark), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1.3))
            HStack(spacing: 8) {
                TextField("1.000.000", text: $recurringAmount)
                    .keyboardType(.numberPad)
                    .font(.system(size: 14, weight: .bold))
                    .padding(12)
                    .background(AppAppearance.input(dark: isDark), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1.3))
                VStack(alignment: .leading, spacing: 3) {
                    Text(isEnglish ? "DAY" : "TANGGAL")
                        .font(.system(size: 9, weight: .heavy)).foregroundStyle(.secondary)
                    TextField("1", text: $recurringDay)
                        .keyboardType(.numberPad)
                        .font(.system(size: 14, weight: .bold))
                        .padding(10)
                        .background(AppAppearance.input(dark: isDark), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1.3))
                }
                .frame(width: 90)
            }
            Menu {
                ForEach(MeowlettCategory.all, id: \.id) { category in
                    Button {
                        recurringCategory = category.id
                    } label: {
                        Label(category.idName, systemImage: category.icon)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: MeowlettCategory.all.first(where: { $0.id == recurringCategory })?.icon ?? "tag")
                        .foregroundStyle(MeowlettCategory.color(for: recurringCategory))
                    Text(MeowlettCategory.name(for: recurringCategory, language: language))
                        .font(.system(size: 12, weight: .bold)).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                }
                .padding(11)
                .background(AppAppearance.input(dark: isDark), in: RoundedRectangle(cornerRadius: 12))
            }
            Toggle(isEnglish ? "Apply automatically" : "Catat otomatis", isOn: $recurringAutoApply)
                .font(.system(size: 12, weight: .semibold)).tint(primary)
            Text(isEnglish ? "Automatic entries are created on the selected day when the app opens. Manual items can be recorded from the list." : "Transaksi otomatis dibuat saat aplikasi dibuka pada tanggal pilihan. Item manual bisa dicatat dari daftar.")
                .font(.system(size: 10)).foregroundStyle(.secondary)
            Button(action: saveRecurring) {
                Label(editingRecurringID == nil
                      ? (isEnglish ? "Add recurring" : "Tambah transaksi rutin")
                      : (isEnglish ? "Save changes" : "Simpan perubahan"),
                      systemImage: editingRecurringID == nil ? "plus" : "checkmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 42)
                    .background(LinearGradient(colors: [accent, primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(recurringDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Int64(recurringAmount.filter(\.isNumber)) ?? 0) <= 0)
            .opacity(recurringDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Int64(recurringAmount.filter(\.isNumber)) ?? 0) <= 0 ? 0.5 : 1)
        }
        .padding(14)
        .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.07), lineWidth: 1))
    }

    private func recurringRow(_ item: MeowlettRecurringTransaction) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 11)
                .fill(MeowlettCategory.color(for: item.category).opacity(0.15))
                .frame(width: 38, height: 38)
                .overlay(Image(systemName: MeowlettCategory.all.first(where: { $0.id == item.category })?.icon ?? "tag")
                    .foregroundStyle(MeowlettCategory.color(for: item.category)))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.description).font(.system(size: 13, weight: .bold)).foregroundStyle(.primary).lineLimit(1)
                HStack(spacing: 4) {
                    Text(MeowlettCategory.name(for: item.category, language: language))
                    Text("·")
                    Text((isEnglish ? "Day" : "Tgl") + " \(item.day)")
                    Text("·")
                    Text(item.autoApply ? (isEnglish ? "Auto" : "Otomatis") : "Manual")
                        .foregroundStyle(item.autoApply ? accent : Color(hex: "#f59e0b"))
                }
                .font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 2)
            VStack(alignment: .trailing, spacing: 6) {
                Text("-\(rupiah(item.amount))").font(.system(size: 12, weight: .heavy)).foregroundStyle(Color(hex: "#f87171"))
                HStack(spacing: 5) {
                    if !item.autoApply {
                        Button {
                            store.add(MeowlettTransaction(date: .now, amount: item.amount, category: item.category, description: item.description, location: "Rutin", note: "Manual"))
                        } label: {
                            Text(isEnglish ? "Record" : "Catat")
                                .font(.system(size: 9, weight: .heavy)).foregroundStyle(Color(hex: "#d97706"))
                                .padding(.horizontal, 7).padding(.vertical, 5)
                                .background(Color(hex: "#f59e0b").opacity(0.13), in: RoundedRectangle(cornerRadius: 7))
                        }.buttonStyle(.plain)
                    }
                    Button {
                        recurringDescription = item.description
                        recurringAmount = String(item.amount)
                        recurringDay = String(item.day)
                        recurringCategory = item.category
                        recurringAutoApply = item.autoApply
                        editingRecurringID = item.id
                    } label: {
                        Image(systemName: "pencil").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                    }.buttonStyle(.plain)
                    Button {
                        recurringItems.removeAll { $0.id == item.id }
                    } label: {
                        Image(systemName: "trash").font(.system(size: 10, weight: .semibold)).foregroundStyle(Color(hex: "#ef4444"))
                    }.buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 11)
    }

    private func loadRecurring() {
        guard !recurringLoaded else { return }
        if let data = recurringRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([MeowlettRecurringTransaction].self, from: data) {
            recurringItems = decoded
        }
        recurringLoaded = true
    }

    private func persistRecurring(_ value: [MeowlettRecurringTransaction]) {
        guard recurringLoaded, let data = try? JSONEncoder().encode(value),
              let json = String(data: data, encoding: .utf8) else { return }
        recurringRaw = json
    }

    private func saveRecurring() {
        let title = recurringDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, let value = Int64(recurringAmount.filter(\.isNumber)), value > 0 else { return }
        let item = MeowlettRecurringTransaction(
            id: editingRecurringID ?? Int64(Date().timeIntervalSince1970 * 1000),
            description: title,
            amount: value,
            category: recurringCategory,
            day: min(31, max(1, Int(recurringDay) ?? 1)),
            autoApply: recurringAutoApply
        )
        if let id = editingRecurringID, let index = recurringItems.firstIndex(where: { $0.id == id }) {
            recurringItems[index] = item
        } else {
            recurringItems.append(item)
        }
        resetRecurringForm()
    }

    private func resetRecurringForm() {
        recurringDescription = ""
        recurringAmount = ""
        recurringDay = "1"
        recurringCategory = "food"
        recurringAutoApply = true
        editingRecurringID = nil
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
