import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var reminderOffsetDays: Int = AppSettings.defaultReminderOffsetDays {
        didSet {
            AppSettings.defaultReminderOffsetDays = reminderOffsetDays
        }
    }
    @Published var biometricLockEnabled: Bool = AppSettings.biometricLockEnabled {
        didSet {
            AppSettings.biometricLockEnabled = biometricLockEnabled
        }
    }
    @Published var negativeCashflowAlertEnabled: Bool = AppSettings.negativeCashflowAlertEnabled {
        didSet {
            AppSettings.negativeCashflowAlertEnabled = negativeCashflowAlertEnabled
        }
    }
    @Published var negativeCashflowAlertWeeks: Int = AppSettings.negativeCashflowAlertWeeks {
        didSet {
            AppSettings.negativeCashflowAlertWeeks = negativeCashflowAlertWeeks
        }
    }
    @Published var urgencySoonDays: Int = AppSettings.urgencySoonDays {
        didSet {
            AppSettings.urgencySoonDays = urgencySoonDays
        }
    }
    @Published var reviewConfidencePercent: Int = Int((AppSettings.reviewConfidenceThreshold * 100).rounded()) {
        didSet {
            AppSettings.reviewConfidenceThreshold = Double(reviewConfidencePercent) / 100.0
        }
    }

    let offsetOptions = [0, 1, 2, 3, 7]
    let cashflowWeeksOptions = [2, 4, 8, 12, 24]
    let urgencySoonDaysOptions = [3, 5, 7, 10]
    let reviewConfidenceOptions = [60, 65, 70, 75, 80, 85, 90]
}
