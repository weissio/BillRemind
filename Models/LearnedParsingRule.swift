import Foundation
import SwiftData

/// Stores a learned extraction pattern from user corrections.
/// Over time, as sampleCount grows and correctionRate drops, the rule becomes "locally trusted"
/// and can be used to pre-fill fields without requiring user review.
@Model
final class LearnedParsingRule {
    enum Field: String, Codable, CaseIterable, Identifiable {
        case vendor
        case amount
        case invoiceNumber
        case iban
        case dueDate
        case category

        var id: String { rawValue }
    }

    /// Unique key: "<vendorID>|<field>"
    @Attribute(.unique) var id: String
    var vendorID: String
    var fieldRaw: String
    /// How many invoices from this vendor have been processed.
    var sampleCount: Int
    /// How many times the user corrected the OCR suggestion for this field.
    var correctionCount: Int
    /// The last value suggested by OCR.
    var lastSuggestedValue: String?
    /// The last value confirmed by the user (after potential correction).
    var lastConfirmedValue: String?
    /// Number of consecutive successes (no correction needed).
    var consecutiveSuccessCount: Int
    var updatedAt: Date

    init(
        vendorID: String,
        field: Field,
        sampleCount: Int = 0,
        correctionCount: Int = 0,
        lastSuggestedValue: String? = nil,
        lastConfirmedValue: String? = nil,
        consecutiveSuccessCount: Int = 0,
        updatedAt: Date = .now
    ) {
        self.id = Self.ruleID(vendorID: vendorID, field: field)
        self.vendorID = vendorID
        self.fieldRaw = field.rawValue
        self.sampleCount = sampleCount
        self.correctionCount = correctionCount
        self.lastSuggestedValue = lastSuggestedValue
        self.lastConfirmedValue = lastConfirmedValue
        self.consecutiveSuccessCount = consecutiveSuccessCount
        self.updatedAt = updatedAt
    }

    var field: Field {
        get { Field(rawValue: fieldRaw) ?? .vendor }
        set { fieldRaw = newValue.rawValue }
    }

    var correctionRate: Double {
        guard sampleCount > 0 else { return 1.0 }
        return Double(correctionCount) / Double(sampleCount)
    }

    /// A rule is "locally trusted" when:
    /// - At least 3 samples have been collected
    /// - The correction rate is below 20%
    /// - There have been at least 2 consecutive successes
    var isLocallyTrusted: Bool {
        sampleCount >= 3 && correctionRate < 0.2 && consecutiveSuccessCount >= 2
    }

    static func ruleID(vendorID: String, field: Field) -> String {
        "\(vendorID)|\(field.rawValue)"
    }
}
