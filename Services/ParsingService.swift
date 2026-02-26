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
            invoiceNumber: extractInvoiceNumber(from: lines),
            iban: extractIBAN(from: text),
            note: nil,
            extractedText: text
        )
    }

    func extractIBAN(from text: String) -> String? {
        let pattern = #"\b[A-Z]{2}\d{2}(?:[ \t]?[A-Z0-9]){10,30}\b"#
        let upper = text.uppercased()
        guard let range = upper.range(of: pattern, options: .regularExpression) else { return nil }
        return Self.normalizeIBANValue(String(upper[range]))
    }

    func extractAmount(from lines: [String], documentType: ParsedDocumentType) -> Decimal? {
        if documentType == .receipt {
            return extractReceiptTotalAmount(from: lines)
        }

        let priorityKeywords = ["gesamt", "betrag", "summe", "total", "zu zahlen"]
        var candidates: [(score: Int, amount: Decimal)] = []

        for line in lines {
            let lower = line.lowercased()
            let score = priorityKeywords.reduce(0) { partial, keyword in
                partial + (lower.contains(keyword) ? 2 : 0)
            } + ((lower.contains("€") || lower.contains("eur")) ? 1 : 0)

            let amounts = extractAmounts(from: line)
            for amount in amounts where amount > 0 && amount < 1_000_000 {
                candidates.append((score: score, amount: amount))
            }
        }

        return candidates
            .sorted { lhs, rhs in
                if lhs.score == rhs.score { return lhs.amount > rhs.amount }
                return lhs.score > rhs.score
            }
            .first?.amount
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
            "belegdatum", "datum der rechnung"
        ]
        let dueKeywords = ["zahlbar bis", "fällig", "faellig", "due date", "due"]

        let keywordLines = lines.filter { line in
            let lower = line.lowercased()
            return keywords.contains { lower.contains($0) } &&
                !dueKeywords.contains(where: { lower.contains($0) })
        }

        for line in keywordLines {
            if let parsed = parseFirstDate(in: line) {
                return parsed
            }
        }

        for line in lines.prefix(12) {
            let lower = line.lowercased()
            if dueKeywords.contains(where: { lower.contains($0) }) { continue }
            if lower.contains("bestelldatum") || lower.contains("versanddatum") { continue }
            if let parsed = parseFirstDate(in: line), parsed <= calendar.startOfDay(for: Date()) {
                return parsed
            }
        }

        return nil
    }

    func extractDueOffsetDaysHint(from lines: [String]) -> Int? {
        let lowerLines = lines.map { $0.lowercased() }
        let dueKeywords = ["zahlbar", "zahlungsziel", "fällig", "faellig", "due", "net"]
        let dayPattern = #"(?:innerhalb\s+von\s+|in\s+|net\s*)(\d{1,2})\s*(?:tagen|tage|tag|days?|d)\b|(\d{1,2})\s*(?:tagen|tage|tag)\s*netto\b"#

        for line in lowerLines {
            guard dueKeywords.contains(where: { line.contains($0) }) else { continue }

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
        let datePattern = #"\b\d{2}\.\d{2}\.\d{2,4}\b|\b\d{4}-\d{2}-\d{2}\b"#
        let tokens = line.matches(for: datePattern)
        guard !tokens.isEmpty else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")
        let formats = ["dd.MM.yyyy", "dd.MM.yy", "yyyy-MM-dd"]

        for token in tokens {
            for format in formats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: token) {
                    return calendar.startOfDay(for: date)
                }
            }
        }
        return nil
    }

    func extractInvoiceNumber(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ")
        let strictPatterns = [
            #"\bDE-\d{4}-\d-\d+\b"#,
            #"\b[A-Z]{2,5}-\d{4}-[A-Z0-9\-]{4,}\b"#
        ]
        for pattern in strictPatterns {
            if let range = joined.range(of: pattern, options: .regularExpression) {
                return String(joined[range])
            }
        }

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
        if let teamVendor = extractTeamVendor(from: lines) {
            return teamVendor
        }

        if let legalEntity = extractLegalEntityLine(from: lines) {
            return legalEntity
        }

        for line in lines {
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.isEmpty { continue }
            let lower = cleaned.lowercased()
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
            let lower = line.lowercased()
            if ignoreFragments.contains(where: { lower.contains($0) }) { continue }
            if isLikelyCustomerLine(lower) { continue }
            if line.count < 3 { continue }
            return line
        }
        return "Unbekannt"
    }

    private func extractPaymentRecipient(from lines: [String]) -> String {
        if let legalEntity = extractLegalEntityLine(from: lines) {
            return legalEntity
        }

        for line in lines {
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.isEmpty { continue }
            let lower = cleaned.lowercased()
            if isLikelyCustomerLine(lower) { continue }
            if containsCompanyMarker(lower) {
                return cleaned
            }
        }
        return extractVendorName(from: lines)
    }

    private func extractLegalEntityLine(from lines: [String]) -> String? {
        for line in lines {
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.isEmpty { continue }
            let lower = cleaned.lowercased()
            if isLikelyCustomerLine(lower) { continue }
            if hasLegalEntitySuffix(lower) {
                return cleaned
            }
        }
        return nil
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
            "hallo ", "deine bestellung", "seite ", "tel.:", "fax:", "email:", "ust-id", "hrb"
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

        let countryLengths: [String: Int] = [
            "DE": 22, "AT": 20, "CH": 21, "NL": 18, "BE": 16, "FR": 27,
            "ES": 24, "IT": 27, "PL": 28, "LU": 20
        ]

        if normalized.count >= 4 {
            let country = String(normalized.prefix(2))
            if let expectedLength = countryLengths[country], normalized.count >= expectedLength {
                return String(normalized.prefix(expectedLength))
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
