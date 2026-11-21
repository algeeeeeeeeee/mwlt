import SwiftUI

struct TransactionEditorSheet: View {
    let transaction: MeowlettTransaction?
    let initialCategory: String

    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_categories") private var categoriesJSON = ""
    @Environment(\.colorScheme) private var colorScheme

    @State private var descriptionText: String
    @State private var amountText: String
    @State private var category: String
    @State private var date: Date
    @State private var location: String
    @State private var note: String
    @State private var paymentMethod: String
    @State private var showCalculator = false

    private var isEnglish: Bool { language == "en" }
    private var primary: Color { Color(hex: AppAppearance.primaryHex) }
    private var accent: Color { Color(hex: AppAppearance.accentHex) }
    private var dark: Bool { colorScheme == .dark }
    private var amount: Int64 { Int64(amountText.filter(\.isNumber)) ?? 0 }

    init(transaction: MeowlettTransaction? = nil, initialCategory: String = "food") {
        self.transaction = transaction
        self.initialCategory = initialCategory
        _descriptionText = State(initialValue: transaction?.description ?? "")
        _amountText = State(initialValue: transaction.map { Self.formatAmount($0.amount) } ?? "")
        _category = State(initialValue: transaction?.category ?? initialCategory)
        _date = State(initialValue: transaction?.date ?? .now)
        _location = State(initialValue: transaction?.location ?? "")
        _note = State(initialValue: transaction?.note ?? "")
        _paymentMethod = State(initialValue: transaction?.paymentMethod ?? "cash")
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    amountRow
                    dateRow
                    categoryPicker
                    paymentPicker
                    styledField(isEnglish ? "Description" : "Keterangan", text: $descriptionText)
                    HStack(spacing: 8) {
                        styledField(isEnglish ? "Location" : "Lokasi", text: $location)
                        styledField(isEnglish ? "Note" : "Catatan", text: $note)
                    }
                    HStack(spacing: 8) {
                        Button(action: save) {
                            Text(transaction == nil ? (isEnglish ? "+ Add" : "+ Tambah") : (isEnglish ? "Save" : "Simpan"))
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(LinearGradient(colors: [accent, primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amount <= 0)
                        .opacity(descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amount <= 0 ? 0.5 : 1)

                        Button(isEnglish ? "Cancel" : "Batal") { dismiss() }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 110, height: 46)
                            .background(AppAppearance.card2(dark: dark), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                    .padding(.top, 2)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(AppAppearance.modal(dark: dark))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .sheet(isPresented: $showCalculator) {
            AmountCalculatorSheet(initialValue: amount, onApply: { amountText = Self.formatAmount($0) })
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Text(transaction == nil ? (isEnglish ? "New transaction" : "Transaksi baru") : (isEnglish ? "Edit transaction" : "Edit transaksi"))
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 27, height: 27)
                    .background(Color.black.opacity(0.2), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(LinearGradient(colors: [primary, primary.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var amountRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Text("Rp.")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.secondary)
                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .onChange(of: amountText) { _, value in
                        let digits = String(value.filter(\.isNumber))
                        if digits != value { amountText = Self.formatAmount(Int64(digits) ?? 0) }
                    }
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(inputBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(inputBorder, lineWidth: 1.5))
            Button { showCalculator = true } label: {
                Image(systemName: "function")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 46)
                    .background(AppAppearance.card2(dark: dark), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var dateRow: some View {
        HStack(spacing: 9) {
            Image(systemName: "calendar")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accent)
            DatePicker(isEnglish ? "Date" : "Tanggal", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
            Spacer()
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .frame(height: 43)
        .background(inputBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(inputBorder, lineWidth: 1.5))
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(MeowlettCategory.all, id: \.id) { item in
                    let selected = category == item.id
                    let color = Color(hex: item.color)
                    Button { category = item.id } label: {
                        HStack(spacing: 5) {
                            Image(systemName: item.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(language == "en" ? item.enName : item.idName)
                                .font(.system(size: 11, weight: selected ? .bold : .medium))
                                .fixedSize()
                        }
                        .foregroundStyle(selected ? color : Color.secondary)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(selected ? color.opacity(0.13) : AppAppearance.card2(dark: dark), in: Capsule())
                        .overlay(Capsule().stroke(selected ? color : Color.primary.opacity(0.08), lineWidth: selected ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var paymentPicker: some View {
        HStack(spacing: 6) {
            paymentOption("cash", title: isEnglish ? "Cash" : "Tunai", symbol: "banknote")
            paymentOption("transfer", title: isEnglish ? "Transfer" : "Transfer", symbol: "building.columns")
            paymentOption("qris", title: "QRIS", symbol: "qrcode")
        }
    }

    private func paymentOption(_ value: String, title: String, symbol: String) -> some View {
        let selected = paymentMethod == value
        return Button { paymentMethod = value } label: {
            VStack(spacing: 3) {
                Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                Text(title).font(.system(size: 10, weight: selected ? .heavy : .semibold))
            }
            .foregroundStyle(selected ? accent : Color.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(selected ? accent.opacity(0.10) : AppAppearance.card2(dark: dark), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? accent : Color.primary.opacity(0.08), lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    private func styledField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 15))
            .padding(.horizontal, 16)
            .frame(height: 46)
            .background(inputBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(inputBorder, lineWidth: 1.5))
    }

    private var inputBackground: Color { dark ? Color.white.opacity(0.06) : AppAppearance.card2(dark: dark) }
    private var inputBorder: Color { dark ? Color.white.opacity(0.12) : Color.primary.opacity(0.10) }

    private func save() {
        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, amount > 0 else { return }
        let item = MeowlettTransaction(
            id: transaction?.id ?? UUID(),
            date: date,
            amount: amount,
            category: category,
            description: trimmed,
            location: location,
            note: note,
            paymentMethod: paymentMethod
        )
        if transaction == nil { store.add(item) } else { store.update(item) }
        dismiss()
    }

    private static func formatAmount(_ value: Int64) -> String {
        guard value > 0 else { return "" }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

private struct AmountCalculatorSheet: View {
    let initialValue: Int64
    let onApply: (Int64) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var display = ""
    private var dark: Bool { colorScheme == .dark }
    @State private var stored: Double = 0
    @State private var operation: String?
    @State private var fresh = true

    private let keys = [["7","8","9","÷"],["4","5","6","×"],["1","2","3","−"],["C","0","⌫","+"]]

    var body: some View {
        VStack(spacing: 14) {
            Text(display.isEmpty ? String(initialValue) : display)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(18)
                .background(AppAppearance.card2(dark: dark), in: RoundedRectangle(cornerRadius: 14))
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(keys[row], id: \.self) { key in
                        Button(key) { tap(key) }
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(["÷","×","−","+"].contains(key) ? AppAppearance.accent : .primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(AppAppearance.card2(dark: dark), in: RoundedRectangle(cornerRadius: 13))
                    }
                }
            }
            HStack(spacing: 10) {
                Button("Batal") { dismiss() }
                    .frame(maxWidth: .infinity).frame(height: 46)
                Button("Gunakan hasil") {
                    onApply(Int64(max(0, currentValue.rounded())))
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 46)
                .background(AppAppearance.primary, in: RoundedRectangle(cornerRadius: 13))
            }
        }
        .padding(20)
        .onAppear { display = initialValue > 0 ? String(initialValue) : "" }
    }

    private var currentValue: Double { Double(display.filter(\.isNumber)) ?? 0 }

    private func tap(_ key: String) {
        if key == "C" { display = ""; stored = 0; operation = nil; fresh = true; return }
        if key == "⌫" { display = String(display.dropLast()); return }
        if ["÷","×","−","+"].contains(key) {
            stored = currentValue
            operation = key
            fresh = true
            return
        }
        if fresh { display = key == "0" ? "0" : key; fresh = false }
        else if display.count < 14 { display += key }
        if let op = operation {
            let rhs = currentValue
            switch op {
            case "+": display = String(Int64(stored + rhs))
            case "−": display = String(max(0, Int64(stored - rhs)))
            case "×": display = String(Int64(stored * rhs))
            case "÷": display = rhs == 0 ? "0" : String(Int64(stored / rhs))
            default: break
            }
            operation = nil
            fresh = true
        }
    }
}
