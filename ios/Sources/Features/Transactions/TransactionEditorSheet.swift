import SwiftUI
import PhotosUI
import UIKit

struct TransactionEditorSheet: View {
    let transaction: MeowlettTransaction?
    let initialCategory: String

    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_categories") private var categoriesJSON = ""
    @AppStorage("gm_tx_receipts") private var receiptsRaw = "{}"
    @Environment(\.colorScheme) private var colorScheme

    @State private var descriptionText: String
    @State private var amountText: String
    @State private var category: String
    @State private var date: Date
    @State private var location: String
    @State private var note: String
    @State private var paymentMethod: String
    @State private var showCalculator = false
    @State private var selectedReceipt: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var receiptDataURL: String?
    @State private var showCameraPicker = false

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
                    receiptSection
                    HStack(spacing: 8) {
                        Button(action: save) {
                            Text(transaction == nil ? (isEnglish ? "+ Add" : "+ Tambah") : (isEnglish ? "Save" : "Simpan"))
                                .font(MeowlettTypography.font(size: 13, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(LinearGradient(colors: [accent, primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amount <= 0)
                        .opacity(descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amount <= 0 ? 0.5 : 1)

                        Button(isEnglish ? "Cancel" : "Batal") { dismiss() }
                            .font(MeowlettTypography.font(size: 13, weight: .bold))
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
        .frame(maxWidth: 400)
        .background(AppAppearance.modal(dark: dark))
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(520)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
        .presentationBackground(AppAppearance.modal(dark: dark))
        .sheet(isPresented: $showCalculator) {
            AmountCalculatorSheet(initialValue: amount, onApply: { amountText = Self.formatAmount($0) })
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCameraPicker) {
            NativeCameraPicker { image in
                acceptReceipt(image)
                showCameraPicker = false
            } onCancel: {
                showCameraPicker = false
            }
            .ignoresSafeArea()
        }
        .onAppear(perform: loadReceipt)
        .onChange(of: selectedReceipt) { _, item in
            guard let item else { return }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                await MainActor.run { acceptReceipt(image) }
            }
        }
    }

    private var header: some View {
        HStack {
            Text(transaction == nil ? (isEnglish ? "New Transaction" : "Transaksi Baru") : (isEnglish ? "Edit Transaction" : "Edit Transaksi"))
                .font(MeowlettTypography.font(size: 14, weight: .black))
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
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(LinearGradient(colors: [primary, Color(hex: AppAppearance.darken(AppAppearance.primaryHex, ratio: 0.25))], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var amountRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Text("Rp.")
                    .font(MeowlettTypography.font(size: 14, weight: .heavy))
                    .foregroundStyle(.secondary)
                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .font(MeowlettTypography.font(size: 22, weight: .black))
                    .foregroundStyle(.primary)
                    .onChange(of: amountText) { _, value in
                        let digits = String(value.filter(\.isNumber))
                        if digits != value { amountText = Self.formatAmount(Int64(digits) ?? 0) }
                    }
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(inputBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(inputBorder, lineWidth: 1.5))
            Button { showCalculator = true } label: {
                Image(systemName: "function")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 42, height: 42)
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
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
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
                                .font(MeowlettTypography.font(size: 11, weight: selected ? .bold : .medium))
                                .fixedSize()
                        }
                        .foregroundStyle(selected ? color : Color.secondary)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(selected ? color.opacity(0.13) : categoryChipBackground, in: Capsule())
                        .overlay(Capsule().stroke(selected ? color : AppAppearance.border(dark: dark), lineWidth: selected ? 2 : 1.5))
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
                Text(title).font(MeowlettTypography.font(size: 10, weight: selected ? .heavy : .semibold))
            }
            .foregroundStyle(selected ? accent : Color.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 47)
            .background(selected ? accent.opacity(0.10) : categoryChipBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? accent : AppAppearance.border(dark: dark), lineWidth: selected ? 2 : 1.5))
        }
        .buttonStyle(.plain)
    }

    private func styledField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(MeowlettTypography.font(size: 16, weight: .regular))
            .padding(.horizontal, 16)
            .frame(height: 46)
            .background(inputBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(inputBorder, lineWidth: 1.5))
    }

    private var categoryChipBackground: Color {
        dark ? AppAppearance.card2(dark: true) : AppAppearance.background(dark: false)
    }
    private var inputBackground: Color { AppAppearance.input(dark: dark) }
    private var inputBorder: Color { AppAppearance.inputBorder(dark: dark) }

    private var receiptSection: some View {
        VStack(spacing: 8) {
            if let image = receiptImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    Button(action: clearReceipt) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Color(hex: "#ef4444").opacity(0.88), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            } else {
                HStack(spacing: 8) {
                    PhotosPicker(selection: $selectedReceipt, matching: .images) {
                        Label(isEnglish ? "Upload" : "Unggah", systemImage: "photo")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(categoryChipBackground, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppAppearance.border(dark: dark), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])))
                    }
                    .buttonStyle(.plain)

                    Button {
                        showCameraPicker = true
                    } label: {
                        Label(isEnglish ? "Camera" : "Kamera", systemImage: "camera")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(categoryChipBackground, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppAppearance.border(dark: dark), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])))
                    }
                    .buttonStyle(.plain)
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    .opacity(UIImagePickerController.isSourceTypeAvailable(.camera) ? 1 : 0.45)
                }
            }
        }
    }

    private func loadReceipt() {
        guard let data = receiptsRaw.data(using: .utf8),
              let receipts = try? JSONDecoder().decode([String: String].self, from: data) else { return }
        let key = transaction.map { $0.id.uuidString } ?? "_new"
        guard let value = receipts[key] else { return }
        receiptDataURL = value
        let base64 = value.components(separatedBy: ",").last ?? value
        if let bytes = Data(base64Encoded: base64) {
            receiptImage = UIImage(data: bytes)
        }
    }

    private func acceptReceipt(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return }
        receiptImage = UIImage(data: data)
        receiptDataURL = "data:image/jpeg;base64," + data.base64EncodedString()
        selectedReceipt = nil
    }

    private func clearReceipt() {
        receiptImage = nil
        receiptDataURL = nil
        selectedReceipt = nil
    }

    private func persistReceipt(for id: UUID) {
        guard let data = receiptsRaw.data(using: .utf8),
              var receipts = try? JSONDecoder().decode([String: String].self, from: data) else { return }
        receipts.removeValue(forKey: "_new")
        if let receiptDataURL {
            receipts[id.uuidString] = receiptDataURL
        } else {
            receipts.removeValue(forKey: id.uuidString)
        }
        if let encoded = try? JSONEncoder().encode(receipts),
           let value = String(data: encoded, encoding: .utf8) {
            receiptsRaw = value
        }
    }

    private func save() {
        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, amount > 0 else { return }
        let savedID = transaction?.id ?? UUID()
        let item = MeowlettTransaction(
            id: savedID,
            date: date,
            amount: amount,
            category: category,
            description: trimmed,
            location: location,
            note: note,
            paymentMethod: paymentMethod
        )
        if transaction == nil { store.add(item) } else { store.update(item) }
        persistReceipt(for: savedID)
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
                .font(MeowlettTypography.font(size: 32, weight: .black))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(18)
                .background(AppAppearance.card2(dark: dark), in: RoundedRectangle(cornerRadius: 14))
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(keys[row], id: \.self) { key in
                        Button(key) { tap(key) }
                            .font(MeowlettTypography.font(size: 20, weight: .bold))
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
