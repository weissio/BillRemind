import Foundation
import SwiftData

@Model
final class Invoice {
    enum Status: String, Codable, CaseIterable {
        case open
        case paid
    }

    static let defaultCategories = [
        "Wohnen",
        "Lebensmittel",
        "Versicherung",
        "Telefon & Internet",
        "Abos",
        "Steuern",
        "Mobilität",
        "Sonstiges"
    ]

    /// Anzeige-Pairs fuer die Default-Kategorien. Die kanonische
    /// Speicher-Form bleibt bewusst Deutsch — so ist kein Datenmigrations-
    /// schritt noetig und bestehende Datensaetze funktionieren weiterhin.
    /// Fuer die Anzeige gibt der UI-Layer (siehe Invoice.localizedCategory)
    /// pro Sprache den passenden Label zurueck.
    static let defaultCategoryLocalization: [(canonical: String, en: String)] = [
        ("Wohnen", "Housing"),
        ("Lebensmittel", "Groceries"),
        ("Versicherung", "Insurance"),
        ("Telefon & Internet", "Phone & Internet"),
        ("Abos", "Subscriptions"),
        ("Steuern", "Taxes"),
        ("Mobilität", "Mobility"),
        ("Sonstiges", "Other")
    ]

    /// Liefert den lokalisierten Anzeige-Text fuer eine Kategorie. Bei
    /// kanonischen Default-Kategorien wird im Englisch-Modus die englische
    /// Beschriftung zurueckgegeben; benutzerdefinierte Kategorien werden
    /// unveraendert weitergereicht (User-Eingabe ist sprach-neutral).
    static func localizedCategory(_ canonical: String, isEnglish: Bool) -> String {
        guard isEnglish else { return canonical }
        return defaultCategoryLocalization.first(where: { $0.canonical == canonical })?.en ?? canonical
    }

    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var receivedAt: Date = Date()
    var invoiceDate: Date?
    var vendorName: String
    var paymentRecipient: String = ""
    var amountValue: Double?
    var categoryRaw: String = "Sonstiges"
    var dueDate: Date?
    var invoiceNumber: String?
    var iban: String?
    var note: String?
    var statusRaw: String
    var paidAt: Date?
    var reminderEnabled: Bool
    var reminderDate: Date?
    var imageFileName: String?
    var extractedText: String?
    var ocrConfidence: Double?
    var vendorConfidence: Double?
    var amountConfidence: Double?
    var dueDateConfidence: Double?
    var invoiceNumberConfidence: Double?
    var ibanConfidence: Double?
    var needsReview: Bool?
    var reviewHint: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        receivedAt: Date = .now,
        invoiceDate: Date? = nil,
        vendorName: String = "Unbekannt",
        paymentRecipient: String? = nil,
        amount: Decimal? = nil,
        category: String = "Sonstiges",
        dueDate: Date? = nil,
        invoiceNumber: String? = nil,
        iban: String? = nil,
        note: String? = nil,
        status: Status = .open,
        paidAt: Date? = nil,
        reminderEnabled: Bool = false,
        reminderDate: Date? = nil,
        imageFileName: String? = nil,
        extractedText: String? = nil,
        ocrConfidence: Double? = nil,
        vendorConfidence: Double? = nil,
        amountConfidence: Double? = nil,
        dueDateConfidence: Double? = nil,
        invoiceNumberConfidence: Double? = nil,
        ibanConfidence: Double? = nil,
        needsReview: Bool? = nil,
        reviewHint: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.receivedAt = receivedAt
        self.invoiceDate = invoiceDate ?? receivedAt
        self.vendorName = vendorName
        self.paymentRecipient = paymentRecipient ?? vendorName
        self.amountValue = amount.map { NSDecimalNumber(decimal: $0).doubleValue }
        self.categoryRaw = category
        self.dueDate = dueDate
        self.invoiceNumber = invoiceNumber
        self.iban = iban
        self.note = note
        self.statusRaw = status.rawValue
        self.paidAt = paidAt
        self.reminderEnabled = reminderEnabled
        self.reminderDate = reminderDate
        self.imageFileName = imageFileName
        self.extractedText = extractedText
        self.ocrConfidence = ocrConfidence
        self.vendorConfidence = vendorConfidence
        self.amountConfidence = amountConfidence
        self.dueDateConfidence = dueDateConfidence
        self.invoiceNumberConfidence = invoiceNumberConfidence
        self.ibanConfidence = ibanConfidence
        self.needsReview = needsReview
        self.reviewHint = reviewHint
    }

    var status: Status {
        get { Status(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }

    var amount: Decimal? {
        get {
            guard let amountValue else { return nil }
            return Decimal(amountValue)
        }
        set {
            amountValue = newValue.map { NSDecimalNumber(decimal: $0).doubleValue }
        }
    }

    var category: String {
        get {
            switch categoryRaw {
            case "housing", "utilities":
                return "Wohnen"
            case "insurance":
                return "Versicherung"
            case "telecom":
                return "Telefon & Internet"
            case "subscriptions":
                return "Abos"
            case "taxes":
                return "Steuern"
            case "mobility":
                return "Mobilität"
            case "other":
                return "Sonstiges"
            default:
                return categoryRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Sonstiges" : categoryRaw
            }
        }
        set {
            let cleaned = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            categoryRaw = cleaned.isEmpty ? "Sonstiges" : cleaned
        }
    }
}

@Model
final class VendorProfile {
    @Attribute(.unique) var id: String
    var displayName: String
    var preferredPaymentRecipient: String
    var preferredCategory: String
    var preferredDueOffsetDays: Int?
    var updatedAt: Date

    init(
        id: String,
        displayName: String,
        preferredPaymentRecipient: String,
        preferredCategory: String,
        preferredDueOffsetDays: Int? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.preferredPaymentRecipient = preferredPaymentRecipient
        self.preferredCategory = preferredCategory
        self.preferredDueOffsetDays = preferredDueOffsetDays
        self.updatedAt = updatedAt
    }

    static func profileID(from vendorName: String) -> String {
        vendorName
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

@Model
final class OCRLearningProfile {
    enum Field: String, Codable, CaseIterable, Identifiable {
        case vendor
        case paymentRecipient
        case category
        case amount
        case dueDate
        case invoiceNumber
        case iban

        var id: String { rawValue }
    }

    @Attribute(.unique) var id: String
    var vendorID: String
    var fieldRaw: String
    var sampleCount: Int
    var correctionCount: Int
    var lastSuggestedValue: String?
    var lastFinalValue: String?
    var updatedAt: Date

    init(
        id: String,
        vendorID: String,
        field: Field,
        sampleCount: Int = 0,
        correctionCount: Int = 0,
        lastSuggestedValue: String? = nil,
        lastFinalValue: String? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.vendorID = vendorID
        self.fieldRaw = field.rawValue
        self.sampleCount = sampleCount
        self.correctionCount = correctionCount
        self.lastSuggestedValue = lastSuggestedValue
        self.lastFinalValue = lastFinalValue
        self.updatedAt = updatedAt
    }

    var field: Field {
        get { Field(rawValue: fieldRaw) ?? .vendor }
        set { fieldRaw = newValue.rawValue }
    }

    var correctionRate: Double {
        guard sampleCount > 0 else { return 0 }
        return Double(correctionCount) / Double(sampleCount)
    }

    static func profileID(vendorID: String, field: Field) -> String {
        "\(vendorID)|\(field.rawValue)"
    }
}

@Model
final class IncomeEntry {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case monthlyFixed
        case oneTime

        var id: String { rawValue }

        /// Picker-tauglicher Title — bekommt isEnglish als Parameter, damit
        /// SwiftUI die @AppStorage-Dependency erkennt und re-rendert.
        func localizedTitle(isEnglish: Bool) -> String {
            switch self {
            case .monthlyFixed: return isEnglish ? "Monthly fixed" : "Fix monatlich"
            case .oneTime:      return isEnglish ? "One-time"      : "Einmalig"
            }
        }

        /// Backwards-Compat fuer CSV-Export & nicht-reaktive Pfade.
        var title: String { localizedTitle(isEnglish: L10n.isEnglish) }
    }

    @Attribute(.unique) var id: UUID
    var name: String
    var amountValue: Double
    var kindRaw: String
    var startDate: Date
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        kind: Kind,
        startDate: Date,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.amountValue = NSDecimalNumber(decimal: amount).doubleValue
        self.kindRaw = kind.rawValue
        self.startDate = startDate
        self.isActive = isActive
    }

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .oneTime }
        set { kindRaw = newValue.rawValue }
    }

    var amount: Decimal {
        get { Decimal(amountValue) }
        set { amountValue = NSDecimalNumber(decimal: newValue).doubleValue }
    }
}

@Model
final class InstallmentPlan {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case fixedCost
        case loan

        var id: String { rawValue }

        func localizedTitle(isEnglish: Bool) -> String {
            switch self {
            case .fixedCost: return isEnglish ? "Fixed cost" : "Fixkosten"
            case .loan:      return isEnglish ? "Loan"       : "Kredit"
            }
        }

        var title: String { localizedTitle(isEnglish: L10n.isEnglish) }
    }

    enum LoanRepaymentMode: String, Codable, CaseIterable, Identifiable {
        case annuity
        case fixedPrincipal

        var id: String { rawValue }

        func localizedTitle(isEnglish: Bool) -> String {
            switch self {
            case .annuity:        return isEnglish ? "Annuity"        : "Annuitaet"
            case .fixedPrincipal: return isEnglish ? "Fixed principal" : "Feste Tilgung"
            }
        }

        var title: String { localizedTitle(isEnglish: L10n.isEnglish) }
    }

    @Attribute(.unique) var id: UUID
    var isLoanFlag: Bool?
    var kindRaw: String = ""
    var name: String
    var monthlyPaymentValue: Double
    var monthlyInterestValue: Double
    var annualInterestRatePercentValue: Double?
    var initialPrincipalValue: Double?
    var loanRepaymentModeRaw: String?
    var startDate: Date
    var endDate: Date?
    var paymentDay: Int
    var isActive: Bool

    init(
        id: UUID = UUID(),
        kind: Kind = .fixedCost,
        name: String,
        monthlyPayment: Decimal,
        monthlyInterest: Decimal = 0,
        annualInterestRatePercent: Decimal? = nil,
        initialPrincipal: Decimal? = nil,
        loanRepaymentMode: LoanRepaymentMode = .annuity,
        startDate: Date,
        endDate: Date? = nil,
        paymentDay: Int = 1,
        isActive: Bool = true
    ) {
        self.id = id
        self.isLoanFlag = (kind == .loan)
        self.kindRaw = kind.rawValue
        self.name = name
        self.monthlyPaymentValue = NSDecimalNumber(decimal: monthlyPayment).doubleValue
        self.monthlyInterestValue = NSDecimalNumber(decimal: monthlyInterest).doubleValue
        self.annualInterestRatePercentValue = annualInterestRatePercent.map { NSDecimalNumber(decimal: $0).doubleValue }
        self.initialPrincipalValue = initialPrincipal.map { NSDecimalNumber(decimal: $0).doubleValue }
        self.loanRepaymentModeRaw = kind == .loan ? loanRepaymentMode.rawValue : nil
        self.startDate = startDate
        self.endDate = endDate
        self.paymentDay = min(max(paymentDay, 1), 28)
        self.isActive = isActive
    }

    var monthlyPayment: Decimal {
        get { Decimal(monthlyPaymentValue) }
        set { monthlyPaymentValue = NSDecimalNumber(decimal: newValue).doubleValue }
    }

    var kind: Kind {
        get {
            if let isLoanFlag {
                return isLoanFlag ? .loan : .fixedCost
            }
            if let parsed = Kind(rawValue: kindRaw) {
                return parsed
            }
            if let raw = loanRepaymentModeRaw, LoanRepaymentMode(rawValue: raw) != nil {
                return .loan
            }
            if initialPrincipal != nil || annualInterestRatePercent != nil || monthlyInterest > 0 {
                return .loan
            }
            return .fixedCost
        }
        set {
            isLoanFlag = (newValue == .loan)
            kindRaw = newValue.rawValue
            if newValue == .fixedCost {
                loanRepaymentModeRaw = nil
            } else if loanRepaymentModeRaw == nil {
                loanRepaymentModeRaw = LoanRepaymentMode.annuity.rawValue
            }
        }
    }

    var monthlyInterest: Decimal {
        get { Decimal(monthlyInterestValue) }
        set { monthlyInterestValue = NSDecimalNumber(decimal: newValue).doubleValue }
    }

    var annualInterestRatePercent: Decimal? {
        get {
            guard let annualInterestRatePercentValue else { return nil }
            return Decimal(annualInterestRatePercentValue)
        }
        set {
            annualInterestRatePercentValue = newValue.map { NSDecimalNumber(decimal: $0).doubleValue }
        }
    }

    var loanRepaymentMode: LoanRepaymentMode {
        get {
            guard kind == .loan else { return .annuity }
            if let raw = loanRepaymentModeRaw, let parsed = LoanRepaymentMode(rawValue: raw) {
                return parsed
            }
            return .annuity
        }
        set {
            loanRepaymentModeRaw = newValue.rawValue
        }
    }

    var monthlyPrincipal: Decimal {
        if kind == .loan, loanRepaymentMode == .fixedPrincipal {
            return max(monthlyPayment, 0)
        }
        return max(monthlyPayment - monthlyInterest, 0)
    }

    var initialPrincipal: Decimal? {
        get {
            guard let initialPrincipalValue else { return nil }
            return Decimal(initialPrincipalValue)
        }
        set {
            initialPrincipalValue = newValue.map { NSDecimalNumber(decimal: $0).doubleValue }
        }
    }
}

@Model
final class InstallmentSpecialRepayment {
    @Attribute(.unique) var id: UUID
    var planID: UUID
    var amountValue: Double
    var repaymentDate: Date
    var note: String?

    init(
        id: UUID = UUID(),
        planID: UUID,
        amount: Decimal,
        repaymentDate: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.planID = planID
        self.amountValue = NSDecimalNumber(decimal: amount).doubleValue
        self.repaymentDate = repaymentDate
        self.note = note
    }

    var amount: Decimal {
        get { Decimal(amountValue) }
        set { amountValue = NSDecimalNumber(decimal: newValue).doubleValue }
    }
}
