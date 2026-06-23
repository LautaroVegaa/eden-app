import SwiftUI

enum AppAppearance: String {
    static let storageKey = "eden.appearance.mode"

    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
