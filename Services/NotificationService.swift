import Foundation
import UserNotifications

protocol NotificationServicing {
    func requestAuthorization() async -> Bool
    func scheduleReminder(for invoice: Invoice) async
    func cancelReminder(for invoiceID: UUID)
    func scheduleNegativeCashflowAlert(weekLabel: String, projectedBalance: Double) async
    func cancelNegativeCashflowAlert()
}

struct NotificationService: NotificationServicing {
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleReminder(for invoice: Invoice) async {
        guard invoice.reminderEnabled, let reminderDate = invoice.reminderDate else {
            cancelReminder(for: invoice.id)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Rechnung fällig"
        content.body = "\(invoice.vendorName) ist bald fällig."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = reminderIdentifier(for: invoice.id)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(for invoiceID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderIdentifier(for: invoiceID)])
    }

    func scheduleNegativeCashflowAlert(weekLabel: String, projectedBalance: Double) async {
        let content = UNMutableNotificationContent()
        content.title = "Cashflow Warnung"
        content.body = "In \(weekLabel) wird ein negativer Kontostand von \(projectedBalance.formatted(.currency(code: "EUR"))) erwartet."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let identifier = negativeCashflowIdentifier()
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelNegativeCashflowAlert() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [negativeCashflowIdentifier()])
    }

    private func reminderIdentifier(for invoiceID: UUID) -> String {
        "invoice-\(invoiceID.uuidString)"
    }

    private func negativeCashflowIdentifier() -> String {
        "cashflow-negative-alert"
    }
}
