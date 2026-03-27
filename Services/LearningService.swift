import Foundation
import SwiftData

/// Records user corrections and builds learned rules that improve OCR accuracy over time.
/// All data stays 100% local — stored via SwiftData alongside other app models.
struct LearningService {

    /// Compares OCR-suggested values against user-confirmed values and updates learned rules.
    /// Call this when the user saves an invoice (after potential corrections).
    func recordOutcome(
        vendorName: String,
        suggested: FieldSnapshot,
        confirmed: FieldSnapshot,
        modelContext: ModelContext
    ) {
        let vendorID = VendorProfile.profileID(from: vendorName)
        guard !vendorID.isEmpty else { return }

        recordField(.vendor, vendorID: vendorID, suggested: suggested.vendor, confirmed: confirmed.vendor, modelContext: modelContext)
        recordField(.amount, vendorID: vendorID, suggested: suggested.amount, confirmed: confirmed.amount, modelContext: modelContext)
        recordField(.invoiceNumber, vendorID: vendorID, suggested: suggested.invoiceNumber, confirmed: confirmed.invoiceNumber, modelContext: modelContext)
        recordField(.iban, vendorID: vendorID, suggested: suggested.iban, confirmed: confirmed.iban, modelContext: modelContext)
        recordField(.dueDate, vendorID: vendorID, suggested: suggested.dueDate, confirmed: confirmed.dueDate, modelContext: modelContext)
        recordField(.category, vendorID: vendorID, suggested: suggested.category, confirmed: confirmed.category, modelContext: modelContext)
    }

    /// Checks if a field for a given vendor has a locally trusted rule, and returns
    /// the last confirmed value if so.
    func trustedValue(
        vendorName: String,
        field: LearnedParsingRule.Field,
        modelContext: ModelContext
    ) -> String? {
        let vendorID = VendorProfile.profileID(from: vendorName)
        guard !vendorID.isEmpty else { return nil }
        let ruleID = LearnedParsingRule.ruleID(vendorID: vendorID, field: field)

        let descriptor = FetchDescriptor<LearnedParsingRule>(
            predicate: #Predicate { $0.id == ruleID }
        )
        guard let rule = try? modelContext.fetch(descriptor).first else { return nil }
        return rule.isLocallyTrusted ? rule.lastConfirmedValue : nil
    }

    // MARK: - Private

    private func recordField(
        _ field: LearnedParsingRule.Field,
        vendorID: String,
        suggested: String?,
        confirmed: String?,
        modelContext: ModelContext
    ) {
        let suggestedNorm = normalize(suggested)
        let confirmedNorm = normalize(confirmed)

        // Skip if both are empty — nothing to learn from
        guard suggestedNorm != nil || confirmedNorm != nil else { return }

        let ruleID = LearnedParsingRule.ruleID(vendorID: vendorID, field: field)
        let descriptor = FetchDescriptor<LearnedParsingRule>(
            predicate: #Predicate { $0.id == ruleID }
        )

        let wasCorrected = suggestedNorm != confirmedNorm

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.sampleCount += 1
            if wasCorrected {
                existing.correctionCount += 1
                existing.consecutiveSuccessCount = 0
            } else {
                existing.consecutiveSuccessCount += 1
            }
            existing.lastSuggestedValue = suggestedNorm
            existing.lastConfirmedValue = confirmedNorm
            existing.updatedAt = .now
        } else {
            let rule = LearnedParsingRule(
                vendorID: vendorID,
                field: field,
                sampleCount: 1,
                correctionCount: wasCorrected ? 1 : 0,
                lastSuggestedValue: suggestedNorm,
                lastConfirmedValue: confirmedNorm,
                consecutiveSuccessCount: wasCorrected ? 0 : 1
            )
            modelContext.insert(rule)
        }
    }

    private func normalize(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

/// Snapshot of field values at a point in time (OCR suggestion or user confirmation).
struct FieldSnapshot {
    var vendor: String?
    var amount: String?
    var invoiceNumber: String?
    var iban: String?
    var dueDate: String?
    var category: String?
}
