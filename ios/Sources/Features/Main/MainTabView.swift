import SwiftUI
import UIKit
import PhotosUI

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
    @AppStorage("gm_username") private var userName = ""
    @AppStorage("gm_dark_override") private var darkOverride = "false"
    @AppStorage("gm_follow_system") private var followSystem = "0"
    @AppStorage("gm_profile_photo") private var profilePhoto = ""
    @AppStorage("gm_notif") private var notificationsEnabled = "0"
    @EnvironmentObject private var store: FinanceStore
    @State private var selected: MeowlettTab = .dashboard
    @State private var showQuickAdd = false
    @State private var selectedHeaderPhoto: PhotosPickerItem?

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
            AppAppearance.background(dark: colorSchemeIsDark).ignoresSafeArea()
            VStack(spacing: 0) {
                topHeader
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomNavigation
        }
        .tint(tint)
        .onAppear {
            // Deterministic launch routing is used only by the simulator preview workflow.
            let arguments = ProcessInfo.processInfo.arguments
            if let argument = arguments.first(where: { $0.hasPrefix("--mwlt-preview-tab=") }) {
                let rawValue = String(argument.dropFirst("--mwlt-preview-tab=".count))
                if let previewTab = MeowlettTab(rawValue: rawValue) {
                    selected = previewTab
                }
            }
            if arguments.contains("--mwlt-preview-quick-add") {
                showQuickAdd = true
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            TransactionEditorSheet(initialCategory: "food")
                .environmentObject(store)
        }
        .onChange(of: selectedHeaderPhoto) { _, item in
            guard let item else { return }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data),
                      let jpeg = image.jpegData(compressionQuality: 0.82) else { return }
                await MainActor.run {
                    profilePhoto = "data:image/jpeg;base64," + jpeg.base64EncodedString()
                    selectedHeaderPhoto = nil
                }
            }
        }
    }

    private var topHeader: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                if selected == .dashboard {
                    Text(greeting)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(userName.isEmpty ? (isEnglish ? "Set your name" : "Isi namamu") : userName)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                } else {
                    HStack(spacing: 7) {
                        Text(isEnglish ? selected.titleEN : selected.titleID)
                            .font(.system(size: 20, weight: .black))
                        if selected == .date {
                            Image(systemName: "heart")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Color(hex: "#f9a8d4"))
                        }
                    }
                }
            }
            Spacer(minLength: 8)
            Button {
                followSystem = "0"
                darkOverride = colorSchemeIsDark ? "false" : "true"
            } label: {
                Image(systemName: colorSchemeIsDark ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(Color.primary.opacity(colorSchemeIsDark ? 0.07 : 0.05), in: Circle())
            }
            .buttonStyle(.plain)
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    selected = .settings
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(primary)
                        .frame(width: 34, height: 34)
                        .background(Color.primary.opacity(colorSchemeIsDark ? 0.07 : 0.05), in: Circle())
                    if notificationsEnabled != "1" {
                        Circle().fill(Color(hex: "#ef4444"))
                            .frame(width: 7, height: 7)
                            .overlay(Circle().strokeBorder(Color(uiColor: .systemBackground), lineWidth: 1))
                            .offset(x: -1, y: 1)
                    }
                }
            }
            .buttonStyle(.plain)
            PhotosPicker(selection: $selectedHeaderPhoto, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(AppAppearance.card2(dark: colorSchemeIsDark))
                        .frame(width: 38, height: 38)
                        .overlay {
                            if let image = profileUIImage {
                                Image(uiImage: image).resizable().scaledToFill()
                                    .frame(width: 38, height: 38).clipShape(Circle())
                            } else {
                                Image(systemName: "cat.fill")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(tint)
                            }
                        }
                        .overlay(Circle().strokeBorder(tint, lineWidth: 2.5))
                    Circle().fill(tint).frame(width: 11, height: 11)
                        .overlay(Image(systemName: "camera.fill").font(.system(size: 5, weight: .bold)).foregroundStyle(.white))
                        .overlay(Circle().strokeBorder(Color(uiColor: .systemBackground), lineWidth: 1.5))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.primary.opacity(0.04)).frame(height: 0.5) }
    }

    private var profileUIImage: UIImage? {
        guard !profilePhoto.isEmpty else { return nil }
        let encoded = profilePhoto.components(separatedBy: ",").last ?? profilePhoto
        guard let data = Data(base64Encoded: encoded) else { return nil }
        return UIImage(data: data)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if isEnglish {
            return hour < 12 ? "Good morning" : hour < 15 ? "Good afternoon" : hour < 18 ? "Good evening" : "Good night"
        }
        return hour < 12 ? "Selamat pagi" : hour < 15 ? "Selamat siang" : hour < 18 ? "Selamat sore" : "Selamat malam"
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

        }
        .padding(.horizontal, 12)
        .padding(.top, 5)
        .padding(.bottom, 7)
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(colors: [AppAppearance.background(dark: colorSchemeIsDark).opacity(0), AppAppearance.background(dark: colorSchemeIsDark).opacity(0.96)], startPoint: .top, endPoint: .bottom)
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
