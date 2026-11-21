import SwiftUI
import UIKit

enum AppAppearance {
    static let presets: [(id: String, nameID: String, nameEN: String, primary: String, accent: String)] = [
        ("green", "Hijau", "Green", "#166534", "#4ade80"),
        ("blue", "Biru", "Blue", "#1e3a8a", "#60a5fa"),
        ("purple", "Ungu", "Purple", "#4c1d95", "#c084fc"),
        ("rose", "Merah", "Rose", "#881337", "#fb7185"),
        ("orange", "Oranye", "Orange", "#7c2d12", "#fb923c"),
        ("teal", "Tosca", "Teal", "#134e4a", "#2dd4bf")
    ]

    static var primaryHex: String {
        let defaults = UserDefaults.standard
        let preset = defaults.string(forKey: "gm_theme_preset") ?? "rose"
        if preset == "custom" {
            return defaults.string(forKey: "gm_custom_primary") ?? "#881337"
        }
        return presets.first(where: { $0.id == preset })?.primary ?? "#881337"
    }

    static var accentHex: String {
        let defaults = UserDefaults.standard
        let preset = defaults.string(forKey: "gm_theme_preset") ?? "rose"
        if preset == "custom" {
            return defaults.string(forKey: "gm_custom_accent") ?? "#fb7185"
        }
        return presets.first(where: { $0.id == preset })?.accent ?? "#fb7185"
    }

    static var accent: Color { Color(hex: accentHex) }
    static var primary: Color { Color(hex: primaryHex) }

    // Exact neutral palette used by buildTheme() in src/utils/theme.js.
    static func background(dark: Bool) -> Color { Color(hex: dark ? "#0a0a0a" : "#f4f4f4") }
    static func card(dark: Bool) -> Color { Color(hex: dark ? "#141414" : "#ffffff") }
    static func card2(dark: Bool) -> Color { Color(hex: dark ? "#1c1c1c" : "#f9f9f9") }
    static func border(dark: Bool) -> Color { Color(hex: dark ? "#272727" : "#e8e8e8") }
    static func input(dark: Bool) -> Color { Color(hex: dark ? "#1a1a1a" : "#f4f4f4") }
    static func inputBorder(dark: Bool) -> Color { Color(hex: dark ? "#303030" : "#e0e0e0") }
    static func text(dark: Bool) -> Color { Color(hex: dark ? "#ffffff" : "#111111") }
    static func textSub(dark: Bool) -> Color { Color(hex: dark ? "#9ca3af" : "#6b7280") }
    static func textMuted(dark: Bool) -> Color { Color(hex: dark ? "#6b7280" : "#9ca3af") }
    static func modal(dark: Bool) -> Color { Color(hex: dark ? "#111111" : "#ffffff") }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xff) / 255,
            green: Double((value >> 8) & 0xff) / 255,
            blue: Double(value & 0xff) / 255,
            opacity: 1
        )
    }

    var meowlettHex: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}
