import SwiftUI

struct NativeSplashView: View {
    let holdForUITest: Bool
    let onFinish: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -44

    private var isDark: Bool { colorScheme == .dark }
    private var backgroundColor: Color {
        Color(hex: isDark ? "#0a0a0a" : "#f5f4f0")
    }
    private var titleColor: Color {
        Color(hex: isDark ? "#ffffff" : "#1a1a1a")
    }
    private var subtitleColor: Color {
        isDark ? Color.white.opacity(0.4) : Color(hex: "#888888")
    }
    private var progressTrackColor: Color {
        isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.10)
    }
    private var accent: Color { Color(hex: AppAppearance.accentHex) }
    private var shimmerColor: Color {
        Color(hex: AppAppearance.lighten(AppAppearance.accentHex, ratio: 0.38))
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 14) {
                Image("MeowlettSplash")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .accessibilityLabel("Meowlett")

                Text("Meowlett")
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .tracking(-0.5)
                    .foregroundStyle(titleColor)
                    .accessibilityIdentifier("mwlt.splash.title")

                Text("Purr-fect finances")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundStyle(subtitleColor)
                    .padding(.top, -6)
                    .accessibilityIdentifier("mwlt.splash.tagline")

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(progressTrackColor)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accent, shimmerColor, accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress)

                        if !reduceMotion {
                            LinearGradient(
                                colors: [.clear, Color.white.opacity(0.55), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 44)
                            .offset(x: shimmerOffset)
                        }
                    }
                    .clipShape(Capsule())
                }
                .frame(width: 160, height: 4)
                .accessibilityLabel("Loading Meowlett")

                if holdForUITest {
                    Button("Continue", action: onFinish)
                        .font(.system(size: 12, weight: .semibold))
                        .accessibilityIdentifier("mwlt.splash.continue")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
        .task {
            if holdForUITest {
                progress = 1
                return
            }
            if reduceMotion {
                progress = 1
                try? await Task.sleep(nanoseconds: 450_000_000)
            } else {
                withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 2.7)) {
                    progress = 1
                }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 170
                }
                try? await Task.sleep(nanoseconds: 2_700_000_000)
            }
            onFinish()
        }
    }
}
