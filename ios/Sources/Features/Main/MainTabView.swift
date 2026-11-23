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

private struct MeowlettTabSymbol: View {
    let tab: MeowlettTab
    let size: CGFloat
    let color: Color

    var body: some View {
        if tab == .dashboard {
            MeowlettCatShape()
                .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                .frame(width: size, height: size)
        } else {
            MeowlettTabShape(tab: tab)
                .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                .frame(width: size, height: size)
        }
    }
}

struct MeowlettCatShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 24
        let sy = rect.height / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }
        var path = Path()
        path.move(to: p(12, 5))
        path.addCurve(to: p(14, 5.26), control1: p(12.67, 5), control2: p(13.35, 5.09))
        path.addCurve(to: p(20.42, 3), control1: p(15.78, 3.26), control2: p(19.03, 2.42))
        path.addCurve(to: p(20, 10), control1: p(21.82, 3.58), control2: p(20, 10))
        path.addCurve(to: p(21, 13.44), control1: p(20.57, 11.07), control2: p(21, 12.24))
        path.addCurve(to: p(12, 21), control1: p(21, 17.9), control2: p(16.97, 21))
        path.addCurve(to: p(3, 13.44), control1: p(7.03, 21), control2: p(3, 18))
        path.addCurve(to: p(4, 10), control1: p(3, 12.19), control2: p(3.5, 11.04))
        path.addCurve(to: p(3.5, 3), control1: p(4, 10), control2: p(2.11, 3.58))
        path.addCurve(to: p(10, 5.23), control1: p(4.89, 2.42), control2: p(8.22, 3.23))
        path.addCurve(to: p(12, 5), control1: p(10.7, 4.99), control2: p(11.35, 4.95))
        path.closeSubpath()

        path.move(to: p(8, 14))
        path.addLine(to: p(8, 14.5))
        path.move(to: p(16, 14))
        path.addLine(to: p(16, 14.5))
        path.move(to: p(11.25, 16.25))
        path.addLine(to: p(12.75, 16.25))
        path.addLine(to: p(12, 17))
        path.closeSubpath()
        return path
    }
}

private struct MeowlettTabShape: Shape {
    let tab: MeowlettTab

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sx = rect.width / 24
        let sy = rect.height / 24
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * sx, y: y * sy)
        }

        switch tab {
        case .transactions:
            path.move(to: point(3, 6)); path.addLine(to: point(21, 6))
            path.move(to: point(3, 12)); path.addLine(to: point(17, 12))
            path.move(to: point(3, 18)); path.addLine(to: point(13, 18))
        case .report:
            path.move(to: point(3, 6)); path.addLine(to: point(21, 6))
            path.move(to: point(3, 12)); path.addLine(to: point(21, 12))
            path.move(to: point(3, 18)); path.addLine(to: point(21, 18))
        case .date:
            path.move(to: point(12, 21))
            path.addCurve(to: point(3, 8.5), control1: point(12, 21), control2: point(3, 15))
            path.addCurve(to: point(8.5, 3), control1: point(3, 5.46), control2: point(5.46, 3))
            path.addCurve(to: point(12, 5), control1: point(10.2, 3), control2: point(11.72, 3.88))
            path.addCurve(to: point(15.5, 3), control1: point(12.28, 3.88), control2: point(13.8, 3))
            path.addCurve(to: point(21, 8.5), control1: point(18.54, 3), control2: point(21, 5.46))
            path.addCurve(to: point(12, 21), control1: point(21, 15), control2: point(12, 21))
            path.closeSubpath()
        case .dashboard, .settings:
            path.move(to: point(3, 6)); path.addLine(to: point(21, 6))
            path.move(to: point(3, 12)); path.addLine(to: point(21, 12))
            path.move(to: point(3, 18)); path.addLine(to: point(21, 18))
        }
        return path
    }
}

@MainActor
final class ModalBlurCoordinator: ObservableObject {
    @Published private(set) var activePresentations: Set<String> = []

    var isBlurred: Bool { !activePresentations.isEmpty }

    func set(_ identifier: String, isPresented: Bool) {
        var updated = activePresentations
        if isPresented { updated.insert(identifier) }
        else { updated.remove(identifier) }
        activePresentations = updated
    }
}

struct MainTabView: View {
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_theme_preset") private var themePreset = "rose"
    @AppStorage("gm_custom_accent") private var customAccent = "#fb7185"
    @AppStorage("gm_username") private var userName = ""
    @AppStorage("gm_dark_override") private var darkOverride = "system"
    @AppStorage("gm_follow_system") private var followSystem = "0"
    @AppStorage("gm_profile_photo") private var profilePhoto = ""
    @AppStorage("gm_notif") private var notificationsEnabled = "0"
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var modalBlurCoordinator = ModalBlurCoordinator()
    @State private var selected: MeowlettTab
    @State private var showQuickAdd: Bool
    @State private var selectedHeaderPhoto: PhotosPickerItem?

    init() {
        // Preview routing must be ready before the first SwiftUI frame.
        // Changing tabs from onAppear can capture a blank first frame for
        // views that need a fresh initial layout, such as the Date tab.
        let arguments = ProcessInfo.processInfo.arguments
        let previewTabArgument = arguments.first {
            $0.hasPrefix("--mwlt-preview-tab=")
        }
        let previewTab = previewTabArgument.flatMap {
            MeowlettTab(rawValue: String($0.dropFirst("--mwlt-preview-tab=".count)))
        }
        _selected = State(initialValue: previewTab ?? .dashboard)
        _showQuickAdd = State(initialValue: arguments.contains("--mwlt-preview-quick-add"))
    }

    private var isEnglish: Bool { language == "en" }
    private var tabTransition: AnyTransition {
        reduceMotion
            ? .identity
            : .asymmetric(
                insertion: .opacity
                    .combined(with: .offset(y: 10))
                    .combined(with: .scale(scale: 0.99)),
                removal: .identity
            )
    }

    private func selectTab(_ tab: MeowlettTab) {
        if reduceMotion {
            selected = tab
        } else {
            // Match the PWA's .tab-enter timing curve (0.22s, cubic-bezier(0.34, 1.1, 0.64, 1)).
            withAnimation(.timingCurve(0.34, 1.1, 0.64, 1, duration: 0.22)) {
                selected = tab
            }
        }
    }

    private var tint: Color {
        themePreset == "custom"
            ? Color(hex: customAccent)
            : Color(hex: AppAppearance.presets.first(where: { $0.id == themePreset })?.accent ?? "#fb7185")
    }
    private var primary: Color {
        Color(hex: AppAppearance.primaryHex)
    }
    private var settingsHeaderIconColor: Color {
        colorSchemeIsDark
            ? Color(hex: AppAppearance.lighten(AppAppearance.primaryHex, ratio: 0.55))
            : AppAppearance.readablePrimaryOnLight()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppAppearance.background(dark: colorSchemeIsDark).ignoresSafeArea()
                ZStack(alignment: .top) {
                    Group {
                        switch selected {
                        case .dashboard:
                            DashboardView(
                                onSeeAllTransactions: {
                                    selectTab(.transactions)
                                },
                                onAddTransaction: { showQuickAdd = true }
                            )
                            .transition(tabTransition)
                        case .transactions: TransactionsView().transition(tabTransition)
                        case .report: ReportsView().transition(tabTransition)
                        case .date: DateTabView().transition(tabTransition)
                        case .settings: SettingsView().transition(tabTransition)
                        }
                    }
                    .environmentObject(store)
                    .environmentObject(modalBlurCoordinator)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)

                    // Match the PWA's fixed 20px backdrop blur while content scrolls beneath it.
                    // Keep the native header layered above the scroll views so cards
                    // move underneath its translucent material while scrolling.
                    topHeader
                        .frame(width: geometry.size.width, alignment: .leading)
                        .zIndex(10)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .overlay(alignment: .bottom) {
            bottomNavigation
        }
        .blur(radius: (showQuickAdd || modalBlurCoordinator.isBlurred) ? 8 : 0)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: showQuickAdd || modalBlurCoordinator.isBlurred)
        .tint(tint)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: colorSchemeIsDark)
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            recordQuickAddLifecycle("main-tab-onAppear")
            RecurringTransactionAutomation.processDueItems(store: store)
        }
        .onChange(of: showQuickAdd) { oldValue, newValue in
            recordQuickAddLifecycle("showQuickAdd-state-change old=\(oldValue) new=\(newValue)", presented: newValue)
        }
        .onChange(of: selected) { oldValue, newValue in
            guard showQuickAdd else { return }
            recordQuickAddLifecycle("selected-tab-change old=\(oldValue.rawValue) new=\(newValue.rawValue)")
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
        HStack(spacing: 7) {
            VStack(alignment: .leading, spacing: 1) {
                if selected == .dashboard {
                    Text(greeting)
                        .font(MeowlettTypography.font(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(userName.isEmpty ? (isEnglish ? "Set your name" : "Isi namamu") : userName)
                        .font(MeowlettTypography.font(size: 20, weight: .black))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                } else {
                    HStack(spacing: 7) {
                        Text(isEnglish ? selected.titleEN : selected.titleID)
                            .font(MeowlettTypography.font(size: 20, weight: .black))
                            .accessibilityIdentifier("mwlt.screen.\(selected.rawValue)")
                        if selected == .date {
                            MeowIcon(key: "heart", size: 18)
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
                MeowIcon(key: colorSchemeIsDark ? "moon" : "sun.max", size: 15)
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(Color.primary.opacity(colorSchemeIsDark ? 0.07 : 0.05), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("mwlt.header.appearance")
            .accessibilityValue(colorSchemeIsDark ? "dark" : "light")
            Button {
                // Preserve the stable header navigation interaction from the last working baseline.
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    selected = .settings
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    MeowIcon(key: "gearshape", size: 15)
                        .foregroundStyle(settingsHeaderIconColor)
                        .frame(width: 34, height: 34)
                        .background(Color.primary.opacity(colorSchemeIsDark ? 0.07 : 0.05), in: Circle())
                    if notificationsEnabled != "1" {
                        Circle().fill(Color(hex: "#ef4444"))
                            .frame(width: 7, height: 7)
                            .overlay(Circle().strokeBorder(AppAppearance.background(dark: colorSchemeIsDark), lineWidth: 1.5).allowsHitTesting(false))
                            .offset(x: -4, y: 4)
                            .allowsHitTesting(false)
                    }
                }
                // Keep a stable 44pt hit target without changing the 34pt icon artwork.
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isEnglish ? "Settings" : "Pengaturan")
            .accessibilityIdentifier("mwlt.header.settings")
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
                                MeowlettCatShape()
                                    .stroke(tint, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                                    .frame(width: 19, height: 19)
                            }
                        }
                        .overlay(Circle().strokeBorder(tint, lineWidth: 2.5))
                    Circle().fill(tint).frame(width: 12, height: 12)
                        .overlay(MeowIcon(key: "camera", size: 5).foregroundStyle(.white))
                        .overlay(Circle().strokeBorder(AppAppearance.background(dark: colorSchemeIsDark), lineWidth: 2))
                        .offset(x: 1, y: 1)
                        .allowsHitTesting(false)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("mwlt.header.profilePhoto")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    AppAppearance.background(dark: colorSchemeIsDark)
                        .opacity(colorSchemeIsDark ? 0.65 : 0.60)
                }
                .ignoresSafeArea(edges: .top)
        }
        .shadow(color: Color.black.opacity(colorSchemeIsDark ? 0.28 : 0.045), radius: 4, x: 0, y: 1)
    }

    private var profileUIImage: UIImage? {
        if !profilePhoto.isEmpty {
            let encoded = profilePhoto.components(separatedBy: ",").last ?? profilePhoto
            if let data = Data(base64Encoded: encoded), let image = UIImage(data: data) {
                return image
            }
        }
        guard let url = Bundle.main.url(forResource: "meow-avatar.jpg", withExtension: "b64")
            ?? Bundle.main.url(forResource: "meow-avatar.jpg", withExtension: "b64", subdirectory: "Images"),
              let encoded = try? String(contentsOf: url, encoding: .utf8),
              let data = Data(base64Encoded: encoded, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return UIImage(data: data)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if isEnglish {
            return hour < 12 ? "Good morning" : hour < 15 ? "Good afternoon" : hour < 18 ? "Good evening" : "Good night"
        }
        return hour < 12 ? "Selamat pagi" : hour < 15 ? "Selamat siang" : hour < 18 ? "Selamat sore" : "Selamat malam"
    }

    private func recordQuickAddLifecycle(_ event: String, presented: Bool? = nil) {
        #if DEBUG
        let timestamp = String(format: "%.3f", Date().timeIntervalSince1970)
        let activePresenters = modalBlurCoordinator.activePresentations.sorted().joined(separator: ",")
        print("[MeowlettQuickAdd] timestamp=\(timestamp) event=\(event) showQuickAdd=\(presented ?? showQuickAdd) selected=\(selected.rawValue) activeOtherPresenters=\(activePresenters)")
        #endif
    }

    private var bottomNavigation: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(spacing: 10) {
            Button {
                recordQuickAddLifecycle("FAB-tap-request", presented: true)
                showQuickAdd = true
            } label: {
                MeowIcon(key: "plus", size: 22)
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(LinearGradient(colors: [tint, primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                    .shadow(color: tint.opacity(0.34), radius: 16, x: 0, y: 4)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isEnglish ? "Add transaction" : "Tambah transaksi")
            .accessibilityIdentifier("mwlt.quickAdd")

            HStack(spacing: 0) {
                ForEach([MeowlettTab.dashboard, .transactions, .report, .date], id: \.self) { tab in
                    let active = selected == tab && !showQuickAdd
                    let isDate = tab == .date
                    let activeColor = isDate
                        ? Color(hex: "#be185d")
                        : (colorSchemeIsDark
                            ? Color(hex: AppAppearance.lighten(AppAppearance.accentHex, ratio: 0.15))
                            : primary)
                    Button {
                        print("[MeowlettNav] bottom tab tapped: \(tab.rawValue)")
                        selectTab(tab)
                    } label: {
                        HStack(spacing: 6) {
                            MeowlettTabSymbol(
                                tab: tab,
                                size: active ? 18 : 22,
                                color: active ? activeColor : (isDate ? Color(hex: "#db2777") : Color.primary.opacity(colorSchemeIsDark ? 0.82 : 0.80))
                            )
                            .frame(width: 22, height: 22)
                            if active {
                                Text(isEnglish ? tab.titleEN : tab.titleID)
                                    .font(MeowlettTypography.font(size: 12, weight: .heavy))
                                    .lineLimit(1)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                        .foregroundStyle(active ? activeColor : (isDate ? Color(hex: "#ec4899") : Color.secondary.opacity(0.92)))
                        .frame(minWidth: 54, minHeight: 54)
                        .padding(.horizontal, active ? 14 : 0)
                        .background {
                            if active {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isDate
                                        ? Color(hex: "#be185d").opacity(colorSchemeIsDark ? 0.20 : 0.18)
                                        : (colorSchemeIsDark ? tint.opacity(0.18) : primary.opacity(0.16)))
                                    .transition(.opacity.combined(with: .scale(scale: 0.90)))
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isEnglish ? tab.titleEN : tab.titleID)
                    .accessibilityIdentifier("mwlt.tab.\(tab.rawValue)")
                    .accessibilityValue(active ? "selected" : "not-selected")
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(5)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().fill(colorSchemeIsDark ? Color.black.opacity(0.20) : Color.white.opacity(0.10)).allowsHitTesting(false))
            .overlay(Capsule().strokeBorder(Color.primary.opacity(colorSchemeIsDark ? 0.20 : 0.22), lineWidth: 1).allowsHitTesting(false))
            .shadow(color: .black.opacity(colorSchemeIsDark ? 0.45 : 0.15), radius: colorSchemeIsDark ? 24 : 20, x: 0, y: colorSchemeIsDark ? 4 : 3)
            .fixedSize(horizontal: true, vertical: false)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(colors: [AppAppearance.background(dark: colorSchemeIsDark).opacity(0), AppAppearance.background(dark: colorSchemeIsDark).opacity(0.96)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        }
        // Present from the persistent dock rather than the Dashboard's nested sheet host.
        // Dashboard owns its own sheets, so keeping Quick Add on a sibling avoids competing
        // SwiftUI sheet presenters while preserving the dock and blurred backdrop.
        .sheet(
            isPresented: $showQuickAdd,
            onDismiss: {
                recordQuickAddLifecycle("sheet-onDismiss", presented: false)
            }
        ) {
            TransactionEditorSheet(initialCategory: "food")
                .environmentObject(store)
                .onAppear {
                    recordQuickAddLifecycle("editor-content-onAppear")
                }
                .onDisappear {
                    recordQuickAddLifecycle("editor-content-onDisappear")
                }
        }
    }

    @Environment(\.colorScheme) private var colorScheme
    private var colorSchemeIsDark: Bool { colorScheme == .dark }
    private var preferredColorScheme: ColorScheme? {
        if followSystem == "1" || darkOverride == "system" { return nil }
        return darkOverride == "true" ? .dark : .light
    }
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
