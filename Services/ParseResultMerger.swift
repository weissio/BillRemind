import Foundation

/// Merges spatial parsing results into heuristic parsing results.
/// The merge is **additive only** — spatial values fill empty fields but never overwrite
/// existing heuristic results. This guarantees no downgrade of existing functionality.
struct ParseResultMerger {

    /// Merges `spatial` into `heuristic`. Returns a new `ParsedInvoiceData` with gaps filled.
    func merge(heuristic: ParsedInvoiceData, spatial: SpatialParseResult) -> ParsedInvoiceData {
        var result = heuristic

        // Vendor: only fill if heuristic returned "Unbekannt" or empty
        if isEmptyVendor(result.vendorName), let spatialVendor = spatial.vendorName, !spatialVendor.isEmpty {
            result.vendorName = spatialVendor
            result.paymentRecipient = spatialVendor
        }

        // Amount: only fill if heuristic found nothing
        if result.amount == nil, let spatialAmount = spatial.amount {
            result.amount = spatialAmount
        }

        // Invoice number: only fill if heuristic found nothing
        if isEmptyString(result.invoiceNumber), let spatialNumber = spatial.invoiceNumber, !spatialNumber.isEmpty {
            result.invoiceNumber = spatialNumber
        }

        // IBAN: only fill if heuristic found nothing
        if isEmptyString(result.iban), let spatialIBAN = spatial.iban, !spatialIBAN.isEmpty {
            result.iban = spatialIBAN
        }

        // Due date: only fill if heuristic found nothing
        if result.dueDate == nil, let spatialDueDate = spatial.dueDate {
            result.dueDate = spatialDueDate
        }

        // Invoice date: only fill if heuristic found nothing
        if result.invoiceDate == nil, let spatialInvoiceDate = spatial.invoiceDate {
            result.invoiceDate = spatialInvoiceDate
        }

        return result
    }

    private func isEmptyVendor(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == "Unbekannt"
    }

    private func isEmptyString(_ value: String?) -> Bool {
        guard let value else { return true }
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
