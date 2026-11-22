import SwiftUI

private struct DateWishlistItem: Identifiable, Codable, Equatable {
    // PWA stores Date.now() as a numeric ID; keep the same JSON shape for migration compatibility.
    var id: Int64
    var label: String
    var done: Bool = false
}

struct DateTabView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_date_wishlist") private var wishlistJSON = "[]"
    @Environment(\.colorScheme) private var colorScheme

    @State private var wishlist: [DateWishlistItem] = []
    @State private var wishlistLoaded = false
    @State private var showWishlistForm = false
    @State private var wishlistInput = ""
    @State private var activeDateID: UUID?
    @State private var showEditor = false
    @State private var editingTransaction: MeowlettTransaction?

    private var isEnglish: Bool { language == "en" }
    private var isDark: Bool { colorScheme == .dark }
    private var datePink: Color { Color(hex: "#f472b6") }
    private var datePrimary: Color { Color(hex: "#be185d") }
    private var monthTransactions: [MeowlettTransaction] {
        store.transactions.filter {
            $0.category == "date" && Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month)
        }
    }
    private var allDateTransactions: [MeowlettTransaction] {
        store.transactions.filter { $0.category == "date" }.sorted { $0.date > $1.date }
    }
    private var dateExpense: Int64 {
        monthTransactions.reduce(Int64(0)) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                dateBudgetCard
                wishlistCard
                dateRecordCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 90)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(AppAppearance.background(dark: isDark))
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: loadWishlist)
        .onChange(of: wishlist) { _, value in saveWishlist(value) }
        .sheet(isPresented: $showWishlistForm) {
            wishlistAddSheet
                .presentationDetents([.height(230)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showEditor) {
            TransactionEditorSheet(transaction: editingTransaction, initialCategory: "date")
                .environmentObject(store)
        }
    }

    private var dateBudgetCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(isEnglish ? "DATE BUDGET THIS MONTH" : "BUDGET DATE BULAN INI")
                .font(MeowlettTypography.font(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(isDark ? Color(hex: "#f9a8d4") : Color(hex: "#9d174d"))
            Text(rupiah(dateExpense))
                .font(MeowlettTypography.font(size: 32, weight: .black))
                .tracking(-0.6)
                .foregroundStyle(isDark ? Color(hex: "#f472b6") : datePrimary)
                .padding(.vertical, 6)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text("\(monthTransactions.count) \(isEnglish ? "date activities" : "aktivitas date")")
                .font(MeowlettTypography.font(size: 12, weight: .medium))
                .foregroundStyle(isDark ? Color(hex: "#f9a8d4") : Color(hex: "#9d174d"))
                .opacity(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .background {
            if isDark {
                Color(hex: "#1a0d14")
            } else {
                LinearGradient(colors: [Color(hex: "#fdf2f8"), Color(hex: "#fce7f3")], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(isDark ? Color(hex: "#3d1a2e") : Color(hex: "#f9a8d4"), lineWidth: 1))
    }

    private var wishlistCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                iconTile(symbol: "heart", pink: true)
                Text(isEnglish ? "Date Wishlist" : "Wishlist Date")
                    .font(MeowlettTypography.font(size: 14, weight: .heavy))
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    wishlistInput = ""
                    showWishlistForm = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                        Text(isEnglish ? "Add" : "Tambah").font(MeowlettTypography.font(size: 12, weight: .bold))
                    }
                    .foregroundStyle(datePink)
                }
                .buttonStyle(.plain)
            }

            if wishlist.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(datePink.opacity(0.42))
                    Text(isEnglish ? "No date wishlist yet" : "Belum ada wishlist date")
                        .font(MeowlettTypography.font(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(isEnglish ? "Add your dream date spots" : "Tambahkan tempat impian kalian")
                        .font(MeowlettTypography.font(size: 11, weight: .regular))
                        .foregroundStyle(Color.secondary.opacity(0.72))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 8) {
                    ForEach(wishlist) { item in
                        HStack(spacing: 10) {
                            Button { toggleWishlist(item) } label: {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(item.done ? datePink : .clear)
                                    .frame(width: 20, height: 20)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(item.done ? datePink : Color.primary.opacity(isDark ? 0.2 : 0.15), lineWidth: 2))
                                    .overlay {
                                        if item.done {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .black))
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            Text(item.label)
                                .font(MeowlettTypography.font(size: 13, weight: .semibold))
                                .foregroundStyle(item.done ? Color.secondary : Color.primary)
                                .strikethrough(item.done)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button { removeWishlist(item) } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#f472b6").opacity(isDark ? 0.07 : 0.06), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#f472b6").opacity(isDark ? 0.15 : 0.20), lineWidth: 1))
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private var dateRecordCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                iconTile(symbol: "pencil", pink: true)
                Text(isEnglish ? "Date Expenses" : "Catat Pengeluaran Date")
                    .font(MeowlettTypography.font(size: 14, weight: .heavy))
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    editingTransaction = nil
                    showEditor = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .black))
                        Text(isEnglish ? "Record" : "Catat").font(MeowlettTypography.font(size: 12, weight: .heavy))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(datePink, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            if allDateTransactions.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "heart")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color(hex: "#f9a8d4"))
                    Text(isEnglish ? "No date expenses yet" : "Belum ada pengeluaran date")
                        .font(MeowlettTypography.font(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
            } else {
                VStack(spacing: 9) {
                    ForEach(allDateTransactions) { transaction in
                        dateTransactionRow(transaction)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0 : 0.025), radius: 4, x: 0, y: 1)
    }

    private func dateTransactionRow(_ transaction: MeowlettTransaction) -> some View {
        let active = activeDateID == transaction.id
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeDateID = active ? nil : transaction.id
                }
            } label: {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(datePink.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "heart").font(.system(size: 16, weight: .medium)).foregroundStyle(datePink))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.description)
                            .font(MeowlettTypography.font(size: 13, weight: .bold))
                            .foregroundStyle(isDark ? datePink : datePrimary)
                            .lineLimit(1)
                        Text(dateLine(transaction))
                            .font(MeowlettTypography.font(size: 11, weight: .medium))
                            .foregroundStyle(isDark ? Color(hex: "#f9a8d4") : datePrimary)
                            .opacity(0.82)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("-\(rupiah(transaction.amount))")
                        .font(MeowlettTypography.font(size: 13, weight: .heavy))
                        .foregroundStyle(isDark ? datePink : datePrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(datePink.opacity(0.65))
                        .rotationEffect(.degrees(active ? 180 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(datePink.opacity(isDark ? 0.07 : 0.06))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if active {
                HStack(spacing: 8) {
                    Button {
                        editingTransaction = transaction
                        showEditor = true
                        activeDateID = nil
                    } label: {
                        Label(isEnglish ? "Edit" : "Edit", systemImage: "pencil")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(datePink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(datePink.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(datePink.opacity(0.25), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    Button {
                        store.delete(transaction)
                        activeDateID = nil
                    } label: {
                        Label(isEnglish ? "Delete" : "Hapus", systemImage: "trash")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.red.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.25), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(datePink.opacity(isDark ? 0.04 : 0.03))
                .overlay(alignment: .top) { Rectangle().fill(datePink.opacity(0.15)).frame(height: 1) }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(active ? datePink.opacity(0.45) : datePink.opacity(isDark ? 0.15 : 0.20), lineWidth: 1))
    }

    private var wishlistAddSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(isEnglish ? "Add Date Wishlist" : "Tambah Wishlist Date")
                    .font(MeowlettTypography.font(size: 16, weight: .black))
                    .foregroundStyle(.primary)
                Spacer()
                Button { showWishlistForm = false } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .semibold)).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            TextField(isEnglish ? "e.g. Rooftop dinner..." : "Contoh: Dinner di rooftop...", text: $wishlistInput)
                .font(MeowlettTypography.font(size: 16, weight: .regular))
                .padding(13)
                .background(AppAppearance.input(dark: isDark), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#f9a8d4"), lineWidth: 1.5))
                .submitLabel(.done)
                .onSubmit(addWishlist)
            Button(action: addWishlist) {
                Text(isEnglish ? "Save" : "Simpan")
                    .font(MeowlettTypography.font(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(datePink, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 36)
        .background(AppAppearance.card(dark: isDark))
    }

    private var cardBackground: Color {
        AppAppearance.card(dark: isDark)
    }
    private var cardBorder: Color {
        AppAppearance.border(dark: isDark)
    }

    private func iconTile(symbol: String, pink: Bool) -> some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(datePink.opacity(0.15))
            .frame(width: 28, height: 28)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(datePink)
            )
    }

    private func dateLine(_ item: MeowlettTransaction) -> String {
        let dateText = item.date.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
        return item.location.isEmpty ? dateText : "\(dateText) · \(item.location)"
    }

    private func loadWishlist() {
        guard !wishlistLoaded else { return }
        if let data = wishlistJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([DateWishlistItem].self, from: data) {
            wishlist = decoded
        }
        wishlistLoaded = true
    }

    private func saveWishlist(_ value: [DateWishlistItem]) {
        guard wishlistLoaded, let data = try? JSONEncoder().encode(value),
              let string = String(data: data, encoding: .utf8) else { return }
        wishlistJSON = string
    }

    private func addWishlist() {
        let value = wishlistInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        wishlist.append(DateWishlistItem(id: Int64(Date().timeIntervalSince1970 * 1000), label: value))
        wishlistInput = ""
        showWishlistForm = false
    }

    private func toggleWishlist(_ item: DateWishlistItem) {
        guard let index = wishlist.firstIndex(where: { $0.id == item.id }) else { return }
        wishlist[index].done.toggle()
    }

    private func removeWishlist(_ item: DateWishlistItem) {
        wishlist.removeAll { $0.id == item.id }
    }

    private func rupiah(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        return "Rp" + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }
}
