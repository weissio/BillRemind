import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum SupportMailService {
    static let recipient = "mnemor.app@gmail.com"

    static func bugReportURL(isEnglish: Bool, source: String) -> URL? {
        let subject = isEnglish ? "Mnemor Bug Report" : "Mnemor Bugmeldung"
        let body = """
        \(isEnglish ? "Please describe the issue briefly:" : "Bitte Problem kurz beschreiben:")

        \(isEnglish ? "Steps to reproduce:" : "Schritte zur Reproduktion:")
        1.
        2.
        3.

        \(isEnglish ? "Expected behavior:" : "Erwartetes Verhalten:")

        \(isEnglish ? "Actual behavior:" : "Ist-Verhalten:")

        ---
        App: \(appVersionString())
        iOS: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        Source: \(source)
        Locale: \(Locale.current.identifier)
        """

        guard
            let subjectEscaped = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let bodyEscaped = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return nil
        }
        return URL(string: "mailto:\(recipient)?subject=\(subjectEscaped)&body=\(bodyEscaped)")
    }

    static func appVersionString() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    static func debugInfoText(source: String) -> String {
        """
        App: \(appVersionString())
        iOS: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        Source: \(source)
        Locale: \(Locale.current.identifier)
        """
    }
}

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var invoices: [Invoice]
    @Query private var vendorProfiles: [VendorProfile]
    @Query private var ocrLearningProfiles: [OCRLearningProfile]
    @Query private var incomeEntries: [IncomeEntry]
    @Query private var installmentPlans: [InstallmentPlan]
    @Query private var installmentSpecialRepayments: [InstallmentSpecialRepayment]
    @StateObject private var viewModel = SettingsViewModel()
    @AppStorage(AppSettings.exportFormatKey) private var exportFormat: String = AppSettings.exportFormat
    @AppStorage(AppSettings.ocrDebugVisibleKey) private var ocrDebugVisible: Bool = AppSettings.ocrDebugVisible
    @AppStorage(AppSettings.appLanguageCodeKey) private var appLanguageCode: String = AppSettings.appLanguageCode
    @State private var backupURL: URL?
    @State private var showRestoreImporter = false
    @State private var infoMessage: String?

    var body: some View {
        Form {
            Section(isEnglish ? "Language" : "Sprache") {
                Picker(isEnglish ? "App language" : "App-Sprache", selection: $appLanguageCode) {
                    Text("Deutsch").tag("de")
                    Text("English").tag("en")
                }
                .pickerStyle(.segmented)
            }

            Section(L10n.t("Datenschutz", "Privacy")) {
                Text(L10n.t("Alle Daten bleiben lokal auf deinem Gerät.", "All data stays local on your device."))
                    .font(.subheadline)
            }

            Section(L10n.t("Standard-Reminder", "Default reminder")) {
                Picker(L10n.t("Tage vor Fälligkeit", "Days before due date"), selection: $viewModel.reminderOffsetDays) {
                    ForEach(viewModel.offsetOptions, id: \.self) { value in
                        Text(isEnglish ? "\(value) days" : "\(value) Tage")
                    }
                }
            }

            Section(L10n.t("Sicherheit", "Security")) {
                Toggle(L10n.t("App-Sperre mit Face ID / Touch ID", "App lock with Face ID / Touch ID"), isOn: $viewModel.biometricLockEnabled)
            }

            Section(L10n.t("Cashflow-Warnung", "Cashflow alert")) {
                Toggle(L10n.t("Mitteilung bei negativem Cashflow", "Notify on negative cashflow"), isOn: $viewModel.negativeCashflowAlertEnabled)
                if viewModel.negativeCashflowAlertEnabled {
                    Picker(L10n.t("Zeitraum", "Range"), selection: $viewModel.negativeCashflowAlertWeeks) {
                        ForEach(viewModel.cashflowWeeksOptions, id: \.self) { value in
                            Text(isEnglish ? "\(value) weeks" : "\(value) Wochen")
                        }
                    }
                }
            }

            Section(L10n.t("OCR & Priorität", "OCR & priority")) {
                Picker(L10n.t("Bald fällig ab", "Due soon threshold"), selection: $viewModel.urgencySoonDays) {
                    ForEach(viewModel.urgencySoonDaysOptions, id: \.self) { value in
                        Text(isEnglish ? "\(value) days" : "\(value) Tage")
                    }
                }
                Picker(L10n.t("OCR-Prüfgrenze", "OCR confidence threshold"), selection: $viewModel.reviewConfidencePercent) {
                    ForEach(viewModel.reviewConfidenceOptions, id: \.self) { value in
                        Text("\(value)%")
                    }
                }
                Toggle(L10n.t("OCR-Debug in Review anzeigen", "Show OCR debug in review"), isOn: $ocrDebugVisible)
            }

            Section(L10n.t("Export", "Export")) {
                Picker(L10n.t("Standardformat", "Default format"), selection: $exportFormat) {
                    Text("Excel (.xlsx)").tag("xlsx")
                    Text("CSV (.csv)").tag("csv")
                    Text("XML (.xml)").tag("xml")
                }
                .pickerStyle(.menu)
            }

            Section(L10n.t("Backup & Restore", "Backup & restore")) {
                Button(L10n.t("Backup erstellen", "Create backup")) {
                    createBackup()
                }
                .buttonStyle(.borderedProminent)
                if let backupURL {
                    ShareLink(item: backupURL) {
                        Text(L10n.t("Backup teilen", "Share backup"))
                            .fontWeight(.medium)
                    }
                }
                Button(L10n.t("Backup wiederherstellen", "Restore backup")) {
                    showRestoreImporter = true
                }
            }

            Section(L10n.t("Support", "Support")) {
                Button(L10n.t("Problem melden", "Report issue")) {
                    openBugReportMail()
                }
                Button(L10n.t("Debug-Infos kopieren", "Copy debug info")) {
                    copyDebugInfo()
                }
            }

            if let infoMessage {
                Section {
                    Text(infoMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(isEnglish ? "Settings" : "Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(isEnglish ? "Back" : "Zurück") {
                    dismiss()
                }
            }
        }
        .fileImporter(
            isPresented: $showRestoreImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                restoreBackup(from: url)
            case .failure:
                infoMessage = L10n.t("Restore abgebrochen.", "Restore cancelled.")
            }
        }
    }

    private func createBackup() {
        let payload = BackupPayload(
            invoices: invoices.map(InvoiceSnapshot.init),
            vendorProfiles: vendorProfiles.map(VendorProfileSnapshot.init),
            ocrLearningProfiles: ocrLearningProfiles.map(OCRLearningProfileSnapshot.init),
            incomeEntries: incomeEntries.map(IncomeEntrySnapshot.init),
            installmentPlans: installmentPlans.map(InstallmentPlanSnapshot.init),
            installmentSpecialRepayments: installmentSpecialRepayments.map(InstallmentSpecialRepaymentSnapshot.init)
        )
        do {
            let data = try JSONEncoder().encode(payload)
            let fileName = "billremind-backup-\(Date().formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))).json"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: url)
            backupURL = url
            infoMessage = L10n.t("Backup erstellt.", "Backup created.")
        } catch {
            infoMessage = L10n.t("Backup fehlgeschlagen.", "Backup failed.")
        }
    }

    private func restoreBackup(from url: URL) {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { url.stopAccessingSecurityScopedResource() }
        }
        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(BackupPayload.self, from: data)

            for invoice in invoices { modelContext.delete(invoice) }
            for profile in vendorProfiles { modelContext.delete(profile) }
            for profile in ocrLearningProfiles { modelContext.delete(profile) }
            for income in incomeEntries { modelContext.delete(income) }
            for plan in installmentPlans { modelContext.delete(plan) }
            for repayment in installmentSpecialRepayments { modelContext.delete(repayment) }

            for snapshot in payload.invoices {
                modelContext.insert(snapshot.makeModel())
            }
            for snapshot in payload.vendorProfiles {
                modelContext.insert(snapshot.makeModel())
            }
            for snapshot in payload.ocrLearningProfiles {
                modelContext.insert(snapshot.makeModel())
            }
            for snapshot in payload.incomeEntries {
                modelContext.insert(snapshot.makeModel())
            }
            for snapshot in payload.installmentPlans {
                modelContext.insert(snapshot.makeModel())
            }
            for snapshot in payload.installmentSpecialRepayments {
                modelContext.insert(snapshot.makeModel())
            }

            try modelContext.save()
            infoMessage = L10n.t("Backup wiederhergestellt.", "Backup restored.")
        } catch {
            infoMessage = L10n.t("Restore fehlgeschlagen.", "Restore failed.")
        }
    }

    private var isEnglish: Bool {
        appLanguageCode == "en"
    }

    private func openBugReportMail() {
        guard let url = SupportMailService.bugReportURL(
            isEnglish: isEnglish,
            source: "Settings"
        ) else {
            infoMessage = L10n.t(
                "Bug-Mail konnte nicht vorbereitet werden.",
                "Could not prepare bug email."
            )
            return
        }
        openURL(url)
    }

    private func copyDebugInfo() {
        UIPasteboard.general.string = SupportMailService.debugInfoText(source: "Settings")
        infoMessage = L10n.t("Debug-Infos kopiert.", "Debug info copied.")
    }
}

struct FeedbackView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackCategory: FeedbackCategory = .bug
    @State private var feedbackText: String = ""
    @State private var infoMessage: String?
    @AppStorage(AppSettings.appLanguageCodeKey) private var appLanguageCode: String = AppSettings.appLanguageCode

    var body: some View {
        Form {
            Section(L10n.t("Feedback", "Feedback")) {
                Picker(L10n.t("Kategorie", "Category"), selection: $feedbackCategory) {
                    ForEach(FeedbackCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                .pickerStyle(.menu)

                TextField(L10n.t("Kurzbeschreibung", "Short description"), text: $feedbackText, axis: .vertical)
                    .font(.body)

                Button(L10n.t("Feedback senden", "Send feedback")) {
                    sendFeedbackMail()
                }
                .buttonStyle(.borderedProminent)
            }
            if let infoMessage {
                Section {
                    Text(infoMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(L10n.t("Feedback", "Feedback"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.t("Zurück", "Back")) {
                    dismiss()
                }
            }
        }
    }

    private func sendFeedbackMail() {
        let bodyText = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let subject = appLanguageCode == "en"
            ? "Mnemor Feedback [\(feedbackCategory.rawValue)]"
            : "Mnemor Feedback [\(feedbackCategory.rawValue)]"
        let body = """
        \(L10n.t("Kategorie", "Category")): \(feedbackCategory.rawValue)
        \(L10n.t("Nachricht", "Message")): \(bodyText.isEmpty ? L10n.t("(bitte ausfüllen)", "(please fill in)") : bodyText)

        \(L10n.t("App-Version", "App version")): \(version) (\(build))
        iOS: \(UIDevice.current.systemVersion)
        """

        let recipient = SupportMailService.recipient
        guard
            let subjectEscaped = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let bodyEscaped = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "mailto:\(recipient)?subject=\(subjectEscaped)&body=\(bodyEscaped)")
        else {
            infoMessage = L10n.t("Feedback-Mail konnte nicht vorbereitet werden.", "Could not prepare feedback email.")
            return
        }
        openURL(url)
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(L10n.t("Schnellstart", "Quick start")) {
                helpLine(L10n.t("1. Starte mit Scan und erfasse eine Rechnung oder einen Kassenbon.", "1. Start with Scan and capture an invoice or a receipt."))
                helpLine(L10n.t("2. Prüfe im Review die erkannten Felder und passe sie bei Bedarf kurz an.", "2. Check detected fields in Review and adjust them if needed."))
                helpLine(L10n.t("3. Speichern und danach in Ausgaben oder Auswertung den aktuellen Stand sehen.", "3. Save, then check your current status in Expenses or Analytics."))
            }

            Section(L10n.t("Scan & Import", "Scan & import")) {
                helpLine(L10n.t("Scan Rechnung setzt den Status standardmäßig auf Offen.", "Scan invoice sets the status to Open by default."))
                helpLine(L10n.t("Scan Kassenbon setzt den Status automatisch auf Bezahlt.", "Scan receipt sets the status to Paid automatically."))
                helpLine(L10n.t("Bei +7 / +14 / +30 Tagen wird vom Rechnungsdatum aus gerechnet.", "+7 / +14 / +30 days are calculated from the invoice date."))
                helpLine(L10n.t("Zusätzlich kannst du Rechnungen per PDF importieren oder manuell erfassen.", "You can also import invoices via PDF or enter them manually."))
            }

            Section(L10n.t("Fixkosten & Kredite", "Fixed costs & loans")) {
                helpLine(L10n.t("In Ausgaben kannst du Fixkosten und Kredite getrennt erfassen.", "In Expenses, you can track fixed costs and loans separately."))
                helpLine(L10n.t("Zins und Anfangsschuld sind nur bei Krediten relevant.", "Interest and initial principal are only relevant for loans."))
                helpLine(L10n.t("Sondertilgungen fügst du direkt im Dialog Kredit bearbeiten hinzu.", "You can add special repayments directly in the Edit loan dialog."))
            }

            Section(L10n.t("Backup & Restore", "Backup & restore")) {
                helpLine(L10n.t("Erstelle regelmäßig ein Backup in den Settings.", "Create backups regularly in Settings."))
                helpLine(L10n.t("Wiederherstellen funktioniert in derselben Ansicht mit der JSON-Datei.", "Restore works from the same screen using the JSON file."))
                helpLine(L10n.t("Für den Desktop-Import wird diese JSON-Backup-Datei verwendet.", "The same JSON backup file is used for desktop import."))
            }

            Section(L10n.t("Hinweise", "Notes")) {
                helpLine(L10n.t("Alle Daten bleiben lokal auf deinem Gerät.", "All data stays local on your device."))
                helpLine(L10n.t("Wenn OCR unsicher ist, korrigiere die Felder einfach im Review.", "If OCR confidence is low, simply correct the fields in Review."))
                helpLine(L10n.t("Tipp: Lieber kurz prüfen als später falsche Werte in der Auswertung haben.", "Tip: A quick check now avoids wrong values in analytics later."))
            }
        }
        .navigationTitle(L10n.t("Anleitung", "Guide"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.t("Zurück", "Back")) {
                    dismiss()
                }
            }
        }
    }

    private func helpLine(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.primary)
            .padding(.vertical, 2)
    }
}

private enum FeedbackCategory: String, CaseIterable, Identifiable {
    case ocr = "OCR"
    case ui = "UI"
    case export = "Export"
    case fixedCosts = "Fixkosten"
    case bug = "Bug"
    case wish = "Wunsch"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ocr: return "OCR"
        case .ui: return "UI"
        case .export: return L10n.t("Export", "Export")
        case .fixedCosts: return L10n.t("Fixkosten", "Fixed costs")
        case .bug: return L10n.t("Bug", "Bug")
        case .wish: return L10n.t("Wunsch", "Feature request")
        }
    }
}

private struct BackupPayload: Codable {
    let invoices: [InvoiceSnapshot]
    let vendorProfiles: [VendorProfileSnapshot]
    let ocrLearningProfiles: [OCRLearningProfileSnapshot]
    let incomeEntries: [IncomeEntrySnapshot]
    let installmentPlans: [InstallmentPlanSnapshot]
    let installmentSpecialRepayments: [InstallmentSpecialRepaymentSnapshot]

    init(
        invoices: [InvoiceSnapshot],
        vendorProfiles: [VendorProfileSnapshot],
        ocrLearningProfiles: [OCRLearningProfileSnapshot],
        incomeEntries: [IncomeEntrySnapshot],
        installmentPlans: [InstallmentPlanSnapshot],
        installmentSpecialRepayments: [InstallmentSpecialRepaymentSnapshot]
    ) {
        self.invoices = invoices
        self.vendorProfiles = vendorProfiles
        self.ocrLearningProfiles = ocrLearningProfiles
        self.incomeEntries = incomeEntries
        self.installmentPlans = installmentPlans
        self.installmentSpecialRepayments = installmentSpecialRepayments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        invoices = try container.decode([InvoiceSnapshot].self, forKey: .invoices)
        vendorProfiles = try container.decode([VendorProfileSnapshot].self, forKey: .vendorProfiles)
        ocrLearningProfiles = try container.decodeIfPresent([OCRLearningProfileSnapshot].self, forKey: .ocrLearningProfiles) ?? []
        incomeEntries = try container.decode([IncomeEntrySnapshot].self, forKey: .incomeEntries)
        installmentPlans = try container.decode([InstallmentPlanSnapshot].self, forKey: .installmentPlans)
        installmentSpecialRepayments = try container.decodeIfPresent([InstallmentSpecialRepaymentSnapshot].self, forKey: .installmentSpecialRepayments) ?? []
    }
}

private struct InvoiceSnapshot: Codable {
    let id: UUID
    let createdAt: Date
    let receivedAt: Date
    let invoiceDate: Date?
    let vendorName: String
    let paymentRecipient: String
    let amount: Decimal?
    let category: String
    let dueDate: Date?
    let invoiceNumber: String?
    let iban: String?
    let note: String?
    let statusRaw: String
    let paidAt: Date?
    let reminderEnabled: Bool
    let reminderDate: Date?
    let imageFileName: String?
    let extractedText: String?
    let ocrConfidence: Double?
    let vendorConfidence: Double?
    let amountConfidence: Double?
    let dueDateConfidence: Double?
    let invoiceNumberConfidence: Double?
    let ibanConfidence: Double?
    let needsReview: Bool
    let reviewHint: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case receivedAt
        case invoiceDate
        case vendorName
        case paymentRecipient
        case amount
        case category
        case dueDate
        case invoiceNumber
        case iban
        case note
        case statusRaw
        case paidAt
        case reminderEnabled
        case reminderDate
        case imageFileName
        case extractedText
        case ocrConfidence
        case vendorConfidence
        case amountConfidence
        case dueDateConfidence
        case invoiceNumberConfidence
        case ibanConfidence
        case needsReview
        case reviewHint
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        receivedAt = try container.decode(Date.self, forKey: .receivedAt)
        invoiceDate = try container.decodeIfPresent(Date.self, forKey: .invoiceDate)
        vendorName = try container.decode(String.self, forKey: .vendorName)
        paymentRecipient = try container.decode(String.self, forKey: .paymentRecipient)
        amount = try container.decodeIfPresent(Decimal.self, forKey: .amount)
        category = try container.decode(String.self, forKey: .category)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        invoiceNumber = try container.decodeIfPresent(String.self, forKey: .invoiceNumber)
        iban = try container.decodeIfPresent(String.self, forKey: .iban)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        statusRaw = try container.decode(String.self, forKey: .statusRaw)
        paidAt = try container.decodeIfPresent(Date.self, forKey: .paidAt)
        reminderEnabled = try container.decode(Bool.self, forKey: .reminderEnabled)
        reminderDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate)
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        extractedText = try container.decodeIfPresent(String.self, forKey: .extractedText)
        ocrConfidence = try container.decodeIfPresent(Double.self, forKey: .ocrConfidence)
        vendorConfidence = try container.decodeIfPresent(Double.self, forKey: .vendorConfidence)
        amountConfidence = try container.decodeIfPresent(Double.self, forKey: .amountConfidence)
        dueDateConfidence = try container.decodeIfPresent(Double.self, forKey: .dueDateConfidence)
        invoiceNumberConfidence = try container.decodeIfPresent(Double.self, forKey: .invoiceNumberConfidence)
        ibanConfidence = try container.decodeIfPresent(Double.self, forKey: .ibanConfidence)
        needsReview = try container.decodeIfPresent(Bool.self, forKey: .needsReview) ?? false
        reviewHint = try container.decodeIfPresent(String.self, forKey: .reviewHint)
    }

    init(from invoice: Invoice) {
        id = invoice.id
        createdAt = invoice.createdAt
        receivedAt = invoice.receivedAt
        invoiceDate = invoice.invoiceDate
        vendorName = invoice.vendorName
        paymentRecipient = invoice.paymentRecipient
        amount = invoice.amount
        category = invoice.category
        dueDate = invoice.dueDate
        invoiceNumber = invoice.invoiceNumber
        iban = invoice.iban
        note = invoice.note
        statusRaw = invoice.statusRaw
        paidAt = invoice.paidAt
        reminderEnabled = invoice.reminderEnabled
        reminderDate = invoice.reminderDate
        imageFileName = invoice.imageFileName
        extractedText = invoice.extractedText
        ocrConfidence = invoice.ocrConfidence
        vendorConfidence = invoice.vendorConfidence
        amountConfidence = invoice.amountConfidence
        dueDateConfidence = invoice.dueDateConfidence
        invoiceNumberConfidence = invoice.invoiceNumberConfidence
        ibanConfidence = invoice.ibanConfidence
        needsReview = invoice.needsReview ?? false
        reviewHint = invoice.reviewHint
    }

    func makeModel() -> Invoice {
        Invoice(
            id: id,
            createdAt: createdAt,
            receivedAt: receivedAt,
            invoiceDate: invoiceDate,
            vendorName: vendorName,
            paymentRecipient: paymentRecipient,
            amount: amount,
            category: category,
            dueDate: dueDate,
            invoiceNumber: invoiceNumber,
            iban: iban,
            note: note,
            status: Invoice.Status(rawValue: statusRaw) ?? .open,
            paidAt: paidAt,
            reminderEnabled: reminderEnabled,
            reminderDate: reminderDate,
            imageFileName: imageFileName,
            extractedText: extractedText,
            ocrConfidence: ocrConfidence,
            vendorConfidence: vendorConfidence,
            amountConfidence: amountConfidence,
            dueDateConfidence: dueDateConfidence,
            invoiceNumberConfidence: invoiceNumberConfidence,
            ibanConfidence: ibanConfidence,
            needsReview: needsReview,
            reviewHint: reviewHint
        )
    }
}

private struct VendorProfileSnapshot: Codable {
    let id: String
    let displayName: String
    let preferredPaymentRecipient: String
    let preferredCategory: String
    let preferredDueOffsetDays: Int?
    let updatedAt: Date

    init(from model: VendorProfile) {
        id = model.id
        displayName = model.displayName
        preferredPaymentRecipient = model.preferredPaymentRecipient
        preferredCategory = model.preferredCategory
        preferredDueOffsetDays = model.preferredDueOffsetDays
        updatedAt = model.updatedAt
    }

    func makeModel() -> VendorProfile {
        VendorProfile(
            id: id,
            displayName: displayName,
            preferredPaymentRecipient: preferredPaymentRecipient,
            preferredCategory: preferredCategory,
            preferredDueOffsetDays: preferredDueOffsetDays,
            updatedAt: updatedAt
        )
    }
}

private struct OCRLearningProfileSnapshot: Codable {
    let id: String
    let vendorID: String
    let fieldRaw: String
    let sampleCount: Int
    let correctionCount: Int
    let lastSuggestedValue: String?
    let lastFinalValue: String?
    let updatedAt: Date

    init(from model: OCRLearningProfile) {
        id = model.id
        vendorID = model.vendorID
        fieldRaw = model.fieldRaw
        sampleCount = model.sampleCount
        correctionCount = model.correctionCount
        lastSuggestedValue = model.lastSuggestedValue
        lastFinalValue = model.lastFinalValue
        updatedAt = model.updatedAt
    }

    func makeModel() -> OCRLearningProfile {
        OCRLearningProfile(
            id: id,
            vendorID: vendorID,
            field: OCRLearningProfile.Field(rawValue: fieldRaw) ?? .vendor,
            sampleCount: sampleCount,
            correctionCount: correctionCount,
            lastSuggestedValue: lastSuggestedValue,
            lastFinalValue: lastFinalValue,
            updatedAt: updatedAt
        )
    }
}

private struct IncomeEntrySnapshot: Codable {
    let id: UUID
    let name: String
    let amount: Decimal
    let kindRaw: String
    let startDate: Date
    let isActive: Bool

    init(from model: IncomeEntry) {
        id = model.id
        name = model.name
        amount = model.amount
        kindRaw = model.kindRaw
        startDate = model.startDate
        isActive = model.isActive
    }

    func makeModel() -> IncomeEntry {
        IncomeEntry(
            id: id,
            name: name,
            amount: amount,
            kind: IncomeEntry.Kind(rawValue: kindRaw) ?? .oneTime,
            startDate: startDate,
            isActive: isActive
        )
    }
}

private struct InstallmentPlanSnapshot: Codable {
    let id: UUID
    let kindRaw: String?
    let name: String
    let monthlyPayment: Decimal
    let monthlyInterest: Decimal
    let annualInterestRatePercent: Decimal?
    let initialPrincipal: Decimal?
    let startDate: Date
    let endDate: Date?
    let paymentDay: Int
    let isActive: Bool

    init(from model: InstallmentPlan) {
        id = model.id
        kindRaw = model.kindRaw
        name = model.name
        monthlyPayment = model.monthlyPayment
        monthlyInterest = model.monthlyInterest
        annualInterestRatePercent = model.annualInterestRatePercent
        initialPrincipal = model.initialPrincipal
        startDate = model.startDate
        endDate = model.endDate
        paymentDay = model.paymentDay
        isActive = model.isActive
    }

    func makeModel() -> InstallmentPlan {
        InstallmentPlan(
            id: id,
            kind: InstallmentPlan.Kind(rawValue: kindRaw ?? "") ?? .fixedCost,
            name: name,
            monthlyPayment: monthlyPayment,
            monthlyInterest: monthlyInterest,
            annualInterestRatePercent: annualInterestRatePercent,
            initialPrincipal: initialPrincipal,
            startDate: startDate,
            endDate: endDate,
            paymentDay: paymentDay,
            isActive: isActive
        )
    }
}

private struct InstallmentSpecialRepaymentSnapshot: Codable {
    let id: UUID
    let planID: UUID
    let amount: Decimal
    let repaymentDate: Date
    let note: String?

    init(from model: InstallmentSpecialRepayment) {
        id = model.id
        planID = model.planID
        amount = model.amount
        repaymentDate = model.repaymentDate
        note = model.note
    }

    func makeModel() -> InstallmentSpecialRepayment {
        InstallmentSpecialRepayment(
            id: id,
            planID: planID,
            amount: amount,
            repaymentDate: repaymentDate,
            note: note
        )
    }
}
