import SwiftUI

@main
struct MeowlettApp: App {
    init() {
        MeowlettTypography.registerBundledFonts()
    }

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
    @State private var showNativeSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var preferredScheme: ColorScheme? {
        if followSystem == "1" || darkOverride == "system" { return nil }
        return darkOverride == "true" ? .dark : .light
    }

    // Preview builds must not depend on simulator preferences being written
    // before the first app launch. This launch-only flag bypasses onboarding
    // without changing the user's persisted onboarding state.
    private var isNativePreviewLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains("--mwlt-preview-mode")
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if isOnboarded || isNativePreviewLaunch {
                    MainTabView()
                        .environmentObject(financeStore)
                } else {
                    OnboardingView {
                        isOnboarded = true
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .background(Color(uiColor: .systemBackground))
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .environment(\.font, MeowlettTypography.font(size: 14, weight: .regular))
        .preferredColorScheme(preferredScheme)
        .overlay {
            if showNativeSplash {
                NativeSplashView {
                    withAnimation(reduceMotion ? .easeOut(duration: 0.18) : .easeOut(duration: 0.4)) {
                        showNativeSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1000)
            }
        }
        .animation(reduceMotion ? .easeOut(duration: 0.18) : .easeOut(duration: 0.4), value: showNativeSplash)
    }
}
