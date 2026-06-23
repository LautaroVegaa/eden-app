import Foundation
import WidgetKit

enum WidgetVerseStore {
    static let appGroupID = "group.com.lautarocarignani.eden"
    static let widgetKind = "EdenVerseWidget"

    private enum Keys {
        static let reference = "eden.widget.verse.reference"
        static let text = "eden.widget.verse.text"
        static let updatedAt = "eden.widget.verse.updatedAt"
    }

    static func save(reference: String, text: String) {
        let cleanReference = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanReference.isEmpty, !cleanText.isEmpty else { return }

        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(cleanReference, forKey: Keys.reference)
        defaults.set(cleanText, forKey: Keys.text)
        defaults.set(Date(), forKey: Keys.updatedAt)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
