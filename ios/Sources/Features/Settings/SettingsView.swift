import SwiftUI

struct SettingsView: View {
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_username") private var userName = ""
    @AppStorage("gm_dark_override") private var darkOverride = "false"
    @AppStorage("gm_follow_system") private var followSystem = "0"
    @AppStorage("gm_theme_preset") private var themePreset = "rose"
    @AppStorage("gm_custom_primary") private var customPrimary = "#881337"
    @AppStorage("gm_custom_accent") private var customAccent = "#fb7185"
    @AppStorage("gm_income") private var incomeRaw = "5000000"
    @AppStorage("mwlt.native.onboarded") private var isOnboarded = true

    private var isEnglish: Bool { language == "en" }

    var body: some View {
        NavigationStack {
            Form {
                Section(isEnglish ? "Profile" : "Profil") {
                    TextField(isEnglish ? "Name" : "Nama", text: $userName)
                    TextField(isEnglish ? "Monthly income" : "Pemasukan bulanan", text: $incomeRaw)
                        .keyboardType(.numberPad)
                }

                Section(isEnglish ? "Language" : "Bahasa") {
                    Picker(isEnglish ? "Language" : "Bahasa", selection: $language) {
                        Text("Indonesia").tag("id")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.segmented)
                }

                Section(isEnglish ? "Appearance" : "Tampilan") {
                    Picker(isEnglish ? "Color theme" : "Tema warna", selection: $themePreset) {
                        ForEach(AppAppearance.presets, id: \.id) { preset in
                            Text(isEnglish ? preset.nameEN : preset.nameID).tag(preset.id)
                        }
                        Text(isEnglish ? "Custom" : "Kustom").tag("custom")
                    }

                    Toggle(isEnglish ? "Dark mode" : "Mode gelap", isOn: Binding(
                        get: { darkOverride == "true" },
                        set: { darkOverride = $0 ? "true" : "false"; followSystem = "0" }
                    ))

                    if themePreset == "custom" {
                        ColorPicker(isEnglish ? "Primary" : "Warna utama", selection: Binding(
                            get: { Color(hex: customPrimary) },
                            set: { customPrimary = $0.meowlettHex }
                        ))
                        ColorPicker(isEnglish ? "Accent" : "Warna aksen", selection: Binding(
                            get: { Color(hex: customAccent) },
                            set: { customAccent = $0.meowlettHex }
                        ))
                    }
                }

                Section {
                    Button(isEnglish ? "Show onboarding again" : "Tampilkan onboarding lagi") {
                        isOnboarded = false
                    }
                } footer: {
                    Text(isEnglish
                        ? "Meowlett native is being migrated from the existing web app in stages."
                        : "Meowlett native sedang dipindahkan dari aplikasi web secara bertahap.")
                }
            }
            .navigationTitle(isEnglish ? "Settings" : "Pengaturan")
        }
    }
}
