import Foundation

enum ParsedDocumentType: String, Codable {
    case invoice
    case receipt
    case unknown
}

struct ParsedInvoiceData {
    var documentType: ParsedDocumentType = .unknown
    var vendorName: String = "Unbekannt"
    var paymentRecipient: String = "Unbekannt"
    var category: String = "Sonstiges"
    var amount: Decimal?
    var invoiceDate: Date?
    var dueOffsetDaysHint: Int? = nil
    var dueDate: Date?
    var invoiceNumber: String?
    var iban: String?
    var note: String?
    var extractedText: String
    var ocrConfidence: Double?
    var vendorConfidence: Double?
    var amountConfidence: Double?
    var dueDateConfidence: Double?
    var invoiceNumberConfidence: Double?
    var ibanConfidence: Double?
    var reviewHint: String?
}

struct ParsingService {
    private let calendar = Calendar.current

    func parse(text: String) -> ParsedInvoiceData {
        let lines = text
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let documentType = classifyDocumentType(from: lines)
        let invoiceDate = documentType == .receipt ? nil : extractInvoiceDate(from: lines)
        let dueDate = documentType == .receipt ? nil : extractDueDate(from: lines)
        let dueOffsetDaysHint = documentType == .receipt ? nil : extractDueOffsetDaysHint(from: lines)

        return ParsedInvoiceData(
            documentType: documentType,
            vendorName: extractVendorName(from: lines),
            paymentRecipient: extractPaymentRecipient(from: lines),
            category: extractCategory(from: lines),
            amount: extractAmount(from: lines, documentType: documentType),
            invoiceDate: invoiceDate,
            dueOffsetDaysHint: dueOffsetDaysHint,
            dueDate: dueDate,
            invoiceNumber: documentType == .receipt ? nil : extractInvoiceNumber(from: lines),
            iban: extractIBAN(from: text),
            note: nil,
            extractedText: text
        )
    }

    func extractIBAN(from text: String) -> String? {
        let upper = text.uppercased()
        if let labeled = upper.firstCaptureGroup(for: #"(?i)\bIBAN\b[^A-Z0-9]*([A-Z]{2}\d{2}[A-Z0-9 \t]{10,40})"#),
           let normalized = Self.normalizeIBANValue(labeled) {
            return normalized
        }

        let pattern = #"\b[A-Z]{2}\d{2}(?:[ \t]?[A-Z0-9]){10,30}\b"#
        for candidate in upper.matches(for: pattern) {
            if let normalized = Self.normalizeIBANValue(candidate) {
                return normalized
            }
        }
        return nil
    }

    func extractAmount(from lines: [String], documentType: ParsedDocumentType) -> Decimal? {
        if documentType == .receipt {
            return extractReceiptTotalAmount(from: lines)
        }

        let grossKeywords = [
            "brutto", "total (gross)", "zu zahlen", "gesamtbetrag", "endbetrag",
            "rechnungsbetrag", "amount due", "grand total", "zahlbetrag"
        ]
        let negativeKeywords = [
            "netto", "net amount", "subtotal", "zwischensumme", "vat", "mwst", "ust", "tax", "mehrwertsteuer"
        ]
        let unitLineKeywords = ["unit price", "einzel", "line total", "menge", "qty", "ep", "gesamt "]

        var candidates: [(score: Double, amount: Decimal)] = []

        for line in lines {
            let lowered = normalizedLower(line)
            let amounts = extractAmounts(from: line).filter { $0 > 0 && $0 < 1_000_000 }
            guard !amounts.isEmpty else { continue }

            var score = 0.0
            score += Double(grossKeywords.filter { lowered.contains($0) }.count) * 5.0
            score -= Double(negativeKeywords.filter { lowered.contains($0) }.count) * 3.0
            score -= Double(unitLineKeywords.filter { lowered.contains($0) }.count) * 2.5
            if lowered.contains("€") || lowered.contains("eur") { score += 0.8 }

            for amount in amounts {
                candidates.append((score: score, amount: amount))
            }

            // If line contains net + tax, add computed gross candidate as fallback.
            let hasNet = lowered.contains("netto") || lowered.contains("net amount")
            let hasTax = lowered.contains("vat") || lowered.contains("mwst") || lowered.contains("ust") || lowered.contains("tax")
            if hasNet && hasTax && amounts.count >= 2 {
                let sorted = amounts.sorted(by: >)
                let computed = sorted[0] + sorted[1]
                candidates.append((score: 3.5, amount: computed))
            }
        }

        return candidates.sorted { lhs, rhs in
            if lhs.score == rhs.score { return lhs.amount > rhs.amount }
            return lhs.score > rhs.score
        }.first?.amount
    }

    private func extractReceiptTotalAmount(from lines: [String]) -> Decimal? {
        guard !lines.isEmpty else { return nil }

        let strongKeywords = ["summe", "gesamt", "zu zahlen", "endbetrag", "zahlbetrag", "ec", "karte"]
        let weakKeywords = ["eur", "€", "betrag", "bar"]
        let negativeKeywords = [
            "mwst", "ust", "steuer", "rabatt", "gespart", "einzelpreis", "zwischensumme",
            "rückgeld", "rueckgeld", "gegeben", "bar gegeben", "erhalten"
        ]

        var scored: [(score: Double, amount: Decimal)] = []
        var lastAmount: Decimal?

        for (index, line) in lines.enumerated() {
            let lower = line.lowercased()
            let amounts = extractAmounts(from: line).filter { $0 > 0 && $0 < 1_000_000 }
            guard !amounts.isEmpty else { continue }

            let progress = Double(index + 1) / Double(lines.count) // end-of-receipt lines usually contain final total
            for amount in amounts {
                var score = 0.0
                score += Double(strongKeywords.filter { lower.contains($0) }.count) * 3.0
                score += Double(weakKeywords.filter { lower.contains($0) }.count) * 0.8
                score -= Double(negativeKeywords.filter { lower.contains($0) }.count) * 2.0
                score += progress * 2.2
                if amount >= 1 { score += 0.3 }
                scored.append((score: score, amount: amount))
                lastAmount = amount
            }
        }

        if let best = scored.sorted(by: { lhs, rhs in
            if lhs.score == rhs.score { return lhs.amount > rhs.amount }
            return lhs.score > rhs.score
        }).first, best.score >= 0.5 {
            return best.amount
        }
        return lastAmount
    }

    private func extractAmounts(from text: String) -> [Decimal] {
        let amountPattern = #"\d{1,3}(?:[\.\s]\d{3})*(?:[\.,]\d{2})|\d+[\.,]\d{2}"#
        let fullDatePattern = #"\b\d{1,2}[.\-/]\d{1,2}[.\-/]\d{2,4}\b"#
        guard
            let amountRegex = try? NSRegularExpression(pattern: amountPattern),
            let fullDateRegex = try? NSRegularExpression(pattern: fullDatePattern)
        else {
            return []
        }

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let dateRanges = fullDateRegex.matches(in: text, range: fullRange).map(\.range)
        let matches = amountRegex.matches(in: text, range: fullRange)

        return matches.compactMap { match in
            if dateRanges.contains(where: { NSIntersectionRange(match.range, $0).length > 0 }) {
                return nil
            }

            let raw = nsText.substring(with: match.range)
            let compact = raw.replacingOccurrences(of: " ", with: "")
            let hasComma = compact.contains(",")
            let hasDot = compact.contains(".")
            let normalized: String

            if hasComma && hasDot {
                // Mixed separators (e.g. 1.234,56 or 1,234.56): choose right-most as decimal separator.
                if let lastComma = compact.lastIndex(of: ","), let lastDot = compact.lastIndex(of: ".") {
                    if lastComma > lastDot {
                        normalized = compact
                            .replacingOccurrences(of: ".", with: "")
                            .replacingOccurrences(of: ",", with: ".")
                    } else {
                        normalized = compact
                            .replacingOccurrences(of: ",", with: "")
                    }
                } else {
                    normalized = compact.replacingOccurrences(of: ",", with: ".")
                }
            } else if hasComma {
                // DE decimal comma.
                normalized = compact.replacingOccurrences(of: ",", with: ".")
            } else if hasDot {
                // If suffix has exactly two digits, treat as decimal dot, otherwise as thousands separator.
                let parts = compact.split(separator: ".", omittingEmptySubsequences: false)
                if parts.count >= 2, parts.last?.count == 2 {
                    normalized = compact
                } else {
                    normalized = compact.replacingOccurrences(of: ".", with: "")
                }
            } else {
                normalized = compact
            }
            return Decimal(string: normalized)
        }
    }

    func extractDueDate(from lines: [String]) -> Date? {
        let keywords = ["zahlbar bis", "fällig am", "fällig", "zahlungsziel", "due", "due date"]
        let formats = ["dd.MM.yyyy", "dd.MM.yy", "yyyy-MM-dd"]
        let datePattern = #"\b\d{2}\.\d{2}\.\d{2,4}\b|\b\d{4}-\d{2}-\d{2}\b"#

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")

        let keywordLines = lines.filter { line in
            let lower = line.lowercased()
            return keywords.contains { lower.contains($0) }
        }
        // Do not guess a due date from order/invoice dates if no payment-due cue exists.
        guard !keywordLines.isEmpty else { return nil }

        for line in keywordLines {
            let candidates = line.matches(for: datePattern)
            for format in formats {
                dateFormatter.dateFormat = format
                for token in candidates {
                    if let date = dateFormatter.date(from: token) {
                        return calendar.startOfDay(for: date)
                    }
                }
            }
        }
        return nil
    }

    func extractInvoiceDate(from lines: [String]) -> Date? {
        let keywords = [
            "rechnungsdatum", "rechnung vom", "invoice date", "invoice dated",
            "belegdatum", "datum der rechnung", "date:", "issue date"
        ]
        let dueKeywords = ["zahlbar bis", "fällig", "faellig", "due date", "due"]

        let indexedLines = Array(lines.enumerated())
        let keywordIndices = indexedLines.compactMap { idx, line -> Int? in
            let lower = line.lowercased()
            if keywords.contains(where: { lower.contains($0) }) &&
                !dueKeywords.contains(where: { lower.contains($0) }) {
                return idx
            }
            return nil
        }

        // 1) Best case: label and date on same line.
        for idx in keywordIndices {
            if let parsed = parseFirstDate(in: lines[idx]) {
                return parsed
            }
        }

        // 2) Table layouts: label in header row, value in subsequent row(s).
        for idx in keywordIndices {
            let nextRange = (idx + 1)...min(idx + 12, lines.count - 1)
            for j in nextRange {
                let lower = lines[j].lowercased()
                if dueKeywords.contains(where: { lower.contains($0) }) { continue }
                if lower.contains("bestelldatum") || lower.contains("versanddatum") || lower.contains("leistungszeitraum") {
                    continue
                }
                if let parsed = parseFirstDate(in: lines[j]), parsed <= calendar.startOfDay(for: Date()) {
                    return parsed
                }
            }
        }

        // 3) Conservative fallback in first lines.
        for line in lines.prefix(20) {
            let lower = line.lowercased()
            if dueKeywords.contains(where: { lower.contains($0) }) { continue }
            if lower.contains("bestelldatum") || lower.contains("versanddatum") || lower.contains("leistungsdatum") { continue }
            if let parsed = parseFirstDate(in: line), parsed <= calendar.startOfDay(for: Date()) {
                return parsed
            }
        }

        return nil
    }

    func extractDueOffsetDaysHint(from lines: [String]) -> Int? {
        let lowerLines = lines.map { $0.lowercased() }
        let dueKeywords = ["zahlbar", "zahlungsziel", "fällig", "faellig", "due", "net", "terms", "payment terms"]
        let dayPattern = #"(?:innerhalb\s+von\s+|in\s+|due\s+in\s+|net\s*)(\d{1,2})\s*(?:tagen|tage|tag|days?|d)\b|(\d{1,2})\s*(?:tagen|tage|tag|days?)\s*(?:net|netto)?\b"#

        for line in lowerLines {
            guard dueKeywords.contains(where: { line.contains($0) }) else { continue }
            let hasDayNumber = line.range(of: #"\b(7|14|30)\b"#, options: .regularExpression) != nil
            if !hasDayNumber { continue }

            if let token = line.firstCaptureGroup(for: dayPattern),
               let days = Int(token),
               [7, 14, 30].contains(days) {
                return days
            }

            if let days = line.matches(for: #"\b(7|14|30)\s*(?:tagen|tage|tag)\b"#).first,
               let value = Int(days.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()),
               [7, 14, 30].contains(value),
               dueKeywords.contains(where: { line.contains($0) }) {
                return value
            }

            if line.contains("net 30") || line.contains("netto 30") {
                return 30
            }
            if line.contains("net 14") || line.contains("netto 14") {
                return 14
            }
            if line.contains("net 7") || line.contains("netto 7") {
                return 7
            }
        }

        return nil
    }

    private func parseFirstDate(in line: String) -> Date? {
        let compact = line.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !compact.isEmpty else { return nil }

        let dateReady = compact
            .replacingOccurrences(of: #"(?<=[0-9])\s+(?=[0-9./-])"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?<=[./-])\s+(?=[0-9])"#, with: "", options: .regularExpression)

        let numericPattern = #"\b\d{1,4}\s*[.\-/]\s*\d{1,2}\s*[.\-/]\s*\d{1,4}\b"#
        let textMonthPattern = #"\b\d{1,2}\s*[.\-]?\s*(?:jan|januar|january|feb|februar|february|mar|märz|maerz|march|apr|april|may|mai|jun|juni|june|jul|juli|july|aug|august|sep|sept|september|oct|okt|october|oktober|nov|november|dec|dez|december)\s*[,\.\-]?\s*\d{2,4}\b"#

        var tokens = dateReady.matches(for: numericPattern)
        tokens.append(contentsOf: dateReady.matches(for: textMonthPattern))
        guard !tokens.isEmpty else { return nil }

        let deFormatter = DateFormatter()
        deFormatter.locale = Locale(identifier: "de_DE")
        deFormatter.isLenient = true

        let enFormatter = DateFormatter()
        enFormatter.locale = Locale(identifier: "en_US_POSIX")
        enFormatter.isLenient = true

        let deFormats = [
            "dd.MM.yyyy", "d.M.yyyy", "dd.MM.yy", "d.M.yy",
            "dd/MM/yyyy", "d/M/yyyy", "dd/MM/yy", "d/M/yy",
            "dd-MM-yyyy", "d-M-yyyy", "dd-MM-yy", "d-M-yy",
            "yyyy-MM-dd", "yyyy-M-d", "yyyy/MM/dd", "yyyy/M/d",
            "d MMM yyyy", "dd MMM yyyy", "d MMMM yyyy", "dd MMMM yyyy"
        ]
        let enFormats = [
            "MM/dd/yyyy", "M/d/yyyy", "MM/dd/yy", "M/d/yy",
            "MMM d, yyyy", "MMMM d, yyyy", "d MMM yyyy", "d MMMM yyyy"
        ]

        for token in tokens {
            let normalizedToken = token
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .replacingOccurrences(of: #"\s*([.\-/,:])\s*"#, with: "$1", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            for format in deFormats {
                deFormatter.dateFormat = format
                if let date = deFormatter.date(from: normalizedToken) {
                    return calendar.startOfDay(for: date)
                }
            }
            for format in enFormats {
                enFormatter.dateFormat = format
                if let date = enFormatter.date(from: normalizedToken) {
                    return calendar.startOfDay(for: date)
                }
            }
        }
        return nil
    }

    func extractInvoiceNumber(from lines: [String]) -> String? {
        let normalizedLines = lines.map { line in
            line.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        }

        let pattern = #"(?i)(?:rechnungs?(?:nummer|[-\s]*nr\.?)|rg[-\s]*nr\.?|beleg(?:nummer|[-\s]*nr\.?)|invoice\s*(?:no|nr|number)\.?)\s*[:#-]?\s*([A-Z0-9][A-Z0-9\-/\.\s]{2,})"#
        for line in normalizedLines {
            if let match = line.firstCaptureGroup(for: pattern) {
                let normalized = normalizeInvoiceNumberCandidate(match)
                if let normalized, !normalized.isEmpty {
                    return normalized
                }
            }
        }

        // Fallback for plain standalone identifiers often used in simple templates.
        let joined = normalizedLines.joined(separator: " ")
        let fallbackPatterns = [
            #"\bRE-\d{4}-\d{3,5}\b"#,
            #"\bRE\s*\d{4}\s*[-/]\s*\d{3,5}\b"#,
            #"\bINV-\d{3,6}\b"#,
            #"\bINV\s*\d{3,6}\b"#,
            #"\bRG\d{4,6}\b"#,
            #"\bRG\s*\d{4,6}\b"#,
            #"\b\d{4}/\d{2,6}\b"#,
            #"\b\d{4}-\d{2,6}\b"#,
            #"\b\d{3,5}-\d{2}\b"#
        ]
        for fallback in fallbackPatterns {
            if let range = joined.range(of: fallback, options: .regularExpression) {
                return normalizeInvoiceNumberCandidate(String(joined[range]))
            }
        }

        return nil
    }

    private func normalizeInvoiceNumberCandidate(_ raw: String?) -> String? {
        Self.normalizeInvoiceNumberValue(raw)
    }

    static func normalizeInvoiceNumberValue(_ raw: String?) -> String? {
        guard let raw else { return nil }
        var value = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: #"[\s]+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[,;:]$"#, with: "", options: .regularExpression)
        guard !value.isEmpty else { return nil }

        // Cut off obvious trailing fields frequently adjacent in OCR output.
        value = value.replacingOccurrences(
            of: #"(?i)(RECHNUNGSDATUM|DATUM|INVOICE|IBAN|TOTAL|NETTO|BRUTTO).*$"#,
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        guard value.count >= 4 else { return nil }
        guard value.range(of: #"[A-Z0-9]"#, options: .regularExpression) != nil else { return nil }
        guard value.range(of: #"^\d{1,2}[./-]\d{1,2}[./-]\d{2,4}$"#, options: .regularExpression) == nil else { return nil }
        return value
    }

    func extractLegacyInvoiceNumber(from lines: [String]) -> String? {
        // kept for backward compatibility in case callers still rely on previous name/behavior
        let pattern = #"(?i)(?:rechnungs?(?:nr|nummer)|rg\.?\s*nr\.?|invoice\s*(?:no|nr|number)|belegnr\.?)\s*[:#-]?\s*([A-Z0-9][A-Z0-9\-/]+)"#
        for line in lines {
            if let match = line.firstCaptureGroup(for: pattern) {
                let lower = match.lowercased()
                if lower.contains("referenz") || lower.contains("versand") || lower.contains("rechnung") {
                    continue
                }
                return match
            }
        }
        return nil
    }

    func extractVendorName(from lines: [String]) -> String {
        if let sellerOfRecord = extractSellerOfRecord(from: lines) {
            return sellerOfRecord
        }

        if let labeledSupplier = extractLabeledEntity(from: lines, labels: ["from", "von", "lieferant", "aussteller", "rechnungssteller"]) {
            return labeledSupplier
        }

        if let teamVendor = extractTeamVendor(from: lines) {
            return teamVendor
        }

        if let legalEntity = extractLegalEntityLine(from: lines) {
            return legalEntity
        }

        for line in lines {
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.isEmpty { continue }
            let lower = normalizedLower(cleaned)
            if isLikelyCustomerLine(lower) { continue }
            if containsCompanyMarker(lower) {
                return cleaned
            }
        }

        let ignoreFragments = [
            "rechnung", "invoice", "rechnungsnr", "rechnungsnummer", "zahlbar", "fällig",
            "iban", "kunde", "rechnung an", "bestelldatum", "rechnungsdatum", "versanddatum",
            "ust-id", "hrb"
        ]
        for line in lines.prefix(10) {
            let lower = normalizedLower(line)
            if ignoreFragments.contains(where: { lower.contains($0) }) { continue }
            if isLikelyCustomerLine(lower) { continue }
            if line.count < 3 { continue }
            return line
        }
        return "Unbekannt"
    }

    private func extractPaymentRecipient(from lines: [String]) -> String {
        if let labeledRecipient = extractLabeledEntity(
            from: lines,
            labels: ["zahlungsempfanger", "zahlungsempfaenger", "zahlungsempfänger", "payment recipient", "kontoinhaber", "beguenstigter", "begünstigter"]
        ) {
            return labeledRecipient
        }

        for line in lines {
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.isEmpty { continue }
            let lower = normalizedLower(cleaned)
            if isLikelyCustomerLine(lower) { continue }
            if containsCompanyMarker(lower) && !hasCustomerMarker(lower) {
                return cleaned
            }
        }
        return extractVendorName(from: lines)
    }

    private func extractLegalEntityLine(from lines: [String]) -> String? {
        for line in lines {
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.isEmpty { continue }
            let lower = normalizedLower(cleaned)
            if lower.contains("auf rechnung der") || lower.contains("im namen und auf rechnung der") {
                continue
            }
            if isLikelyCustomerLine(lower) { continue }
            if hasLegalEntitySuffix(lower) {
                return cleaned
            }
        }
        return nil
    }

    private func extractSellerOfRecord(from lines: [String]) -> String? {
        let patterns = [
            #"(?i)im\s+namen\s+und\s+auf\s+rechnung\s+der\s+([A-Z0-9ÄÖÜß&.,\-\s]{3,80})"#,
            #"(?i)auf\s+rechnung\s+der\s+([A-Z0-9ÄÖÜß&.,\-\s]{3,80})"#
        ]

        for line in lines.prefix(30) {
            for pattern in patterns {
                guard let match = line.firstCaptureGroup(for: pattern) else { continue }
                let company = normalizeSellerPhraseCapture(match)
                if !company.isEmpty { return company }
            }
        }
        return nil
    }

    private func normalizeSellerPhraseCapture(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[.;,:]+$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractLabeledEntity(from lines: [String], labels: [String]) -> String? {
        let normalizedLabels = labels.map { normalizedLower($0) }
        for (index, rawLine) in lines.enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = normalizedLower(line)
            guard let matched = normalizedLabels.first(where: { label in
                lower == label || lower.hasPrefix(label + ":") || lower.hasPrefix(label + " ")
            }) else { continue }

            if let sameLine = extractAfterLabel(in: line, label: matched), !sameLine.isEmpty {
                return sameLine
            }

            var collected: [String] = []
            if index + 1 < lines.count {
                for next in (index + 1)...min(index + 3, lines.count - 1) {
                    let candidate = cleanEntityCandidate(lines[next])
                    if candidate.isEmpty { break }
                    if hasStopMarker(normalizedLower(candidate)) { break }
                    collected.append(candidate)
                }
            }
            if !collected.isEmpty {
                return collected.joined(separator: " ")
            }
        }
        return nil
    }

    private func extractAfterLabel(in line: String, label: String) -> String? {
        let lower = normalizedLower(line)
        if let colon = line.firstIndex(of: ":") {
            let suffix = String(line[line.index(after: colon)...])
            let cleaned = cleanEntityCandidate(suffix)
            return cleaned.isEmpty ? nil : cleaned
        }
        if lower.hasPrefix(label + " ") {
            let suffix = String(line.dropFirst(label.count + 1))
            let cleaned = cleanEntityCandidate(suffix)
            return cleaned.isEmpty ? nil : cleaned
        }
        return nil
    }

    private func cleanEntityCandidate(_ raw: String) -> String {
        var value = raw
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return "" }
        value = value.replacingOccurrences(
            of: #"(?i)\b(rechnungsnummer|rechnung\s*nr\.?|belegnr\.?|invoice\s*no\.?|invoice\s*date|datum|belegdatum|item|beschreibung|menge|qty|unit|price|line\s*total|netto|subtotal|zwischensumme|total|brutto|zahlung|iban)\b.*$"#,
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        return value
    }

    private func hasStopMarker(_ lower: String) -> Bool {
        [
            "rechnung", "invoice", "rechnungsnummer", "belegnr", "datum", "belegdatum",
            "item", "beschreibung", "menge", "qty", "unit", "price", "line total",
            "netto", "subtotal", "zwischensumme", "total", "brutto", "zahlung", "iban",
            "empfanger", "empfaenger", "empfänger", "kunde", "to"
        ].contains { lower.contains($0) }
    }

    private func hasCustomerMarker(_ lower: String) -> Bool {
        ["empfanger", "empfaenger", "empfänger", "rechnungsempfanger", "rechnungsempfaenger", "rechnungsempfänger", "kunde", "bill to", "rechnung an", "to"]
            .contains { lower.contains($0) }
    }

    private func extractTeamVendor(from lines: [String]) -> String? {
        for line in lines {
            let lower = line.lowercased()
            if let range = lower.range(of: #"dein\s+([a-z0-9&\-\.\s]+)\s+team"#, options: .regularExpression) {
                let fragment = String(line[range])
                let stripped = fragment
                    .replacingOccurrences(of: "(?i)^dein\\s+", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "(?i)\\s+team$", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !stripped.isEmpty { return stripped }
            }
            if lower.contains("medimops") {
                return "medimops"
            }
        }
        return nil
    }

    private func containsCompanyMarker(_ lower: String) -> Bool {
        let brandMarkers = [" momox", " medimops"]
        return hasLegalEntitySuffix(lower) || brandMarkers.contains { lower.contains($0) }
    }

    private func hasLegalEntitySuffix(_ lower: String) -> Bool {
        lower.range(of: #"\b(gmbh|ag|se|kg|ug|ltd|llc|inc)\b"#, options: .regularExpression) != nil
    }

    private func isLikelyCustomerLine(_ lower: String) -> Bool {
        if hasLegalEntitySuffix(lower) || lower.contains("momox") || lower.contains("medimops") {
            return false
        }
        let customerMarkers = [
            "bestelldatum", "rechnungsdatum", "versanddatum", "rechnung für deine bestellung",
            "hallo ", "deine bestellung", "seite ", "tel.:", "fax:", "email:", "ust-id", "hrb",
            "empfänger", "empfaenger", "empfanger", "kunde", "rechnung an", "bill to", " to "
        ]
        if customerMarkers.contains(where: { lower.contains($0) }) {
            return true
        }
        // Typical personal/address line at top (street + house number pattern).
        if lower.range(of: #"[a-zäöüß]+\s*(straße|str\.?|weg|platz)\s+\d+"#, options: .regularExpression) != nil {
            return true
        }
        return false
    }

    private func extractCategory(from lines: [String]) -> String {
        let text = lines.joined(separator: " ").lowercased()
        if containsAny(in: text, keywords: ["miete", "vermieter", "warmmiete", "kaltmiete"]) { return "Wohnen" }
        if containsAny(in: text, keywords: ["strom", "gas", "wasser", "energie", "heizung"]) { return "Wohnen" }
        if containsAny(in: text, keywords: ["supermarkt", "lebensmittel", "rewe", "edeka", "lidl", "aldi", "penny", "netto markt"]) { return "Lebensmittel" }
        if containsAny(in: text, keywords: ["versicherung", "haftpflicht", "kasko", "krankenversicherung"]) { return "Versicherung" }
        if containsAny(in: text, keywords: ["telekom", "internet", "mobilfunk", "dsl", "vodafone", "o2"]) { return "Telefon & Internet" }
        if containsAny(in: text, keywords: ["abo", "subscription", "netflix", "spotify", "apple.com/bill"]) { return "Abos" }
        if containsAny(in: text, keywords: ["finanzamt", "steuerbescheid"]) { return "Steuern" }
        if containsAny(in: text, keywords: ["bahn", "ticket", "parken", "tankstelle", "shell", "aral"]) { return "Mobilität" }
        return "Sonstiges"
    }

    private func classifyDocumentType(from lines: [String]) -> ParsedDocumentType {
        let text = lines.joined(separator: " ").lowercased()

        let receiptKeywords = [
            "kassenbon", "bon", "kassenbeleg", "ec-karte", "kartenzahlung", "barzahlung", "wechselgeld",
            "ust", "mwst", "summe eur", "gesamtsumme", "steuer", "filiale"
        ]
        let invoiceKeywords = [
            "rechnung", "invoice", "rechnungsnummer", "rechnung nr", "zahlbar bis", "fällig", "faellig",
            "zahlungsempfänger", "zahlungsempfaenger", "iban", "due date"
        ]

        let receiptHits = receiptKeywords.filter { text.contains($0) }.count
        let invoiceHits = invoiceKeywords.filter { text.contains($0) }.count

        if receiptHits >= 2 && invoiceHits <= 1 { return .receipt }
        if invoiceHits >= 2 { return .invoice }
        return .unknown
    }

    private func containsAny(in text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    private func normalizedLower(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "de_DE"))
    }

    static func normalizeIBANValue(_ value: String?) -> String? {
        guard let value else { return nil }

        var normalized = value.uppercased()
            .replacingOccurrences(of: #"(?i)\bBIC\b.*$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[^A-Z0-9]"#, with: "", options: .regularExpression)

        guard !normalized.isEmpty else { return nil }

        if let bicRange = normalized.range(of: "BIC") {
            normalized = String(normalized[..<bicRange.lowerBound])
        }

        guard normalized.count >= 15 else { return nil }
        guard normalized.range(of: #"^[A-Z]{2}\d{2}[A-Z0-9]{9,30}$"#, options: .regularExpression) != nil else {
            return nil
        }

        let countryLengths: [String: Int] = [
            "DE": 22, "AT": 20, "CH": 21, "NL": 18, "BE": 16, "FR": 27,
            "ES": 24, "IT": 27, "PL": 28, "LU": 20
        ]

        if normalized.count >= 4 {
            let country = String(normalized.prefix(2))
            guard let expectedLength = countryLengths[country] else {
                return nil
            }
            if country == "DE" {
                guard let range = normalized.range(of: #"^DE\d{20}"#, options: .regularExpression) else {
                    return nil
                }
                normalized = String(normalized[range])
            } else {
                guard normalized.count >= expectedLength else { return nil }
                normalized = String(normalized.prefix(expectedLength))
            }
        }

        if normalized.count > 34 {
            normalized = String(normalized.prefix(34))
        }

        return normalized
    }
}

private extension String {
    func matches(for pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(startIndex..<endIndex, in: self)
        return regex.matches(in: self, range: nsRange).compactMap { result in
            guard let range = Range(result.range, in: self) else { return nil }
            return String(self[range])
        }
    }

    func firstCaptureGroup(for pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsRange = NSRange(startIndex..<endIndex, in: self)
        guard let match = regex.firstMatch(in: self, range: nsRange),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: self) else {
            return nil
        }
        return String(self[range])
    }
}
