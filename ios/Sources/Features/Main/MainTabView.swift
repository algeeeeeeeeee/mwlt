import SwiftUI

struct MainTabView: View {
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_theme_preset") private var themePreset = "rose"
    @AppStorage("gm_custom_accent") private var customAccent = "#fb7185"

    private var isEnglish: Bool { language == "en" }
    private var tint: Color {
        themePreset == "custom"
            ? Color(hex: customAccent)
            : Color(hex: AppAppearance.presets.first(where: { $0.id == themePreset })?.accent ?? "#fb7185")
    }

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label(isEnglish ? "Home" : "Beranda", systemImage: "house.fill") }

            TransactionsView()
                .tabItem { Label(isEnglish ? "Transactions" : "Transaksi", systemImage: "list.bullet.rectangle") }

            ReportsView()
                .tabItem { Label(isEnglish ? "Reports" : "Laporan", systemImage: "chart.bar.fill") }

            DateTabView()
                .tabItem { Label("Date", systemImage: "heart.fill") }

            SettingsView()
                .tabItem { Label(isEnglish ? "Settings" : "Pengaturan", systemImage: "slider.horizontal.3") }
        }
        .tint(tint)
    }
}
