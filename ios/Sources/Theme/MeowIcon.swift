import SwiftUI
import Foundation
import Compression

/// Canonical Lucide names extracted from the installed lucide-react package.
enum MeowIconKey: String, CaseIterable {
    case alarmClock = "AlarmClock"
    case alertCircle = "AlertCircle"
    case alertTriangle = "AlertTriangle"
    case apple = "Apple"
    case arrowDown = "ArrowDown"
    case arrowRight = "ArrowRight"
    case arrowUpRight = "ArrowUpRight"
    case badgeDollarSign = "BadgeDollarSign"
    case badgeInfo = "BadgeInfo"
    case ban = "Ban"
    case banknote = "Banknote"
    case barChart2 = "BarChart2"
    case beer = "Beer"
    case bell = "Bell"
    case bellOff = "BellOff"
    case bellRing = "BellRing"
    case book = "Book"
    case calculator = "Calculator"
    case calendar = "Calendar"
    case camera = "Camera"
    case car = "Car"
    case cat = "Cat"
    case chartPie = "ChartPie"
    case check = "Check"
    case checkCheck = "CheckCheck"
    case checkCircle = "CheckCircle"
    case chevronDown = "ChevronDown"
    case chevronRight = "ChevronRight"
    case circle = "Circle"
    case circleDollarSign = "CircleDollarSign"
    case citrus = "Citrus"
    case clock = "Clock"
    case coffee = "Coffee"
    case coins = "Coins"
    case creditCard = "CreditCard"
    case diamond = "Diamond"
    case diamondPlus = "DiamondPlus"
    case dollarSign = "DollarSign"
    case download = "Download"
    case droplets = "Droplets"
    case dumbbell = "Dumbbell"
    case equal = "Equal"
    case fileText = "FileText"
    case film = "Film"
    case flame = "Flame"
    case flower2 = "Flower2"
    case gamepad2 = "Gamepad2"
    case gift = "Gift"
    case globe = "Globe"
    case grape = "Grape"
    case handCoins = "HandCoins"
    case heart = "Heart"
    case heartPulse = "HeartPulse"
    case home = "Home"
    case image = "Image"
    case imagePlus = "ImagePlus"
    case inbox = "Inbox"
    case landmark = "Landmark"
    case laptop = "Laptop"
    case layoutList = "LayoutList"
    case leaf = "Leaf"
    case messageCircle = "MessageCircle"
    case monitor = "Monitor"
    case moon = "Moon"
    case music = "Music"
    case package = "Package"
    case paintRoller = "PaintRoller"
    case paintbrushVertical = "PaintbrushVertical"
    case palette = "Palette"
    case pawPrint = "PawPrint"
    case pencil = "Pencil"
    case piggyBank = "PiggyBank"
    case pill = "Pill"
    case pizza = "Pizza"
    case plane = "Plane"
    case plus = "Plus"
    case qrCode = "QrCode"
    case receipt = "Receipt"
    case refreshCw = "RefreshCw"
    case repeatIcon = "Repeat"
    case rocket = "Rocket"
    case save = "Save"
    case search = "Search"
    case settings = "Settings"
    case share2 = "Share2"
    case shirt = "Shirt"
    case shoppingBag = "ShoppingBag"
    case slidersHorizontal = "SlidersHorizontal"
    case smartphone = "Smartphone"
    case smile = "Smile"
    case sparkles = "Sparkles"
    case star = "Star"
    case sun = "Sun"
    case sunMoon = "SunMoon"
    case tag = "Tag"
    case target = "Target"
    case trash2 = "Trash2"
    case trendingUp = "TrendingUp"
    case umbrella = "Umbrella"
    case upload = "Upload"
    case user = "User"
    case users = "Users"
    case utensils = "Utensils"
    case wallet = "Wallet"
    case waves = "Waves"
    case wifiOff = "WifiOff"
    case wind = "Wind"
    case wrench = "Wrench"
    case x = "X"
    case zap = "Zap"
}

struct MeowIcon: View {
    let key: String
    var size: CGFloat = 24
    var color: Color? = nil
    var strokeWidth: CGFloat = 2

    var body: some View {
        Group {
            if let path = MeowIconCatalog.path(for: key) {
                if let color {
                    path.stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                } else {
                    path.stroke(.foreground, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                }
            } else {
                #if DEBUG
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.red, lineWidth: 1.5)
                    Text("?")
                        .font(.system(size: max(8, size * 0.55), weight: .bold))
                        .foregroundStyle(.red)
                }
                .onAppear {
                    NSLog("[MeowIcon] Missing icon key: %@", key)
                }
                #else
                EmptyView()
                #endif
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct MeowIconNode {
    let tag: String
    let attributes: [String: String]

    init(_ tag: String, _ attributes: [String: String]) {
        self.tag = tag
        self.attributes = attributes
    }
}

private final class MeowIconBundleToken {}

enum MeowIconCatalog {
    private static let aliases: [String: String] = [
        "utensil": "Utensils", "utensils": "Utensils", "fork.knife": "Utensils",
        "coffee": "Coffee", "cup.and.saucer.fill": "Coffee",
        "pizza": "Pizza", "takeoutbag.and.cup.and.straw.fill": "Pizza",
        "beer": "Beer", "mug.fill": "Beer",
        "car.fill": "Car", "airplane": "Plane",
        "shoppingbag": "ShoppingBag", "bag.fill": "ShoppingBag",
        "tshirt.fill": "Shirt", "paintpalette.fill": "Palette", "paintpalette": "Palette",
        "gift.fill": "Gift", "heart.fill": "Heart", "pills.fill": "Pill", "cross.case.fill": "Pill",
        "dumbbell.fill": "Dumbbell", "dollarsign.circle": "CircleDollarSign",
        "dollarsign.circle.fill": "CircleDollarSign", "banknote": "Banknote",
        "wallet.bifold": "Wallet", "wallet.bifold.fill": "Wallet", "wallet": "Wallet",
        "piggy": "PiggyBank", "piggybank": "PiggyBank",
        "chart.line.uptrend.xyaxis": "TrendingUp", "coins": "Coins",
        "home": "Home", "house.fill": "Home", "drop.fill": "Droplets",
        "bolt": "Zap", "bolt.fill": "Zap", "wrench.fill": "Wrench",
        "flame": "Flame", "flame.fill": "Flame", "wind": "Wind",
        "desktopcomputer": "Monitor", "laptopcomputer": "Laptop", "music.note": "Music",
        "film.fill": "Film", "book.fill": "Book", "leaf.fill": "Leaf", "umbrella.fill": "Umbrella",
        "scope": "Target", "tray.fill": "Inbox", "person.2": "Users", "person.2.fill": "Users",
        "clock.fill": "Clock", "alarm.fill": "AlarmClock", "bell.fill": "Bell",
        "bell.slash.fill": "BellOff", "bell.badge": "BellRing", "tag.fill": "Tag",
        "alertcircle": "AlertCircle", "exclamationmark.circle": "AlertCircle",
        "exclamationmark.circle.fill": "AlertCircle", "exclamationmark.triangle": "AlertTriangle",
        "chart.bar": "BarChart2", "chart.pie": "BarChart2", "list.bullet": "LayoutList",
        "line.3.horizontal": "LayoutList", "nosign": "Ban", "function": "Calculator",
        "tablecells": "LayoutList", "doc.text": "FileText", "doc.text.fill": "FileText",
        "square.and.arrow.up": "Share2", "message.fill": "MessageCircle",
        "arrow.down.to.line": "Download", "arrow.up.to.line": "Upload",
        "building.columns": "Landmark", "qrcode": "QrCode",
        "checkmark.circle": "CheckCircle", "checkmark.circle.fill": "CheckCircle",
        "checkmark": "Check", "xmark": "X", "chevron.down": "ChevronDown",
        "chevron.right": "ChevronRight", "plus": "Plus", "plus.circle": "CirclePlus",
        "trash": "Trash2", "pencil": "Pencil", "repeat": "Repeat",
        "creditcard": "CreditCard", "creditcard.fill": "CreditCard", "photo": "Image",
        "camera.fill": "Camera", "gearshape": "Settings", "globe": "Globe",
        "moon": "Moon", "moon.fill": "Moon", "sun.max": "Sun", "sun.max.fill": "Sun",
        "sun.horizon": "Sun", "sparkles": "Sparkles", "diamond": "Diamond",
        "heart.text.square": "HeartPulse", "arrow.right": "ArrowRight",
        "arrow.down": "ArrowDown", "arrow.up.right": "ArrowUpRight",
        "rocket": "Rocket", "search": "Search", "magnifyingglass": "Search",
        "shippingbox": "Package", "shippingbox.fill": "Package",
        "slider.horizontal.3": "SlidersHorizontal", "receipt": "Receipt",
        "calendar": "Calendar", "camera": "Camera", "image": "Image",
        "flower": "Flower2", "flower2": "Flower2", "hand.coins": "HandCoins",
        "checkcircle": "CheckCircle", "alerttriangle": "AlertTriangle",
        "filetext": "FileText", "pawprint": "PawPrint", "trendingup": "TrendingUp",
        "gamepad": "Gamepad2", "gamecontroller.fill": "Gamepad2",
        "smartphone": "Smartphone", "iphone": "Smartphone", "shopping": "ShoppingBag",
        "searchicon": "Search", "dollar": "CircleDollarSign", "star": "Sparkles",
        "paintbrush.pointed": "PaintbrushVertical", "checkmark.circle.fill": "CheckCircle",
        "circle": "Circle"
    ]

    private static let specialNodes: [String: [MeowIconNode]] = [
        "SunMoon": [
            MeowIconNode("path", ["d": "M12 2v2"]),
            MeowIconNode("path", ["d": "M14.837 16.385a6 6 0 1 1-7.223-7.222c.624-.147.97.66.715 1.248a4 4 0 0 0 5.26 5.259c.589-.255 1.396.09 1.248.715"]),
            MeowIconNode("path", ["d": "M16 12a4 4 0 0 0-4-4"]),
            MeowIconNode("path", ["d": "m19 5-1.256 1.256"]),
            MeowIconNode("path", ["d": "M20 12h2"])
        ],
        "CirclePlus": [
            MeowIconNode("circle", ["cx": "12", "cy": "12", "r": "10"]),
            MeowIconNode("path", ["d": "M8 12h8"]),
            MeowIconNode("path", ["d": "M12 8v8"])
        ],
        "PaintbrushVertical": [
            MeowIconNode("path", ["d": "M10 2v2"]),
            MeowIconNode("path", ["d": "M14 2v4"]),
            MeowIconNode("path", ["d": "M17 2a1 1 0 0 1 1 1v9H6V3a1 1 0 0 1 1-1z"]),
            MeowIconNode("path", ["d": "M6 12a1 1 0 0 0-1 1v1a2 2 0 0 0 2 2h2a1 1 0 0 1 1 1v2.9a2 2 0 1 0 4 0V17a1 1 0 0 1 1-1h2a2 2 0 0 0 2-2v-1a1 1 0 0 0-1-1"])
        ],
        "MessageCircle": [
            MeowIconNode("path", ["d": "M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719"])
        ],
        "DiamondPlus": [
            MeowIconNode("path", ["d": "M12 8v8"]),
            MeowIconNode("path", ["d": "M2.7 10.3a2.41 2.41 0 0 0 0 3.41l7.59 7.59a2.41 2.41 0 0 0 3.41 0l7.59-7.59a2.41 2.41 0 0 0 0-3.41L13.7 2.71a2.41 2.41 0 0 0-3.41 0z"]),
            MeowIconNode("path", ["d": "M8 12h8"])
        ],
        "Smile": [
            MeowIconNode("circle", ["cx": "12", "cy": "12", "r": "10"]),
            MeowIconNode("path", ["d": "M8 14s1.5 2 4 2 4-2 4-2"]),
            MeowIconNode("line", ["x1": "9", "x2": "9.01", "y1": "9", "y2": "9"]),
            MeowIconNode("line", ["x1": "15", "x2": "15.01", "y1": "9", "y2": "9"])
        ],
        "QrCode": [
            MeowIconNode("rect", ["x": "3", "y": "3", "width": "7", "height": "7"]),
            MeowIconNode("rect", ["x": "14", "y": "3", "width": "7", "height": "7"]),
            MeowIconNode("rect", ["x": "3", "y": "14", "width": "7", "height": "7"]),
            MeowIconNode("path", ["d": "M14 14h3v3h-3zM17 17h3v3h-3zM14 20h3"])
        ],
        "Landmark": [
            MeowIconNode("line", ["x1": "3", "y1": "22", "x2": "21", "y2": "22"]),
            MeowIconNode("line", ["x1": "6", "y1": "18", "x2": "6", "y2": "11"]),
            MeowIconNode("line", ["x1": "10", "y1": "18", "x2": "10", "y2": "11"]),
            MeowIconNode("line", ["x1": "14", "y1": "18", "x2": "14", "y2": "11"]),
            MeowIconNode("line", ["x1": "18", "y1": "18", "x2": "18", "y2": "11"]),
            MeowIconNode("polygon", ["points": "12 2 20 7 4 7"])
        ],
        "Diamond": [
            MeowIconNode("polygon", ["points": "6 3 18 3 22 9 12 21 2 9"])
        ],
        "ArrowUpRight": [
            MeowIconNode("path", ["d": "M7 17 17 7M7 7h10v10"])
        ],
        "Circle": [
            MeowIconNode("circle", ["cx": "12", "cy": "12", "r": "10"])
        ],
        "Check": [
            MeowIconNode("path", ["d": "m5 12 4 4L19 6"])
        ]
    ]

    private static let iconPaths: [String: Path] = {
        var result = loadInstalledIconPaths()
        for (name, nodes) in specialNodes {
            result[name] = makePath(nodes)
        }
        return result
    }()

    static var missingKeys: [String] {
        MeowIconKey.allCases.map(\.rawValue).filter { path(for: $0) == nil }
    }

    static func path(for key: String) -> Path? {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let canonical = aliases[trimmed.lowercased()]
            ?? MeowIconKey.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(trimmed) == .orderedSame })?.rawValue
        guard let canonical else { return nil }
        return iconPaths[canonical]
    }

    private static func loadInstalledIconPaths() -> [String: Path] {
        guard
            let url = Bundle(for: MeowIconBundleToken.self).url(forResource: "lucide-icons", withExtension: "json.z"),
            let compressed = try? Data(contentsOf: url)
        else {
            #if DEBUG
            NSLog("[MeowIcon] Lucide icon resource is missing from the app bundle")
            #endif
            return [:]
        }

        var decoded = Data(count: 512 * 1024)
        let decodedCount = decoded.withUnsafeMutableBytes { destination in
            compressed.withUnsafeBytes { source in
                guard
                    let destinationBase = destination.bindMemory(to: UInt8.self).baseAddress,
                    let sourceBase = source.bindMemory(to: UInt8.self).baseAddress
                else { return 0 }
                return compression_decode_buffer(
                    destinationBase,
                    destination.count,
                    sourceBase,
                    compressed.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard decodedCount > 0 else {
            #if DEBUG
            NSLog("[MeowIcon] Failed to decompress Lucide icon resource")
            #endif
            return [:]
        }
        decoded.count = decodedCount

        guard
            let root = try? JSONSerialization.jsonObject(with: decoded) as? [String: Any],
            let icons = root["icons"] as? [[String: Any]]
        else { return [:] }

        var paths: [String: Path] = [:]
        for icon in icons {
            guard
                let name = icon["name"] as? String,
                let rows = icon["node"] as? [[Any]]
            else { continue }

            var nodes: [MeowIconNode] = []
            for row in rows {
                guard
                    row.count == 2,
                    let tag = row[0] as? String,
                    let attributes = row[1] as? [String: Any]
                else { continue }
                nodes.append(MeowIconNode(tag, attributes.mapValues { String(describing: $0) }))
            }
            if !nodes.isEmpty {
                paths[name] = makePath(nodes)
            }
        }
        return paths
    }

    private static func makePath(_ nodes: [MeowIconNode]) -> Path {
        var result = Path()
        for node in nodes {
            let a = node.attributes
            switch node.tag {
            case "path":
                if let data = a["d"] { result.addPath(SVGPathParser.parse(data)) }
            case "circle":
                if let cx = number(a["cx"]), let cy = number(a["cy"]), let r = number(a["r"]) {
                    result.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
                }
            case "ellipse":
                if let cx = number(a["cx"]), let cy = number(a["cy"]), let rx = number(a["rx"]), let ry = number(a["ry"]) {
                    result.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
                }
            case "rect":
                if let x = number(a["x"]), let y = number(a["y"]), let width = number(a["width"]), let height = number(a["height"]) {
                    let radius = max(number(a["rx"]) ?? 0, number(a["ry"]) ?? 0)
                    let rect = CGRect(x: x, y: y, width: width, height: height)
                    if radius > 0 {
                        result.addRoundedRect(in: rect, cornerSize: CGSize(width: radius, height: radius))
                    } else {
                        result.addRect(rect)
                    }
                }
            case "line":
                if let x1 = number(a["x1"]), let y1 = number(a["y1"]), let x2 = number(a["x2"]), let y2 = number(a["y2"]) {
                    result.move(to: CGPoint(x: x1, y: y1))
                    result.addLine(to: CGPoint(x: x2, y: y2))
                }
            case "polyline", "polygon":
                let points = numberList(a["points"] ?? "")
                if points.count >= 4 {
                    result.move(to: CGPoint(x: points[0], y: points[1]))
                    for index in stride(from: 2, to: points.count - 1, by: 2) {
                        result.addLine(to: CGPoint(x: points[index], y: points[index + 1]))
                    }
                    if node.tag == "polygon" { result.closeSubpath() }
                }
            default:
                continue
            }
        }
        return result
    }

    private static func number(_ value: String?) -> CGFloat? {
        guard let value, let parsed = Double(value) else { return nil }
        return CGFloat(parsed)
    }

    private static func numberList(_ value: String) -> [CGFloat] {
        let pattern = "[-+]?(?:\\d*\\.\\d+|\\d+\\.?\\d*)(?:[eE][-+]?\\d+)?"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = value as NSString
        return regex.matches(in: value, range: NSRange(location: 0, length: ns.length)).compactMap {
            Double(ns.substring(with: $0.range)).map(CGFloat.init)
        }
    }
}

private struct SVGPathParser {
    private let tokens: [String]
    private var index = 0
    private var command: Character?
    private var current = CGPoint.zero
    private var subpathStart = CGPoint.zero
    private var lastControl = CGPoint.zero
    private var previousCommand: Character?
    private var path = Path()

    private init(_ value: String) {
        let pattern = "[A-Za-z]|[-+]?(?:\\d*\\.\\d+|\\d+\\.?\\d*)(?:[eE][-+]?\\d+)?"
        let regex = try! NSRegularExpression(pattern: pattern)
        let ns = value as NSString
        self.tokens = regex.matches(in: value, range: NSRange(location: 0, length: ns.length)).map {
            ns.substring(with: $0.range)
        }
    }

    static func parse(_ value: String) -> Path {
        var parser = SVGPathParser(value)
        return parser.run()
    }

    private mutating func run() -> Path {
        while index < tokens.count {
            if let first = tokens[index].first, first.isLetter {
                command = first
                index += 1
            }
            guard let active = command else { break }
            let upper = Character(String(active).uppercased())
            let relative = active.isLowercase

            switch upper {
            case "M":
                var isFirst = true
                while hasNumber {
                    let point = readPoint(relative: relative)
                    if isFirst {
                        path.move(to: point)
                        subpathStart = point
                        isFirst = false
                    } else {
                        path.addLine(to: point)
                    }
                    current = point
                }
                command = relative ? "l" : "L"
                previousCommand = "M"
            case "L":
                while hasNumber {
                    let point = readPoint(relative: relative)
                    path.addLine(to: point)
                    current = point
                }
                previousCommand = "L"
            case "H":
                while hasNumber {
                    let x = readNumber()
                    current = CGPoint(x: relative ? current.x + x : x, y: current.y)
                    path.addLine(to: current)
                }
                previousCommand = "H"
            case "V":
                while hasNumber {
                    let y = readNumber()
                    current = CGPoint(x: current.x, y: relative ? current.y + y : y)
                    path.addLine(to: current)
                }
                previousCommand = "V"
            case "C":
                while hasNumber {
                    let start = current
                    let c1 = readPoint(relative: relative, origin: start)
                    let c2 = readPoint(relative: relative, origin: start)
                    let end = readPoint(relative: relative, origin: start)
                    path.addCurve(to: end, control1: c1, control2: c2)
                    current = end
                    lastControl = c2
                }
                previousCommand = "C"
            case "S":
                while hasNumber {
                    let start = current
                    let c1 = (previousCommand == "C" || previousCommand == "S")
                        ? CGPoint(x: 2 * start.x - lastControl.x, y: 2 * start.y - lastControl.y)
                        : start
                    let c2 = readPoint(relative: relative, origin: start)
                    let end = readPoint(relative: relative, origin: start)
                    path.addCurve(to: end, control1: c1, control2: c2)
                    current = end
                    lastControl = c2
                }
                previousCommand = "S"
            case "Q":
                while hasNumber {
                    let start = current
                    let control = readPoint(relative: relative, origin: start)
                    let end = readPoint(relative: relative, origin: start)
                    path.addQuadCurve(to: end, control: control)
                    current = end
                    lastControl = control
                }
                previousCommand = "Q"
            case "T":
                while hasNumber {
                    let start = current
                    let control = (previousCommand == "Q" || previousCommand == "T")
                        ? CGPoint(x: 2 * start.x - lastControl.x, y: 2 * start.y - lastControl.y)
                        : start
                    let end = readPoint(relative: relative, origin: start)
                    path.addQuadCurve(to: end, control: control)
                    current = end
                    lastControl = control
                }
                previousCommand = "T"
            case "A":
                while hasNumber {
                    let rx = readNumber()
                    let ry = readNumber()
                    let rotation = readNumber()
                    let largeArc = readNumber() != 0
                    let sweep = readNumber() != 0
                    let end = readPoint(relative: relative)
                    addArc(to: end, rx: rx, ry: ry, rotation: rotation, largeArc: largeArc, sweep: sweep)
                    current = end
                }
                previousCommand = "A"
            case "Z":
                path.closeSubpath()
                current = subpathStart
                previousCommand = "Z"
                command = nil
            default:
                command = nil
            }
        }
        return path
    }

    private var hasNumber: Bool {
        guard index < tokens.count, let first = tokens[index].first else { return false }
        return !first.isLetter
    }

    private mutating func readNumber() -> CGFloat {
        guard index < tokens.count, let value = Double(tokens[index]) else { return 0 }
        index += 1
        return CGFloat(value)
    }

    private mutating func readPoint(relative: Bool, origin: CGPoint? = nil) -> CGPoint {
        let base = origin ?? current
        let x = readNumber()
        let y = readNumber()
        return relative ? CGPoint(x: base.x + x, y: base.y + y) : CGPoint(x: x, y: y)
    }

    private mutating func addArc(
        to end: CGPoint,
        rx inputRX: CGFloat,
        ry inputRY: CGFloat,
        rotation: CGFloat,
        largeArc: Bool,
        sweep: Bool
    ) {
        var rx = abs(inputRX)
        var ry = abs(inputRY)
        guard rx > 0, ry > 0, current != end else {
            path.addLine(to: end)
            return
        }

        let phi = rotation * .pi / 180
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)
        let dx = (current.x - end.x) / 2
        let dy = (current.y - end.y) / 2
        let xPrime = cosPhi * dx + sinPhi * dy
        let yPrime = -sinPhi * dx + cosPhi * dy

        let lambda = (xPrime * xPrime) / (rx * rx) + (yPrime * yPrime) / (ry * ry)
        if lambda > 1 {
            let scale = sqrt(lambda)
            rx *= scale
            ry *= scale
        }

        let numerator = max(0, rx * rx * ry * ry - rx * rx * yPrime * yPrime - ry * ry * xPrime * xPrime)
        let denominator = max(CGFloat.leastNonzeroMagnitude, rx * rx * yPrime * yPrime + ry * ry * xPrime * xPrime)
        let sign: CGFloat = largeArc == sweep ? -1 : 1
        let coefficient = sign * sqrt(numerator / denominator)
        let cxPrime = coefficient * (rx * yPrime / ry)
        let cyPrime = coefficient * (-ry * xPrime / rx)
        let center = CGPoint(
            x: cosPhi * cxPrime - sinPhi * cyPrime + (current.x + end.x) / 2,
            y: sinPhi * cxPrime + cosPhi * cyPrime + (current.y + end.y) / 2
        )

        let ux = (xPrime - cxPrime) / rx
        let uy = (yPrime - cyPrime) / ry
        let vx = (-xPrime - cxPrime) / rx
        let vy = (-yPrime - cyPrime) / ry
        let startAngle = atan2(uy, ux)
        var delta = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
        if !sweep && delta > 0 { delta -= 2 * .pi }
        if sweep && delta < 0 { delta += 2 * .pi }

        var unitArc = Path()
        unitArc.addArc(
            center: .zero,
            radius: 1,
            startAngle: .radians(startAngle),
            endAngle: .radians(startAngle + delta),
            clockwise: !sweep
        )
        let transform = CGAffineTransform(
            a: rx * cosPhi,
            b: rx * sinPhi,
            c: -ry * sinPhi,
            d: ry * cosPhi,
            tx: center.x,
            ty: center.y
        )
        path.addPath(unitArc.applying(transform))
    }
}