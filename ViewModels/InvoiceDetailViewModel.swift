import Foundation
import SwiftData
import UIKit

@MainActor
final class InvoiceDetailViewModel: ObservableObject {
    private let notificationService: NotificationServicing
    private let imageStore: ImageStore

    init(
        notificationService: NotificationServicing = NotificationService(),
        imageStore: ImageStore = ImageStore()
    ) {
        self.notificationService = notificationService
        self.imageStore = imageStore
    }

    func toggleReminder(for invoice: Invoice, enabled: Bool) async {
        invoice.reminderEnabled = enabled

        if enabled {
            let granted = await notificationService.requestAuthorization()
            guard granted else {
                invoice.reminderEnabled = false
                return
            }

            if invoice.reminderDate == nil {
                if let dueDate = invoice.dueDate {
                    invoice.reminderDate = Calendar.current.date(byAdding: .day, value: -AppSettings.defaultReminderOffsetDays, to: dueDate)
                } else {
                    invoice.reminderDate = Date().addingTimeInterval(3600)
                }
            }
            await notificationService.scheduleReminder(for: invoice)
        } else {
            notificationService.cancelReminder(for: invoice.id)
        }
    }

    func updateReminderDate(for invoice: Invoice, date: Date) async {
        invoice.reminderDate = date
        if invoice.reminderEnabled {
            await notificationService.scheduleReminder(for: invoice)
        }
    }

    func markAsPaid(_ invoice: Invoice) {
        invoice.status = .paid
        invoice.paidAt = .now
        invoice.reminderEnabled = false
        notificationService.cancelReminder(for: invoice.id)
    }

    func markAsOpen(_ invoice: Invoice) {
        invoice.status = .open
        invoice.paidAt = nil
    }

    func delete(invoice: Invoice, modelContext: ModelContext) {
        notificationService.cancelReminder(for: invoice.id)
        imageStore.deleteImage(fileName: invoice.imageFileName)
        modelContext.delete(invoice)
    }

    func deleteImage(for invoice: Invoice) {
        imageStore.deleteImage(fileName: invoice.imageFileName)
        invoice.imageFileName = nil
    }

    func rescheduleIfNeeded(_ invoice: Invoice) async {
        guard invoice.reminderEnabled else { return }
        await notificationService.scheduleReminder(for: invoice)
    }

    func image(for invoice: Invoice) -> UIImage? {
        guard let fileName = invoice.imageFileName else { return nil }
        return imageStore.loadImage(fileName: fileName)
    }
}
