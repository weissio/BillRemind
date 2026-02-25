import SwiftUI
import SwiftData
import UIKit

struct InvoiceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InvoiceDetailViewModel()
    @Query private var existingInvoices: [Invoice]

    @Bindable var invoice: Invoice
    @State private var showDeleteConfirm = false
    @State private var showFullScreenImage = false
    @State private var ibanCopied = false
    @State private var customCategoryInput = ""
    @AppStorage("categories.custom") private var customCategoriesStorage: String = ""

    var body: some View {
        Form {
            Section(L10n.t("Status", "Status")) {
                LabeledContent(L10n.t("Aktuell", "Current"), value: invoice.status == .open ? L10n.t("Offen", "Open") : L10n.t("Bezahlt", "Paid"))
                if let paidAt = invoice.paidAt {
                    LabeledContent(L10n.t("Bezahlt am", "Paid on"), value: paidAt.formatted(date: .abbreviated, time: .shortened))
                }
                Button(invoice.status == .open ? L10n.t("Als bezahlt markieren", "Mark as paid") : L10n.t("Als offen markieren", "Mark as open")) {
                    if invoice.status == .open {
                        viewModel.markAsPaid(invoice)
                    } else {
                        viewModel.markAsOpen(invoice)
                    }
                    try? modelContext.save()
                }
            }

            Section(L10n.t("Details", "Details")) {
                DatePicker(L10n.t("Rechnungsdatum", "Invoice date"), selection: invoiceDateBinding, displayedComponents: .date)
                DatePicker(L10n.t("Eingangsdatum", "Received date"), selection: $invoice.receivedAt, displayedComponents: .date)
                TextField(L10n.t("Anbieter", "Vendor"), text: $invoice.vendorName)
                TextField(L10n.t("Zahlungsempfaenger", "Payment recipient"), text: $invoice.paymentRecipient)
                Picker(L10n.t("Kategorie", "Category"), selection: categoryBinding) {
                    ForEach(allCategories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                HStack(spacing: 8) {
                    TextField(L10n.t("Eigene Kategorie", "Custom category"), text: $customCategoryInput)
                    Button(L10n.t("Hinzufügen", "Add")) {
                        addCustomCategory()
                    }
                    .buttonStyle(.bordered)
                }
                TextField(L10n.t("Betrag", "Amount"), value: $invoice.amount, format: .number)
                    .keyboardType(.decimalPad)
                HStack {
                    Button(L10n.t("+7 Tage", "+7 days")) {
                        applyDueDate(offsetDays: 7)
                    }
                    .buttonStyle(.bordered)

                    Button(L10n.t("+14 Tage", "+14 days")) {
                        applyDueDate(offsetDays: 14)
                    }
                    .buttonStyle(.bordered)

                    Button(L10n.t("+30 Tage", "+30 days")) {
                        applyDueDate(offsetDays: 30)
                    }
                    .buttonStyle(.bordered)
                }
                DatePicker(L10n.t("Fällig am", "Due date"), selection: dueDateBinding, displayedComponents: .date)
                TextField(L10n.t("Rechnungsnummer", "Invoice number"), text: optionalBinding($invoice.invoiceNumber))
                TextField("IBAN", text: optionalBinding($invoice.iban))
                    .textInputAutocapitalization(.characters)
                HStack(spacing: 10) {
                    Button(L10n.t("IBAN kopieren", "Copy IBAN")) {
                        copyIBANToClipboard(invoice.iban)
                    }
                    .buttonStyle(.bordered)
                    if ibanCopied {
                        Text(L10n.t("Kopiert", "Copied"))
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                Text(L10n.t("Bitte IBAN vor der Zahlung pruefen.", "Please verify IBAN before payment."))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                TextField(L10n.t("Notiz", "Note"), text: optionalBinding($invoice.note), axis: .vertical)
            }

            if let duplicateHint = duplicateWarningMessage() {
                Section(L10n.t("Mögliche Dublette", "Possible duplicate")) {
                    Text(duplicateHint)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section(L10n.t("Reminder", "Reminder")) {
                Toggle(L10n.t("Aktiv", "Active"), isOn: reminderBinding)
                if invoice.reminderEnabled {
                    DatePicker(L10n.t("Erinnern am", "Remind at"), selection: reminderDateBinding, displayedComponents: [.date, .hourAndMinute])
                }
            }

            if let image = viewModel.image(for: invoice) {
                Section(L10n.t("Beleg", "Receipt")) {
                    Button {
                        showFullScreenImage = true
                    } label: {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                    }
                    .buttonStyle(.plain)
                    Button(L10n.t("Belegbild löschen", "Delete receipt image"), role: .destructive) {
                        viewModel.deleteImage(for: invoice)
                        try? modelContext.save()
                    }
                }
            }

            Section {
                Button(L10n.t("Löschen", "Delete"), role: .destructive) {
                    showDeleteConfirm = true
                }
            }

            if let extractedText = invoice.extractedText, !extractedText.isEmpty {
                Section("OCR Debug") {
                    if let confidence = invoice.ocrConfidence {
                        Text("\(L10n.t("OCR-Sicherheit", "OCR confidence")): \(Int((confidence * 100).rounded()))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        confidenceRow(L10n.t("Anbieter", "Vendor"), invoice.vendorConfidence)
                        confidenceRow(L10n.t("Betrag", "Amount"), invoice.amountConfidence)
                        confidenceRow(L10n.t("Fälligkeitsdatum", "Due date"), invoice.dueDateConfidence)
                        confidenceRow(L10n.t("Rechnungsnummer", "Invoice number"), invoice.invoiceNumberConfidence)
                        confidenceRow("IBAN", invoice.ibanConfidence)
                    }
                    if invoice.needsReview == true, let hint = invoice.reviewHint, !hint.isEmpty {
                        Text(hint)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(extractedText)
                        .font(.caption)
                }
            }
        }
        .navigationTitle(invoice.vendorName)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(L10n.t("Rechnung löschen?", "Delete invoice?"), isPresented: $showDeleteConfirm) {
            Button(L10n.t("Löschen", "Delete"), role: .destructive) {
                viewModel.delete(invoice: invoice, modelContext: modelContext)
                try? modelContext.save()
                dismiss()
            }
            Button(L10n.t("Abbrechen", "Cancel"), role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            FullScreenImageView(image: viewModel.image(for: invoice), isPresented: $showFullScreenImage)
        }
        .task {
            await viewModel.rescheduleIfNeeded(invoice)
        }
        .onDisappear {
            invoice.iban = ParsingService.normalizeIBANValue(invoice.iban)
            upsertVendorProfile(from: invoice)
            try? modelContext.save()
        }
    }

    private var dueDateBinding: Binding<Date> {
        Binding {
            invoice.dueDate ?? invoice.invoiceDate ?? invoice.receivedAt
        } set: { value in
            invoice.dueDate = value
            if invoice.reminderDate == nil {
                invoice.reminderDate = Calendar.current.date(byAdding: .day, value: -AppSettings.defaultReminderOffsetDays, to: value)
            }
        }
    }

    private var invoiceDateBinding: Binding<Date> {
        Binding {
            invoice.invoiceDate ?? invoice.receivedAt
        } set: { value in
            invoice.invoiceDate = value
        }
    }

    private var reminderBinding: Binding<Bool> {
        Binding {
            invoice.reminderEnabled
        } set: { enabled in
            Task {
                await viewModel.toggleReminder(for: invoice, enabled: enabled)
                try? modelContext.save()
            }
        }
    }

    private var reminderDateBinding: Binding<Date> {
        Binding {
            invoice.reminderDate ?? Date().addingTimeInterval(3600)
        } set: { newDate in
            Task {
                await viewModel.updateReminderDate(for: invoice, date: newDate)
                try? modelContext.save()
            }
        }
    }

    private func optionalBinding(_ binding: Binding<String?>) -> Binding<String> {
        Binding {
            binding.wrappedValue ?? ""
        } set: { value in
            binding.wrappedValue = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : value
        }
    }

    private var categoryBinding: Binding<String> {
        Binding {
            invoice.category
        } set: { value in
            invoice.category = value
        }
    }

    private func applyDueDate(offsetDays: Int) {
        let base = invoice.invoiceDate ?? invoice.receivedAt
        let due = Calendar.current.date(byAdding: .day, value: offsetDays, to: base) ?? base
        invoice.dueDate = due
        if invoice.reminderDate == nil || invoice.reminderEnabled {
            invoice.reminderDate = Calendar.current.date(byAdding: .day, value: -AppSettings.defaultReminderOffsetDays, to: due)
        }
    }

    private func copyIBANToClipboard(_ iban: String?) {
        let normalized = ParsingService.normalizeIBANValue(iban) ?? ""
        guard !normalized.isEmpty else { return }
        UIPasteboard.general.string = normalized
        ibanCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            ibanCopied = false
        }
    }

    private func duplicateWarningMessage() -> String? {
        let vendor = normalized(invoice.vendorName)
        let number = normalized(invoice.invoiceNumber)
        let amount = invoice.amount.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0

        let exactMatch = existingInvoices.first { other in
            guard other.id != invoice.id else { return false }
            let sameVendor = normalized(other.vendorName) == vendor
            let sameNumber = !number.isEmpty && normalized(other.invoiceNumber) == number
            let sameAmount = abs((other.amount.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0) - amount) < 0.01
            return sameVendor && sameNumber && sameAmount
        }
        if let exactMatch {
            let amountText = exactMatch.amount?.formatted(.currency(code: "EUR")) ?? "-"
            return L10n.t("Ähnliche Rechnung gefunden: \(exactMatch.vendorName), \(amountText).", "Similar invoice found: \(exactMatch.vendorName), \(amountText).")
        }

        let looseMatch = existingInvoices.first { other in
            guard other.id != invoice.id else { return false }
            let sameVendor = normalized(other.vendorName) == vendor
            let sameAmount = abs((other.amount.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0) - amount) < 0.01
            return sameVendor && sameAmount
        }
        if let looseMatch {
            return L10n.t("Mögliche Dublette: gleicher Anbieter und gleicher Betrag (\(looseMatch.vendorName)).", "Possible duplicate: same vendor and same amount (\(looseMatch.vendorName)).")
        }

        return nil
    }

    private func normalized(_ value: String?) -> String {
        (value ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private var allCategories: [String] {
        let merged = Invoice.defaultCategories + customCategories
        var seen = Set<String>()
        return merged.filter { seen.insert($0).inserted }
    }

    private var customCategories: [String] {
        customCategoriesStorage
            .split(separator: "|")
            .map { String($0) }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func addCustomCategory() {
        let trimmed = customCategoryInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var values = customCategories
        if !values.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            values.append(trimmed)
            customCategoriesStorage = values.joined(separator: "|")
        }
        invoice.category = trimmed
        customCategoryInput = ""
    }

    private func upsertVendorProfile(from invoice: Invoice) {
        let vendor = invoice.vendorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !vendor.isEmpty else { return }

        let profileID = VendorProfile.profileID(from: vendor)
        guard !profileID.isEmpty else { return }

        let descriptor = FetchDescriptor<VendorProfile>(
            predicate: #Predicate { $0.id == profileID }
        )

        let dueOffsetDays: Int? = {
            guard let dueDate = invoice.dueDate else { return nil }
            let invoiceDate = Calendar.current.startOfDay(for: invoice.invoiceDate ?? invoice.receivedAt)
            let due = Calendar.current.startOfDay(for: dueDate)
            return Calendar.current.dateComponents([.day], from: invoiceDate, to: due).day
        }()

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.displayName = vendor
            existing.preferredPaymentRecipient = invoice.paymentRecipient
            existing.preferredCategory = invoice.category
            existing.preferredDueOffsetDays = dueOffsetDays
            existing.updatedAt = .now
        } else {
            let profile = VendorProfile(
                id: profileID,
                displayName: vendor,
                preferredPaymentRecipient: invoice.paymentRecipient,
                preferredCategory: invoice.category,
                preferredDueOffsetDays: dueOffsetDays
            )
            modelContext.insert(profile)
        }
    }

    @ViewBuilder
    private func confidenceRow(_ title: String, _ value: Double?) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let value {
                Text("\(Int((value * 100).rounded()))%")
                    .foregroundStyle(value < 0.6 ? .orange : .secondary)
            } else {
                Text("-")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }
}
