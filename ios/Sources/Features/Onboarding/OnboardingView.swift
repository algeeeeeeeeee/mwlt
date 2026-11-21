import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_username") private var savedName = ""
    @AppStorage("gm_income") private var savedIncome = "5000000"
    @AppStorage("gm_dark_override") private var darkOverride = "false"
    @AppStorage("gm_follow_system") private var followSystem = "0"
    @AppStorage("gm_theme_preset") private var themePreset = "rose"
    @AppStorage("gm_custom_primary") private var customPrimary = "#881337"
    @AppStorage("gm_custom_accent") private var customAccent = "#fb7185"

    @State private var step = 0
    @State private var name = ""
    @State private var income = ""
    @State private var isDark = false
    @State private var showCustomColors = false

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
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 5) {
                        ForEach(0..<4, id: \.self) { index in
                            Capsule()
                                .fill(index <= step ? accent : Color.secondary.opacity(0.2))
                                .frame(width: index == step ? 25 : 7, height: 3)
                        }
                        Spacer()
                        Text("MEOWLETT")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(accent)
                    }
                    .padding(.top, 16)

                    Group {
                        switch step {
                        case 0: welcomeStep
                        case 1: nameStep
                        case 2: incomeStep
                        default: appearanceStep
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(step)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: 430)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(accent)
        .animation(.easeInOut(duration: 0.2), value: step)
        .onAppear {
            name = savedName
            income = savedIncome == "5000000" ? "" : savedIncome
            isDark = darkOverride == "true"
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepLabel(1)
            Text(isEnglish ? "Welcome to\nMeowlett" : "Selamat datang\ndi Meowlett")
                .font(.system(size: 31, weight: .black, design: .rounded))
                .lineSpacing(1)
                .foregroundStyle(.primary)

            Text(isEnglish
                 ? "Track expenses, monitor your budget, and reach your financial goals."
                 : "Catat pengeluaran, pantau budget,\ndan capai tujuan finansialmu.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                languageButton(code: "id", title: "ID  Indonesia")
                languageButton(code: "en", title: "EN  English")
            }
            .padding(.top, 6)

            primaryButton(isEnglish ? "Start Setup →" : "Mulai Setup →") {
                go(to: 1)
            }
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 15) {
            stepLabel(2)
            Text(isEnglish ? "What's your\nname?" : "Siapa\nnamamu?")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.primary)

            Text(isEnglish ? "So greetings feel more personal." : "Biar sapaan lebih personal.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            TextField(isEnglish ? "e.g. Pickles..." : "Contoh: Pickles...", text: $name)
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(name.isEmpty ? Color.secondary.opacity(0.15) : accent, lineWidth: 1.5))

            primaryButton(isEnglish ? "Next →" : "Lanjut →") {
                go(to: 2)
            }

            secondaryButton(isEnglish ? "Skip" : "Lewati") {
                go(to: 2)
            }
        }
    }

    private var incomeStep: some View {
        VStack(alignment: .leading, spacing: 15) {
            stepLabel(3)
            Text(isEnglish ? "Monthly\nincome?" : "Pemasukan\nbulan ini?")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.primary)

            Text(isEnglish ? "You can change this anytime." : "Bisa diubah kapan saja di Pengaturan.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text("Rp")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.secondary)
                TextField("5.000.000", text: $income)
                    .keyboardType(.numberPad)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(income.isEmpty ? Color.secondary.opacity(0.15) : accent, lineWidth: 1.5))

            if let value = parsedIncome, value > 0 {
                Text("= \(rupiah(value))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accent)
            }

            primaryButton(isEnglish ? "Next →" : "Lanjut →") {
                go(to: 3)
            }

            secondaryButton(isEnglish ? "← Back" : "← Kembali") {
                go(to: 1)
            }
        }
    }

    private var appearanceStep: some View {
        VStack(alignment: .leading, spacing: 15) {
            stepLabel(4)
            Text(isEnglish ? "Choose your\nlook" : "Pilih\ntampilan")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.primary)

            Text(isEnglish ? "You can change this anytime in Settings." : "Bisa diganti kapan saja di Pengaturan.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Text(isEnglish ? "DISPLAY MODE" : "MODE TAMPILAN")
                .font(.system(size: 10, weight: .black))
                .tracking(1)
                .foregroundStyle(.secondary)

            HStack(spacing: 9) {
                modeButton(title: isEnglish ? "Light" : "Terang", dark: false)
                modeButton(title: isEnglish ? "Dark" : "Gelap", dark: true)
            }

            Text(isEnglish ? "COLOR THEME" : "TEMA WARNA")
                .font(.system(size: 10, weight: .black))
                .tracking(1)
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 12)], alignment: .leading, spacing: 12) {
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
                            .overlay(Circle().stroke(themePreset == preset.id ? Color(hex: preset.accent) : .clear, lineWidth: 3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isEnglish ? preset.nameEN : preset.nameID)
                }

                Button {
                    themePreset = "custom"
                    showCustomColors.toggle()
                } label: {
                    Circle()
                        .fill(themePreset == "custom" ? Color(hex: customPrimary) : Color.gray)
                        .frame(width: 44, height: 44)
                        .overlay(Image(systemName: "paintpalette.fill").foregroundStyle(.white))
                        .overlay(Circle().stroke(themePreset == "custom" ? Color(hex: customAccent) : .clear, lineWidth: 3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isEnglish ? "Custom color" : "Warna kustom")
            }

            if themePreset == "custom" || showCustomColors {
                VStack(spacing: 10) {
                    ColorPicker(isEnglish ? "Primary color" : "Warna utama", selection: primaryBinding)
                    ColorPicker(isEnglish ? "Accent color" : "Warna aksen", selection: accentBinding)
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            }

            primaryButton(isEnglish ? "Done, Let's Go!" : "Selesai, Mulai!") {
                finish()
            }

            secondaryButton(isEnglish ? "← Back" : "← Kembali") {
                go(to: 2)
            }
        }
    }

    private func stepLabel(_ number: Int) -> some View {
        Text(isEnglish ? "STEP \(number) / 4" : "LANGKAH \(number) / 4")
            .font(.system(size: 11, weight: .black))
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
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(selected ? accent : Color.primary.opacity(0.65))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(selected ? accent.opacity(0.12) : Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? accent : Color.secondary.opacity(0.15), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private func modeButton(title: String, dark: Bool) -> some View {
        let selected = isDark == dark
        return Button {
            isDark = dark
        } label: {
            HStack(spacing: 8) {
                Image(systemName: dark ? "moon.fill" : "sun.max.fill")
                Text(title)
                if selected { Image(systemName: "checkmark.circle.fill") }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(selected ? accent : Color.primary.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(selected ? accent.opacity(0.12) : Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? accent : Color.secondary.opacity(0.15), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient(colors: [accent, primary], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var parsedIncome: Int64? {
        Int64(income.filter(\.isNumber))
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
