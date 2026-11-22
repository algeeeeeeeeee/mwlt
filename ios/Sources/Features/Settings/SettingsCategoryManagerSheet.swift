import SwiftUI

struct SettingsCategoryManagerSheet: View {
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_categories") private var categoriesRaw = ""
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("gm_category_order") private var categoryOrderRaw = "[]"
    @State private var categories: [String: MeowlettCategoryDefinition] = [:]
    @State private var categoryOrder: [String] = []
    @State private var loaded = false
    @State private var editingKey: String?
    @State private var label = ""
    @State private var icon = "package"
    @State private var color = "#94a3b8"

    private var isEnglish: Bool { language == "en" }
    private var isDark: Bool { colorScheme == .dark }
    private var categoryBackground: Color {
        isDark ? AppAppearance.card2(dark: true) : AppAppearance.background(dark: false)
    }
    private var categoryItemBackground: Color {
        isDark ? AppAppearance.card(dark: true) : AppAppearance.card2(dark: false)
    }
    private var categoryItemBorder: Color {
        Color(hex: isDark ? "#272727" : "#eeeeee")
    }
    private var orderedKeys: [String] {
        let present = categoryOrder.filter { categories[$0] != nil }
        let missing = categories.keys.filter { !present.contains($0) }.sorted()
        return present + missing
    }
    private let colors = [
        "#4ade80","#86efac","#f9a8d4","#a3e635","#34d399","#6ee7b7",
        "#fbbf24","#94a3b8","#60a5fa","#f87171","#c084fc","#fb923c",
        "#38bdf8","#e879f9","#facc15"
    ]
    private let icons: [(String,String)] = [
        ("utensils","fork.knife"),("coffee","cup.and.saucer.fill"),("pizza","takeoutbag.and.cup.and.straw.fill"),("beer","mug.fill"),
        ("car","car.fill"),("plane","airplane"),("shoppingbag","bag.fill"),("shirt","tshirt.fill"),
        ("palette","paintpalette.fill"),("gift","gift.fill"),("heart","heart.fill"),("pill","pills.fill"),
        ("dumbbell","dumbbell.fill"),("dollar","dollarsign.circle.fill"),("banknote","banknote"),
        ("wallet","wallet.bifold.fill"),("piggybank","banknote"),("trendingup","chart.line.uptrend.xyaxis"),
        ("coins","coins"),("home","house.fill"),("droplets","drop.fill"),("zap","bolt.fill"),
        ("wrench","wrench.fill"),("flame","flame.fill"),("wind","wind"),("monitor","desktopcomputer"),
        ("smartphone","iphone"),("laptop","laptopcomputer"),("gamepad","gamecontroller.fill"),
        ("music","music.note"),("film","film.fill"),("book","book.fill"),("leaf","leaf.fill"),
        ("pawprint","pawprint.fill"),("flower","flower"),("umbrella","umbrella.fill"),
        ("package","shippingbox.fill"),("filetext","doc.text.fill"),("sparkles","sparkles"),
        ("target","scope"),("repeat","repeat"),("inbox","tray.fill"),("users","person.2.fill"),
        ("clock","clock.fill"),("calendar","calendar"),("alarmclock","alarm.fill"),
        ("bell","bell.fill"),("tag","tag.fill"),("receipt","receipt")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEnglish ? "Manage Categories" : "Kelola Kategori")
                    .font(MeowlettTypography.font(size: 16, weight: .heavy))
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    editingKey = nil
                    label = ""
                    icon = "package"
                    color = "#94a3b8"
                    dismiss()
                } label: {
                    Text(isEnglish ? "Done" : "Selesai")
                        .font(MeowlettTypography.font(size: 13, weight: .bold))
                        .foregroundStyle(isDark ? Color(hex: "#e5e7eb") : Color(hex: "#374151"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(categoryBackground, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    editorCard(existingKey: editingKey)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(isEnglish ? "ACTIVE CATEGORIES (\(categories.count))" : "KATEGORI AKTIF (\(categories.count))")
                            .font(MeowlettTypography.font(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 6) {
                            ForEach(orderedKeys, id: \.self) { key in
                                categoryRow(key)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity)
        .background(AppAppearance.modal(dark: isDark))
        .presentationDetents([.fraction(0.85)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(22)
        .onAppear(perform: load)
        .onChange(of: categoriesRaw) { _, value in
            guard loaded, !value.isEmpty,
                  let data = value.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String: MeowlettCategoryDefinition].self, from: data) else { return }
            categories = decoded
            categoryOrder = MeowlettCategory.orderedKeys(
                fromJSON: value,
                availableKeys: Set(decoded.keys),
                storedOrderJSON: categoryOrderRaw
            )
        }
    }

    private func categoryRow(_ key: String) -> some View {
        guard let item = categories[key] else {
            return AnyView(EmptyView())
        }
        let catColor = Color(hex: item.color)
        let transactionCount = store.transactions.filter { $0.category == key }.count

        return AnyView(
            HStack(spacing: 11) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(catColor.opacity(0.20))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: MeowlettCategoryDefinition(
                            label: item.label,
                            labelId: item.labelId,
                            icon: item.icon,
                            color: item.color
                        ).displayIcon)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(catColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(isEnglish ? item.label : (item.labelId ?? item.label))
                        .font(MeowlettTypography.font(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("\(transactionCount) \(isEnglish ? "transactions" : "transaksi")")
                        .font(MeowlettTypography.font(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 4)

                HStack(spacing: 6) {
                    Button {
                        editingKey = key
                        label = item.label
                        icon = item.icon
                        color = item.color
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(isDark ? Color(hex: "#e5e7eb") : Color(hex: "#374151"))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(categoryBackground, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppAppearance.border(dark: isDark), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)

                    Button {
                        guard categories.count > 1 else { return }
                        categories.removeValue(forKey: key)
                        categoryOrder.removeAll { $0 == key }
                        if editingKey == key {
                            editingKey = nil
                            label = ""
                            icon = "package"
                            color = "#94a3b8"
                        }
                        persist()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(isDark ? Color(hex: "#f87171") : Color(hex: "#e11d48"))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Color(hex: isDark ? "#1f0a0a" : "#fff1f2"), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: isDark ? "#3d1414" : "#fecdd3"), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(categoryItemBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(categoryItemBorder, lineWidth: 1))
        )
    }

    private func editorCard(existingKey: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(existingKey == nil
                 ? (isEnglish ? "Add Category" : "Tambah Kategori")
                 : (isEnglish ? "Edit Category" : "Edit Kategori"))
                .font(MeowlettTypography.font(size: 13, weight: .heavy))
                .foregroundStyle(.primary)
                .padding(.bottom, 11)

            TextField(isEnglish ? "Category name..." : "Nama kategori...", text: $label)
                .font(MeowlettTypography.font(size: 14, weight: .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(AppAppearance.input(dark: isDark), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppAppearance.inputBorder(dark: isDark), lineWidth: 1.5))
                .padding(.bottom, 11)

            Text(isEnglish ? "Choose Icon:" : "Pilih Ikon:")
                .font(MeowlettTypography.font(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 7)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                ForEach(Array(icons.enumerated()), id: \.offset) { _, item in
                    let selected = icon == item.0
                    Button { icon = item.0 } label: {
                        Image(systemName: item.1)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(selected ? Color(hex: color) : AppAppearance.textSub(dark: isDark))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(selected ? Color(hex: color).opacity(0.13) : categoryBackground, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color(hex: color) : .clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 11)

            Text(isEnglish ? "Choose Colour:" : "Pilih Warna:")
                .font(MeowlettTypography.font(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 7)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 28), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(colors, id: \.self) { value in
                    Button { color = value } label: {
                        Circle()
                            .fill(Color(hex: value))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(selectedColor(value) ? primaryColor : .clear, lineWidth: 3))
                            .scaleEffect(selectedColor(value) ? 1.08 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 8)

            HStack(spacing: 8) {
                ColorPicker("", selection: Binding(
                    get: { Color(hex: color) },
                    set: { color = $0.meowlettHex }
                ))
                .labelsHidden()
                .frame(width: 36, height: 36)
                .padding(2)
                .background(AppAppearance.input(dark: isDark), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppAppearance.border(dark: isDark), lineWidth: 1.5))

                Text(isEnglish ? "or custom" : "Warna Custom")
                    .font(MeowlettTypography.font(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Image(systemName: icons.first(where: { $0.0 == icon })?.1 ?? "shippingbox.fill")
                        .font(.system(size: 16, weight: .regular))
                    Text(label.isEmpty ? "Preview" : label)
                        .font(MeowlettTypography.font(size: 12, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundStyle(Color(hex: color))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: color).opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: color).opacity(0.27), lineWidth: 1.5))
            }
            .padding(.bottom, 12)

            HStack(spacing: 8) {
                Button {
                    saveCategory(existingKey: existingKey)
                } label: {
                    Text(isEnglish ? (existingKey == nil ? "Add" : "Save") : (existingKey == nil ? "Tambah" : "Simpan"))
                        .font(MeowlettTypography.font(size: 14, weight: .heavy))
                        .tracking(0.3)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(Color(hex: AppAppearance.accentHex), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                if existingKey != nil {
                    Button {
                        editingKey = nil
                        label = ""
                        icon = "package"
                        color = "#94a3b8"
                    } label: {
                        Text(isEnglish ? "Cancel" : "Batal")
                            .font(MeowlettTypography.font(size: 14, weight: .bold))
                            .foregroundStyle(isDark ? Color(hex: "#e5e7eb") : Color(hex: "#374151"))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(categoryBackground, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppAppearance.border(dark: isDark), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(categoryBackground, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppAppearance.border(dark: isDark), lineWidth: 1.5))
    }

    private var primaryColor: Color {
        Color(hex: AppAppearance.primaryHex)
    }

    private func selectedColor(_ value: String) -> Bool {
        color.caseInsensitiveCompare(value) == .orderedSame
    }

    private func load() {
        guard !loaded else { return }
        if !categoriesRaw.isEmpty,
           let data = categoriesRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: MeowlettCategoryDefinition].self, from: data) {
            categories = decoded
        } else {
            categories = [
                "food": .init(label: "Food & Drinks", labelId: "Makan & Minum", icon: "utensils", color: "#4ade80"),
                "transport": .init(label: "Transport", labelId: "Transportasi", icon: "car", color: "#60a5fa"),
                "date": .init(label: "Date", labelId: "Date", icon: "heart", color: "#f9a8d4"),
                "shopping": .init(label: "Shopping", labelId: "Belanja", icon: "shoppingbag", color: "#f97316"),
                "entertainment": .init(label: "Entertainment", labelId: "Hiburan", icon: "gamepad", color: "#c084fc"),
                "health": .init(label: "Health", labelId: "Kesehatan", icon: "pill", color: "#f87171"),
                "bills": .init(label: "Bills", labelId: "Tagihan", icon: "filetext", color: "#fbbf24"),
                "pets": .init(label: "Pets", labelId: "Hewan Peliharaan", icon: "pawprint", color: "#fb923c"),
                "other": .init(label: "Other", labelId: "Lainnya", icon: "package", color: "#94a3b8")
            ]
        }
        categoryOrder = MeowlettCategory.orderedKeys(
            fromJSON: categoriesRaw,
            availableKeys: Set(categories.keys),
            storedOrderJSON: categoryOrderRaw
        )
        loaded = true
        persist()
    }

    private func saveCategory(existingKey: String?) {
        let clean = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        if let existingKey {
            let defaultName = ["food":"Makan & Minum","transport":"Transportasi","date":"Date","shopping":"Belanja","entertainment":"Hiburan","health":"Kesehatan","bills":"Tagihan","pets":"Hewan Peliharaan","other":"Lainnya"][existingKey]
            let previous = categories[existingKey]
            categories[existingKey] = MeowlettCategoryDefinition(
                label: clean,
                labelId: previous?.labelId ?? defaultName,
                icon: icon,
                color: color
            )
        } else {
            let baseKey = clean.lowercased().split(whereSeparator: { $0.isWhitespace }).joined(separator: "_")
            let key = baseKey + "_" + String(Int64(Date().timeIntervalSince1970 * 1000))
            categories[key] = MeowlettCategoryDefinition(label: clean, labelId: nil, icon: icon, color: color)
            categoryOrder.append(key)
        }

        persist()
        editingKey = nil
        label = ""
        icon = "package"
        color = "#94a3b8"
    }

    private func persist() {
        let currentOrder = orderedKeys
        categoryOrder = currentOrder
        if let orderData = try? JSONEncoder().encode(currentOrder),
           let orderValue = String(data: orderData, encoding: .utf8) {
            categoryOrderRaw = orderValue
        }
        guard let data = try? JSONEncoder().encode(categories),
              let value = String(data: data, encoding: .utf8) else { return }
        categoriesRaw = value
    }
}
