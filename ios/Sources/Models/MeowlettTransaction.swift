import Foundation
import SwiftUI

struct MeowlettTransaction: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var amount: Int64
    var category: String
    var description: String
    var location: String
    var note: String
    var paymentMethod: String

    init(
        id: UUID = UUID(),
        date: Date = .now,
        amount: Int64,
        category: String,
        description: String,
        location: String = "",
        note: String = "",
        paymentMethod: String = "cash"
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.category = category
        self.description = description
        self.location = location
        self.note = note
        self.paymentMethod = paymentMethod
    }
}

enum MeowlettCategory {
    static let all: [(id: String, idName: String, enName: String, icon: String, color: String)] = [
        ("food", "Makan & Minum", "Food & Drinks", "fork.knife", "#4ade80"),
        ("transport", "Transportasi", "Transport", "car.fill", "#60a5fa"),
        ("date", "Date", "Date", "heart.fill", "#f9a8d4"),
        ("shopping", "Belanja", "Shopping", "bag.fill", "#f97316"),
        ("entertainment", "Hiburan", "Entertainment", "gamecontroller.fill", "#c084fc"),
        ("health", "Kesehatan", "Health", "cross.case.fill", "#f87171"),
        ("bills", "Tagihan", "Bills", "doc.text.fill", "#fbbf24"),
        ("pets", "Hewan Peliharaan", "Pets", "pawprint.fill", "#fb923c"),
        ("other", "Lainnya", "Other", "square.grid.2x2.fill", "#94a3b8")
    ]

    static func name(for id: String, language: String) -> String {
        guard let value = all.first(where: { $0.id == id }) else { return id }
        return language == "en" ? value.enName : value.idName
    }

    static func color(for id: String) -> Color {
        Color(hex: all.first(where: { $0.id == id })?.color ?? "#94a3b8")
    }
}
