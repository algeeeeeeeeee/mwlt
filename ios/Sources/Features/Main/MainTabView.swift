import SwiftUI

private enum MeowlettTab: String, CaseIterable {
    case dashboard, transactions, report, date, settings

    var titleID: String {
        switch self {
        case .dashboard: return "Beranda"
        case .transactions: return "Transaksi"
        case .report: return "Laporan"
        case .date: return "Date"
        case .settings: return "Pengaturan"
        }
    }

    var titleEN: String {
        switch self {
        case .dashboard: return "Home"
        case .transactions: return "Transactions"
        case .report: return "Reports"
        case .date: return "Date"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: return "cat"
        case .transactions: return "line.3.horizontal"
        case .report: return "list.bullet"
        case .date: return "heart"
        case .settings: return "slider.horizontal.3"
        }
    }
}

struct MainTabView: View {
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_theme_preset") private var themePreset = "rose"
    @AppStorage("gm_custom_accent") private var customAccent = "#fb7185"
    @EnvironmentObject private var store: FinanceStore
    @State private var selected: MeowlettTab = .dashboard
    @State private var showQuickAdd = false

    private var isEnglish: Bool { language == "en" }
    private var tint: Color {
        themePreset == "custom"
            ? Color(hex: customAccent)
            : Color(hex: AppAppearance.presets.first(where: { $0.id == themePreset })?.accent ?? "#fb7185")
    }
    private var primary: Color {
        Color(hex: AppAppearance.primaryHex)
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            Group {
                switch selected {
                case .dashboard: DashboardView()
                case .transactions: TransactionsView()
                case .report: ReportsView()
                case .date: DateTabView()
                case .settings: SettingsView()
                }
            }
            .environmentObject(store)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomNavigation
        }
        .tint(tint)
        .sheet(isPresented: $showQuickAdd) {
            NavigationStack {
                QuickTransactionSheet()
                    .environmentObject(store)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var bottomNavigation: some View {
        HStack(spacing: 10) {
            Button {
                showQuickAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(LinearGradient(colors: [tint, primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                    .shadow(color: tint.opacity(0.34), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isEnglish ? "Add transaction" : "Tambah transaksi")

            HStack(spacing: 0) {
                ForEach([MeowlettTab.dashboard, .transactions, .report, .date], id: \.self) { tab in
                    let active = selected == tab
                    let isDate = tab == .date
                    let activeColor = isDate ? Color(hex: "#be185d") : (colorSchemeIsDark ? tint.opacity(0.9) : primary)
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            selected = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: active ? 18 : 22, weight: .regular))
                                .frame(width: 22, height: 22)
                            if active {
                                Text(isEnglish ? tab.titleEN : tab.titleID)
                                    .font(.system(size: 12, weight: .heavy))
                                    .lineLimit(1)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                        .foregroundStyle(active ? activeColor : (isDate ? Color(hex: "#f9a8d4") : Color.secondary.opacity(0.65)))
                        .frame(minWidth: 54, minHeight: 54)
                        .padding(.horizontal, active ? 9 : 0)
                        .background {
                            if active {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isDate ? Color(hex: "#be185d").opacity(0.09) : tint.opacity(colorSchemeIsDark ? 0.16 : 0.08))
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(colorSchemeIsDark ? 0.10 : 0.07), lineWidth: 1))
            .shadow(color: .black.opacity(colorSchemeIsDark ? 0.25 : 0.08), radius: 14, x: 0, y: 3)

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    selected = .settings
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(selected == .settings ? tint : Color.secondary)
                    .frame(width: 42, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isEnglish ? "Settings" : "Pengaturan")
        }
        .padding(.horizontal, 12)
        .padding(.top, 5)
        .padding(.bottom, 7)
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(colors: [Color(uiColor: .systemGroupedBackground).opacity(0), Color(uiColor: .systemGroupedBackground).opacity(0.96)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    @Environment(\.colorScheme) private var colorScheme
    private var colorSchemeIsDark: Bool { colorScheme == .dark }
}

private struct QuickTransactionSheet: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("gm_lang") private var language = "id"
    @State private var title = ""
    @State private var amount = ""
    @State private var category = "food"
    @State private var date = Date.now

    private var isEnglish: Bool { language == "en" }
    private var parsedAmount: Int64 { Int64(amount.filter(\.isNumber)) ?? 0 }

    var body: some View {
        Form {
            Section(isEnglish ? "Expense" : "Pengeluaran") {
                TextField(isEnglish ? "Description" : "Keterangan", text: $title)
                TextField(isEnglish ? "Amount (IDR)" : "Jumlah (Rupiah)", text: $amount)
                    .keyboardType(.numberPad)
                DatePicker(isEnglish ? "Date" : "Tanggal", selection: $date, displayedComponents: .date)
                Picker(isEnglish ? "Category" : "Kategori", selection: $category) {
                    ForEach(MeowlettCategory.all, id: \.id) { item in
                        Text(language == "en" ? item.enName : item.idName).tag(item.id)
                    }
                }
            }
        }
        .navigationTitle(isEnglish ? "New transaction" : "Transaksi baru")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(isEnglish ? "Cancel" : "Batal") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEnglish ? "Save" : "Simpan") {
                    store.add(MeowlettTransaction(date: date, amount: parsedAmount, category: category, description: title.trimmingCharacters(in: .whitespacesAndNewlines)))
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedAmount <= 0)
            }
        }
    }
}
