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
                    Section("Prüfhinweis") {
                        if !draft.reviewHint.isEmpty {
                            Text(draft.reviewHint)
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                        if let confidence = draft.ocrConfidence {
                            Text("OCR-Sicherheit: \(Int((confidence * 100).rounded()))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            confidenceRow("Anbieter", draft.vendorConfidence)
                            confidenceRow("Betrag", draft.amountConfidence)
                            confidenceRow("Fälligkeitsdatum", draft.dueDateConfidence)
                            confidenceRow("Rechnungsnummer", draft.invoiceNumberConfidence)
                            confidenceRow("IBAN", draft.ibanConfidence)
                        }
                    }
                }

                if let importHint = importHintText {
                    Section("Import") {
                        Text(importHint)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Rechnung") {
                    DatePicker("Eingangsdatum", selection: $draft.receivedAt, displayedComponents: .date)
                    Picker("Status", selection: statusBinding) {
                        Text("Offen").tag(Invoice.Status.open)
                        Text("Bezahlt").tag(Invoice.Status.paid)
                    }
                    .pickerStyle(.segmented)
                    if draft.status == .paid {
                        DatePicker("Bezahlt am", selection: paidAtBinding, displayedComponents: .date)
                        Button("Als bezahlt (heute)") {
                            draft.status = .paid
                            draft.paidAt = Calendar.current.startOfDay(for: Date())
                        }
                        .buttonStyle(.bordered)
                    }
                    highlightedField(title: "Anbieter", confidence: draft.vendorConfidence) {
                        TextField("z. B. Stadtwerke", text: $draft.vendorName)
                    }
                    highlightedField(title: "Zahlungsempfaenger", confidence: draft.vendorConfidence) {
                        TextField("Empfaenger laut Rechnung", text: $draft.paymentRecipient)
                    }
                    Picker("Kategorie", selection: $draft.category) {
                        ForEach(allCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    HStack(spacing: 8) {
                        TextField("Eigene Kategorie", text: $customCategoryInput)
                        Button("Hinzufügen") {
                            addCustomCategory()
                        }
                        .buttonStyle(.bordered)
                    }
                    highlightedField(title: "Betrag", confidence: draft.amountConfidence) {
                        TextField("z. B. 49,99", value: $draft.amount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    highlightedField(title: "Fälligkeitsdatum", confidence: draft.dueDateConfidence) {
                        HStack {
                            Button("+7 Tage") {
                                applyDueDate(offsetDays: 7)
                            }
                            .buttonStyle(.bordered)

                            Button("+14 Tage") {
                                applyDueDate(offsetDays: 14)
                            }
                            .buttonStyle(.bordered)

                            Button("+30 Tage") {
                                applyDueDate(offsetDays: 30)
                            }
                            .buttonStyle(.bordered)
                        }
                        DatePicker("Fällig am", selection: dueDateBinding, displayedComponents: .date)
                    }
                    highlightedField(title: "Rechnungsnummer", confidence: draft.invoiceNumberConfidence) {
                        TextField("z. B. INV-2026-001", text: $draft.invoiceNumber)
                    }
                    highlightedField(title: "IBAN", confidence: draft.ibanConfidence) {
                        TextField("DE89 3704 0044 0532 0130 00", text: $draft.iban)
                            .textInputAutocapitalization(.characters)
                        HStack(spacing: 10) {
                            Button("IBAN kopieren") {
                                copyIBANToClipboard(draft.iban)
                            }
                            .buttonStyle(.bordered)
                            if ibanCopied {
                                Text("Kopiert")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        Text("Bitte IBAN vor der Zahlung pruefen.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notiz") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notiz")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Optional", text: $draft.note, axis: .vertical)
                    }
                }

                Section("Reminder") {
                    if draft.status == .open {
                        Toggle("Erinnerung aktivieren", isOn: $draft.reminderEnabled)
                        if draft.reminderEnabled {
                            DatePicker("Erinnerungsdatum", selection: reminderDateBinding, displayedComponents: [.date, .hourAndMinute])
                        }
                    } else {
                        Text("Für bezahlte Rechnungen sind Erinnerungen deaktiviert.")
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
            .navigationTitle("Review")
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
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var dueDateBinding: Binding<Date> {
        Binding {
            draft.dueDate ?? Date()
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
            return "Importtyp: Kassenbon (automatisch auf Bezahlt gesetzt)"
        case .scanInvoice:
            return "Importtyp: Rechnungsscan"
        case .pdfImport:
            return "Importtyp: PDF Import"
        case .manual:
            return "Importtyp: Manuell"
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
        let due = Calendar.current.date(byAdding: .day, value: offsetDays, to: Date()) ?? Date()
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
        if draft.dueDate == nil, let days = profile.preferredDueOffsetDays {
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
                Text("Unsicher erkannt - bitte manuell prüfen")
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
