import SwiftUI
import SwiftData
import UIKit

struct InvoiceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InvoiceDetailViewModel()

    @Bindable var invoice: Invoice
    @State private var showDeleteConfirm = false
    @State private var showFullScreenImage = false
    @State private var ibanCopied = false
    @State private var customCategoryInput = ""
    @AppStorage("categories.custom") private var customCategoriesStorage: String = ""

    var body: some View {
        Form {
            Section("Status") {
                LabeledContent("Aktuell", value: invoice.status == .open ? "Offen" : "Bezahlt")
                if let paidAt = invoice.paidAt {
                    LabeledContent("Bezahlt am", value: paidAt.formatted(date: .abbreviated, time: .shortened))
                }
                Button(invoice.status == .open ? "Als bezahlt markieren" : "Als offen markieren") {
                    if invoice.status == .open {
                        viewModel.markAsPaid(invoice)
                    } else {
                        viewModel.markAsOpen(invoice)
                    }
                    try? modelContext.save()
                }
            }

            Section("Details") {
                DatePicker("Eingangsdatum", selection: $invoice.receivedAt, displayedComponents: .date)
                TextField("Anbieter", text: $invoice.vendorName)
                TextField("Zahlungsempfaenger", text: $invoice.paymentRecipient)
                Picker("Kategorie", selection: categoryBinding) {
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
                TextField("Betrag", value: $invoice.amount, format: .number)
                    .keyboardType(.decimalPad)
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
                TextField("Rechnungsnummer", text: optionalBinding($invoice.invoiceNumber))
                TextField("IBAN", text: optionalBinding($invoice.iban))
                    .textInputAutocapitalization(.characters)
                HStack(spacing: 10) {
                    Button("IBAN kopieren") {
                        copyIBANToClipboard(invoice.iban)
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
                TextField("Notiz", text: optionalBinding($invoice.note), axis: .vertical)
            }

            Section("Reminder") {
                Toggle("Aktiv", isOn: reminderBinding)
                if invoice.reminderEnabled {
                    DatePicker("Erinnern am", selection: reminderDateBinding, displayedComponents: [.date, .hourAndMinute])
                }
            }

            if let image = viewModel.image(for: invoice) {
                Section("Beleg") {
                    Button {
                        showFullScreenImage = true
                    } label: {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                Button("Löschen", role: .destructive) {
                    showDeleteConfirm = true
                }
            }

            if let extractedText = invoice.extractedText, !extractedText.isEmpty {
                Section("OCR Debug") {
                    if let confidence = invoice.ocrConfidence {
                        Text("OCR-Sicherheit: \(Int((confidence * 100).rounded()))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        confidenceRow("Anbieter", invoice.vendorConfidence)
                        confidenceRow("Betrag", invoice.amountConfidence)
                        confidenceRow("Fälligkeitsdatum", invoice.dueDateConfidence)
                        confidenceRow("Rechnungsnummer", invoice.invoiceNumberConfidence)
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
        .confirmationDialog("Rechnung löschen?", isPresented: $showDeleteConfirm) {
            Button("Löschen", role: .destructive) {
                viewModel.delete(invoice: invoice, modelContext: modelContext)
                try? modelContext.save()
                dismiss()
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            FullScreenImageView(image: viewModel.image(for: invoice), isPresented: $showFullScreenImage)
        }
        .task {
            await viewModel.rescheduleIfNeeded(invoice)
        }
        .onDisappear {
            invoice.iban = invoice.iban?.replacingOccurrences(of: " ", with: "").uppercased()
            upsertVendorProfile(from: invoice)
            try? modelContext.save()
        }
    }

    private var dueDateBinding: Binding<Date> {
        Binding {
            invoice.dueDate ?? Date()
        } set: { value in
            invoice.dueDate = value
            if invoice.reminderDate == nil {
                invoice.reminderDate = Calendar.current.date(byAdding: .day, value: -AppSettings.defaultReminderOffsetDays, to: value)
            }
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
        let base = invoice.createdAt
        let due = Calendar.current.date(byAdding: .day, value: offsetDays, to: base) ?? Date()
        invoice.dueDate = due
        if invoice.reminderDate == nil || invoice.reminderEnabled {
            invoice.reminderDate = Calendar.current.date(byAdding: .day, value: -AppSettings.defaultReminderOffsetDays, to: due)
        }
    }

    private func copyIBANToClipboard(_ iban: String?) {
        let normalized = (iban ?? "").replacingOccurrences(of: " ", with: "").uppercased()
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
            let received = Calendar.current.startOfDay(for: invoice.receivedAt)
            let due = Calendar.current.startOfDay(for: dueDate)
            return Calendar.current.dateComponents([.day], from: received, to: due).day
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
