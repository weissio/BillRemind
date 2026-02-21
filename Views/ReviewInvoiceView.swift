import SwiftUI
import SwiftData
import UIKit

struct ReviewInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var vendorProfiles: [VendorProfile]
    @StateObject var scanViewModel: ScanViewModel
    let onSaved: () -> Void

    @State private var draft: InvoiceDraft
    @State private var saveError: String?
    @State private var ibanCopied = false
    @State private var customCategoryInput = ""
    @AppStorage("categories.custom") private var customCategoriesStorage: String = ""
    @AppStorage(AppSettings.reviewConfidenceThresholdKey) private var reviewConfidenceThreshold: Double = AppSettings.reviewConfidenceThreshold
    @AppStorage(AppSettings.ocrDebugVisibleKey) private var ocrDebugVisible: Bool = AppSettings.ocrDebugVisible
    private let notificationService = NotificationService()

    init(scanViewModel: ScanViewModel, onSaved: @escaping () -> Void) {
        _scanViewModel = StateObject(wrappedValue: scanViewModel)
        _draft = State(initialValue: scanViewModel.draft ?? InvoiceDraft(importKind: .manual))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                if let warning = scanViewModel.parsingWarning {
                    Section {
                        Text(warning)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }

                if ocrDebugVisible,
                   let ocrDebugInfo = scanViewModel.ocrDebugInfo,
                   !ocrDebugInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("OCR Debug") {
                        Text(ocrDebugInfo)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }

                if draft.needsReview {
                    Section(L10n.t("Prüfhinweis", "Review note")) {
                        if !draft.reviewHint.isEmpty {
                            Text(draft.reviewHint)
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                        if let confidence = draft.ocrConfidence {
                            Text("\(L10n.t("OCR-Sicherheit", "OCR confidence")): \(Int((confidence * 100).rounded()))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            confidenceRow(L10n.t("Anbieter", "Vendor"), draft.vendorConfidence)
                            confidenceRow(L10n.t("Betrag", "Amount"), draft.amountConfidence)
                            confidenceRow(L10n.t("Fälligkeitsdatum", "Due date"), draft.dueDateConfidence)
                            confidenceRow(L10n.t("Rechnungsnummer", "Invoice number"), draft.invoiceNumberConfidence)
                            confidenceRow("IBAN", draft.ibanConfidence)
                        }
                    }
                }

                if let importHint = importHintText {
                    Section(L10n.t("Import", "Import")) {
                        Text(importHint)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let capturedImage = scanViewModel.selectedImage {
                    Section(L10n.t("Belegfoto", "Receipt photo")) {
                        Toggle(L10n.t("Foto speichern", "Save photo"), isOn: $draft.keepCapturedImage)
                        if draft.keepCapturedImage {
                            Image(uiImage: capturedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        } else {
                            Text(L10n.t("Foto wird beim Speichern verworfen.", "Photo will be discarded on save."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(L10n.t("Rechnung", "Invoice")) {
                    DatePicker(L10n.t("Eingangsdatum", "Received date"), selection: $draft.receivedAt, displayedComponents: .date)
                    Picker(L10n.t("Status", "Status"), selection: statusBinding) {
                        Text(L10n.t("Offen", "Open")).tag(Invoice.Status.open)
                        Text(L10n.t("Bezahlt", "Paid")).tag(Invoice.Status.paid)
                    }
                    .pickerStyle(.segmented)
                    if draft.status == .paid {
                        DatePicker(L10n.t("Bezahlt am", "Paid on"), selection: paidAtBinding, displayedComponents: .date)
                        Button(L10n.t("Als bezahlt (heute)", "Mark as paid (today)")) {
                            draft.status = .paid
                            draft.paidAt = Calendar.current.startOfDay(for: Date())
                        }
                        .buttonStyle(.bordered)
                    }
                    highlightedField(title: L10n.t("Anbieter", "Vendor"), confidence: draft.vendorConfidence) {
                        TextField(L10n.t("z. B. Stadtwerke", "e.g. City Utilities"), text: $draft.vendorName)
                    }
                    highlightedField(title: L10n.t("Zahlungsempfaenger", "Payment recipient"), confidence: draft.vendorConfidence) {
                        TextField(L10n.t("Empfaenger laut Rechnung", "Recipient as shown on invoice"), text: $draft.paymentRecipient)
                    }
                    Picker(L10n.t("Kategorie", "Category"), selection: $draft.category) {
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
                    highlightedField(title: L10n.t("Betrag", "Amount"), confidence: draft.amountConfidence) {
                        TextField(L10n.t("z. B. 49,99", "e.g. 49.99"), value: $draft.amount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    if draft.importKind != .scanReceipt {
                        highlightedField(title: L10n.t("Fälligkeitsdatum", "Due date"), confidence: draft.dueDateConfidence) {
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
                        }
                    }
                    highlightedField(title: L10n.t("Rechnungsnummer", "Invoice number"), confidence: draft.invoiceNumberConfidence) {
                        TextField(L10n.t("z. B. INV-2026-001", "e.g. INV-2026-001"), text: $draft.invoiceNumber)
                    }
                    highlightedField(title: "IBAN", confidence: draft.ibanConfidence) {
                        TextField("DE89 3704 0044 0532 0130 00", text: $draft.iban)
                            .textInputAutocapitalization(.characters)
                        HStack(spacing: 10) {
                            Button(L10n.t("IBAN kopieren", "Copy IBAN")) {
                                copyIBANToClipboard(draft.iban)
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
                    }
                }

                Section(L10n.t("Notiz", "Note")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.t("Notiz", "Note"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField(L10n.t("Optional", "Optional"), text: $draft.note, axis: .vertical)
                    }
                }

                Section(L10n.t("Reminder", "Reminder")) {
                    if draft.status == .open {
                        Toggle(L10n.t("Erinnerung aktivieren", "Enable reminder"), isOn: $draft.reminderEnabled)
                        if draft.reminderEnabled {
                            DatePicker(L10n.t("Erinnerungsdatum", "Reminder date"), selection: reminderDateBinding, displayedComponents: [.date, .hourAndMinute])
                        }
                    } else {
                        Text(L10n.t("Für bezahlte Rechnungen sind Erinnerungen deaktiviert.", "Reminders are disabled for paid invoices."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let saveError {
                    Section {
                        Text(saveError)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(L10n.t("Review", "Review"))
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .tint(Color(red: 0.54, green: 0.35, blue: 0.25))
            .onAppear {
                applyLearnedDefaultsIfAvailable()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("Abbrechen", "Cancel")) {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("Speichern", "Save")) {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var dueDateBinding: Binding<Date> {
        Binding {
            draft.dueDate ?? draft.receivedAt
        } set: { value in
            draft.dueDate = value
            if draft.reminderDate == nil {
                draft.reminderDate = Calendar.current.date(byAdding: .day, value: -AppSettings.defaultReminderOffsetDays, to: value)
            }
        }
    }

    private var paidAtBinding: Binding<Date> {
        Binding {
            draft.paidAt ?? draft.receivedAt
        } set: { value in
            draft.paidAt = value
        }
    }

    private var statusBinding: Binding<Invoice.Status> {
        Binding {
            draft.status
        } set: { value in
            draft.status = value
            if value == .paid {
                draft.paidAt = draft.paidAt ?? draft.receivedAt
                draft.reminderEnabled = false
                draft.reminderDate = nil
            } else {
                draft.paidAt = nil
            }
        }
    }

    private var reminderDateBinding: Binding<Date> {
        Binding {
            draft.reminderDate ?? Date().addingTimeInterval(3600)
        } set: { value in
            draft.reminderDate = value
        }
    }

    private var importHintText: String? {
        switch draft.importKind {
        case .scanReceipt:
            return L10n.t("Importtyp: Kassenbon (automatisch auf Bezahlt gesetzt)", "Import type: receipt (automatically set to Paid)")
        case .scanInvoice:
            return L10n.t("Importtyp: Rechnungsscan", "Import type: invoice scan")
        case .pdfImport:
            return L10n.t("Importtyp: PDF Import", "Import type: PDF import")
        case .manual:
            return L10n.t("Importtyp: Manuell", "Import type: manual")
        }
    }

    private func save() {
        draft.iban = draft.iban.replacingOccurrences(of: " ", with: "").uppercased()
        draft.needsReview = (draft.ocrConfidence ?? 0) < 0.8 || !draft.reviewHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        do {
            let invoice = try scanViewModel.createInvoice(from: draft, modelContext: modelContext)
            if invoice.reminderEnabled {
                Task {
                    let granted = await notificationService.requestAuthorization()
                    if granted {
                        await notificationService.scheduleReminder(for: invoice)
                    } else {
                        invoice.reminderEnabled = false
                        try? modelContext.save()
                    }
                }
            }
            onSaved()
            dismiss()
        } catch {
            saveError = "Konnte Rechnung nicht speichern."
        }
    }

    private func applyDueDate(offsetDays: Int) {
        let due = Calendar.current.date(byAdding: .day, value: offsetDays, to: draft.receivedAt) ?? draft.receivedAt
        draft.dueDate = due
        if draft.reminderDate == nil || draft.reminderEnabled {
            draft.reminderDate = Calendar.current.date(byAdding: .day, value: -AppSettings.defaultReminderOffsetDays, to: due)
        }
    }

    private func copyIBANToClipboard(_ iban: String) {
        let normalized = iban.replacingOccurrences(of: " ", with: "").uppercased()
        guard !normalized.isEmpty else { return }
        UIPasteboard.general.string = normalized
        ibanCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            ibanCopied = false
        }
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
        draft.category = trimmed
        customCategoryInput = ""
    }

    private func applyLearnedDefaultsIfAvailable() {
        let vendor = draft.vendorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !vendor.isEmpty else { return }

        let key = VendorProfile.profileID(from: vendor)
        guard let profile = vendorProfiles.first(where: { $0.id == key }) else { return }

        if draft.paymentRecipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draft.paymentRecipient = profile.preferredPaymentRecipient
        }
        if draft.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.category == "Sonstiges" {
            draft.category = profile.preferredCategory
        }
        if draft.importKind != .scanReceipt, draft.dueDate == nil, let days = profile.preferredDueOffsetDays {
            draft.dueDate = Calendar.current.date(byAdding: .day, value: days, to: draft.receivedAt)
        }
    }

    @ViewBuilder
    private func confidenceRow(_ title: String, _ value: Double?) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let value {
                Text("\(Int((value * 100).rounded()))%")
                    .monospacedDigit()
                    .foregroundStyle(value < reviewConfidenceThreshold ? .orange : .secondary)
            } else {
                Text("-")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }

    @ViewBuilder
    private func highlightedField<Content: View>(title: String, confidence: Double?, @ViewBuilder content: () -> Content) -> some View {
        let isUncertain = (confidence ?? 1.0) < reviewConfidenceThreshold && draft.needsReview
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
            if isUncertain {
                Text(L10n.t("Unsicher erkannt - bitte manuell prüfen", "Low confidence detected - please review manually"))
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isUncertain ? Color.orange.opacity(0.08) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isUncertain ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 1)
        )
    }
}
