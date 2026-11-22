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
    var createdAt: Date?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        amount: Int64,
        category: String,
        description: String,
        location: String = "",
        note: String = "",
        paymentMethod: String = "cash",
        createdAt: Date? = .now
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.category = category
        self.description = description
        self.location = location
        self.note = note
        self.paymentMethod = paymentMethod
        self.createdAt = createdAt
    }
}

struct MeowlettCategoryDefinition: Codable, Equatable {
    var label: String
    var labelId: String?
    var icon: String
    var color: String

    var displayIcon: String {
        switch icon.lowercased() {
        case "utensils", "utensil": return "fork.knife"
        case "beer": return "mug.fill"
        case "palette": return "paintpalette.fill"
        case "gift": return "gift.fill"
        case "dumbbell": return "dumbbell.fill"
        case "smartphone": return "iphone"
        case "gamepad": return "gamecontroller.fill"
        case "search": return "magnifyingglass"
        case "star": return "sparkles"
        case "car": return "car.fill"
        case "heart": return "heart.fill"
        case "shoppingbag": return "bag.fill"
        case "pill": return "cross.case.fill"
        case "filetext": return "doc.text.fill"
        case "pawprint": return "pawprint.fill"
        case "package": return "shippingbox.fill"
        case "coffee": return "cup.and.saucer.fill"
        case "pizza": return "takeoutbag.and.cup.and.straw.fill"
        case "plane": return "airplane"
        case "shirt": return "tshirt.fill"
        case "dollar", "banknote": return "banknote"
        case "wallet": return "wallet.bifold.fill"
        case "piggybank": return "banknote"
        case "trendingup": return "chart.line.uptrend.xyaxis"
        case "coins": return "dollarsign.circle.fill"
        case "home": return "house.fill"
        case "droplets": return "drop.fill"
        case "zap": return "bolt.fill"
        case "wrench": return "wrench.fill"
        case "flame": return "flame.fill"
        case "wind": return "wind"
        case "monitor": return "desktopcomputer"
        case "laptop": return "laptopcomputer"
        case "music": return "music.note"
        case "film": return "film.fill"
        case "book": return "book.fill"
        case "leaf": return "leaf.fill"
        case "flower": return "flower"
        case "umbrella": return "umbrella.fill"
        case "sparkles": return "sparkles"
        case "target": return "scope"
        case "repeat": return "repeat"
        case "inbox": return "tray.fill"
        case "users": return "person.2.fill"
        case "clock": return "clock.fill"
        case "calendar": return "calendar"
        case "alarmclock": return "alarm.fill"
        case "bell": return "bell.fill"
        case "tag": return "tag.fill"
        case "receipt": return "receipt"
        default: return icon
        }
    }
}

enum MeowlettCategory {
    private static let builtIns: [(id: String, idName: String, enName: String, icon: String, color: String)] = [
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

    static func orderedKeys(
        fromJSON json: String,
        availableKeys: Set<String>,
        storedOrderJSON: String? = nil
    ) -> [String] {
        var candidates: [String] = []

        if let orderData = storedOrderJSON?.data(using: .utf8),
           let storedOrder = try? JSONDecoder().decode([String].self, from: orderData) {
            candidates.append(contentsOf: storedOrder)
        }
        candidates.append(contentsOf: topLevelObjectKeys(in: json))
        candidates.append(contentsOf: builtIns.map(\.id))
        candidates.append(contentsOf: availableKeys.sorted())

        var seen = Set<String>()
        return candidates.filter { availableKeys.contains($0) && seen.insert($0).inserted }
    }

    private static func topLevelObjectKeys(in json: String) -> [String] {
        let characters = Array(json)
        var keys: [String] = []
        var depth = 0
        var index = 0

        while index < characters.count {
            let character = characters[index]
            if character == "\"" {
                let start = index
                index += 1
                var escaped = false

                while index < characters.count {
                    let current = characters[index]
                    if escaped {
                        escaped = false
                    } else if current == "\\" {
                        escaped = true
                    } else if current == "\"" {
                        break
                    }
                    index += 1
                }

                let end = index
                if depth == 1, end < characters.count {
                    var next = end + 1
                    while next < characters.count && characters[next].isWhitespace {
                        next += 1
                    }
                    if next < characters.count && characters[next] == ":" {
                        let literal = String(characters[start...end])
                        if let data = literal.data(using: .utf8),
                           let key = try? JSONDecoder().decode(String.self, from: data) {
                            keys.append(key)
                        }
                    }
                }

                index = min(index + 1, characters.count)
                continue
            }

            if character == "{" {
                depth += 1
            } else if character == "}" {
                depth = max(0, depth - 1)
            }
            index += 1
        }
        return keys
    }

    static var all: [(id: String, idName: String, enName: String, icon: String, color: String)] {
        let defaults = UserDefaults.standard
        let rawJSON = defaults.string(forKey: "gm_categories") ?? ""
        guard let data = rawJSON.data(using: .utf8),
              let saved = try? JSONDecoder().decode([String: MeowlettCategoryDefinition].self, from: data) else {
            return builtIns
        }

        // Keep the PWA object's insertion order; native category edits preserve it separately.
        let ordered = orderedKeys(
            fromJSON: rawJSON,
            availableKeys: Set(saved.keys),
            storedOrderJSON: defaults.string(forKey: "gm_category_order")
        )
        return ordered.compactMap { key in
            guard let item = saved[key] else { return nil }
            let fallback = builtIns.first(where: { $0.id == key })
            let english = item.label.isEmpty ? (fallback?.enName ?? key) : item.label
            let indonesia = item.labelId ?? fallback?.idName ?? item.label
            return (key, indonesia, english, item.displayIcon, item.color)
        }
    }
    static func name(for id: String, language: String) -> String {
        guard let value = all.first(where: { $0.id == id }) else { return id }
        return language == "en" ? value.enName : value.idName
    }

    static func color(for id: String) -> Color {
        Color(hex: all.first(where: { $0.id == id })?.color ?? "#94a3b8")
    }
}
