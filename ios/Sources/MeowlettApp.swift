import SwiftUI

@main
struct MeowlettApp: App {
    init() {
        Self.resetUITestPersistenceIfRequested()
        MeowlettTypography.registerBundledFonts()
    }

    private static func resetUITestPersistenceIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-uitest-reset") else { return }

        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.mwlt.meowlett"
        UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        UserDefaults.standard.synchronize()

        let supportRoot = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let transactionsDirectory = supportRoot?.appendingPathComponent("Meowlett", isDirectory: true)
        var fileState = "not-found"
        if let transactionsDirectory, FileManager.default.fileExists(atPath: transactionsDirectory.path) {
            do {
                try FileManager.default.removeItem(at: transactionsDirectory)
                fileState = "removed"
            } catch {
                fileState = "failed: \(error.localizedDescription)"
            }
        }

        let timestamp = String(format: "%.3f", Date().timeIntervalSince1970)
        NSLog("[MeowlettUITestReset] timestamp=%@ defaultsDomain=%@ transactionsDirectory=%@", timestamp, bundleIdentifier, fileState)
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

    private var isSplashUITestLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains("--mwlt-test-splash")
    }

    // The screenshot pipeline must hold the real splash visible while simctl
    // finishes launching the app and returns control to the capture script.
    private var isSplashPreviewLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains("--mwlt-preview-splash")
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
            // Controls beneath the blocking opening splash must not receive accessibility focus or taps.
            .accessibilityHidden(showNativeSplash)
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .environment(\.font, MeowlettTypography.font(size: 14, weight: .regular))
        .preferredColorScheme(preferredScheme)
        .overlay {
            if showNativeSplash {
                NativeSplashView(
                    holdForUITest: isSplashUITestLaunch,
                    holdForPreview: isSplashPreviewLaunch
                ) {
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
