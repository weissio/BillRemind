import SwiftUI
import SwiftData
import UIKit

struct ReviewInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existingInvoices: [Invoice]
    @Query private var vendorProfiles: [VendorProfile]
    @Query private var ocrLearningProfiles: [OCRLearningProfile]
    @StateObject var scanViewModel: ScanViewModel
    let onSaved: () -> Void

    @State private var draft: InvoiceDraft
    @State private var saveError: String?
    @State private var showDuplicateAlert = false
    @State private var duplicateHintText = ""
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
                    DatePicker(L10n.t("Rechnungsdatum", "Invoice date"), selection: $draft.invoiceDate, displayedComponents: .date)
                    DatePicker(L10n.t("Eingangsdatum", "Received date"), selection: $draft.receivedAt, displayedComponents: .date)
                    Text(L10n.t("Rechnungsdatum steuert Fälligkeit (+7/+14/+30).", "Invoice date controls due date (+7/+14/+30)."))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
                    Text(L10n.t("Tipp: Hier den exakten Zahlungsempfänger von der Rechnung eintragen.", "Tip: Enter the exact payment recipient from the invoice here."))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
                                .tint(isDuePresetSelected(7) ? Color.accentColor : Color.secondary)

                                Button(L10n.t("+14 Tage", "+14 days")) {
                                    applyDueDate(offsetDays: 14)
                                }
                                .buttonStyle(.bordered)
                                .tint(isDuePresetSelected(14) ? Color.accentColor : Color.secondary)

                                Button(L10n.t("+30 Tage", "+30 days")) {
                                    applyDueDate(offsetDays: 30)
                                }
                                .buttonStyle(.bordered)
                                .tint(isDuePresetSelected(30) ? Color.accentColor : Color.secondary)
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
                    Text(L10n.t("Beim Speichern prüfen wir automatisch auf mögliche Duplikate.", "On save, we automatically check for possible duplicates."))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
            .onChange(of: draft.invoiceDate) { value in
                guard let offset = draft.dueOffsetDaysHint else { return }
                draft.dueDate = Calendar.current.date(byAdding: .day, value: offset, to: value)
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
            .alert(L10n.t("Mögliche Dublette", "Possible duplicate"), isPresented: $showDuplicateAlert) {
                Button(L10n.t("Trotzdem speichern", "Save anyway")) {
                    saveDirectly()
                }
                Button(L10n.t("Prüfen", "Review"), role: .cancel) {}
            } message: {
                Text(duplicateHintText)
            }
        }
    }

    private var dueDateBinding: Binding<Date> {
        Binding {
            draft.dueDate ?? draft.invoiceDate
        } set: { value in
            draft.dueDate = value
            draft.dueOffsetDaysHint = nil
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
        if let duplicateMessage = duplicateWarningMessage() {
            duplicateHintText = duplicateMessage
            showDuplicateAlert = true
            return
        }
        saveDirectly()
    }

    private func saveDirectly() {
        draft.iban = ParsingService.normalizeIBANValue(draft.iban) ?? ""
        draft.needsReview = (draft.ocrConfidence ?? 0) < 0.8 || !draft.reviewHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        persistOCRLearningFromReview()
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

    private func duplicateWarningMessage() -> String? {
        let vendor = normalized(draft.vendorName)
        let number = normalized(draft.invoiceNumber)
        let amount = draft.amount.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0

        let exactMatch = existingInvoices.first { invoice in
            guard invoice.id != draft.id else { return false }
            let sameVendor = normalized(invoice.vendorName) == vendor
            let sameNumber = !number.isEmpty && normalized(invoice.invoiceNumber) == number
            let sameAmount = abs((invoice.amount.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0) - amount) < 0.01
            return sameVendor && sameNumber && sameAmount
        }
        if let exactMatch {
            let amountText = exactMatch.amount?.formatted(.currency(code: "EUR")) ?? "-"
            return L10n.t("Eine ähnliche Rechnung ist bereits vorhanden (\(exactMatch.vendorName), \(amountText)).", "A similar invoice already exists (\(exactMatch.vendorName), \(amountText)).")
        }

        let looseMatch = existingInvoices.first { invoice in
            guard invoice.id != draft.id else { return false }
            let sameVendor = normalized(invoice.vendorName) == vendor
            let sameAmount = abs((invoice.amount.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0) - amount) < 0.01
            return sameVendor && sameAmount
        }
        if let looseMatch {
            return L10n.t("Mögliche Dublette erkannt (\(looseMatch.vendorName), gleicher Betrag). Bitte kurz prüfen.", "Possible duplicate detected (\(looseMatch.vendorName), same amount). Please review briefly.")
        }
        return nil
    }

    private func normalized(_ value: String?) -> String {
        (value ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func applyDueDate(offsetDays: Int) {
        let due = Calendar.current.date(byAdding: .day, value: offsetDays, to: draft.invoiceDate) ?? draft.invoiceDate
        draft.dueDate = due
        draft.dueOffsetDaysHint = offsetDays
        if draft.reminderDate == nil || draft.reminderEnabled {
            draft.reminderDate = Calendar.current.date(byAdding: .day, value: -AppSettings.defaultReminderOffsetDays, to: due)
        }
    }

    private func isDuePresetSelected(_ offsetDays: Int) -> Bool {
        if draft.dueOffsetDaysHint == offsetDays { return true }
        guard let dueDate = draft.dueDate else { return false }
        let invoiceDay = Calendar.current.startOfDay(for: draft.invoiceDate)
        let dueDay = Calendar.current.startOfDay(for: dueDate)
        let diff = Calendar.current.dateComponents([.day], from: invoiceDay, to: dueDay).day
        return diff == offsetDays
    }

    private func copyIBANToClipboard(_ iban: String) {
        let normalized = ParsingService.normalizeIBANValue(iban) ?? ""
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
            draft.dueDate = Calendar.current.date(byAdding: .day, value: days, to: draft.invoiceDate)
        }

        if let categoryLearning = learningProfile(for: key, field: .category),
           categoryLearning.correctionRate >= 0.6,
           let learnedCategory = categoryLearning.lastFinalValue,
           (draft.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.category == "Sonstiges") {
            draft.category = learnedCategory
        }

        if let recipientLearning = learningProfile(for: key, field: .paymentRecipient),
           recipientLearning.correctionRate >= 0.6,
           let learnedRecipient = recipientLearning.lastFinalValue,
           draft.paymentRecipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draft.paymentRecipient = learnedRecipient
        }
    }

    private func learningProfile(for vendorID: String, field: OCRLearningProfile.Field) -> OCRLearningProfile? {
        let id = OCRLearningProfile.profileID(vendorID: vendorID, field: field)
        return ocrLearningProfiles.first(where: { $0.id == id })
    }

    private func persistOCRLearningFromReview() {
        let vendorKeySource = draft.vendorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !vendorKeySource.isEmpty else { return }

        let vendorID = VendorProfile.profileID(from: vendorKeySource)
        guard !vendorID.isEmpty else { return }

        updateLearning(vendorID: vendorID, field: .vendor, suggested: draft.ocrOriginalVendorName, final: draft.vendorName)
        updateLearning(vendorID: vendorID, field: .paymentRecipient, suggested: draft.ocrOriginalPaymentRecipient, final: draft.paymentRecipient)
        updateLearning(vendorID: vendorID, field: .category, suggested: draft.ocrOriginalCategory, final: draft.category)
        updateLearning(vendorID: vendorID, field: .amount, suggested: decimalText(draft.ocrOriginalAmount), final: decimalText(draft.amount))
        updateLearning(vendorID: vendorID, field: .dueDate, suggested: isoDate(draft.ocrOriginalDueDate), final: isoDate(draft.dueDate))
        updateLearning(vendorID: vendorID, field: .invoiceNumber, suggested: draft.ocrOriginalInvoiceNumber, final: draft.invoiceNumber)
        updateLearning(vendorID: vendorID, field: .iban, suggested: normalizedIbanText(draft.ocrOriginalIBAN), final: normalizedIbanText(draft.iban))
    }

    private func updateLearning(vendorID: String, field: OCRLearningProfile.Field, suggested: String?, final: String?) {
        let normalizedSuggested = canonicalLearningValue(suggested)
        let normalizedFinal = canonicalLearningValue(final)
        guard normalizedSuggested != nil || normalizedFinal != nil else { return }

        let id = OCRLearningProfile.profileID(vendorID: vendorID, field: field)
        let changed = normalizedSuggested != normalizedFinal

        if let existing = ocrLearningProfiles.first(where: { $0.id == id }) {
            existing.sampleCount += 1
            if changed {
                existing.correctionCount += 1
            }
            existing.lastSuggestedValue = normalizedSuggested
            existing.lastFinalValue = normalizedFinal
            existing.updatedAt = .now
        } else {
            let profile = OCRLearningProfile(
                id: id,
                vendorID: vendorID,
                field: field,
                sampleCount: 1,
                correctionCount: changed ? 1 : 0,
                lastSuggestedValue: normalizedSuggested,
                lastFinalValue: normalizedFinal
            )
            modelContext.insert(profile)
        }
    }

    private func canonicalLearningValue(_ value: String?) -> String? {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .lowercased()
    }

    private func decimalText(_ value: Decimal?) -> String? {
        guard let value else { return nil }
        return value.formatted(.number.precision(.fractionLength(2)))
    }

    private func isoDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func normalizedIbanText(_ iban: String?) -> String? {
        let normalized = ParsingService.normalizeIBANValue(iban) ?? ""
        return normalized.isEmpty ? nil : normalized
    }

    @ViewBuilder
    private func confidenceRow(_ title: String, _ value: Double?) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let value {
                Text("\(Int((value * 100).rounded()))% · \(confidenceLevelLabel(for: value))")
                    .monospacedDigit()
                    .foregroundStyle(confidenceLevelColor(for: value))
            } else {
                Text("-")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }

    private func confidenceLevelLabel(for value: Double) -> String {
        if value >= 0.85 { return L10n.t("hoch", "high") }
        if value >= 0.65 { return L10n.t("mittel", "medium") }
        return L10n.t("prüfen", "review")
    }

    private func confidenceLevelColor(for value: Double) -> Color {
        if value >= 0.85 { return .green }
        if value >= 0.65 { return .orange }
        return .red
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
