import SwiftUI

@main
struct MeowlettApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @AppStorage("mwlt.native.onboarded") private var isOnboarded = false
    @AppStorage("gm_dark_override") private var darkOverride = "system"
    @AppStorage("gm_follow_system") private var followSystem = "0"
    @StateObject private var financeStore = FinanceStore()

    private var preferredScheme: ColorScheme? {
        if followSystem == "1" || darkOverride == "system" { return nil }
        return darkOverride == "true" ? .dark : .light
    }

    var body: some View {
        Group {
            if isOnboarded {
                MainTabView()
                    .environmentObject(financeStore)
            } else {
                OnboardingView {
                    isOnboarded = true
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .preferredColorScheme(preferredScheme)
    }
}
