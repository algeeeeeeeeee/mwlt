import Foundation
import Combine

@MainActor
final class FinanceStore: ObservableObject {
    @Published private(set) var transactions: [MeowlettTransaction] = []

    private let fileURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("Meowlett", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("transactions.json")
        load()
        seedPreviewDataIfRequested()
        // Defer UserNotifications service IPC until after the first app frame.
        // Calling this synchronously from FinanceStore.init can stall cold launch
        // on a freshly booted simulator while the notification daemon starts.
        // Avoid touching UserNotifications on every cold launch when reminders are off.
        // Settings removes pending requests when the user explicitly disables notifications.
        if UserDefaults.standard.string(forKey: "gm_notif") == "1" {
            let startupTransactions = transactions
            Task { @MainActor in
                MeowlettReminderScheduler.scheduleFromDefaults(transactions: startupTransactions)
            }
        }
    }

    func add(_ transaction: MeowlettTransaction) {
        var value = transaction
        if value.createdAt == nil { value.createdAt = .now }
        transactions.insert(value, at: 0)
        save()
        MeowlettReminderScheduler.scheduleFromDefaults(transactions: transactions)
    }

    func update(_ transaction: MeowlettTransaction) {
        guard let index = transactions.firstIndex(where: { $0.id == transaction.id }) else { return }
        var value = transaction
        if value.createdAt == nil {
            value.createdAt = transactions[index].createdAt ?? transactions[index].date
        }
        transactions[index] = value
        transactions.sort { $0.date > $1.date }
        save()
        MeowlettReminderScheduler.scheduleFromDefaults(transactions: transactions)
    }

    func delete(at offsets: IndexSet) {
        transactions = transactions.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map { $0.element }
        save()
        MeowlettReminderScheduler.scheduleFromDefaults(transactions: transactions)
    }

    func delete(_ transaction: MeowlettTransaction) {
        transactions.removeAll { $0.id == transaction.id }
        save()
        MeowlettReminderScheduler.scheduleFromDefaults(transactions: transactions)
    }

    func restore(_ transaction: MeowlettTransaction) {
        guard !transactions.contains(where: { $0.id == transaction.id }) else { return }
        var value = transaction
        if value.createdAt == nil { value.createdAt = value.date }
        transactions.append(value)
        transactions.sort { $0.date > $1.date }
        save()
        MeowlettReminderScheduler.scheduleFromDefaults(transactions: transactions)
    }

    func clearAllTransactions() {
        transactions.removeAll()
        save()
        MeowlettReminderScheduler.scheduleFromDefaults(transactions: transactions)
    }

    func replaceAllTransactions(_ values: [MeowlettTransaction]) {
        transactions = values.map { item in
            var value = item
            if value.createdAt == nil { value.createdAt = value.date }
            return value
        }.sorted { $0.date > $1.date }
        save()
        MeowlettReminderScheduler.scheduleFromDefaults(transactions: transactions)
    }

    func expenses(in month: Date = .now, calendar: Calendar = .current) -> Int64 {
        transactions
            .filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            .reduce(Int64(0)) { $0 + $1.amount }
    }

    func expensesByCategory(in month: Date = .now, calendar: Calendar = .current) -> [(String, Int64)] {
        let grouped = Dictionary(grouping: transactions.filter {
            calendar.isDate($0.date, equalTo: month, toGranularity: .month)
        }, by: \.category)
        return grouped.map { key, values in
            (key, values.reduce(Int64(0)) { $0 + $1.amount })
        }.sorted { $0.1 > $1.1 }
    }


    private func seedPreviewDataIfRequested() {
        guard CommandLine.arguments.contains("--mwlt-preview-seed-data"), transactions.isEmpty else { return }
        let calendar = Calendar.current
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: .now) ?? .now
        }
        let previewTransactions = [
            MeowlettTransaction(date: day(0), amount: 32000, category: "food", description: "Sarapan nasi uduk", location: "Pontianak", paymentMethod: "cash"),
            MeowlettTransaction(date: day(0), amount: 15000, category: "transport", description: "Ojek ke sekolah", location: "Kota", paymentMethod: "qris"),
            MeowlettTransaction(date: day(-1), amount: 58000, category: "food", description: "Kopi dan camilan", location: "Coffee shop", note: "Meeting", paymentMethod: "cash"),
            MeowlettTransaction(date: day(-2), amount: 189000, category: "shopping", description: "Belanja kebutuhan", location: "Mall", paymentMethod: "transfer"),
            MeowlettTransaction(date: day(-3), amount: 75000, category: "entertainment", description: "Nonton film", location: "Bioskop", paymentMethod: "qris"),
            MeowlettTransaction(date: day(-5), amount: 280000, category: "date", description: "Makan malam", location: "Restoran", paymentMethod: "cash"),
            MeowlettTransaction(date: day(-8), amount: 116300, category: "bills", description: "Tagihan bulanan", paymentMethod: "transfer"),
            MeowlettTransaction(date: day(-10), amount: 145000, category: "health", description: "Perlengkapan kesehatan", paymentMethod: "qris"),
            MeowlettTransaction(date: day(-13), amount: 350000, category: "date", description: "Aktivitas akhir pekan", location: "Pontianak", paymentMethod: "cash"),
            MeowlettTransaction(date: day(-18), amount: 55000, category: "food", description: "Makan siang", paymentMethod: "cash")
        ]
        transactions = previewTransactions.enumerated().map { index, item in
            var value = item
            value.createdAt = .now.addingTimeInterval(-Double(index))
            return value
        }.sorted { $0.date > $1.date }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([MeowlettTransaction].self, from: data) else {
            transactions = []
            return
        }
        var migrated = decoded
        var needsSave = false
        for index in migrated.indices where migrated[index].createdAt == nil {
            migrated[index].createdAt = migrated[index].date
            needsSave = true
        }
        transactions = migrated.sorted { $0.date > $1.date }
        if needsSave { save() }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(transactions)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            NSLog("[Meowlett] Could not save transactions: %@", error.localizedDescription)
        }
    }
}
