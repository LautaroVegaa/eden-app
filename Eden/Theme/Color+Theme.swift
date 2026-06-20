import SwiftUI
import UIKit

extension UIColor {
    /// Creates a color from a 6-digit hex string ("0E1320" or "#0E1320").
    convenience init(hex: String) {
        var string = hex
        if string.hasPrefix("#") { string.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: string).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

/// Returns a color that adapts to light / dark mode.
private func adaptiveColor(dark: String, light: String) -> Color {
    Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
    })
}

/// Eden brand palette. Dark is the hero look; light is supported.
/// The gold accent is the brand constant — identical in both modes.
enum Theme {
    static let background = adaptiveColor(dark: "0E1320", light: "F5F0E8")
    static let surface = adaptiveColor(dark: "1A2233", light: "FFFFFF")
    static let textPrimary = adaptiveColor(dark: "F4EFE6", light: "2A2620")
    static let textMuted = adaptiveColor(dark: "8A93A6", light: "6B6457")

    static let accent = Color(UIColor(hex: "E0A955"))
    static let onAccent = Color(UIColor(hex: "0E1320"))
}
