import SwiftUI

private struct NativeSplitBillMember: Codable, Identifiable, Equatable {
    var name: String
    var share: Int64
    var paid: Bool
    var id: String { name }
}

private struct NativeSplitBill: Codable, Identifiable, Equatable {
    var id: Int64
    var title: String
    var total: Int64
    var members: [NativeSplitBillMember]
    var paidBy: String
    var date: String
    var settled: Bool
}

struct NativeSplitBillsSheet: View {
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_splitbills") private var splitBillsRaw = "[]"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var bills: [NativeSplitBill] = []
    @State private var loaded = false
    @State private var editorItem: NativeSplitBill?
    @State private var expandedID: Int64?

    private var isEnglish: Bool { language == "en" }
    private var isDark: Bool { colorScheme == .dark }
    private var outstanding: [NativeSplitBill] { bills.filter { !$0.settled } }
    private var outstandingTotal: Int64 {
        outstanding.reduce(0) { sum, bill in
            sum + bill.members.filter { !$0.paid && $0.name != bill.paidBy }.reduce(Int64(0)) { $0 + $1.share }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 36, height: 4).padding(.top, 12)
            HStack {
                Label(isEnglish ? "Split bills" : "Patungan", systemImage: "person.2")
                    .font(MeowlettTypography.font(size: 16, weight: .black))
                Spacer()
                Button {
                    editorItem = NativeSplitBill(id: Int64(Date().timeIntervalSince1970 * 1000), title: "", total: 0, members: [], paidBy: "", date: String(ISO8601DateFormatter().string(from: Date.now).prefix(10)), settled: false)
                } label: {
                    Label(isEnglish ? "Add" : "Tambah", systemImage: "plus")
                        .font(MeowlettTypography.font(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppAppearance.primary, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(AppAppearance.card2(dark: isDark), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    summaryCard
                    if bills.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "person.2")
                                .font(.system(size: 30, weight: .light))
                                .foregroundStyle(AppAppearance.accent)
                            Text(isEnglish ? "No shared bills yet" : "Belum ada patungan")
                                .font(MeowlettTypography.font(size: 14, weight: .bold))
                            Text(isEnglish ? "Add a bill and split it between friends." : "Tambahkan tagihan dan bagi bersama teman.")
                                .font(MeowlettTypography.font(size: 11))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 18))
                    } else {
                        ForEach(bills) { bill in
                            billCard(bill)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(AppAppearance.background(dark: isDark))
        .blur(radius: editorItem == nil ? 0 : 8)
        .animation(.easeInOut(duration: 0.2), value: editorItem != nil)
        .sheet(item: $editorItem) { item in
            NativeSplitBillEditor(item: item) { saved in
                if let index = bills.firstIndex(where: { $0.id == saved.id }) {
                    bills[index] = saved
                } else {
                    bills.append(saved)
                }
            }
        }
        .onAppear(perform: load)
        .onChange(of: bills) { _, value in persist(value) }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(isEnglish ? "OUTSTANDING AMOUNT" : "TOTAL BELUM LUNAS")
                .font(MeowlettTypography.font(size: 10, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.65))
            Text(rupiah(outstandingTotal))
                .font(MeowlettTypography.font(size: 24, weight: .black))
                .foregroundStyle(.white)
            Text("\(bills.count) \(isEnglish ? "shared bills" : "patungan") · \(outstanding.count) \(isEnglish ? "unsettled" : "belum selesai")")
                .font(MeowlettTypography.font(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LinearGradient(colors: [AppAppearance.primary, AppAppearance.accent.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
    }

    private func billCard(_ bill: NativeSplitBill) -> some View {
        let expanded = expandedID == bill.id
        let paidCount = bill.members.filter { $0.paid || $0.name == bill.paidBy }.count
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expandedID = expanded ? nil : bill.id }
            } label: {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color(hex: "#60a5fa").opacity(0.14))
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "receipt").foregroundStyle(Color(hex: "#60a5fa")))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(bill.title)
                            .font(MeowlettTypography.font(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text("\(bill.members.count) \(isEnglish ? "members" : "orang") · \(paidCount)/\(bill.members.count) \(isEnglish ? "paid" : "lunas")")
                            .font(MeowlettTypography.font(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(rupiah(bill.total))
                            .font(MeowlettTypography.font(size: 13, weight: .heavy))
                            .foregroundStyle(.primary)
                        Text(bill.settled ? (isEnglish ? "Settled" : "Lunas") : (isEnglish ? "In progress" : "Berjalan"))
                            .font(MeowlettTypography.font(size: 9, weight: .bold))
                            .foregroundStyle(bill.settled ? Color(hex: "#4ade80") : Color(hex: "#fbbf24"))
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .padding(13)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: 0) {
                    ForEach(bill.members) { member in
                        HStack(spacing: 9) {
                            Button {
                                togglePaid(billID: bill.id, memberName: member.name)
                            } label: {
                                Image(systemName: member.paid || member.name == bill.paidBy ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 19, weight: .medium))
                                    .foregroundStyle(member.paid || member.name == bill.paidBy ? Color(hex: "#4ade80") : Color.secondary.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name)
                                    .font(MeowlettTypography.font(size: 12, weight: .semibold))
                                Text(member.name == bill.paidBy
                                     ? (isEnglish ? "Paid by organizer" : "Dibayar pengaju")
                                     : (member.paid ? (isEnglish ? "Paid" : "Sudah bayar") : (isEnglish ? "Not paid" : "Belum bayar")))
                                    .font(MeowlettTypography.font(size: 9, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(rupiah(member.share))
                                .font(MeowlettTypography.font(size: 11, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 9)
                        if member.id != bill.members.last?.id {
                            Divider().opacity(0.4)
                        }
                    }
                    HStack(spacing: 8) {
                        Button { editorItem = bill } label: {
                            Label(isEnglish ? "Edit" : "Ubah", systemImage: "pencil")
                                .font(MeowlettTypography.font(size: 11, weight: .bold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(AppAppearance.card2(dark: isDark), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        Button { deleteBill(bill.id); expandedID = nil } label: {
                            Label(isEnglish ? "Delete" : "Hapus", systemImage: "trash")
                                .font(MeowlettTypography.font(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "#f87171"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color(hex: "#f87171").opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 13)
                .padding(.bottom, 13)
                .background(AppAppearance.card2(dark: isDark).opacity(0.65))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppAppearance.card(dark: isDark), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
    }

    private func togglePaid(billID: Int64, memberName: String) {
        guard let index = bills.firstIndex(where: { $0.id == billID }) else { return }
        bills[index].members = bills[index].members.map { item in
            guard item.name == memberName else { return item }
            return NativeSplitBillMember(name: item.name, share: item.share, paid: !item.paid)
        }
        bills[index].settled = bills[index].members.allSatisfy { $0.name == bills[index].paidBy || $0.paid }
    }

    private func deleteBill(_ id: Int64) {
        bills.removeAll { $0.id == id }
    }

    private func load() {
        guard !loaded else { return }
        if let data = splitBillsRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([NativeSplitBill].self, from: data) {
            bills = decoded
        }
        loaded = true
    }

    private func persist(_ value: [NativeSplitBill]) {
        guard loaded, let data = try? JSONEncoder().encode(value),
              let json = String(data: data, encoding: .utf8) else { return }
        splitBillsRaw = json
    }

    private func rupiah(_ amount: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "Rp \(amount)"
    }
}

private struct NativeSplitBillEditor: View {
    let item: NativeSplitBill
    let onSave: (NativeSplitBill) -> Void
    @AppStorage("gm_lang") private var language = "id"
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var total: String
    @State private var members: String
    @State private var paidBy: String

    init(item: NativeSplitBill, onSave: @escaping (NativeSplitBill) -> Void) {
        self.item = item
        self.onSave = onSave
        _title = State(initialValue: item.title)
        _total = State(initialValue: item.total > 0 ? String(item.total) : "")
        _members = State(initialValue: item.members.map(\.name).joined(separator: ", "))
        _paidBy = State(initialValue: item.paidBy)
    }

    private var isEnglish: Bool { language == "en" }
    private var parsedTotal: Int64 { Int64(total.filter(\.isNumber)) ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section(isEnglish ? "Bill" : "Tagihan") {
                    TextField(isEnglish ? "Description" : "Nama tagihan", text: $title)
                    TextField(isEnglish ? "Total amount" : "Total nominal", text: $total)
                        .keyboardType(.numberPad)
                    TextField(isEnglish ? "Members separated by commas" : "Nama anggota dipisahkan koma", text: $members, axis: .vertical)
                    TextField(isEnglish ? "Paid by" : "Dibayar oleh", text: $paidBy)
                }
                Section {
                    Text(isEnglish ? "Each person's share is divided evenly. The organizer is marked as paid." : "Nominal tiap orang dibagi rata. Pengaju dianggap sudah membayar.")
                        .font(MeowlettTypography.font(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(isEnglish ? "Split bill" : "Patungan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEnglish ? "Cancel" : "Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEnglish ? "Save" : "Simpan") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedTotal <= 0 || members.split(separator: ",").filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }).count < 2)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let names = members.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard names.count >= 2, parsedTotal > 0 else { return }
        let old = item.members.reduce(into: [String: NativeSplitBillMember]()) { $0[$1.name] = $1 }
        let share = Int64((Double(parsedTotal) / Double(names.count)).rounded())
        let owner = paidBy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? names[0] : paidBy.trimmingCharacters(in: .whitespacesAndNewlines)
        let newMembers = names.map { name in
            let saved = old[name]
            return NativeSplitBillMember(name: name, share: share, paid: saved?.paid ?? false)
        }
        onSave(NativeSplitBill(
            id: item.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            total: parsedTotal,
            members: newMembers,
            paidBy: owner,
            date: item.date,
            settled: item.settled
        ))
        dismiss()
    }
}
