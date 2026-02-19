import Foundation
import SwiftData
import UIKit

enum ScanCaptureMode {
    case invoice
    case receipt
}

enum InvoiceImportKind {
    case scanInvoice
    case scanReceipt
    case pdfImport
    case manual
}

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isProcessing = false
    @Published var parsingWarning: String?
    @Published var ocrDebugInfo: String?
    @Published var draft: InvoiceDraft?

    private let ocrService: OCRServicing
    private let parsingService: ParsingService
    private let imageStore: ImageStore

    init(
        ocrService: OCRServicing = OCRService(),
        parsingService: ParsingService = ParsingService(),
        imageStore: ImageStore = ImageStore()
    ) {
        self.ocrService = ocrService
        self.parsingService = parsingService
        self.imageStore = imageStore
    }

    func processPickedImage(_ image: UIImage, mode: ScanCaptureMode = .invoice) async {
        selectedImage = image
        isProcessing = true
        defer { isProcessing = false }

        do {
            let ocr = try await ocrService.recognizeText(from: image)
            let text = ocr.text
            var parsed = parsingService.parse(text: text)
            applyQualityIndicators(to: &parsed)
            parsingWarning = text.isEmpty ? "Kein Text erkannt. Bitte Daten manuell ergänzen." : nil
            ocrDebugInfo = ocr.debugSummary
            draft = InvoiceDraft(parsed: parsed, captureMode: mode)
        } catch {
            let failed = ParsedInvoiceData(
                extractedText: "",
                ocrConfidence: 0,
                vendorConfidence: 0,
                amountConfidence: 0,
                dueDateConfidence: 0,
                invoiceNumberConfidence: 0,
                ibanConfidence: 0,
                reviewHint: "OCR fehlgeschlagen"
            )
            draft = InvoiceDraft(parsed: failed, captureMode: mode)
            parsingWarning = "OCR fehlgeschlagen. Bitte Daten manuell ergänzen."
            ocrDebugInfo = nil
        }
    }

    func processPDF(at url: URL) async {
        selectedImage = nil
        isProcessing = true
        defer { isProcessing = false }

        do {
            let ocr = try await ocrService.extractText(fromPDFAt: url)
            let text = ocr.text
            var parsed = parsingService.parse(text: text)
            applyQualityIndicators(to: &parsed)
            parsingWarning = text.isEmpty ? "Kein auswertbarer PDF-Text erkannt. Bitte Daten manuell ergänzen." : nil
            ocrDebugInfo = ocr.debugSummary
            draft = InvoiceDraft(parsed: parsed, captureMode: .invoice, importKind: .pdfImport)
        } catch {
            let failed = ParsedInvoiceData(
                extractedText: "",
                ocrConfidence: 0,
                vendorConfidence: 0,
                amountConfidence: 0,
                dueDateConfidence: 0,
                invoiceNumberConfidence: 0,
                ibanConfidence: 0,
                reviewHint: "PDF-Import fehlgeschlagen"
            )
            draft = InvoiceDraft(parsed: failed, captureMode: .invoice, importKind: .pdfImport)
            parsingWarning = "PDF konnte nicht gelesen werden. Bitte Daten manuell ergänzen."
            ocrDebugInfo = nil
        }
    }

    func prepareManualEntry() {
        selectedImage = nil
        isProcessing = false
        parsingWarning = nil
        ocrDebugInfo = nil
        draft = InvoiceDraft(importKind: .manual)
    }

    func createInvoice(from draft: InvoiceDraft, modelContext: ModelContext) throws -> Invoice {
        let effectivePaidAt: Date? = draft.status == .paid ? (draft.paidAt ?? draft.receivedAt) : nil
        let effectiveReminderEnabled = draft.status == .open ? draft.reminderEnabled : false
        let effectiveReminderDate = draft.status == .open ? draft.reminderDate : nil

        let invoice = Invoice(
            id: draft.id,
            createdAt: .now,
            receivedAt: draft.receivedAt,
            vendorName: draft.vendorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unbekannt" : draft.vendorName,
            paymentRecipient: draft.paymentRecipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? draft.vendorName : draft.paymentRecipient,
            amount: draft.amount,
            category: draft.category,
            dueDate: draft.dueDate,
            invoiceNumber: draft.invoiceNumber,
            iban: draft.iban,
            note: draft.note,
            status: draft.status,
            paidAt: effectivePaidAt,
            reminderEnabled: effectiveReminderEnabled,
            reminderDate: effectiveReminderDate,
            imageFileName: nil,
            extractedText: draft.extractedText,
            ocrConfidence: draft.ocrConfidence,
            vendorConfidence: draft.vendorConfidence,
            amountConfidence: draft.amountConfidence,
            dueDateConfidence: draft.dueDateConfidence,
            invoiceNumberConfidence: draft.invoiceNumberConfidence,
            ibanConfidence: draft.ibanConfidence,
            needsReview: draft.needsReview,
            reviewHint: draft.reviewHint
        )

        if let selectedImage {
            let fileName = try imageStore.save(image: selectedImage, id: invoice.id)
            invoice.imageFileName = fileName
        }

        modelContext.insert(invoice)
        upsertVendorProfile(from: invoice, modelContext: modelContext)
        try modelContext.save()
        return invoice
    }

    private func upsertVendorProfile(from invoice: Invoice, modelContext: ModelContext) {
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

    private func applyQualityIndicators(to parsed: inout ParsedInvoiceData) {
        let text = parsed.extractedText
        let vendorEvidence = hasVendorEvidence(vendor: parsed.vendorName, text: text)
        let amountEvidence = hasAmountEvidence(amount: parsed.amount, text: text)
        let dueDateEvidence = hasDueDateEvidence(dueDate: parsed.dueDate, text: text)
        let numberEvidence = hasInvoiceNumberEvidence(invoiceNumber: parsed.invoiceNumber, text: text)
        let ibanEvidence = hasIBANEvidence(iban: parsed.iban, text: text)

        var vendorConfidence = qualityForVendor(parsed.vendorName)
        var amountConfidence = parsed.amount == nil ? 0.05 : 0.75
        var dueDateConfidence = parsed.dueDate == nil ? 0.05 : 0.75
        var numberConfidence = qualityForInvoiceNumber(parsed.invoiceNumber)
        var ibanConfidence = qualityForIBAN(parsed.iban)

        vendorConfidence = vendorEvidence ? min(0.95, vendorConfidence + 0.1) : max(0.05, vendorConfidence * 0.45)
        amountConfidence = amountEvidence ? min(0.95, amountConfidence + 0.15) : max(0.05, amountConfidence * 0.45)
        dueDateConfidence = dueDateEvidence ? min(0.95, dueDateConfidence + 0.15) : max(0.05, dueDateConfidence * 0.45)
        numberConfidence = numberEvidence ? min(0.95, numberConfidence + 0.15) : max(0.05, numberConfidence * 0.45)
        ibanConfidence = ibanEvidence ? min(0.95, ibanConfidence + 0.15) : max(0.05, ibanConfidence * 0.45)

        if let dueDate = parsed.dueDate {
            let today = Calendar.current.startOfDay(for: Date())
            let due = Calendar.current.startOfDay(for: dueDate)
            if due < Calendar.current.date(byAdding: .day, value: -60, to: today) ?? due {
                dueDateConfidence = min(dueDateConfidence, 0.35)
            }
        }

        parsed.vendorConfidence = vendorConfidence
        parsed.amountConfidence = amountConfidence
        parsed.dueDateConfidence = dueDateConfidence
        parsed.invoiceNumberConfidence = numberConfidence
        parsed.ibanConfidence = ibanConfidence

        let all = [vendorConfidence, amountConfidence, dueDateConfidence, numberConfidence, ibanConfidence]
        var overall = all.reduce(0, +) / Double(all.count)
        let evidenceCount = [vendorEvidence, amountEvidence, dueDateEvidence, numberEvidence, ibanEvidence].filter { $0 }.count
        if evidenceCount <= 1 {
            overall = min(overall, 0.45)
        } else if evidenceCount == 2 {
            overall = min(overall, 0.65)
        } else if evidenceCount == 3 {
            overall = min(overall, 0.8)
        }
        parsed.ocrConfidence = overall

        var low: [String] = []
        if vendorConfidence < 0.7 { low.append("Anbieter") }
        if amountConfidence < 0.7 { low.append("Betrag") }
        if dueDateConfidence < 0.7 { low.append("Fälligkeitsdatum") }
        if numberConfidence < 0.7 { low.append("Rechnungsnummer") }
        if ibanConfidence < 0.7 { low.append("IBAN") }
        parsed.reviewHint = low.isEmpty ? nil : "Bitte prüfen: \(low.joined(separator: ", "))"
    }

    private func qualityForVendor(_ vendor: String) -> Double {
        let normalized = vendor.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty || normalized == "Unbekannt" { return 0.1 }
        if normalized.count < 3 { return 0.3 }
        return 0.9
    }

    private func qualityForInvoiceNumber(_ invoiceNumber: String?) -> Double {
        let value = (invoiceNumber ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return 0.1 }
        if value.count < 4 { return 0.4 }
        return 0.85
    }

    private func qualityForIBAN(_ iban: String?) -> Double {
        let value = (iban ?? "").replacingOccurrences(of: " ", with: "").uppercased()
        if value.isEmpty { return 0.1 }
        let pattern = #"^[A-Z]{2}\d{2}[A-Z0-9]{10,30}$"#
        if value.range(of: pattern, options: .regularExpression) != nil {
            return 0.9
        }
        return 0.35
    }

    private func hasVendorEvidence(vendor: String, text: String) -> Bool {
        let name = vendor.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.lowercased() != "unbekannt" else { return false }
        let lines = text.lowercased().split(separator: "\n").prefix(8).map(String.init)
        return lines.contains { $0.contains(name.lowercased()) }
    }

    private func hasAmountEvidence(amount: Decimal?, text: String) -> Bool {
        guard let amount else { return false }
        let keywords = ["betrag", "summe", "gesamt", "total", "zu zahlen", "eur", "€"]
        let lowerLines = text.lowercased().split(separator: "\n").map(String.init)
        let normalized = NSDecimalNumber(decimal: amount).doubleValue
        let dot = String(format: "%.2f", normalized)
        let comma = dot.replacingOccurrences(of: ".", with: ",")
        return lowerLines.contains { line in
            keywords.contains(where: { line.contains($0) }) && (line.contains(dot) || line.contains(comma))
        }
    }

    private func hasDueDateEvidence(dueDate: Date?, text: String) -> Bool {
        guard let dueDate else { return false }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "dd.MM.yyyy"
        let token1 = formatter.string(from: dueDate)
        formatter.dateFormat = "yyyy-MM-dd"
        let token2 = formatter.string(from: dueDate)
        let keywords = ["fällig", "faellig", "zahlbar bis", "due", "due date", "zahlungsziel"]
        let lowerLines = text.lowercased().split(separator: "\n").map(String.init)
        return lowerLines.contains { line in
            keywords.contains(where: { line.contains($0) }) && (line.contains(token1.lowercased()) || line.contains(token2.lowercased()))
        }
    }

    private func hasInvoiceNumberEvidence(invoiceNumber: String?, text: String) -> Bool {
        let number = (invoiceNumber ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !number.isEmpty else { return false }
        let keywords = ["rechnung", "rechnungsnr", "rechnungsnummer", "invoice", "invoice no", "invoice number"]
        let lower = text.lowercased()
        return keywords.contains(where: { lower.contains($0) }) && lower.contains(number.lowercased())
    }

    private func hasIBANEvidence(iban: String?, text: String) -> Bool {
        let normalized = (iban ?? "").replacingOccurrences(of: " ", with: "").uppercased()
        guard !normalized.isEmpty else { return false }
        let upper = text.uppercased().replacingOccurrences(of: " ", with: "")
        return upper.contains(normalized)
    }
}

struct InvoiceDraft {
    var id: UUID = UUID()
    var vendorName: String = ""
    var paymentRecipient: String = ""
    var category: String = "Sonstiges"
    var amount: Decimal?
    var receivedAt: Date = Date()
    var dueDate: Date?
    var invoiceNumber: String = ""
    var iban: String = ""
    var note: String = ""
    var importKind: InvoiceImportKind = .manual
    var status: Invoice.Status = .open
    var paidAt: Date?
    var reminderEnabled: Bool = false
    var reminderDate: Date?
    var extractedText: String = ""
    var ocrConfidence: Double?
    var vendorConfidence: Double?
    var amountConfidence: Double?
    var dueDateConfidence: Double?
    var invoiceNumberConfidence: Double?
    var ibanConfidence: Double?
    var needsReview: Bool = false
    var reviewHint: String = ""

    init(parsed: ParsedInvoiceData? = nil, captureMode: ScanCaptureMode = .invoice, importKind: InvoiceImportKind? = nil) {
        self.importKind = importKind ?? (captureMode == .receipt ? .scanReceipt : .scanInvoice)
        guard let parsed else {
            return
        }
        vendorName = parsed.vendorName
        paymentRecipient = parsed.paymentRecipient
        category = parsed.category
        amount = parsed.amount
        receivedAt = Date()
        dueDate = parsed.dueDate
        invoiceNumber = parsed.invoiceNumber ?? ""
        iban = parsed.iban ?? ""
        note = parsed.note ?? ""
        extractedText = parsed.extractedText
        ocrConfidence = parsed.ocrConfidence
        vendorConfidence = parsed.vendorConfidence
        amountConfidence = parsed.amountConfidence
        dueDateConfidence = parsed.dueDateConfidence
        invoiceNumberConfidence = parsed.invoiceNumberConfidence
        ibanConfidence = parsed.ibanConfidence
        reviewHint = parsed.reviewHint ?? ""
        needsReview = (parsed.ocrConfidence ?? 0) < 0.8 || !reviewHint.isEmpty

        if let dueDate {
            reminderDate = Calendar.current.date(byAdding: .day, value: -AppSettings.defaultReminderOffsetDays, to: dueDate)
        }

        if captureMode == .receipt || shouldSuggestPaidStatus(from: parsed.extractedText) {
            status = .paid
            paidAt = receivedAt
            reminderEnabled = false
            reminderDate = nil
        }
    }

    private func shouldSuggestPaidStatus(from text: String) -> Bool {
        let lower = text.lowercased()
        let receiptMarkers = [
            "kassenbon", "kassenbeleg", "bon", "ec-karte", "kartenzahlung",
            "barzahlung", "bar bezahlt", "wechselgeld", "mwst", "ust",
            "summe eur", "gesamt eur"
        ]
        let invoiceMarkers = [
            "zahlbar bis", "fällig", "faellig", "rechnungsnummer", "iban",
            "zahlungsempfänger", "ueberweisung"
        ]

        let receiptHits = receiptMarkers.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let invoiceHits = invoiceMarkers.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        return receiptHits >= 2 && invoiceHits == 0
    }
}
