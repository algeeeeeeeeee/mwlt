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
    }

    func add(_ transaction: MeowlettTransaction) {
        transactions.insert(transaction, at: 0)
        save()
    }

    func update(_ transaction: MeowlettTransaction) {
        guard let index = transactions.firstIndex(where: { $0.id == transaction.id }) else { return }
        transactions[index] = transaction
        transactions.sort { $0.date > $1.date }
        save()
    }

    func delete(at offsets: IndexSet) {
        transactions = transactions.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map { $0.element }
        save()
    }

    func delete(_ transaction: MeowlettTransaction) {
        transactions.removeAll { $0.id == transaction.id }
        save()
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

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([MeowlettTransaction].self, from: data) else {
            transactions = []
            return
        }
        transactions = decoded.sorted { $0.date > $1.date }
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
