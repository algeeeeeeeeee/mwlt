import SwiftUI
import PhotosUI
import UIKit
import UserNotifications
import UniformTypeIdentifiers

private enum SettingsPresentedSheet: String, Identifiable {
    case appearance, notifications, budgets, categoryMenu, categoryManager, data
    var id: String { rawValue }
}

struct SettingsView: View {
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_categories") private var categoriesJSON = ""
    @AppStorage("gm_username") private var userName = ""
    @AppStorage("gm_dark_override") private var darkOverride = "system"
    @AppStorage("gm_follow_system") private var followSystem = "0"
    @AppStorage("gm_theme_preset") private var themePreset = "rose"
    @AppStorage("gm_custom_primary") private var customPrimary = "#881337"
    @AppStorage("gm_custom_accent") private var customAccent = "#fb7185"
    @AppStorage("gm_profile_photo") private var profilePhoto = ""
    @AppStorage("gm_income") private var incomeRaw = "5000000"
    @AppStorage("gm_notif") private var notificationsEnabled = "0"
    @AppStorage("gm_weekly_notif") private var weeklyNotification = "false"
    @AppStorage("gm_weekly_notif_day") private var weeklyNotificationDay = "0"
    @AppStorage("gm_budgets") private var budgetsRaw = "{}"
    @AppStorage("mwlt.native.onboarded") private var isOnboarded = true

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var modalBlurCoordinator: ModalBlurCoordinator
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var nameDraft = ""
    @State private var showNameEditor = false
    @State private var activeSheet: SettingsPresentedSheet?

    private var isEnglish: Bool { language == "en" }
    private var isDark: Bool { colorScheme == .dark }
    private var primary: Color { Color(hex: AppAppearance.primaryHex) }
    private var accent: Color { Color(hex: AppAppearance.accentHex) }
    private var photo: UIImage? {
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
    private var budgetCount: Int {
        guard let data = budgetsRaw.data(using: .utf8),
              let values = try? JSONDecoder().decode([String: Int64].self, from: data) else { return 0 }
        return values.values.filter { $0 > 0 }.count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                profileCard

                settingsCard {
                    settingsRow(
                        title: isEnglish ? "Display Mode" : "Mode Tampilan",
                        subtitle: "\(isDark ? (isEnglish ? "Dark mode active" : "Mode gelap aktif") : (isEnglish ? "Light mode active" : "Mode terang aktif")) · \(selectedThemeName)",
                        symbol: isDark ? "moon.fill" : "sun.max.fill"
                    ) { activeSheet = .appearance }
                    .accessibilityIdentifier("mwlt.settings.appearance")
                }

                settingsCard {
                    settingsRow(
                        title: isEnglish ? "Notifications" : "Notifikasi",
                        subtitle: notificationsEnabled == "1"
                            ? (isEnglish ? "Active — every day at 9 PM" : "Aktif — setiap hari jam 9 malam")
                            : (isEnglish ? "Inactive" : "Nonaktif"),
                        symbol: "bell",
                        statusDot: notificationsEnabled != "1"
                    ) { activeSheet = .notifications }
                    .accessibilityIdentifier("mwlt.settings.notifications")
                }

                settingsCard {
                    settingsRow(
                        title: isEnglish ? "Category" : "Kategori",
                        subtitle: isEnglish ? "Manage & organise categories" : "Atur & kelola kategori",
                        symbol: "square.grid.2x2"
                    ) { activeSheet = .categoryMenu }
                    .accessibilityIdentifier("mwlt.settings.category")
                }

                settingsCard {
                    settingsRow(
                        title: "Data",
                        subtitle: isEnglish ? "Backup, restore & reset" : "Cadangkan, pulihkan & atur ulang",
                        symbol: "externaldrive"
                    ) { activeSheet = .data }
                    .accessibilityIdentifier("mwlt.settings.data")
                }

            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 90)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(AppAppearance.background(dark: isDark))
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: activeSheet != nil) { _, presented in
            modalBlurCoordinator.set("settings", isPresented: presented)
        }
        .onDisappear { modalBlurCoordinator.set("settings", isPresented: false) }
        .onChange(of: selectedPhoto) { _, item in
            Task {
                guard let data = try? await item?.loadTransferable(type: Data.self) else { return }
                profilePhoto = "data:image/jpeg;base64," + data.base64EncodedString()
            }
        }
                .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .appearance:
                SettingsAppearanceSheet()
            case .notifications:
                SettingsNotificationsSheet(
                    enabled: Binding(get: { notificationsEnabled == "1" }, set: { notificationsEnabled = $0 ? "1" : "0" }),
                    weekly: Binding(get: { weeklyNotification == "true" }, set: { weeklyNotification = $0 ? "true" : "false" }),
                    day: Binding(get: { weeklyNotificationDay }, set: { weeklyNotificationDay = $0 }),
                    isEnglish: isEnglish
                )
            case .budgets:
                SettingsBudgetSheet(isEnglish: isEnglish)
            case .categoryMenu:
                SettingsCategoryMenuSheet(
                    isEnglish: isEnglish,
                    onBudget: {
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { activeSheet = .budgets }
                    },
                    onManage: {
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { activeSheet = .categoryManager }
                    }
                )
            case .categoryManager:
                SettingsCategoryManagerSheet()
            case .data:
                SettingsDataSheet(isEnglish: isEnglish, incomeRaw: $incomeRaw)
            }
        }

    }

    private var selectedThemeName: String {
        if themePreset == "custom" { return isEnglish ? "Custom" : "Kustom" }
        let preset = AppAppearance.presets.first(where: { $0.id == themePreset })
        return preset.map { isEnglish ? $0.nameEN : $0.nameID } ?? "Rose"
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(AppAppearance.card2(dark: isDark))
                        .frame(width: 56, height: 56)
                        .overlay {
                            if let photo {
                                Image(uiImage: photo).resizable().scaledToFill()
                                    .frame(width: 56, height: 56).clipShape(Circle())
                            } else {
                                MeowlettCatShape()
                                    .stroke(accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                                    .frame(width: 27, height: 27)
                            }
                        }
                        .overlay(Circle().strokeBorder(AppAppearance.border(dark: isDark), lineWidth: 2.5))
                    Circle().fill(primary).frame(width: 18, height: 18)
                        .overlay(Image(systemName: "camera").font(.system(size: 8, weight: .medium)).foregroundStyle(.white))
                        .overlay(Circle().strokeBorder(AppAppearance.background(dark: isDark), lineWidth: 2))
                }
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 3) {
                Text(isEnglish ? "Profile name" : "Nama profil")
                    .font(MeowlettTypography.font(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                if showNameEditor {
                    HStack(spacing: 6) {
                        TextField(isEnglish ? "Your name" : "Namamu", text: $nameDraft)
                            .font(MeowlettTypography.font(size: 16, weight: .bold))
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .onSubmit(saveProfileName)
                            .frame(width: 130)
                            .padding(.vertical, 2)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(accent).frame(height: 2)
                            }
                        Button(action: saveProfileName) {
                            Text("OK")
                                .font(MeowlettTypography.font(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(primary, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        nameDraft = userName
                        showNameEditor = true
                    } label: {
                        HStack(spacing: 5) {
                            Text(userName.isEmpty ? (isEnglish ? "Tap to set name" : "Tap untuk isi nama") : userName)
                                .font(MeowlettTypography.font(size: 17, weight: .black))
                                .foregroundStyle(.primary)
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardColor, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(cardBorder, lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.06), radius: 4, x: 0, y: 1)
    }

    private func saveProfileName() {
        userName = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        showNameEditor = false
    }

    private var cardColor: Color {
        isDark ? AppAppearance.card(dark: isDark) : .white
    }
    private var cardBorder: Color { AppAppearance.border(dark: isDark) }
    private var rowDivider: some View { Rectangle().fill(cardBorder).frame(height: 1).padding(.leading, 16) }

    private func settingsCard<Content: View>(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: spacing, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardColor, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(cardBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(isDark ? 0 : 0.025), radius: 4, x: 0, y: 1)
    }

    private func settingsRow(title: String, subtitle: String, symbol: String, statusDot: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title).font(MeowlettTypography.font(size: 14, weight: .bold)).foregroundStyle(.primary)
                        if statusDot {
                            Circle().fill(Color(hex: "#ef4444")).frame(width: 7, height: 7)
                        }
                    }
                    Text(subtitle).font(MeowlettTypography.font(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func languageButton(_ code: String, title: String) -> some View {
        let selected = language == code
        return Button { language = code } label: {
            HStack(spacing: 5) {
                Text(title).font(MeowlettTypography.font(size: 12, weight: .bold))
                if selected { Image(systemName: "checkmark.circle.fill").font(.system(size: 11)) }
            }
            .foregroundStyle(selected ? accent : Color.secondary)
            .frame(maxWidth: .infinity).frame(height: 38)
            .background(selected ? accent.opacity(0.10) : AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? accent : cardBorder, lineWidth: 1.3))
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsAppearanceSheet: View {
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_dark_override") private var darkOverride = "system"
    @AppStorage("gm_follow_system") private var followSystem = "0"
    @AppStorage("gm_theme_preset") private var themePreset = "rose"
    @AppStorage("gm_custom_primary") private var customPrimary = "#881337"
    @AppStorage("gm_custom_accent") private var customAccent = "#fb7185"
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private var isEnglish: Bool { language == "en" }
    private var isDark: Bool { colorScheme == .dark }
    private var categoryBackground: Color {
        isDark ? AppAppearance.card2(dark: true) : AppAppearance.background(dark: false)
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppAppearance.border(dark: isDark))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            HStack(spacing: 10) {
                Image(systemName: isDark ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppAppearance.accent)
                    .frame(width: 36, height: 36)
                    .background(categoryBackground, in: RoundedRectangle(cornerRadius: 12))
                Text(isEnglish ? "APPEARANCE" : "TAMPILAN")
                    .font(MeowlettTypography.font(size: 17, weight: .black))
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("mwlt.settings.sheet.appearance.title")
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(categoryBackground, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("mwlt.settings.sheet.appearance.close")
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    appearanceSwitchRow(
                        symbol: isDark ? "moon.fill" : "sun.max.fill",
                        title: isEnglish ? "Display Mode" : "Mode Tampilan",
                        subtitle: isDark ? (isEnglish ? "Dark mode active" : "Mode gelap aktif") : (isEnglish ? "Light mode active" : "Mode terang aktif"),
                        isOn: Binding(
                            get: { colorScheme == .dark },
                            set: { value in
                                guard followSystem != "1" else { return }
                                darkOverride = value ? "true" : "false"
                            }
                        ),
                        isDisabled: followSystem == "1",
                        iconColor: AppAppearance.accent
                    )

                    Divider().overlay(AppAppearance.border(dark: isDark))

                    appearanceSwitchRow(
                        symbol: "sun.horizon",
                        title: isEnglish ? "Follow System" : "Ikuti Sistem",
                        subtitle: followSystem == "1"
                            ? (isEnglish ? "Automatic from device settings" : "Otomatis dari pengaturan HP")
                            : (isEnglish ? "Mode set manually" : "Mode diatur manual"),
                        isOn: Binding(
                            get: { followSystem == "1" },
                            set: { value in
                                followSystem = value ? "1" : "0"
                                darkOverride = value ? "system" : (colorScheme == .dark ? "true" : "false")
                            }
                        ),
                        iconColor: AppAppearance.primary
                    )

                    Divider().overlay(AppAppearance.border(dark: isDark))

                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(AppAppearance.primary)
                            .frame(width: 36, height: 36)
                            .background(categoryBackground, in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isEnglish ? "Language" : "Bahasa")
                                .font(MeowlettTypography.font(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                            Text(isEnglish ? "Choose display language" : "Pilih bahasa tampilan")
                                .font(MeowlettTypography.font(size: 11, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            languageButton("id")
                            languageButton("en")
                        }
                    }
                    .padding(.vertical, 14)

                    Divider().overlay(AppAppearance.border(dark: isDark))

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            Image(systemName: "paintpalette")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(AppAppearance.primary)
                                .frame(width: 36, height: 36)
                                .background(categoryBackground, in: RoundedRectangle(cornerRadius: 12))
                            Text(isEnglish ? "Colour Theme" : "Tema Warna")
                                .font(MeowlettTypography.font(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(AppAppearance.presets, id: \.id) { preset in
                                let selected = themePreset == preset.id
                                Button { themePreset = preset.id } label: {
                                    VStack(spacing: 5) {
                                        HStack(spacing: 3) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color(hex: preset.primary))
                                                .frame(width: 14, height: 14)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color(hex: preset.accent))
                                                .frame(width: 14, height: 14)
                                        }
                                        HStack(spacing: 4) {
                                            Image(systemName: presetIcon(preset.id))
                                                .font(.system(size: 11, weight: .semibold))
                                            Text(isEnglish ? preset.nameEN : preset.nameID)
                                                .font(MeowlettTypography.font(size: 11, weight: .bold))
                                        }
                                    }
                                    .foregroundStyle(selected ? Color(hex: preset.accent) : Color.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        selected ? Color(hex: preset.primary).opacity(0.13) : categoryBackground,
                                        in: RoundedRectangle(cornerRadius: 14)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(selected ? Color(hex: preset.accent) : AppAppearance.border(dark: isDark),
                                                    lineWidth: selected ? 2.5 : 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(spacing: 10) {
                            HStack(spacing: 5) {
                                Image(systemName: "paintbrush.pointed")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppAppearance.primary)
                                Text(isEnglish ? "Custom" : "Kustom")
                                    .font(MeowlettTypography.font(size: 12, weight: .heavy))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Button { themePreset = "custom" } label: {
                                    Group {
                                        if themePreset == "custom" {
                                            Label(isEnglish ? "Active" : "Aktif", systemImage: "checkmark.circle.fill")
                                        } else {
                                            Text(isEnglish ? "Use" : "Gunakan")
                                        }
                                    }
                                    .font(MeowlettTypography.font(size: 11, weight: .bold))
                                    .foregroundStyle(themePreset == "custom" ? Color.white : Color.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(themePreset == "custom" ? AppAppearance.primary : categoryBackground, in: RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }

                            HStack(alignment: .top, spacing: 10) {
                                customColorControl(
                                    title: isEnglish ? "PRIMARY" : "UTAMA",
                                    value: Binding(
                                        get: { Color(hex: customPrimary) },
                                        set: { customPrimary = $0.meowlettHex; themePreset = "custom" }
                                    ),
                                    hex: customPrimary
                                )
                                customColorControl(
                                    title: isEnglish ? "ACCENT" : "AKSEN",
                                    value: Binding(
                                        get: { Color(hex: customAccent) },
                                        set: { customAccent = $0.meowlettHex; themePreset = "custom" }
                                    ),
                                    hex: customAccent
                                )
                            }
                        }
                        .padding(12)
                        .background(categoryBackground, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppAppearance.border(dark: isDark), lineWidth: 1.5))
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 26)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(AppAppearance.card(dark: isDark))
        .presentationDetents([.fraction(0.9)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    private func appearanceSwitchRow(
        symbol: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        isDisabled: Bool = false,
        iconColor: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(categoryBackground, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MeowlettTypography.font(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(MeowlettTypography.font(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            switchControl(isOn: isOn.wrappedValue, isDisabled: isDisabled) {
                isOn.wrappedValue.toggle()
            }
        }
        .padding(.vertical, 14)
    }

    private func switchControl(isOn: Bool, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Capsule()
                .fill(isOn ? AppAppearance.primary : AppAppearance.border(dark: isDark))
                .frame(width: 48, height: 28)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.16), radius: 3, x: 0, y: 1)
                        .padding(4)
                }
                .opacity(isDisabled ? 0.4 : 1)
                .animation(.easeInOut(duration: 0.18), value: isOn)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(isOn ? (isEnglish ? "On" : "Aktif") : (isEnglish ? "Off" : "Nonaktif"))
    }

    private func languageButton(_ code: String) -> some View {
        let selected = language == code
        return Button { language = code } label: {
            Text(code.uppercased())
                .font(MeowlettTypography.font(size: 12, weight: .bold))
                .foregroundStyle(selected ? selectedLanguageTextColor : Color.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? AppAppearance.primary.opacity(0.13) : categoryBackground, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selected ? AppAppearance.primary : AppAppearance.border(dark: isDark), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    private func presetIcon(_ id: String) -> String {
        switch id {
        case "green": return "leaf"
        case "blue": return "water.waves"
        case "purple": return "sparkles"
        case "rose": return "heart"
        case "orange": return "sun.max"
        default: return "wind"
        }
    }

    private var selectedLanguageTextColor: Color {
        let hex = AppAppearance.primaryHex
        let rgb = rgbComponents(hex)
        if isDark {
            return Color(hex: transformedHex(rgb, ratio: 0.45, lighten: true))
        }

        let originalLuminance = (0.299 * Double(rgb.0) + 0.587 * Double(rgb.1) + 0.114 * Double(rgb.2)) / 255
        if originalLuminance <= 0.5 { return Color(hex: hex) }
        var adjustment = 0.1
        var result = hex
        while adjustment <= 1.0 {
            result = transformedHex(rgb, ratio: adjustment, lighten: false)
            let value = rgbComponents(result)
            let luminance = (0.299 * Double(value.0) + 0.587 * Double(value.1) + 0.114 * Double(value.2)) / 255
            if luminance <= 0.5 { break }
            adjustment += 0.1
        }
        return Color(hex: result)
    }

    private func rgbComponents(_ hex: String) -> (Int, Int, Int) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        return (Int((value >> 16) & 0xff), Int((value >> 8) & 0xff), Int(value & 0xff))
    }

    private func transformedHex(_ rgb: (Int, Int, Int), ratio: Double, lighten: Bool) -> String {
        func component(_ value: Int) -> Int {
            if lighten {
                return min(255, Int((Double(value) + Double(255 - value) * ratio).rounded()))
            }
            return max(0, Int((Double(value) * (1 - ratio)).rounded()))
        }
        return String(format: "#%02X%02X%02X", component(rgb.0), component(rgb.1), component(rgb.2))
    }

    private func customColorControl(title: String, value: Binding<Color>, hex: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(MeowlettTypography.font(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: hex))
                    .frame(width: 28, height: 28)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppAppearance.border(dark: isDark), lineWidth: 1.5))
                ColorPicker("", selection: value)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsNotificationsSheet: View {
    @Binding var enabled: Bool
    @Binding var weekly: Bool
    @Binding var day: String
    let isEnglish: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var financeStore: FinanceStore
    @State private var showReminderSettings = false
    @State private var permissionMessage: String?
    @State private var isRequestingPermission = false

    private var isDark: Bool { colorScheme == .dark }
    private var primary: Color { AppAppearance.primary }
    private var accent: Color { AppAppearance.accent }
    private var categoryBackground: Color {
        isDark ? AppAppearance.card2(dark: true) : AppAppearance.background(dark: false)
    }
    private var dayLabels: [String] {
        isEnglish ? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] : ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"]
    }
    private var selectedDayLabel: String {
        dayLabels[min(6, max(0, Int(day) ?? 0))]
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.28))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryBackground)
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: enabled ? "bell.fill" : "bell.slash.fill")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(enabled ? accent : Color.secondary))
                Text(isEnglish ? "Notifications" : "Notifikasi")
                    .font(MeowlettTypography.font(size: 17, weight: .black))
                    .accessibilityIdentifier("mwlt.settings.sheet.notifications.title")
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(AppAppearance.card2(dark: isDark), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("mwlt.settings.sheet.notifications.close")
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppAppearance.card2(dark: isDark))
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: enabled ? "bell.fill" : "bell.slash.fill")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(enabled ? accent : Color.secondary))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isEnglish ? "Daily Reminder" : "Pengingat Harian")
                                .font(MeowlettTypography.font(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                            Text(enabled
                                 ? (isEnglish ? "Active — every day at 9 PM" : "Aktif — setiap hari jam 9 malam")
                                 : (isEnglish ? "Inactive" : "Nonaktif"))
                                .font(MeowlettTypography.font(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        switchControl(isOn: enabled, isLoading: isRequestingPermission) {
                            Task { await updateNotifications(to: !enabled) }
                        }
                    }
                    .padding(.vertical, 14)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(AppAppearance.border(dark: isDark)).frame(height: 1)
                    }

                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppAppearance.card2(dark: isDark))
                                .frame(width: 36, height: 36)
                                .overlay(Image(systemName: "info.circle")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(weekly ? accent : Color.secondary))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isEnglish ? "Weekly Summary" : "Ringkasan Mingguan")
                                    .font(MeowlettTypography.font(size: 14, weight: .bold))
                                    .foregroundStyle(.primary)
                                Text(weekly
                                     ? (isEnglish ? "Every \(selectedDayLabel)" : "\(selectedDayLabel) tiap minggu")
                                     : (isEnglish ? "Off" : "Nonaktif"))
                                    .font(MeowlettTypography.font(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            switchControl(isOn: weekly) { weekly.toggle() }
                        }

                        if weekly {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 6)], spacing: 6) {
                                ForEach(Array(dayLabels.enumerated()), id: \.offset) { index, title in
                                    let selected = day == String(index)
                                    Button { day = String(index) } label: {
                                        Text(title)
                                            .font(MeowlettTypography.font(size: 11, weight: .bold))
                                            .foregroundStyle(selected ? .white : Color.secondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(selected ? primary : categoryBackground, in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 12)
                        }
                    }
                    .padding(.vertical, 14)
                    .overlay(alignment: .bottom) {
                        if weekly {
                            Rectangle().fill(AppAppearance.border(dark: isDark)).frame(height: 1)
                        }
                    }

                    Button {
                        showReminderSettings = true
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppAppearance.card2(dark: isDark))
                                .frame(width: 36, height: 36)
                                .overlay(Image(systemName: "bell.badge")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(accent))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isEnglish ? "Transaction Reminder" : "Pengingat Transaksi")
                                    .font(MeowlettTypography.font(size: 14, weight: .bold))
                                    .foregroundStyle(.primary)
                                Text(isEnglish
                                     ? "Notify if no spending recorded today"
                                     : "Notif kalau belum input pengeluaran hari ini")
                                    .font(MeowlettTypography.font(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                        .overlay(alignment: .top) {
                            Rectangle().fill(AppAppearance.border(dark: isDark)).frame(height: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .background(AppAppearance.card(dark: isDark))
        .blur(radius: showReminderSettings ? 8 : 0)
        .animation(.easeInOut(duration: 0.2), value: showReminderSettings)
        .sheet(isPresented: $showReminderSettings) { SettingsReminderSheet() }
        .alert(
            isEnglish ? "Notifications unavailable" : "Notifikasi tidak tersedia",
            isPresented: Binding(
                get: { permissionMessage != nil },
                set: { if !$0 { permissionMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { permissionMessage = nil }
        } message: {
            Text(permissionMessage ?? "")
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    private func switchControl(isOn: Bool, isLoading: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Capsule()
                .fill(isOn ? primary : AppAppearance.border(dark: isDark))
                .frame(width: 48, height: 28)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.16), radius: 3, x: 0, y: 1)
                        .padding(4)
                }
                .opacity(isLoading ? 0.55 : 1)
                .animation(.easeInOut(duration: 0.18), value: isOn)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(isOn ? (isEnglish ? "On" : "Aktif") : (isEnglish ? "Off" : "Nonaktif"))
    }

    @MainActor
    private func updateNotifications(to value: Bool) async {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        defer { isRequestingPermission = false }

        guard value else {
            enabled = false
            MeowlettReminderScheduler.removePendingRequests()
            return
        }

        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                enabled = false
                permissionMessage = isEnglish
                    ? "Notification permission was denied. Enable it in iPhone Settings."
                    : "Izin notifikasi ditolak. Aktifkan melalui Pengaturan iPhone."
                return
            }

            enabled = true
            scheduleNotifications()

            let confirmation = UNMutableNotificationContent()
            confirmation.title = "Meowlett"
            confirmation.body = isEnglish
                ? "Reminder on! You'll be notified every day at 9 PM."
                : "Pengingat aktif! Kamu akan diingatkan setiap hari jam 9 malam."
            confirmation.sound = .default
            let request = UNNotificationRequest(
                identifier: "meowlett-reminder-activated",
                content: confirmation,
                trigger: nil
            )
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            enabled = false
            MeowlettReminderScheduler.removePendingRequests()
            permissionMessage = error.localizedDescription
        }
    }

    private func scheduleNotifications() {
        let defaults = UserDefaults.standard
        let rawDays = defaults.string(forKey: "gm_reminder_days") ?? "[1,2,3,4,5]"
        let reminderDays = (try? JSONDecoder().decode([Int].self, from: Data(rawDays.utf8))) ?? [1,2,3,4,5]
        let hour = Int(defaults.string(forKey: "gm_reminder_hour") ?? "21") ?? 21
        let smart = defaults.string(forKey: "gm_reminder_smart") != "0"
        MeowlettReminderScheduler.schedule(
            days: reminderDays,
            hour: min(23, max(0, hour)),
            smart: smart,
            language: isEnglish ? "en" : "id",
            transactions: financeStore.transactions
        )
    }
}

private struct SettingsCategoryMenuSheet: View {
    let isEnglish: Bool
    let onBudget: () -> Void
    let onManage: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var categoryBackground: Color {
        isDark ? AppAppearance.card2(dark: true) : AppAppearance.background(dark: false)
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppAppearance.border(dark: isDark))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            HStack {
                Text(isEnglish ? "Category" : "Kategori")
                    .font(MeowlettTypography.font(size: 17, weight: .black))
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("mwlt.settings.sheet.category.title")
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(categoryBackground, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("mwlt.settings.sheet.category.close")
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            VStack(spacing: 0) {
                menuRow(
                    symbol: "chart.bar",
                    title: isEnglish ? "Spending Limits" : "Batas Pengeluaran",
                    subtitle: isEnglish ? "Set spending limits per category" : "Atur batas pengeluaran per kategori",
                    color: AppAppearance.accent,
                    action: onBudget
                )
                .accessibilityIdentifier("mwlt.settings.category.budgets")

                Rectangle()
                    .fill(AppAppearance.border(dark: isDark))
                    .frame(height: 1)
                    .padding(.leading, 48)

                menuRow(
                    symbol: "square.grid.2x2",
                    title: isEnglish ? "Manage Categories" : "Kelola Kategori",
                    subtitle: isEnglish ? "Manage & organise categories" : "Atur & kelola kategori",
                    color: AppAppearance.primary,
                    action: onManage
                )
                .accessibilityIdentifier("mwlt.settings.category.manage")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity)
        .background(AppAppearance.card(dark: isDark))
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    private func menuRow(symbol: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(MeowlettTypography.font(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(MeowlettTypography.font(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsPlaceholderSheet: View {
    let title: String
    let subtitle: String
    let symbol: String
    let isEnglish: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 28)).foregroundStyle(AppAppearance.accent)
                .frame(width: 72, height: 72).background(AppAppearance.accent.opacity(0.12), in: Circle())
            Text(title).font(MeowlettTypography.font(size: 17, weight: .black))
            Text(subtitle).font(MeowlettTypography.font(size: 12, weight: .regular)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button(isEnglish ? "Close" : "Tutup") { dismiss() }
                .font(MeowlettTypography.font(size: 13, weight: .bold)).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 44).background(AppAppearance.primary, in: RoundedRectangle(cornerRadius: 13))
        }
        .padding(22)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

private struct SettingsDataSheet: View {
    private enum ConfirmationKind {
        case restore
        case reset
    }

    let isEnglish: Bool
    @Binding var incomeRaw: String
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("gm_savings_goals") private var goalsRaw = "[]"
    @AppStorage("gm_budgets") private var budgetsRaw = "{}"
    @AppStorage("gm_categories") private var categoriesRaw = ""
    @AppStorage("gm_daily_notes") private var dailyNotesRaw = "{}"

    @State private var backupFile: MeowlettBackupFile?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var confirmation: ConfirmationKind?
    @State private var pendingRestore: MeowlettBackupPayload?
    @State private var importError = ""

    private var isDark: Bool { colorScheme == .dark }
    private var cardBorder: Color { Color.primary.opacity(isDark ? 0.10 : 0.07) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Data")
                    .font(MeowlettTypography.font(size: 16, weight: .heavy))
                    .accessibilityIdentifier("mwlt.settings.sheet.data.title")
                Spacer()
                Button(isEnglish ? "Done" : "Selesai") { dismiss() }
                    .accessibilityIdentifier("mwlt.settings.sheet.data.close")
                    .font(MeowlettTypography.font(size: 13, weight: .bold))
                    .foregroundStyle(Color.primary.opacity(0.72))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.bottom, 10)
            Button {
                backupFile = makeBackupFile()
                showExporter = backupFile != nil
            } label: {
                dataAction(
                    symbol: "arrow.down.to.line",
                    title: isEnglish ? "Backup Data" : "Cadangkan Data",
                    subtitle: isEnglish ? "Download all data as JSON" : "Unduh semua data sebagai JSON",
                    color: AppAppearance.accent,
                    variant: "accent"
                )
            }
            .buttonStyle(.plain)

            Button { showImporter = true } label: {
                dataAction(
                    symbol: "arrow.up.to.line",
                    title: isEnglish ? "Restore Backup" : "Pulihkan Cadangan",
                    subtitle: isEnglish ? "Import from backup file" : "Impor dari file cadangan",
                    color: AppAppearance.primary,
                    variant: "neutral"
                )
            }
            .buttonStyle(.plain)

            Rectangle().fill(cardBorder).frame(height: 1).padding(.vertical, 4)

            Button { confirmation = .reset } label: {
                dataAction(
                    symbol: "trash",
                    title: isEnglish ? "Reset All Data" : "Atur Ulang Semua Data",
                    subtitle: isEnglish ? "Delete all data permanently" : "Hapus semua data permanen",
                    color: Color(hex: "#ef4444"),
                    variant: "danger"
                )
            }
            .buttonStyle(.plain)

            if !importError.isEmpty {
                Text(importError)
                    .font(MeowlettTypography.font(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "#ef4444"))
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 40)
        .background(AppAppearance.modal(dark: isDark))
        .blur(radius: confirmation == nil ? 0 : 8)
        .animation(.easeInOut(duration: 0.2), value: confirmation != nil)
        .presentationDetents([.height(370)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(22)
        .fileExporter(
            isPresented: $showExporter,
            document: backupFile,
            contentType: .json,
            defaultFilename: "meowlett-backup-\(MeowlettDateFormat.day(.now))"
        ) { result in
            if case .failure(let error) = result { importError = error.localizedDescription }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            do {
                let url = try result.get().first
                guard let url else { return }
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                let payload = try JSONDecoder().decode(MeowlettBackupPayload.self, from: data)
                guard payload.transactions != nil else { throw BackupFileError.invalid }
                pendingRestore = payload
                confirmation = .restore
                importError = ""
            } catch {
                importError = isEnglish ? "Invalid backup file." : "File backup tidak valid."
            }
        }
        .overlay {
            if let confirmation {
                confirmationOverlay(confirmation)
            }
        }
    }

    private func confirmationOverlay(_ kind: ConfirmationKind) -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { confirmation = nil }

            VStack(alignment: .leading, spacing: 0) {
                Text(kind == .restore
                     ? (isEnglish ? "Restore this backup? Current data will be replaced." : "Pulihkan cadangan ini? Data saat ini akan diganti.")
                     : (isEnglish ? "Are you sure you want to delete all data? This cannot be undone." : "Yakin ingin menghapus semua data? Tidak bisa dibatalkan."))
                    .font(MeowlettTypography.font(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .padding(.bottom, 20)

                HStack(spacing: 10) {
                    Button {
                        confirmation = nil
                        pendingRestore = nil
                    } label: {
                        Text(isEnglish ? "Cancel" : "Batal")
                            .font(MeowlettTypography.font(size: 14, weight: .bold))
                            .foregroundStyle(AppAppearance.textSub(dark: isDark))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppAppearance.input(dark: isDark), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button {
                        let selected = confirmation
                        confirmation = nil
                        switch selected {
                        case .restore:
                            restorePendingBackup()
                        case .reset:
                            resetData()
                        case .none:
                            break
                        }
                    } label: {
                        Text(isEnglish ? "Done" : "Selesai")
                            .font(MeowlettTypography.font(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#ef4444"), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
            .frame(maxWidth: 320)
            .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 16)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
        .zIndex(100)
    }

    private func makeBackupFile() -> MeowlettBackupFile? {
        let transactions = store.transactions.map {
            MeowlettBackupTransaction(
                id: $0.id.uuidString,
                date: MeowlettDateFormat.day($0.date),
                amount: $0.amount,
                category: $0.category,
                description: $0.description,
                location: $0.location,
                note: $0.note,
                paymentMethod: $0.paymentMethod
            )
        }
        let goalsData = goalsRaw.data(using: .utf8) ?? Data("[]".utf8)
        let goals = (try? JSONDecoder().decode([MeowlettBackupGoal].self, from: goalsData)) ?? []
        let budgetsData = budgetsRaw.data(using: .utf8) ?? Data("{}".utf8)
        let budgets = (try? JSONDecoder().decode([String: Int64].self, from: budgetsData)) ?? [:]
        let categoriesData = categoriesRaw.data(using: .utf8) ?? Data("{}".utf8)
        let categories = (try? JSONDecoder().decode([String: MeowlettCategoryDefinition].self, from: categoriesData)) ?? [:]
        let notesData = dailyNotesRaw.data(using: .utf8) ?? Data("{}".utf8)
        let dailyNotes = (try? JSONDecoder().decode([String: String].self, from: notesData)) ?? [:]
        let payload = MeowlettBackupPayload(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: .now),
            transactions: transactions,
            income: Int64(incomeRaw) ?? 5_000_000,
            goals: goals,
            budgets: budgets,
            categories: categories,
            dailyNotes: dailyNotes
        )
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return MeowlettBackupFile(data: data)
    }

    private func restorePendingBackup() {
        guard let payload = pendingRestore, let rows = payload.transactions else { return }
        let restored = rows.compactMap { row -> MeowlettTransaction? in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "yyyy-MM-dd"
            guard let date = formatter.date(from: row.date) else { return nil }
            return MeowlettTransaction(
                id: UUID(uuidString: row.id) ?? UUID(),
                date: date,
                amount: row.amount,
                category: row.category,
                description: row.description,
                location: row.location,
                note: row.note,
                paymentMethod: row.paymentMethod
            )
        }
        store.replaceAllTransactions(restored)
        incomeRaw = String(payload.income ?? 5_000_000)
        if let goals = payload.goals, let data = try? JSONEncoder().encode(goals) {
            goalsRaw = String(data: data, encoding: .utf8) ?? "[]"
        }
        if let budgets = payload.budgets, let data = try? JSONEncoder().encode(budgets) {
            budgetsRaw = String(data: data, encoding: .utf8) ?? "{}"
        }
        if let categories = payload.categories, let data = try? JSONEncoder().encode(categories) {
            categoriesRaw = String(data: data, encoding: .utf8) ?? "{}"
        }
        if let notes = payload.dailyNotes, let data = try? JSONEncoder().encode(notes) {
            dailyNotesRaw = String(data: data, encoding: .utf8) ?? "{}"
        }
        pendingRestore = nil
        dismiss()
    }

    private func resetData() {
        // Clear scheduled reminders once for an explicit full data reset.
        MeowlettReminderScheduler.removePendingRequests()
        // Match the PWA localStorage.clear() while preserving native onboarding state.
        for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("gm_") {
            UserDefaults.standard.removeObject(forKey: key)
        }
        store.clearAllTransactions()
        incomeRaw = "5000000"
        goalsRaw = "[]"
        budgetsRaw = "{}"
        categoriesRaw = ""
        dailyNotesRaw = "{}"
        dismiss()
    }

    private func dataAction(symbol: String, title: String, subtitle: String, color: Color, variant: String) -> some View {
        let isAccent = variant == "accent"
        let isDanger = variant == "danger"
        let foreground = isAccent ? color : (isDanger ? color : Color.primary)
        let surface = isAccent ? color.opacity(0.09) : (isDanger ? color.opacity(0.07) : AppAppearance.card2(dark: isDark))
        let iconSurface = isAccent ? color.opacity(0.15) : (isDanger ? color.opacity(0.12) : AppAppearance.card2(dark: isDark))
        let borderColor = isAccent ? color.opacity(0.25) : (isDanger ? color.opacity(0.21) : cardBorder)

        return HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 18, weight: .regular)).foregroundStyle(foreground)
                .frame(width: 38, height: 38).background(iconSurface, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(MeowlettTypography.font(size: 14, weight: .heavy)).foregroundStyle(foreground)
                Text(subtitle).font(MeowlettTypography.font(size: 11, weight: .regular))
                    .foregroundStyle(isAccent || isDanger ? foreground.opacity(0.7) : Color.secondary)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: 1.5))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

private enum BackupFileError: Error {
    case invalid
}

private struct MeowlettBackupFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct MeowlettBackupTransaction: Codable {
    var id: String
    var date: String
    var amount: Int64
    var category: String
    var description: String
    var location: String
    var note: String
    var paymentMethod: String

    private enum CodingKeys: String, CodingKey {
        case id, date, amount, category, description, location, note, paymentMethod
    }

    init(id: String, date: String, amount: Int64, category: String, description: String, location: String, note: String, paymentMethod: String) {
        self.id = id
        self.date = date
        self.amount = amount
        self.category = category
        self.description = description
        self.location = location
        self.note = note
        self.paymentMethod = paymentMethod
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let stringID = try? values.decode(String.self, forKey: .id) {
            id = stringID
        } else if let numberID = try? values.decode(Int64.self, forKey: .id) {
            id = String(numberID)
        } else {
            id = UUID().uuidString
        }
        if let stringDate = try? values.decode(String.self, forKey: .date) {
            date = String(stringDate.prefix(10))
        } else if let timestamp = try? values.decode(Double.self, forKey: .date) {
            let seconds = timestamp > 10_000_000_000 ? timestamp / 1000 : timestamp
            date = MeowlettDateFormat.day(Date(timeIntervalSince1970: seconds))
        } else {
            throw BackupFileError.invalid
        }
        if let numericAmount = try? values.decode(Int64.self, forKey: .amount) {
            amount = numericAmount
        } else if let stringAmount = try? values.decode(String.self, forKey: .amount) {
            amount = Int64(stringAmount.filter(\.isNumber)) ?? 0
        } else {
            amount = 0
        }
        category = (try? values.decode(String.self, forKey: .category)) ?? "other"
        description = (try? values.decode(String.self, forKey: .description)) ?? ""
        location = (try? values.decode(String.self, forKey: .location)) ?? ""
        note = (try? values.decode(String.self, forKey: .note)) ?? ""
        paymentMethod = (try? values.decode(String.self, forKey: .paymentMethod)) ?? "cash"
    }
}

private struct MeowlettBackupGoal: Codable {
    var id: Int64
    var label: String
    var target: Int64
    var saved: Int64
    var color: String
    var icon: String
    var deadline: String?
}

private struct MeowlettBackupPayload: Codable {
    var version: Int?
    var exportedAt: String?
    var transactions: [MeowlettBackupTransaction]?
    var income: Int64?
    var goals: [MeowlettBackupGoal]?
    var budgets: [String: Int64]?
    var categories: [String: MeowlettCategoryDefinition]?
    var dailyNotes: [String: String]?
}
