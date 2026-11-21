import SwiftUI

struct SettingsCategoryManagerSheet: View {
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_categories") private var categoriesRaw = ""
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var categories: [String: MeowlettCategoryDefinition] = [:]
    @State private var loaded = false
    @State private var editingKey: String?
    @State private var label = ""
    @State private var icon = "package"
    @State private var color = "#94a3b8"

    private var isEnglish: Bool { language == "en" }
    private var orderedKeys: [String] {
        let builtIn = ["food","transport","date","shopping","entertainment","health","bills","pets","other"]
        return builtIn.filter { categories[$0] != nil } + categories.keys.filter { !builtIn.contains($0) }.sorted()
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
            Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 36, height: 4).padding(.top, 12)
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppAppearance.accent)
                Text(isEnglish ? "Manage categories" : "Kelola Kategori")
                    .font(MeowlettTypography.font(size: 16, weight: .black))
                Spacer()
                if editingKey == nil {
                    Button {
                        editingKey = ""
                        label = ""
                        icon = "package"
                        color = "#94a3b8"
                    } label: {
                        Label(isEnglish ? "Add" : "Tambah", systemImage: "plus")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(LinearGradient(colors: [AppAppearance.accent, AppAppearance.primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary).frame(width: 30, height: 30)
                        .background(Color(uiColor: .secondarySystemBackground), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            Divider().opacity(0.45)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if let key = editingKey {
                        editorCard(existingKey: key.isEmpty ? nil : key)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(isEnglish ? "ACTIVE CATEGORIES (\(categories.count))" : "KATEGORI AKTIF (\(categories.count))")
                                .font(MeowlettTypography.font(size: 10, weight: .heavy)).tracking(0.6).foregroundStyle(.secondary)
                                .padding(.horizontal, 3)
                            ForEach(orderedKeys, id: \.self) { key in
                                categoryRow(key)
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .onAppear(perform: load)
        .onChange(of: categoriesRaw) { _, value in
            guard loaded, !value.isEmpty,
                  let data = value.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String: MeowlettCategoryDefinition].self, from: data) else { return }
            categories = decoded
        }
    }

    private func categoryRow(_ key: String) -> some View {
        let item = categories[key]!
        let isDefault = ["food","transport","date","shopping","entertainment","health","bills","pets","other"].contains(key)
        let catColor = Color(hex: item.color)
        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 11)
                .fill(catColor.opacity(0.15))
                .frame(width: 38, height: 38)
                .overlay(Image(systemName: MeowlettCategoryDefinition(label: item.label, labelId: item.labelId, icon: item.icon, color: item.color).displayIcon)
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(catColor))
            VStack(alignment: .leading, spacing: 2) {
                Text(isEnglish ? item.label : (item.labelId ?? item.label))
                    .font(MeowlettTypography.font(size: 13, weight: .bold))
                Text("\(key) · \(isDefault ? (isEnglish ? "Default category" : "Kategori bawaan") : (isEnglish ? "Custom category" : "Kategori kustom"))")
                    .font(MeowlettTypography.font(size: 10, weight: .medium)).foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 2)
            Button {
                editingKey = key
                label = item.label
                icon = item.icon
                color = item.color
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            Button {
                guard categories.count > 1 else { return }
                categories.removeValue(forKey: key)
                persist()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#ef4444"))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: "#ef4444").opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(categories.count <= 1)
            .opacity(categories.count <= 1 ? 0.35 : 1)
        }
        .padding(11)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.primary.opacity(0.07), lineWidth: 1))
    }

    private func editorCard(existingKey: String?) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text(existingKey == nil
                     ? (isEnglish ? "Add category" : "Tambah Kategori")
                     : (isEnglish ? "Edit category" : "Edit Kategori"))
                    .font(MeowlettTypography.font(size: 14, weight: .black))
                Spacer()
                Button(isEnglish ? "Back" : "Kembali") {
                    editingKey = nil
                }
                .font(MeowlettTypography.font(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            }
            TextField(isEnglish ? "Category name" : "Nama kategori", text: $label)
                .font(MeowlettTypography.font(size: 14, weight: .regular))
                .padding(13)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.primary.opacity(0.08), lineWidth: 1.3))

            Text(isEnglish ? "PICK ICON" : "PILIH IKON")
                .font(MeowlettTypography.font(size: 10, weight: .heavy)).tracking(0.5).foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 7) {
                ForEach(Array(icons.enumerated()), id: \.offset) { _, item in
                    let selected = icon == item.0
                    Button { icon = item.0 } label: {
                        Image(systemName: item.1)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(selected ? Color(hex: color) : Color.secondary)
                            .frame(maxWidth: .infinity).frame(height: 40)
                            .background(selected ? Color(hex: color).opacity(0.16) : Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(selected ? Color(hex: color) : .clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(isEnglish ? "PICK COLOR" : "PILIH WARNA")
                .font(MeowlettTypography.font(size: 10, weight: .heavy)).tracking(0.5).foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 8), spacing: 10) {
                ForEach(colors, id: \.self) { value in
                    Circle()
                        .fill(Color(hex: value))
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(color == value ? Color.white : .clear, lineWidth: 2))
                        .overlay(Circle().stroke(color == value ? Color(hex: value) : .clear, lineWidth: 1.5).padding(-3))
                        .onTapGesture { color = value }
                }
            }

            HStack(spacing: 8) {
                ColorPicker(isEnglish ? "Custom color" : "Warna kustom", selection: Binding(
                    get: { Color(hex: color) },
                    set: { color = $0.meowlettHex }
                ))
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: icons.first(where: { $0.0 == icon })?.1 ?? "shippingbox.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(label.isEmpty ? (isEnglish ? "Preview" : "Pratinjau") : label)
                        .font(MeowlettTypography.font(size: 12, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundStyle(Color(hex: color))
                .padding(.horizontal, 11).padding(.vertical, 8)
                .background(Color(hex: color).opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(Color(hex: color).opacity(0.3), lineWidth: 1))
            }

            HStack(spacing: 8) {
                Button(isEnglish ? "Save" : "Simpan") {
                    saveCategory(existingKey: existingKey)
                }
                .font(MeowlettTypography.font(size: 13, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(LinearGradient(colors: [AppAppearance.accent, AppAppearance.primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 13))
                .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button(isEnglish ? "Cancel" : "Batal") {
                    editingKey = nil
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 96, height: 44)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 13))
            }
        }
        .padding(15)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(Color.primary.opacity(0.07), lineWidth: 1))
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
        }
        persist()
        editingKey = nil
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(categories), let value = String(data: data, encoding: .utf8) else { return }
        categoriesRaw = value
    }
}
