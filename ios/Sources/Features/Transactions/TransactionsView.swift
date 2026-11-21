import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("gm_lang") private var language = "id"
    @State private var showAdd = false

    private var isEnglish: Bool { language == "en" }

    var body: some View {
        NavigationStack {
            Group {
                if store.transactions.isEmpty {
                    ContentUnavailableView(
                        isEnglish ? "No transactions yet" : "Belum ada transaksi",
                        systemImage: "list.bullet.rectangle",
                        description: Text(isEnglish ? "Add an expense to start tracking." : "Tambahkan pengeluaran untuk mulai mencatat.")
                    )
                } else {
                    List {
                        ForEach(store.transactions) { transaction in
                            TransactionRow(transaction: transaction, language: language)
                        }
                        .onDelete(perform: store.delete)
                    }
                }
            }
            .navigationTitle(isEnglish ? "Transactions" : "Transaksi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) {
                NavigationStack {
                    TransactionEditorView()
                }
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: MeowlettTransaction
    let language: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: MeowlettCategory.all.first(where: { $0.id == transaction.category })?.icon ?? "square.grid.2x2.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MeowlettCategory.color(for: transaction.category))
                .frame(width: 40, height: 40)
                .background(MeowlettCategory.color(for: transaction.category).opacity(0.14), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.description)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(MeowlettCategory.name(for: transaction.category, language: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("-\(rupiah(transaction.amount))")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.red)
        }
        .padding(.vertical, 3)
    }

    private func rupiah(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

private struct TransactionEditorView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("gm_lang") private var language = "id"

    @State private var description = ""
    @State private var amount = ""
    @State private var category = "food"
    @State private var transactionDate = Date.now
    @State private var location = ""
    @State private var note = ""
    @State private var paymentMethod = "cash"

    private var isEnglish: Bool { language == "en" }

    var body: some View {
        Form {
            Section(isEnglish ? "Details" : "Detail transaksi") {
                TextField(isEnglish ? "Description" : "Keterangan", text: $description)
                TextField(isEnglish ? "Amount (IDR)" : "Jumlah (Rupiah)", text: $amount)
                    .keyboardType(.numberPad)
                DatePicker(isEnglish ? "Date" : "Tanggal", selection: $transactionDate, displayedComponents: .date)
                Picker(isEnglish ? "Category" : "Kategori", selection: $category) {
                    ForEach(MeowlettCategory.all, id: \.id) { item in
                        Text(language == "en" ? item.enName : item.idName).tag(item.id)
                    }
                }
            }

            Section(isEnglish ? "Optional" : "Tambahan") {
                TextField(isEnglish ? "Location" : "Lokasi", text: $location)
                TextField(isEnglish ? "Note" : "Catatan", text: $note)
                Picker(isEnglish ? "Payment method" : "Metode pembayaran", selection: $paymentMethod) {
                    Text(isEnglish ? "Cash" : "Tunai").tag("cash")
                    Text("Transfer").tag("transfer")
                    Text("QRIS").tag("qris")
                }
            }
        }
        .navigationTitle(isEnglish ? "New expense" : "Transaksi baru")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(isEnglish ? "Cancel" : "Batal") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEnglish ? "Save" : "Simpan", action: save)
                    .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedAmount <= 0)
            }
        }
    }

    private var parsedAmount: Int64 {
        Int64(amount.filter(\.isNumber)) ?? 0
    }

    private func save() {
        guard parsedAmount > 0, !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        store.add(MeowlettTransaction(
            date: transactionDate,
            amount: parsedAmount,
            category: category,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location,
            note: note,
            paymentMethod: paymentMethod
        ))
        dismiss()
    }
}
