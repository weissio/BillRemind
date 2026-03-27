import Foundation

/// Extracted fields from spatial/layout-aware parsing.
/// Fields are optional — only populated when spatial analysis finds a confident match.
struct SpatialParseResult {
    var vendorName: String?
    var amount: Decimal?
    var invoiceNumber: String?
    var iban: String?
    var dueDate: Date?
    var invoiceDate: Date?
}

/// Uses bounding-box positions from LayoutAwareOCR to match labels to their values spatially.
/// This complements the heuristic line-based ParsingService by understanding document layout.
struct SpatialParser {

    func parse(layout: LayoutAwareOCRResult) -> SpatialParseResult {
        let rows = layout.rows()
        var result = SpatialParseResult()

        result.invoiceNumber = extractLabeledValue(
            rows: rows,
            labels: ["rechnungsnummer", "rechnungsnr", "rechnung nr", "invoice no", "invoice number", "belegnr", "rg nr", "rg-nr"],
            validator: Self.isPlausibleInvoiceNumber
        )

        result.iban = extractLabeledValue(
            rows: rows,
            labels: ["iban"],
            validator: Self.isPlausibleIBAN
        )

        result.amount = extractLabeledAmount(
            rows: rows,
            labels: ["brutto", "gesamtbetrag", "rechnungsbetrag", "zu zahlen", "zahlbetrag", "amount due", "total", "endbetrag", "grand total"]
        )

        result.dueDate = extractLabeledDate(
            rows: rows,
            labels: ["fällig", "faellig", "zahlbar bis", "due date", "zahlungsziel", "fälligkeitsdatum"]
        )

        result.invoiceDate = extractLabeledDate(
            rows: rows,
            labels: ["rechnungsdatum", "rechnung vom", "invoice date", "datum", "date"]
        )

        if result.vendorName == nil {
            result.vendorName = extractTopVendor(from: layout)
        }

        return result
    }

    // MARK: - Label-Value Matching

    /// Finds a value spatially associated with a label — either to the right on the same row,
    /// or directly below on the next row.
    private func extractLabeledValue(
        rows: [[OCRTextBlock]],
        labels: [String],
        validator: ((String) -> Bool)? = nil
    ) -> String? {
        for (rowIdx, row) in rows.enumerated() {
            for (blockIdx, block) in row.enumerated() {
                let lower = block.text.lowercased()
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard labels.contains(where: { lower.contains($0) }) else { continue }

                // Strategy 1: Value is the suffix after the label in the same block
                if let value = extractValueAfterLabel(text: block.text, labels: labels) {
                    if validator?(value) ?? true { return value }
                }

                // Strategy 2: Value is the next block to the right in the same row
                if blockIdx + 1 < row.count {
                    let rightBlock = row[blockIdx + 1]
                    let candidate = rightBlock.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !candidate.isEmpty, validator?(candidate) ?? true {
                        return candidate
                    }
                }

                // Strategy 3: Value is directly below in the next row
                if rowIdx + 1 < rows.count {
                    let nextRow = rows[rowIdx + 1]
                    if let below = findVerticallyAligned(block: block, in: nextRow) {
                        let candidate = below.text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !candidate.isEmpty, validator?(candidate) ?? true {
                            return candidate
                        }
                    }
                }
            }
        }
        return nil
    }

    private func extractLabeledAmount(
        rows: [[OCRTextBlock]],
        labels: [String]
    ) -> Decimal? {
        if let raw = extractLabeledValue(rows: rows, labels: labels, validator: { Self.parseAmount($0) != nil }) {
            return Self.parseAmount(raw)
        }
        return nil
    }

    private func extractLabeledDate(
        rows: [[OCRTextBlock]],
        labels: [String]
    ) -> Date? {
        if let raw = extractLabeledValue(rows: rows, labels: labels, validator: { Self.parseDate($0) != nil }) {
            return Self.parseDate(raw)
        }
        return nil
    }

    // MARK: - Vendor Extraction

    /// Extracts the vendor from the top-left area of the document.
    private func extractTopVendor(from layout: LayoutAwareOCRResult) -> String? {
        let topBlocks = layout.blocks
            .filter { $0.centerY < 0.25 && $0.centerX < 0.65 }
            .sorted { $0.centerY < $1.centerY }

        let ignorePatterns = [
            "rechnung", "invoice", "seite", "page", "datum", "date",
            "rechnungsnr", "kundennr", "bestellnr"
        ]

        for block in topBlocks.prefix(6) {
            let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = text.lowercased()
            if text.count < 3 { continue }
            if ignorePatterns.contains(where: { lower.contains($0) }) { continue }

            let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
            let digits = text.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }.count
            if letters < 3 || digits > letters { continue }

            // Prefer blocks with larger font (larger bounding box height)
            if block.height > 0.015 {
                return text
            }
        }
        return nil
    }

    // MARK: - Spatial Helpers

    /// Finds a block in `targetRow` that is vertically aligned with `block`.
    private func findVerticallyAligned(block: OCRTextBlock, in targetRow: [OCRTextBlock]) -> OCRTextBlock? {
        let tolerance: CGFloat = 0.08
        return targetRow.min(by: { abs($0.centerX - block.centerX) < abs($1.centerX - block.centerX) })
            .flatMap { abs($0.centerX - block.centerX) < tolerance ? $0 : nil }
    }

    private func extractValueAfterLabel(text: String, labels: [String]) -> String? {
        let lower = text.lowercased()
        for label in labels {
            if let range = lower.range(of: label) {
                let suffix = String(text[range.upperBound...])
                    .replacingOccurrences(of: #"^[\s:;-]+"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !suffix.isEmpty { return suffix }
            }
        }
        return nil
    }

    // MARK: - Validators & Parsers

    static func isPlausibleInvoiceNumber(_ value: String) -> Bool {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count < 3 { return false }
        let hasDigit = cleaned.unicodeScalars.contains { CharacterSet.decimalDigits.contains($0) }
        return hasDigit
    }

    static func isPlausibleIBAN(_ value: String) -> Bool {
        let cleaned = value.replacingOccurrences(of: " ", with: "").uppercased()
        return cleaned.count >= 15 && cleaned.range(of: #"^[A-Z]{2}\d{2}[A-Z0-9]+"#, options: .regularExpression) != nil
    }

    static func parseAmount(_ raw: String) -> Decimal? {
        let cleaned = raw
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "EUR", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // German format: 1.234,56
        if cleaned.contains(",") {
            let germanCleaned = cleaned
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
            if let value = Decimal(string: germanCleaned), value > 0, value < 1_000_000 {
                return value
            }
        }

        // English format: 1,234.56
        let englishCleaned = cleaned.replacingOccurrences(of: ",", with: "")
        if let value = Decimal(string: englishCleaned), value > 0, value < 1_000_000 {
            return value
        }

        return nil
    }

    static func parseDate(_ raw: String) -> Date? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatters: [(String, String)] = [
            ("dd.MM.yyyy", #"\d{2}\.\d{2}\.\d{4}"#),
            ("dd.MM.yy", #"\d{2}\.\d{2}\.\d{2}"#),
            ("yyyy-MM-dd", #"\d{4}-\d{2}-\d{2}"#),
            ("dd/MM/yyyy", #"\d{2}/\d{2}/\d{4}"#)
        ]
        for (format, pattern) in formatters {
            guard let match = cleaned.range(of: pattern, options: .regularExpression) else { continue }
            let dateString = String(cleaned[match])
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "de_DE")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
}
