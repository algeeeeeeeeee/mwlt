import SwiftUI
import PhotosUI
import UIKit
import UserNotifications
import UniformTypeIdentifiers

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
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var nameDraft = ""
    @State private var showNameEditor = false
    @State private var showAppearance = false
    @State private var showNotifications = false
    @State private var showBudgets = false
    @State private var showCategoryMenu = false
    @State private var showCategoryManager = false
    @State private var showData = false

    private var isEnglish: Bool { language == "en" }
    private var isDark: Bool { colorScheme == .dark }
    private var primary: Color { Color(hex: AppAppearance.primaryHex) }
    private var accent: Color { Color(hex: AppAppearance.accentHex) }
    private var photo: UIImage? {
        let encoded = profilePhoto.components(separatedBy: ",").last ?? profilePhoto
        guard let data = Data(base64Encoded: encoded) else { return nil }
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
                        title: isEnglish ? "Display mode" : "Mode tampilan",
                        subtitle: "\(isDark ? (isEnglish ? "Dark" : "Gelap") : (isEnglish ? "Light" : "Terang")) · \(selectedThemeName)",
                        symbol: darkOverride == "true" ? "moon.fill" : "sun.max.fill"
                    ) { showAppearance = true }
                }

                settingsCard {
                    settingsRow(
                        title: isEnglish ? "Notifications" : "Notifikasi",
                        subtitle: notificationsEnabled == "1"
                            ? (isEnglish ? "Notifications enabled" : "Notifikasi aktif")
                            : (isEnglish ? "Notifications disabled" : "Notifikasi nonaktif"),
                        symbol: "bell"
                    ) { showNotifications = true }
                }

                settingsCard {
                    settingsRow(
                        title: isEnglish ? "Category" : "Kategori",
                        subtitle: isEnglish ? "Manage & organise categories" : "Atur & kelola kategori",
                        symbol: "square.grid.2x2"
                    ) { showCategoryMenu = true }
                }

                settingsCard {
                    settingsRow(
                        title: "Data",
                        subtitle: isEnglish ? "Backup, restore & reset" : "Backup, pulihkan & reset",
                        symbol: "externaldrive"
                    ) { showData = true }
                }

            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(AppAppearance.background(dark: isDark))
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: selectedPhoto) { _, item in
            Task {
                guard let data = try? await item?.loadTransferable(type: Data.self) else { return }
                profilePhoto = "data:image/jpeg;base64," + data.base64EncodedString()
            }
        }
        .sheet(isPresented: $showNameEditor) { nameEditor }
        .sheet(isPresented: $showAppearance) { SettingsAppearanceSheet() }
        .sheet(isPresented: $showNotifications) {
            SettingsNotificationsSheet(
                enabled: Binding(get: { notificationsEnabled == "1" }, set: { notificationsEnabled = $0 ? "1" : "0" }),
                weekly: Binding(get: { weeklyNotification == "true" }, set: { weeklyNotification = $0 ? "true" : "false" }),
                day: Binding(get: { weeklyNotificationDay }, set: { weeklyNotificationDay = $0 }),
                isEnglish: isEnglish
            )
        }
        .sheet(isPresented: $showBudgets) { SettingsBudgetSheet(isEnglish: isEnglish) }
        .sheet(isPresented: $showCategoryMenu) {
            SettingsCategoryMenuSheet(
                isEnglish: isEnglish,
                onBudget: {
                    showCategoryMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showBudgets = true }
                },
                onManage: {
                    showCategoryMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showCategoryManager = true }
                }
            )
        }
        .sheet(isPresented: $showCategoryManager) { SettingsCategoryManagerSheet() }
        .sheet(isPresented: $showData) { SettingsDataSheet(isEnglish: isEnglish, incomeRaw: $incomeRaw) }
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
                                Image(systemName: "cat.fill")
                                    .font(.system(size: 25, weight: .medium))
                                    .foregroundStyle(accent)
                            }
                        }
                        .overlay(Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1.5))
                    Circle().fill(primary).frame(width: 18, height: 18)
                        .overlay(Image(systemName: "camera.fill").font(.system(size: 8, weight: .black)).foregroundStyle(.white))
                        .overlay(Circle().strokeBorder(AppAppearance.background(dark: isDark), lineWidth: 2))
                }
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 3) {
                Text(isEnglish ? "Profile name" : "Nama profil")
                    .font(MeowlettTypography.font(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Button {
                    nameDraft = userName
                    showNameEditor = true
                } label: {
                    HStack(spacing: 5) {
                        Text(userName.isEmpty ? (isEnglish ? "Tap to add your name" : "Ketuk untuk isi nama") : userName)
                            .font(MeowlettTypography.font(size: 17, weight: .black))
                            .foregroundStyle(.primary)
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardColor, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(cardBorder, lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0 : 0.025), radius: 4, x: 0, y: 1)
    }

    private var nameEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEnglish ? "Profile name" : "Nama profil")
                .font(MeowlettTypography.font(size: 17, weight: .black))
            TextField(isEnglish ? "Your name" : "Namamu", text: $nameDraft)
                .font(MeowlettTypography.font(size: 15, weight: .regular))
                .padding(14)
                .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 13))
            HStack(spacing: 10) {
                Button(isEnglish ? "Cancel" : "Batal") { showNameEditor = false }
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 12))
                Button(isEnglish ? "Save" : "Simpan") {
                    userName = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    showNameEditor = false
                }
                .fontWeight(.bold).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 44)
                .background(primary, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .presentationDetents([.height(210)])
        .presentationDragIndicator(.visible)
    }

    private var cardColor: Color {
        isDark ? AppAppearance.card(dark: isDark) : .white
    }
    private var cardBorder: Color { Color.primary.opacity(isDark ? 0.10 : 0.07) }
    private var rowDivider: some View { Rectangle().fill(cardBorder).frame(height: 1).padding(.leading, 16) }

    private func settingsCard<Content: View>(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: spacing, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardColor, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(cardBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(isDark ? 0 : 0.025), radius: 4, x: 0, y: 1)
    }

    private func settingsRow(title: String, subtitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(MeowlettTypography.font(size: 14, weight: .bold)).foregroundStyle(.primary)
                    Text(subtitle).font(MeowlettTypography.font(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
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

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 36, height: 4).padding(.top, 12)
            HStack(spacing: 10) {
                Image(systemName: darkOverride == "true" ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppAppearance.accent)
                    .frame(width: 36, height: 36)
                    .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 12))
                Text(isEnglish ? "Appearance" : "Tampilan")
                    .font(MeowlettTypography.font(size: 17, weight: .black))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary).frame(width: 32, height: 32)
                        .background(AppAppearance.card2(dark: isDark), in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    appearanceSwitchRow(
                        symbol: darkOverride == "true" ? "moon.fill" : "sun.max.fill",
                        title: isEnglish ? "Display mode" : "Mode tampilan",
                        subtitle: darkOverride == "true" ? (isEnglish ? "Dark mode" : "Mode gelap") : (isEnglish ? "Light mode" : "Mode terang"),
                        isOn: Binding(
                            get: { colorScheme == .dark },
                            set: { darkOverride = $0 ? "true" : "false"; followSystem = "0" }
                        )
                    )
                    Divider().opacity(0.45)
                    appearanceSwitchRow(
                        symbol: "desktopcomputer",
                        title: isEnglish ? "Follow system" : "Ikuti sistem",
                        subtitle: followSystem == "1" ? (isEnglish ? "Using device appearance" : "Mengikuti tampilan perangkat") : (isEnglish ? "Manual mode" : "Mode manual"),
                        isOn: Binding(
                            get: { followSystem == "1" },
                            set: { value in
                                followSystem = value ? "1" : "0"
                                if !value { darkOverride = colorScheme == .dark ? "true" : "false" }
                            }
                        )
                    )
                    Divider().opacity(0.45)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isEnglish ? "Language" : "Bahasa").font(MeowlettTypography.font(size: 14, weight: .bold))
                            Text(isEnglish ? "Choose app language" : "Pilih bahasa aplikasi").font(MeowlettTypography.font(size: 11, weight: .regular)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $language) {
                            Text("ID").tag("id")
                            Text("EN").tag("en")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 105)
                    }
                    .padding(.vertical, 14)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "paintpalette.fill").foregroundStyle(AppAppearance.primary)
                            Text(isEnglish ? "Color theme" : "Tema warna").font(MeowlettTypography.font(size: 14, weight: .bold))
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(AppAppearance.presets, id: \.id) { preset in
                                let active = themePreset == preset.id
                                Button { themePreset = preset.id } label: {
                                    VStack(spacing: 6) {
                                        HStack(spacing: 3) {
                                            Circle().fill(Color(hex: preset.primary)).frame(width: 15, height: 15)
                                            Circle().fill(Color(hex: preset.accent)).frame(width: 15, height: 15)
                                        }
                                        Text(isEnglish ? preset.nameEN : preset.nameID).font(MeowlettTypography.font(size: 11, weight: .bold))
                                        if active { Label(isEnglish ? "Active" : "Aktif", systemImage: "checkmark.circle.fill").font(.system(size: 9, weight: .bold)) }
                                    }
                                    .foregroundStyle(active ? Color(hex: preset.accent) : .secondary)
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(active ? Color(hex: preset.primary).opacity(0.12) : AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(active ? Color(hex: preset.accent) : Color.primary.opacity(0.07), lineWidth: active ? 2.5 : 1))
                                }
                                .buttonStyle(.plain)
                            }
                            Button { themePreset = "custom" } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "paintbrush.pointed.fill").font(.system(size: 17))
                                    Text(isEnglish ? "Custom" : "Kustom").font(MeowlettTypography.font(size: 11, weight: .bold))
                                    if themePreset == "custom" { Label(isEnglish ? "Active" : "Aktif", systemImage: "checkmark.circle.fill").font(.system(size: 9, weight: .bold)) }
                                }
                                .foregroundStyle(themePreset == "custom" ? Color(hex: customAccent) : .secondary)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(themePreset == "custom" ? Color(hex: customPrimary).opacity(0.12) : AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(themePreset == "custom" ? Color(hex: customAccent) : Color.primary.opacity(0.07), lineWidth: themePreset == "custom" ? 2.5 : 1))
                            }
                            .buttonStyle(.plain)
                        }
                        VStack(spacing: 10) {
                            ColorPicker(isEnglish ? "Primary color" : "Warna utama", selection: Binding(get: { Color(hex: customPrimary) }, set: { customPrimary = $0.meowlettHex; themePreset = "custom" }))
                            ColorPicker(isEnglish ? "Accent color" : "Warna aksen", selection: Binding(get: { Color(hex: customAccent) }, set: { customAccent = $0.meowlettHex; themePreset = "custom" }))
                        }
                        .padding(14)
                        .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 26)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(AppAppearance.modal(dark: isDark))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func appearanceSwitchRow(symbol: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 17, weight: .semibold)).foregroundStyle(AppAppearance.accent)
                .frame(width: 36, height: 36).background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(MeowlettTypography.font(size: 14, weight: .bold))
                Text(subtitle).font(MeowlettTypography.font(size: 11, weight: .regular)).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(AppAppearance.primary)
        }
        .padding(.vertical, 14)
    }
}

private struct SettingsNotificationsSheet: View {
    @Binding var enabled: Bool
    @Binding var weekly: Bool
    @Binding var day: String
    let isEnglish: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showReminderSettings = false

    private var isDark: Bool { colorScheme == .dark }
    private var primary: Color { AppAppearance.primary }
    private var accent: Color { AppAppearance.accent }
    private var dayLabels: [String] {
        isEnglish ? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] : ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"]
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.28))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 14)

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppAppearance.card2(dark: isDark))
                    .frame(width: 38, height: 38)
                    .overlay(Image(systemName: enabled ? "bell.fill" : "bell.slash.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(accent))
                Text(isEnglish ? "Notifications" : "Notifikasi")
                    .font(MeowlettTypography.font(size: 17, weight: .black))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(AppAppearance.card2(dark: isDark), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Button { showReminderSettings = true } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppAppearance.card2(dark: isDark))
                                .frame(width: 36, height: 36)
                                .overlay(Image(systemName: enabled ? "bell.fill" : "bell.slash.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(accent))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isEnglish ? "Transaction reminder" : "Pengingat Transaksi")
                                    .font(MeowlettTypography.font(size: 14, weight: .bold))
                                    .foregroundStyle(.primary)
                                Text(enabled
                                     ? (isEnglish ? "Notifications active" : "Notifikasi aktif")
                                     : (isEnglish ? "Notifications off" : "Notifikasi nonaktif"))
                                    .font(MeowlettTypography.font(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider().overlay(AppAppearance.border(dark: isDark))

                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppAppearance.card2(dark: isDark))
                                .frame(width: 36, height: 36)
                                .overlay(Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(weekly ? accent : .secondary))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isEnglish ? "Weekly summary" : "Ringkasan Mingguan")
                                    .font(MeowlettTypography.font(size: 14, weight: .bold))
                                Text(weekly ? (isEnglish ? "Every \(dayLabels[Int(day) ?? 0])" : "\(dayLabels[Int(day) ?? 0]) tiap minggu") : (isEnglish ? "Off" : "Nonaktif"))
                                    .font(MeowlettTypography.font(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            switchControl(isOn: weekly) { weekly.toggle() }
                        }
                        if weekly {
                            HStack(spacing: 6) {
                                ForEach(Array(dayLabels.enumerated()), id: \.offset) { index, title in
                                    let selected = day == String(index)
                                    Button { day = String(index) } label: {
                                        Text(title)
                                            .font(MeowlettTypography.font(size: 11, weight: .bold))
                                            .foregroundStyle(selected ? .white : Color.secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(selected ? primary : AppAppearance.card2(dark: isDark), in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 3)
                        }
                    }
                    .padding(.vertical, 14)

                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(AppAppearance.modal(dark: isDark))
        .sheet(isPresented: $showReminderSettings) { SettingsReminderSheet() }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    private func switchControl(isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Capsule()
                .fill(isOn ? primary : Color.secondary.opacity(isDark ? 0.25 : 0.20))
                .frame(width: 48, height: 28)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.16), radius: 3, x: 0, y: 1)
                        .padding(4)
                }
                .animation(.easeInOut(duration: 0.18), value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? (isEnglish ? "On" : "Aktif") : (isEnglish ? "Off" : "Nonaktif"))
    }


}

private struct SettingsCategoryMenuSheet: View {
    let isEnglish: Bool
    let onBudget: () -> Void
    let onManage: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 36, height: 4).padding(.top, 12)
            HStack {
                Text(isEnglish ? "Category" : "Kategori")
                    .font(MeowlettTypography.font(size: 17, weight: .black))
                    .foregroundStyle(.primary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary).frame(width: 32, height: 32)
                        .background(Color(uiColor: .secondarySystemBackground), in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 15)

            VStack(spacing: 0) {
                menuRow(
                    symbol: "chart.bar",
                    title: isEnglish ? "Spending Limits" : "Batas Pengeluaran",
                    subtitle: isEnglish ? "Set monthly category budgets" : "Atur batas pengeluaran per kategori",
                    color: AppAppearance.accent,
                    action: onBudget
                )
                Rectangle().fill(Color.primary.opacity(0.07)).frame(height: 1).padding(.leading, 52)
                menuRow(
                    symbol: "square.grid.2x2",
                    title: isEnglish ? "Manage categories" : "Kelola Kategori",
                    subtitle: isEnglish ? "Manage & organise categories" : "Atur & kelola kategori",
                    color: AppAppearance.primary,
                    action: onManage
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(AppAppearance.modal(dark: colorScheme == .dark))
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func menuRow(symbol: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(MeowlettTypography.font(size: 14, weight: .bold)).foregroundStyle(.primary)
                    Text(subtitle).font(MeowlettTypography.font(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.tertiary)
            }
            .padding(.vertical, 13)
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
    @State private var showResetConfirm = false
    @State private var showRestoreConfirm = false
    @State private var pendingRestore: MeowlettBackupPayload?
    @State private var importError = ""

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Data").font(MeowlettTypography.font(size: 17, weight: .black))
                Spacer()
                Button(isEnglish ? "Done" : "Selesai") { dismiss() }
                    .font(MeowlettTypography.font(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            Button {
                backupFile = makeBackupFile()
                showExporter = backupFile != nil
            } label: {
                dataAction(
                    symbol: "arrow.down.to.line",
                    title: isEnglish ? "Backup data" : "Backup data",
                    subtitle: isEnglish ? "Export a full JSON backup" : "Ekspor cadangan data lengkap",
                    color: AppAppearance.accent
                )
            }
            .buttonStyle(.plain)

            Button { showImporter = true } label: {
                dataAction(
                    symbol: "arrow.up.to.line",
                    title: isEnglish ? "Restore backup" : "Pulihkan backup",
                    subtitle: isEnglish ? "Restore from a Meowlett JSON file" : "Pulihkan dari file JSON Meowlett",
                    color: AppAppearance.primary
                )
            }
            .buttonStyle(.plain)

            Rectangle().fill(Color.primary.opacity(0.08)).frame(height: 1).padding(.vertical, 3)

            Button { showResetConfirm = true } label: {
                dataAction(
                    symbol: "trash",
                    title: isEnglish ? "Reset data" : "Reset data",
                    subtitle: isEnglish ? "Delete finance data on this device" : "Hapus data keuangan di perangkat ini",
                    color: Color(hex: "#ef4444")
                )
            }
            .buttonStyle(.plain)

            if !importError.isEmpty {
                Text(importError)
                    .font(MeowlettTypography.font(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "#ef4444"))
            }
        }
        .padding(20)
        .background(AppAppearance.modal(dark: isDark))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .fileExporter(
            isPresented: $showExporter,
            document: backupFile,
            contentType: .json,
            defaultFilename: "meowlett-backup-\(Date.now.formatted(.iso8601.year().month().day()))"
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
                showRestoreConfirm = true
                importError = ""
            } catch {
                importError = isEnglish ? "Invalid backup file." : "File backup tidak valid."
            }
        }
        .confirmationDialog(
            isEnglish ? "Restore this backup?" : "Pulihkan backup ini?",
            isPresented: $showRestoreConfirm,
            titleVisibility: .visible
        ) {
            Button(isEnglish ? "Restore data" : "Pulihkan data", role: .destructive) {
                restorePendingBackup()
            }
            Button(isEnglish ? "Cancel" : "Batal", role: .cancel) { pendingRestore = nil }
        } message: {
            Text(isEnglish ? "Current finance data will be replaced." : "Data keuangan saat ini akan diganti.")
        }
        .confirmationDialog(
            isEnglish ? "Reset all finance data?" : "Reset semua data keuangan?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button(isEnglish ? "Reset data" : "Reset data", role: .destructive) { resetData() }
            Button(isEnglish ? "Cancel" : "Batal", role: .cancel) {}
        }
    }

    private func makeBackupFile() -> MeowlettBackupFile? {
        let transactions = store.transactions.map {
            MeowlettBackupTransaction(
                id: $0.id.uuidString,
                date: $0.date.formatted(.iso8601.year().month().day()),
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
            formatter.dateFormat = "yyyy-MM-dd"
            guard let date = formatter.date(from: row.date) else { return nil }
            return MeowlettTransaction(
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

    private func dataAction(symbol: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 17, weight: .bold)).foregroundStyle(color)
                .frame(width: 38, height: 38).background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(MeowlettTypography.font(size: 14, weight: .bold)).foregroundStyle(color)
                Text(subtitle).font(MeowlettTypography.font(size: 11, weight: .regular)).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.25), lineWidth: 1.5))
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
            date = Date(timeIntervalSince1970: seconds).formatted(.iso8601.year().month().day())
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
