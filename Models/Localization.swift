import Foundation

enum L10n {
    static var isEnglish: Bool {
        AppSettings.appLanguageCode == "en"
    }

    static func t(_ de: String, _ en: String) -> String {
        isEnglish ? en : de
    }
}
