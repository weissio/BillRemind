import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var invoices: [Invoice]
    @Query private var vendorProfiles: [VendorProfile]
    @Query private var incomeEntries: [IncomeEntry]
    @Query private var installmentPlans: [InstallmentPlan]
    @Query private var installmentSpecialRepayments: [InstallmentSpecialRepayment]
    @StateObject private var viewModel = SettingsViewModel()
    @AppStorage(AppSettings.exportFormatKey) private var exportFormat: String = AppSettings.exportFormat
    @AppStorage(AppSettings.ocrDebugVisibleKey) private var ocrDebugVisible: Bool = AppSettings.ocrDebugVisible
    @State private var backupURL: URL?
    @State private var showRestoreImporter = false
    @State private var infoMessage: String?

    var body: some View {
        Form {
            Section("Datenschutz") {
                Text("Alle Daten bleiben lokal auf deinem Gerät.")
                    .font(.subheadline)
            }

            Section("Standard-Reminder") {
                Picker("Tage vor Fälligkeit", selection: $viewModel.reminderOffsetDays) {
                    ForEach(viewModel.offsetOptions, id: \.self) { value in
                        Text("\(value) Tage")
                    }
                }
            }

            Section("Sicherheit") {
                Toggle("App-Sperre mit Face ID / Touch ID", isOn: $viewModel.biometricLockEnabled)
            }

            Section("Cashflow-Warnung") {
                Toggle("Mitteilung bei negativem Cashflow", isOn: $viewModel.negativeCashflowAlertEnabled)
                if viewModel.negativeCashflowAlertEnabled {
                    Picker("Zeitraum", selection: $viewModel.negativeCashflowAlertWeeks) {
                        ForEach(viewModel.cashflowWeeksOptions, id: \.self) { value in
                            Text("\(value) Wochen")
                        }
                    }
                }
            }

            Section("OCR & Priorität") {
                Picker("Bald fällig ab", selection: $viewModel.urgencySoonDays) {
                    ForEach(viewModel.urgencySoonDaysOptions, id: \.self) { value in
                        Text("\(value) Tage")
                    }
                }
                Picker("OCR-Prüfgrenze", selection: $viewModel.reviewConfidencePercent) {
                    ForEach(viewModel.reviewConfidenceOptions, id: \.self) { value in
                        Text("\(value)%")
                    }
                }
                Toggle("OCR-Debug in Review anzeigen", isOn: $ocrDebugVisible)
            }

            Section("Export") {
                Picker("Standardformat", selection: $exportFormat) {
                    Text("Excel (.xlsx)").tag("xlsx")
                    Text("CSV (.csv)").tag("csv")
                    Text("XML (.xml)").tag("xml")
                }
                .pickerStyle(.menu)
            }

            Section("Backup & Restore") {
                Button("Backup erstellen") {
                    createBackup()
                }
                .buttonStyle(.borderedProminent)
                if let backupURL {
                    ShareLink(item: backupURL) {
                        Text("Backup teilen")
                            .fontWeight(.medium)
                    }
                }
                Button("Backup wiederherstellen") {
                    showRestoreImporter = true
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
        .navigationTitle("Einstellungen")
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
                Button("Zurück") {
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
                infoMessage = "Restore abgebrochen."
            }
        }
    }

    private func createBackup() {
        let payload = BackupPayload(
            invoices: invoices.map(InvoiceSnapshot.init),
            vendorProfiles: vendorProfiles.map(VendorProfileSnapshot.init),
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
            infoMessage = "Backup erstellt."
        } catch {
            infoMessage = "Backup fehlgeschlagen."
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
            for income in incomeEntries { modelContext.delete(income) }
            for plan in installmentPlans { modelContext.delete(plan) }
            for repayment in installmentSpecialRepayments { modelContext.delete(repayment) }

            for snapshot in payload.invoices {
                modelContext.insert(snapshot.makeModel())
            }
            for snapshot in payload.vendorProfiles {
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
            infoMessage = "Backup wiederhergestellt."
        } catch {
            infoMessage = "Restore fehlgeschlagen."
        }
    }
}

struct FeedbackView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackCategory: FeedbackCategory = .bug
    @State private var feedbackText: String = ""
    @State private var infoMessage: String?

    var body: some View {
        Form {
            Section("Feedback") {
                Picker("Kategorie", selection: $feedbackCategory) {
                    ForEach(FeedbackCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.menu)

                TextField("Kurzbeschreibung", text: $feedbackText, axis: .vertical)
                    .font(.body)

                Button("Feedback senden") {
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
        .navigationTitle("Feedback")
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
                Button("Zurück") {
                    dismiss()
                }
            }
        }
    }

    private func sendFeedbackMail() {
        let bodyText = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let subject = "BillRemind Feedback [\(feedbackCategory.rawValue)]"
        let body = """
        Kategorie: \(feedbackCategory.rawValue)
        Nachricht: \(bodyText.isEmpty ? "(bitte ausfüllen)" : bodyText)

        App-Version: \(version) (\(build))
        iOS: \(UIDevice.current.systemVersion)
        """

        let recipient = "feedback@billremind.app"
        guard
            let subjectEscaped = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let bodyEscaped = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "mailto:\(recipient)?subject=\(subjectEscaped)&body=\(bodyEscaped)")
        else {
            infoMessage = "Feedback-Mail konnte nicht vorbereitet werden."
            return
        }
        openURL(url)
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
}

private struct BackupPayload: Codable {
    let invoices: [InvoiceSnapshot]
    let vendorProfiles: [VendorProfileSnapshot]
    let incomeEntries: [IncomeEntrySnapshot]
    let installmentPlans: [InstallmentPlanSnapshot]
    let installmentSpecialRepayments: [InstallmentSpecialRepaymentSnapshot]

    init(
        invoices: [InvoiceSnapshot],
        vendorProfiles: [VendorProfileSnapshot],
        incomeEntries: [IncomeEntrySnapshot],
        installmentPlans: [InstallmentPlanSnapshot],
        installmentSpecialRepayments: [InstallmentSpecialRepaymentSnapshot]
    ) {
        self.invoices = invoices
        self.vendorProfiles = vendorProfiles
        self.incomeEntries = incomeEntries
        self.installmentPlans = installmentPlans
        self.installmentSpecialRepayments = installmentSpecialRepayments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        invoices = try container.decode([InvoiceSnapshot].self, forKey: .invoices)
        vendorProfiles = try container.decode([VendorProfileSnapshot].self, forKey: .vendorProfiles)
        incomeEntries = try container.decode([IncomeEntrySnapshot].self, forKey: .incomeEntries)
        installmentPlans = try container.decode([InstallmentPlanSnapshot].self, forKey: .installmentPlans)
        installmentSpecialRepayments = try container.decodeIfPresent([InstallmentSpecialRepaymentSnapshot].self, forKey: .installmentSpecialRepayments) ?? []
    }
}

private struct InvoiceSnapshot: Codable {
    let id: UUID
    let createdAt: Date
    let receivedAt: Date
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

    init(from invoice: Invoice) {
        id = invoice.id
        createdAt = invoice.createdAt
        receivedAt = invoice.receivedAt
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
