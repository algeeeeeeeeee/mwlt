import SwiftUI
import CoreText

enum MeowlettTypography {
    private static let fontNames = [
        "PlusJakartaSans-Regular",
        "PlusJakartaSans-Medium",
        "PlusJakartaSans-SemiBold",
        "PlusJakartaSans-Bold",
        "PlusJakartaSans-ExtraBold"
    ]

    static func registerBundledFonts() {
        for name in fontNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") else {
                assertionFailure("Missing bundled font: \\(name).ttf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .ultraLight, .thin, .light, .regular:
            name = "PlusJakartaSans-Regular"
        case .medium:
            name = "PlusJakartaSans-Medium"
        case .semibold:
            name = "PlusJakartaSans-SemiBold"
        case .bold:
            name = "PlusJakartaSans-Bold"
        default:
            name = "PlusJakartaSans-ExtraBold"
        }
        return .custom(name, size: size)
    }
}
