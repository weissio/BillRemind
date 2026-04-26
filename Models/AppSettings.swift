import Foundation

enum AppSettings {
    static let defaultReminderOffsetDaysKey = "defaultReminderOffsetDays"
    static let biometricLockEnabledKey = "biometricLockEnabled"
    static let negativeCashflowAlertEnabledKey = "negativeCashflowAlertEnabled"
    static let negativeCashflowAlertWeeksKey = "negativeCashflowAlertWeeks"
    static let urgencySoonDaysKey = "urgencySoonDays"
    static let reviewConfidenceThresholdKey = "reviewConfidenceThreshold"
    static let ocrDebugVisibleKey = "ocrDebugVisible"
    static let exportFormatKey = "exportFormat"
    static let appLanguageCodeKey = "appLanguageCode"

    static var defaultReminderOffsetDays: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: defaultReminderOffsetDaysKey)
            return [0, 1, 2, 3, 7].contains(stored) ? stored : 2
        }
        set {
            UserDefaults.standard.set(newValue, forKey: defaultReminderOffsetDaysKey)
        }
    }

    static var biometricLockEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: biometricLockEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: biometricLockEnabledKey) }
    }

    static var negativeCashflowAlertEnabled: Bool {
        get { UserDefaults.standard.object(forKey: negativeCashflowAlertEnabledKey) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: negativeCashflowAlertEnabledKey) }
    }

    static var negativeCashflowAlertWeeks: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: negativeCashflowAlertWeeksKey)
            return [2, 4, 8, 12, 24].contains(value) ? value : 8
        }
        set {
            UserDefaults.standard.set(newValue, forKey: negativeCashflowAlertWeeksKey)
        }
    }

    static var urgencySoonDays: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: urgencySoonDaysKey)
            return [3, 5, 7, 10].contains(value) ? value : 5
        }
        set {
            UserDefaults.standard.set(newValue, forKey: urgencySoonDaysKey)
        }
    }

    static var reviewConfidenceThreshold: Double {
        get {
            let raw = UserDefaults.standard.double(forKey: reviewConfidenceThresholdKey)
            if raw == 0 { return 0.75 }
            return min(max(raw, 0.55), 0.95)
        }
        set {
            UserDefaults.standard.set(min(max(newValue, 0.55), 0.95), forKey: reviewConfidenceThresholdKey)
        }
    }

    static var ocrDebugVisible: Bool {
        get { UserDefaults.standard.object(forKey: ocrDebugVisibleKey) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: ocrDebugVisibleKey) }
    }

    static var exportFormat: String {
        get {
            let value = UserDefaults.standard.string(forKey: exportFormatKey) ?? "xlsx"
            return ["xlsx", "csv", "xml"].contains(value) ? value : "xlsx"
        }
        set {
            let sanitized = ["xlsx", "csv", "xml"].contains(newValue) ? newValue : "xlsx"
            UserDefaults.standard.set(sanitized, forKey: exportFormatKey)
        }
    }

    static var appLanguageCode: String {
        get {
            if let stored = UserDefaults.standard.string(forKey: appLanguageCodeKey) {
                return ["de", "en"].contains(stored) ? stored : systemPreferredLanguageDefault()
            }
            return systemPreferredLanguageDefault()
        }
        set {
            let sanitized = ["de", "en"].contains(newValue) ? newValue : "en"
            UserDefaults.standard.set(sanitized, forKey: appLanguageCodeKey)
        }
    }

    private static func systemPreferredLanguageDefault() -> String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let code = Locale(identifier: preferred).language.languageCode?.identifier ?? "en"
        return code == "de" ? "de" : "en"
    }
}
