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

    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var receivedAt: Date = Date()
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
final class IncomeEntry {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case monthlyFixed
        case oneTime

        var id: String { rawValue }

        var title: String {
            switch self {
            case .monthlyFixed: return "Fix monatlich"
            case .oneTime: return "Einmalig"
            }
        }
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
    @Attribute(.unique) var id: UUID
    var name: String
    var monthlyPaymentValue: Double
    var monthlyInterestValue: Double
    var annualInterestRatePercentValue: Double?
    var initialPrincipalValue: Double?
    var startDate: Date
    var endDate: Date?
    var paymentDay: Int
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        monthlyPayment: Decimal,
        monthlyInterest: Decimal = 0,
        annualInterestRatePercent: Decimal? = nil,
        initialPrincipal: Decimal? = nil,
        startDate: Date,
        endDate: Date? = nil,
        paymentDay: Int = 1,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.monthlyPaymentValue = NSDecimalNumber(decimal: monthlyPayment).doubleValue
        self.monthlyInterestValue = NSDecimalNumber(decimal: monthlyInterest).doubleValue
        self.annualInterestRatePercentValue = annualInterestRatePercent.map { NSDecimalNumber(decimal: $0).doubleValue }
        self.initialPrincipalValue = initialPrincipal.map { NSDecimalNumber(decimal: $0).doubleValue }
        self.startDate = startDate
        self.endDate = endDate
        self.paymentDay = min(max(paymentDay, 1), 28)
        self.isActive = isActive
    }

    var monthlyPayment: Decimal {
        get { Decimal(monthlyPaymentValue) }
        set { monthlyPaymentValue = NSDecimalNumber(decimal: newValue).doubleValue }
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

    var monthlyPrincipal: Decimal {
        max(monthlyPayment - monthlyInterest, 0)
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
