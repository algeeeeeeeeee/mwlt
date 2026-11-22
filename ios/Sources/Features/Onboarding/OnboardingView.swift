import SwiftUI

struct OnboardingView: View {
    private enum OnboardingField: Hashable {
        case name
        case income
    }

    let onComplete: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_username") private var savedName = ""
    @AppStorage("gm_income") private var savedIncome = "5000000"
    @AppStorage("gm_dark_override") private var darkOverride = "system"
    @AppStorage("gm_follow_system") private var followSystem = "0"
    @AppStorage("gm_theme_preset") private var themePreset = "rose"
    @AppStorage("gm_custom_primary") private var customPrimary = "#881337"
    @AppStorage("gm_custom_accent") private var customAccent = "#fb7185"

    @State private var step = 0
    @State private var name = ""
    @State private var income = ""
    @State private var isDark = false
    @FocusState private var focusedField: OnboardingField?

    private var isEnglish: Bool { language == "en" }

    private var primary: Color {
        themePreset == "custom"
            ? Color(hex: customPrimary)
            : Color(hex: AppAppearance.presets.first(where: { $0.id == themePreset })?.primary ?? "#881337")
    }

    private var accent: Color {
        themePreset == "custom"
            ? Color(hex: customAccent)
            : Color(hex: AppAppearance.presets.first(where: { $0.id == themePreset })?.accent ?? "#fb7185")
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 5) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index <= step ? accent : (isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.12)))
                            .frame(width: index == step ? 24 : 6, height: 3)
                    }
                }
                .padding(.bottom, 20)

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: nameStep
                    case 2: incomeStep
                    default: appearanceStep
                    }
                }
                .frame(maxWidth: 400, alignment: .leading)
                .id(step)
                .transition(.opacity.combined(with: .offset(y: 10)))
            }
            .frame(maxWidth: 400, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppAppearance.background(dark: isDark).ignoresSafeArea())
        .tint(accent)
        .animation(.easeInOut(duration: 0.18), value: step)
        .onAppear {
            name = savedName
            income = savedIncome == "5000000" ? "" : formatIncomeInput(savedIncome)
            isDark = (followSystem == "1" || darkOverride == "system")
                ? colorScheme == .dark
                : darkOverride == "true"
        }
        .onChange(of: step) { _, newStep in
            switch newStep {
            case 1: focusedField = .name
            case 2: focusedField = .income
            default: focusedField = nil
            }
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepLabel(1)
                .padding(.bottom, 6)

            Text(isEnglish ? "Welcome to\nMeowlett" : "Selamat datang\ndi Meowlett")
                .font(MeowlettTypography.font(size: 28, weight: .black))
                .lineSpacing(1)
                .foregroundStyle(AppAppearance.text(dark: isDark))
                .padding(.bottom, 4)

            Text(isEnglish
                 ? "Track expenses, monitor your budget, and reach your financial goals."
                 : "Catat pengeluaran, pantau budget,\ndan capai tujuan finansialmu.")
                .font(MeowlettTypography.font(size: 13, weight: .regular))
                .lineSpacing(4)
                .foregroundStyle(AppAppearance.textSub(dark: isDark))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 20)

            HStack(spacing: 8) {
                languageButton(code: "id", title: "ID  Indonesia")
                languageButton(code: "en", title: "EN  English")
            }
            .padding(.bottom, 20)

            primaryButton(isEnglish ? "Start Setup →" : "Mulai Setup →", fontSize: 15, cornerRadius: 16, verticalPadding: 16) {
                go(to: 1)
            }
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepLabel(2)
                .padding(.bottom, 6)

            Text(isEnglish ? "What's your\nname?" : "Siapa\nnamamu?")
                .font(MeowlettTypography.font(size: 26, weight: .black))
                .lineSpacing(1)
                .foregroundStyle(AppAppearance.text(dark: isDark))
                .padding(.bottom, 4)

            Text(isEnglish ? "So greetings feel more personal." : "Biar sapaan lebih personal.")
                .font(MeowlettTypography.font(size: 13, weight: .regular))
                .foregroundStyle(AppAppearance.textSub(dark: isDark))
                .padding(.bottom, 16)

            TextField(isEnglish ? "e.g. Pickles..." : "Contoh: Pickles...", text: $name)
                .focused($focusedField, equals: .name)
                .foregroundStyle(AppAppearance.text(dark: isDark))
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
                .font(MeowlettTypography.font(size: 16, weight: .regular))
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(name.isEmpty ? AppAppearance.border(dark: isDark) : accent, lineWidth: 2))
                .padding(.bottom, 12)

            primaryButton(isEnglish ? "Next →" : "Lanjut →", fontSize: 14, cornerRadius: 14, verticalPadding: 15) {
                go(to: 2)
            }
            .padding(.bottom, 8)

            secondaryButton(isEnglish ? "Skip" : "Lewati") {
                go(to: 2)
            }
        }
    }

    private var incomeStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepLabel(3)
                .padding(.bottom, 6)

            Text(isEnglish ? "Monthly\nincome?" : "Pemasukan\nbulan ini?")
                .font(MeowlettTypography.font(size: 26, weight: .black))
                .lineSpacing(1)
                .foregroundStyle(AppAppearance.text(dark: isDark))
                .padding(.bottom, 4)

            Text(isEnglish ? "You can change this anytime." : "Bisa diubah kapan saja di Pengaturan.")
                .font(MeowlettTypography.font(size: 13, weight: .regular))
                .foregroundStyle(AppAppearance.textSub(dark: isDark))
                .padding(.bottom, 16)

            HStack(spacing: 8) {
                Text("Rp")
                    .font(MeowlettTypography.font(size: 13, weight: .bold))
                    .foregroundStyle(AppAppearance.textSub(dark: isDark))
                TextField("5.000.000", text: $income)
                    .focused($focusedField, equals: .income)
                    .foregroundStyle(AppAppearance.text(dark: isDark))
                    .keyboardType(.numberPad)
                    .font(MeowlettTypography.font(size: 16, weight: .regular))
                    .onChange(of: income) { _, newValue in
                        let formatted = formatIncomeInput(newValue)
                        if formatted != newValue {
                            income = formatted
                        }
                    }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(income.isEmpty ? AppAppearance.border(dark: isDark) : accent, lineWidth: 2))
            .padding(.bottom, 8)

            if let value = parsedIncome, value > 0 {
                Text("= \(rupiah(value))")
                    .font(MeowlettTypography.font(size: 12, weight: .bold))
                    .foregroundStyle(accent)
                    .padding(.bottom, 8)
            } else {
                Color.clear.frame(height: 8)
            }

            primaryButton(isEnglish ? "Next →" : "Lanjut →") {
                go(to: 3)
            }
            .padding(.bottom, 8)

            secondaryButton(isEnglish ? "← Back" : "← Kembali") {
                go(to: 1)
            }
        }
    }

    private var appearanceStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepLabel(4)
                .padding(.bottom, 6)

            Text(isEnglish ? "Choose your\nlook" : "Pilih\ntampilan")
                .font(MeowlettTypography.font(size: 26, weight: .black))
                .lineSpacing(1)
                .foregroundStyle(AppAppearance.text(dark: isDark))
                .padding(.bottom, 4)

            Text(isEnglish ? "You can change this anytime in Settings." : "Bisa diganti kapan saja di Pengaturan.")
                .font(MeowlettTypography.font(size: 13, weight: .regular))
                .foregroundStyle(AppAppearance.textSub(dark: isDark))
                .padding(.bottom, 14)

            Text(isEnglish ? "DISPLAY MODE" : "MODE TAMPILAN")
                .font(MeowlettTypography.font(size: 10, weight: .black))
                .tracking(1)
                .foregroundStyle(AppAppearance.textMuted(dark: isDark))
                .padding(.bottom, 8)

            HStack(spacing: 8) {
                modeButton(title: isEnglish ? "Light" : "Terang", dark: false)
                modeButton(title: isEnglish ? "Dark" : "Gelap", dark: true)
            }
            .padding(.bottom, 18)

            Text(isEnglish ? "COLOR THEME" : "TEMA WARNA")
                .font(MeowlettTypography.font(size: 10, weight: .black))
                .tracking(1)
                .foregroundStyle(AppAppearance.textMuted(dark: isDark))
                .padding(.bottom, 8)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 44, maximum: 44), spacing: 12)],
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(AppAppearance.presets, id: \.id) { preset in
                    Button {
                        themePreset = preset.id
                    } label: {
                        Circle()
                            .fill(Color(hex: preset.primary))
                            .frame(width: 44, height: 44)
                            .overlay {
                                if themePreset == preset.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundStyle(Color(hex: preset.accent))
                                }
                            }
                            .overlay(
                                Circle().stroke(
                                    themePreset == preset.id ? Color(hex: preset.accent) : .clear,
                                    lineWidth: 3
                                )
                            )
                            .overlay(
                                Circle().stroke(
                                    themePreset == preset.id ? Color(hex: preset.accent).opacity(0.33) : .clear,
                                    lineWidth: 2
                                ).padding(-2)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isEnglish ? preset.nameEN : preset.nameID)
                }

                Button {
                    themePreset = "custom"
                } label: {
                    Circle()
                        .fill(themePreset == "custom" ? Color(hex: customPrimary) : Color.gray)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: themePreset == "custom" ? "checkmark" : "paintpalette.fill")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white)
                        }
                        .overlay(
                            Circle().stroke(
                                themePreset == "custom" ? Color(hex: customAccent) : .clear,
                                lineWidth: 3
                            )
                        )
                        .overlay(
                            Circle().stroke(
                                themePreset == "custom" ? Color(hex: customAccent).opacity(0.33) : .clear,
                                lineWidth: 2
                            ).padding(-2)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isEnglish ? "Custom color" : "Warna kustom")
            }
            .padding(.bottom, 12)

            if themePreset == "custom" {
                HStack(alignment: .top, spacing: 8) {
                    onboardingColorControl(
                        title: isEnglish ? "PRIMARY" : "WARNA UTAMA",
                        value: primaryBinding,
                        hex: customPrimary
                    )
                    onboardingColorControl(
                        title: isEnglish ? "ACCENT" : "WARNA AKSEN",
                        value: accentBinding,
                        hex: customAccent
                    )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppAppearance.border(dark: isDark), lineWidth: 1.5)
                )
                .padding(.bottom, 14)
            }

            Button {
                finish()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                    Text(isEnglish ? "Done, Let's Go!" : "Selesai, Mulai!")
                        .font(MeowlettTypography.font(size: 14, weight: .heavy))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(colors: [accent, primary], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)

            secondaryButton(isEnglish ? "← Back" : "← Kembali") {
                go(to: 2)
            }
        }
    }

    private func onboardingColorControl(
        title: String,
        value: Binding<Color>,
        hex: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(MeowlettTypography.font(size: 10, weight: .black))
                .tracking(0.5)
                .foregroundStyle(AppAppearance.textMuted(dark: isDark))

            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: hex))
                    ColorPicker("", selection: value)
                        .labelsHidden()
                        .opacity(0.02)
                }
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppAppearance.border(dark: isDark), lineWidth: 2)
                )

                Text(hex.uppercased())
                    .font(MeowlettTypography.font(size: 12, weight: .semibold))
                    .foregroundStyle(AppAppearance.textSub(dark: isDark))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stepLabel(_ number: Int) -> some View {
        Text(isEnglish ? "STEP \(number) / 4" : "LANGKAH \(number) / 4")
            .font(MeowlettTypography.font(size: 11, weight: .black))
            .tracking(1)
            .foregroundStyle(accent)
    }

    private func languageButton(code: String, title: String) -> some View {
        let selected = language == code
        return Button {
            language = code
        } label: {
            HStack(spacing: 6) {
                Text(title)
                if selected {
                    Image(systemName: "checkmark")
                }
            }
            .font(MeowlettTypography.font(size: 13, weight: .bold))
            .foregroundStyle(selected ? accent : AppAppearance.textSub(dark: isDark))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? accent.opacity(24.0 / 255.0) : AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? accent : AppAppearance.border(dark: isDark), lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func modeButton(title: String, dark: Bool) -> some View {
        let selected = isDark == dark
        return Button {
            isDark = dark
            darkOverride = dark ? "true" : "false"
            followSystem = "0"
        } label: {
            HStack(spacing: 7) {
                Image(systemName: dark ? "moon.fill" : "sun.max.fill")
                Text(title)
                if selected { Image(systemName: "checkmark") }
            }
            .font(MeowlettTypography.font(size: 13, weight: .bold))
            .foregroundStyle(selected ? accent : AppAppearance.textSub(dark: isDark))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(selected ? accent.opacity(24.0 / 255.0) : AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? accent : AppAppearance.border(dark: isDark), lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func primaryButton(_ title: String, fontSize: CGFloat = 14, cornerRadius: CGFloat = 14, verticalPadding: CGFloat = 15, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(MeowlettTypography.font(size: fontSize, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, verticalPadding)
                .background(LinearGradient(colors: [accent, primary], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(MeowlettTypography.font(size: 13, weight: .semibold))
                .foregroundStyle(AppAppearance.textSub(dark: isDark))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private var parsedIncome: Int64? {
        Int64(income.filter(\.isNumber))
    }

    private func formatIncomeInput(_ value: String) -> String {
        let digits = value.filter(\.isNumber)
        guard let amount = Int64(digits), amount > 0 else {
            return digits.isEmpty ? "" : digits
        }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: amount)) ?? digits
    }

    private var primaryBinding: Binding<Color> {
        Binding(
            get: { Color(hex: customPrimary) },
            set: { customPrimary = $0.meowlettHex; themePreset = "custom" }
        )
    }

    private var accentBinding: Binding<Color> {
        Binding(
            get: { Color(hex: customAccent) },
            set: { customAccent = $0.meowlettHex; themePreset = "custom" }
        )
    }

    private func go(to newStep: Int) {
        withAnimation(.easeInOut(duration: 0.18)) {
            step = min(3, max(0, newStep))
        }
    }

    private func finish() {
        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            savedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let parsedIncome, parsedIncome > 0 {
            savedIncome = String(parsedIncome)
        }
        darkOverride = isDark ? "true" : "false"
        followSystem = "0"
        onComplete()
    }

    private func rupiah(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        return "Rp " + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }
}
