import SwiftUI
import UserNotifications

private struct NativeRecurringItem: Codable, Identifiable, Equatable {
    var id: Int64
    var description: String
    var amount: Int64
    var category: String
    var day: Int
    var autoApply: Bool

    enum CodingKeys: String, CodingKey {
        case id, description, amount, category, day, autoApply
    }

    init(id: Int64, description: String, amount: Int64, category: String = "food", day: Int = 1, autoApply: Bool = true) {
        self.id = id
        self.description = description
        self.amount = amount
        self.category = category
        self.day = day
        self.autoApply = autoApply
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let number = try? values.decode(Int64.self, forKey: .id) {
            id = number
        } else if let number = try? values.decode(Double.self, forKey: .id) {
            id = Int64(number)
        } else {
            id = Int64(Date().timeIntervalSince1970 * 1000)
        }
        description = (try? values.decode(String.self, forKey: .description)) ?? ""
        if let number = try? values.decode(Int64.self, forKey: .amount) {
            amount = number
        } else if let text = try? values.decode(String.self, forKey: .amount) {
            amount = Int64(text.filter(\.isNumber)) ?? 0
        } else {
            amount = 0
        }
        category = (try? values.decode(String.self, forKey: .category)) ?? "food"
        if let number = try? values.decode(Int.self, forKey: .day) {
            day = number
        } else if let text = try? values.decode(String.self, forKey: .day) {
            day = Int(text) ?? 1
        } else {
            day = 1
        }
        autoApply = (try? values.decode(Bool.self, forKey: .autoApply)) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(description, forKey: .description)
        try values.encode(amount, forKey: .amount)
        try values.encode(category, forKey: .category)
        try values.encode(day, forKey: .day)
        try values.encode(autoApply, forKey: .autoApply)
    }
}

struct RecurringTransactionsSection: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_income") private var incomeRaw = "5000000"
    @AppStorage("gm_recurring") private var recurringRaw = "[]"
    @AppStorage("gm_recurring_income") private var recurringIncomeRaw = "[]"
    @AppStorage("gm_notif") private var notificationsEnabled = "0"

    @State private var recurring: [NativeRecurringItem] = []
    @State private var recurringIncome: [NativeRecurringItem] = []
    @State private var loaded = false
    @State private var showRecurring = false
    @State private var showRecurringIncome = false
    @State private var showInstallments = false
    @State private var showSplitBills = false

    @State private var editingRecurringID: Int64?
    @State private var recurringName = ""
    @State private var recurringAmount = ""
    @State private var recurringCategory = "food"
    @State private var recurringDay = "1"
    @State private var recurringAutoApply = true

    @State private var editingIncomeID: Int64?
    @State private var incomeName = ""
    @State private var incomeAmount = ""
    @State private var incomeDay = "1"
    @State private var incomeAutoApply = true

    private var isEnglish: Bool { language == "en" }
    private var accent: Color { AppAppearance.accent }
    private var primary: Color { AppAppearance.primary }
    private var todayDay: Int { Calendar.current.component(.day, from: .now) }
    private var pendingManualCount: Int { recurring.filter { !$0.autoApply }.count }
    private var unsettledInstallments: Int {
        guard let data = UserDefaults.standard.string(forKey: "gm_cicilan")?.data(using: .utf8),
              let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return 0 }
        return items.count
    }

    var body: some View {
        VStack(spacing: 10) {
            utilityLinks
            recurringExpenseSection
            recurringIncomeSection
        }
        .onAppear(perform: load)
        .onChange(of: recurring) { _, value in persist(value, key: "gm_recurring") }
        .onChange(of: recurringIncome) { _, value in persist(value, key: "gm_recurring_income") }
        .sheet(isPresented: $showInstallments) {
            SettingsCicilanSheet()
        }
        .sheet(isPresented: $showSplitBills) {
            NativeSplitBillsSheet()
        }
    }

    private var utilityLinks: some View {
        HStack(spacing: 0) {
            Button { showInstallments = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 11, weight: .semibold))
                    Text(isEnglish ? "INSTALLMENTS" : "CICILAN")
                        .font(MeowlettTypography.font(size: 10, weight: .black))
                        .tracking(1)
                    if unsettledInstallments > 0 {
                        Text("\(unsettledInstallments)")
                            .font(MeowlettTypography.font(size: 9, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(accent, in: Capsule())
                    }
                }
                .foregroundStyle(accent)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(AppAppearance.border(dark: isDark))
                .frame(width: 1, height: 16)

            Button { showSplitBills = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .font(.system(size: 11, weight: .semibold))
                    Text(isEnglish ? "SPLIT BILLS" : "PATUNGAN")
                        .font(MeowlettTypography.font(size: 10, weight: .black))
                        .tracking(1)
                }
                .foregroundStyle(accent)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 3)
    }

    private var recurringExpenseSection: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showRecurring.toggle() }
            } label: {
                HStack(spacing: 9) {
                    Rectangle().fill(AppAppearance.border(dark: isDark)).frame(height: 1)
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                            .font(.system(size: 11, weight: .semibold))
                        Text(isEnglish ? "RECURRING TRANSACTIONS" : "TRANSAKSI RUTIN")
                            .font(MeowlettTypography.font(size: 10, weight: .black))
                            .tracking(1)
                            .fixedSize()
                        if pendingManualCount > 0 {
                            Text("\(pendingManualCount)")
                                .font(MeowlettTypography.font(size: 9, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#ef4444"), in: Capsule())
                        }
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .rotationEffect(.degrees(showRecurring ? 180 : 0))
                    }
                    .foregroundStyle(.secondary)
                    Rectangle().fill(AppAppearance.border(dark: isDark)).frame(height: 1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showRecurring {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 7) {
                        Image(systemName: "repeat").foregroundStyle(accent)
                        Text(isEnglish ? "Add recurring transaction" : "Tambah Transaksi Rutin")
                            .font(MeowlettTypography.font(size: 13, weight: .heavy))
                        Spacer()
                    }
                    recurringExpenseForm

                    if recurring.isEmpty {
                        emptyMessage(
                            symbol: "repeat",
                            title: isEnglish ? "No recurring transactions yet" : "Belum ada transaksi rutin"
                        )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(recurring) { item in
                                recurringExpenseRow(item)
                                if item.id != recurring.last?.id {
                                    Divider().overlay(AppAppearance.border(dark: isDark))
                                }
                            }
                        }
                    }
                }
                .padding(15)
                .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var recurringIncomeSection: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showRecurringIncome.toggle() }
            } label: {
                HStack(spacing: 9) {
                    Rectangle().fill(Color(hex: "#4ade80").opacity(0.25)).frame(height: 1)
                    HStack(spacing: 6) {
                        Image(systemName: "banknote")
                            .font(.system(size: 11, weight: .semibold))
                        Text(isEnglish ? "RECURRING INCOME" : "PEMASUKAN RUTIN")
                            .font(MeowlettTypography.font(size: 10, weight: .black))
                            .tracking(1)
                            .fixedSize()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .rotationEffect(.degrees(showRecurringIncome ? 180 : 0))
                    }
                    .foregroundStyle(Color(hex: "#4ade80"))
                    Rectangle().fill(Color(hex: "#4ade80").opacity(0.25)).frame(height: 1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showRecurringIncome {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 7) {
                        Image(systemName: "banknote").foregroundStyle(Color(hex: "#4ade80"))
                        Text(isEnglish ? "Add recurring income" : "Tambah Pemasukan Rutin")
                            .font(MeowlettTypography.font(size: 13, weight: .heavy))
                        Spacer()
                    }
                    recurringIncomeForm

                    if recurringIncome.isEmpty {
                        emptyMessage(
                            symbol: "banknote",
                            title: isEnglish ? "No recurring income yet" : "Belum ada pemasukan rutin",
                            tint: Color(hex: "#4ade80")
                        )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(recurringIncome) { item in
                                recurringIncomeRow(item)
                                if item.id != recurringIncome.last?.id {
                                    Divider().overlay(Color(hex: "#4ade80").opacity(0.18))
                                }
                            }
                        }
                    }
                }
                .padding(15)
                .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#4ade80").opacity(0.20), lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var recurringExpenseForm: some View {
        VStack(spacing: 9) {
            TextField(isEnglish ? "Name (e.g. Internet, Subscription...)" : "Nama (mis: Internet, Langganan...)", text: $recurringName)
                .font(MeowlettTypography.font(size: 13, weight: .medium))
                .padding(12)
                .background(inputBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(inputBorder, lineWidth: 1.2))

            HStack(spacing: 8) {
                TextField("1.000.000", text: $recurringAmount)
                    .keyboardType(.numberPad)
                    .font(MeowlettTypography.font(size: 14, weight: .bold))
                    .padding(12)
                    .background(inputBackground, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(inputBorder, lineWidth: 1.2))
                VStack(alignment: .leading, spacing: 3) {
                    Text(isEnglish ? "DAY" : "TANGGAL")
                        .font(MeowlettTypography.font(size: 9, weight: .heavy))
                        .foregroundStyle(.secondary)
                    TextField("1", text: $recurringDay)
                        .keyboardType(.numberPad)
                        .font(MeowlettTypography.font(size: 14, weight: .bold))
                        .padding(12)
                        .background(inputBackground, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(inputBorder, lineWidth: 1.2))
                        .frame(width: 78)
                }
            }

            Picker(isEnglish ? "Category" : "Kategori", selection: $recurringCategory) {
                ForEach(MeowlettCategory.all, id: \.id) { item in
                    Text(language == "en" ? item.enName : item.idName).tag(item.id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(inputBackground, in: RoundedRectangle(cornerRadius: 12))

            autoApplyToggle(isOn: $recurringAutoApply, tint: accent)

            HStack(spacing: 8) {
                Button {
                    saveRecurringExpense()
                } label: {
                    Label(editingRecurringID == nil ? (isEnglish ? "Add recurring" : "Tambah Rutin") : (isEnglish ? "Save changes" : "Simpan"), systemImage: editingRecurringID == nil ? "plus" : "checkmark")
                        .font(MeowlettTypography.font(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(LinearGradient(colors: [accent, primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
                .disabled(recurringName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedRecurringAmount <= 0)

                if editingRecurringID != nil {
                    Button(isEnglish ? "Cancel" : "Batal") { resetRecurringDraft() }
                        .font(MeowlettTypography.font(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var recurringIncomeForm: some View {
        VStack(spacing: 9) {
            TextField(isEnglish ? "Name (e.g. Salary, Freelance...)" : "Nama (mis: Gaji, Freelance...)", text: $incomeName)
                .font(MeowlettTypography.font(size: 13, weight: .medium))
                .padding(12)
                .background(inputBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#4ade80").opacity(0.32), lineWidth: 1.2))

            HStack(spacing: 8) {
                TextField("5.000.000", text: $incomeAmount)
                    .keyboardType(.numberPad)
                    .font(MeowlettTypography.font(size: 14, weight: .bold))
                    .padding(12)
                    .background(inputBackground, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#4ade80").opacity(0.32), lineWidth: 1.2))
                VStack(alignment: .leading, spacing: 3) {
                    Text(isEnglish ? "DAY" : "TANGGAL")
                        .font(MeowlettTypography.font(size: 9, weight: .heavy))
                        .foregroundStyle(.secondary)
                    TextField("1", text: $incomeDay)
                        .keyboardType(.numberPad)
                        .font(MeowlettTypography.font(size: 14, weight: .bold))
                        .padding(12)
                        .background(inputBackground, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#4ade80").opacity(0.32), lineWidth: 1.2))
                        .frame(width: 78)
                }
            }

            autoApplyToggle(isOn: $incomeAutoApply, tint: Color(hex: "#4ade80"))

            Button {
                saveRecurringIncome()
            } label: {
                Label(editingIncomeID == nil ? (isEnglish ? "Add income" : "Tambah Pemasukan") : (isEnglish ? "Save changes" : "Simpan"), systemImage: editingIncomeID == nil ? "plus" : "checkmark")
                    .font(MeowlettTypography.font(size: 12, weight: .heavy))
                    .foregroundStyle(Color(hex: "#052e16"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color(hex: "#4ade80"), in: RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)
            .disabled(incomeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedIncomeAmount <= 0)
        }
    }

    private func recurringExpenseRow(_ item: NativeRecurringItem) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 11)
                .fill(MeowlettCategory.color(for: item.category).opacity(0.16))
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: MeowlettCategory.all.first(where: { $0.id == item.category })?.icon ?? "repeat")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(MeowlettCategory.color(for: item.category))
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.description)
                    .font(MeowlettTypography.font(size: 12, weight: .bold))
                    .lineLimit(1)
                Text("\(MeowlettCategory.name(for: item.category, language: language)) · \(isEnglish ? "Day" : "Tgl") \(item.day) · \(item.autoApply ? (isEnglish ? "Auto" : "Otomatis") : (isEnglish ? "Manual" : "Manual"))")
                    .font(MeowlettTypography.font(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 5) {
                Text("-\(rupiah(item.amount))")
                    .font(MeowlettTypography.font(size: 12, weight: .heavy))
                    .foregroundStyle(Color(hex: "#f87171"))
                HStack(spacing: 5) {
                    if !item.autoApply {
                        smallAction(isEnglish ? "Record" : "Catat", tint: accent) { recordRecurringExpense(item) }
                    }
                    smallIconAction("pencil", tint: .secondary) { editRecurringExpense(item) }
                    smallIconAction("trash", tint: Color(hex: "#f87171")) { recurring.removeAll { $0.id == item.id } }
                }
            }
        }
        .padding(.vertical, 11)
    }

    private func recurringIncomeRow(_ item: NativeRecurringItem) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 11)
                .fill(Color(hex: "#4ade80").opacity(0.15))
                .frame(width: 38, height: 38)
                .overlay(Image(systemName: "banknote").font(.system(size: 17, weight: .semibold)).foregroundStyle(Color(hex: "#4ade80")))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.description)
                    .font(MeowlettTypography.font(size: 12, weight: .bold))
                    .lineLimit(1)
                Text("\(isEnglish ? "Day" : "Tgl") \(item.day) · \(item.autoApply ? (isEnglish ? "Auto" : "Otomatis") : "Manual")")
                    .font(MeowlettTypography.font(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 5) {
                Text("+\(rupiah(item.amount))")
                    .font(MeowlettTypography.font(size: 12, weight: .heavy))
                    .foregroundStyle(Color(hex: "#4ade80"))
                HStack(spacing: 5) {
                    if !item.autoApply {
                        smallAction(isEnglish ? "Record" : "Catat", tint: Color(hex: "#4ade80")) { recordRecurringIncome(item) }
                    }
                    smallIconAction("pencil", tint: .secondary) { editRecurringIncome(item) }
                    smallIconAction("trash", tint: Color(hex: "#f87171")) { recurringIncome.removeAll { $0.id == item.id } }
                }
            }
        }
        .padding(.vertical, 11)
    }

    private var isDark: Bool { colorScheme == .dark }
    private var inputBackground: Color { AppAppearance.input(dark: isDark) }
    private var inputBorder: Color { AppAppearance.inputBorder(dark: isDark) }
    private var parsedRecurringAmount: Int64 { Int64(recurringAmount.filter(\.isNumber)) ?? 0 }
    private var parsedIncomeAmount: Int64 { Int64(incomeAmount.filter(\.isNumber)) ?? 0 }

    private func autoApplyToggle(isOn: Binding<Bool>, tint: Color) -> some View {
        Toggle(isEnglish ? "Automatically record on due day" : "Catat otomatis pada tanggal jatuh tempo", isOn: isOn)
            .font(MeowlettTypography.font(size: 11, weight: .semibold))
            .tint(tint)
            .padding(11)
            .background(inputBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func emptyMessage(symbol: String, title: String, tint: Color? = nil) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(tint ?? accent)
            Text(title)
                .font(MeowlettTypography.font(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func smallAction(_ title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(MeowlettTypography.font(size: 9, weight: .heavy))
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(tint.opacity(0.30), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func smallIconAction(_ symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 25)
                .background(Color.primary.opacity(isDark ? 0.07 : 0.05), in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    private func load() {
        guard !loaded else { return }
        if let data = recurringRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([NativeRecurringItem].self, from: data) {
            recurring = decoded
        }
        if let data = recurringIncomeRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([NativeRecurringItem].self, from: data) {
            recurringIncome = decoded
        }
        loaded = true
        applyAutomaticRecurringExpenses()
    }

    private func persist(_ items: [NativeRecurringItem], key: String) {
        guard loaded, let data = try? JSONEncoder().encode(items),
              let json = String(data: data, encoding: .utf8) else { return }
        if key == "gm_recurring" { recurringRaw = json }
        else { recurringIncomeRaw = json }
    }

    private func applyAutomaticRecurringExpenses() {
        let now = Date.now
        let day = Calendar.current.component(.day, from: now)
        for item in recurring where item.autoApply && item.day == day {
            let alreadyAdded = store.transactions.contains {
                Calendar.current.isDate($0.date, inSameDayAs: now) &&
                $0.description == item.description && $0.amount == item.amount &&
                $0.location == "Rutin"
            }
            if !alreadyAdded {
                store.add(MeowlettTransaction(date: now, amount: item.amount, category: item.category, description: item.description, location: "Rutin", note: "Otomatis"))
                if notificationsEnabled == "1" {
                    postNotification(title: isEnglish ? "Auto-recorded" : "Tercatat Otomatis",
                                     body: "\(item.description) · \(rupiah(item.amount))")
                }
            }
        }
    }

    private func recordRecurringExpense(_ item: NativeRecurringItem) {
        store.add(MeowlettTransaction(date: .now, amount: item.amount, category: item.category, description: item.description, location: "Rutin", note: "Manual"))
    }

    private func recordRecurringIncome(_ item: NativeRecurringItem) {
        let current = Int64(incomeRaw.filter(\.isNumber)) ?? 0
        incomeRaw = String(current + item.amount)
    }

    private func editRecurringExpense(_ item: NativeRecurringItem) {
        editingRecurringID = item.id
        recurringName = item.description
        recurringAmount = String(item.amount)
        recurringCategory = item.category
        recurringDay = String(item.day)
        recurringAutoApply = item.autoApply
    }

    private func editRecurringIncome(_ item: NativeRecurringItem) {
        editingIncomeID = item.id
        incomeName = item.description
        incomeAmount = String(item.amount)
        incomeDay = String(item.day)
        incomeAutoApply = item.autoApply
    }

    private func saveRecurringExpense() {
        let name = recurringName.trimmingCharacters(in: .whitespacesAndNewlines)
        let amount = parsedRecurringAmount
        guard !name.isEmpty, amount > 0 else { return }
        let id = editingRecurringID ?? Int64(Date().timeIntervalSince1970 * 1000)
        let item = NativeRecurringItem(id: id, description: name, amount: amount, category: recurringCategory,
                                       day: min(31, max(1, Int(recurringDay) ?? 1)), autoApply: recurringAutoApply)
        if editingRecurringID == nil { recurring.append(item) }
        else if let index = recurring.firstIndex(where: { $0.id == id }) { recurring[index] = item }
        resetRecurringDraft()
    }

    private func saveRecurringIncome() {
        let name = incomeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let amount = parsedIncomeAmount
        guard !name.isEmpty, amount > 0 else { return }
        let id = editingIncomeID ?? Int64(Date().timeIntervalSince1970 * 1000)
        let item = NativeRecurringItem(id: id, description: name, amount: amount, category: "income",
                                       day: min(31, max(1, Int(incomeDay) ?? 1)), autoApply: incomeAutoApply)
        if editingIncomeID == nil { recurringIncome.append(item) }
        else if let index = recurringIncome.firstIndex(where: { $0.id == id }) { recurringIncome[index] = item }
        resetIncomeDraft()
    }

    private func resetRecurringDraft() {
        editingRecurringID = nil
        recurringName = ""
        recurringAmount = ""
        recurringCategory = "food"
        recurringDay = "1"
        recurringAutoApply = true
    }

    private func resetIncomeDraft() {
        editingIncomeID = nil
        incomeName = ""
        incomeAmount = ""
        incomeDay = "1"
        incomeAutoApply = true
    }

    private func rupiah(_ amount: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "Rp \(amount)"
    }

    private func postNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: "meowlett-recurring-\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
