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
    private struct HeaderSignals {
        var invoiceNumber: String?
        var invoiceDate: Date?
        var dueOffsetDaysHint: Int?
        static let empty = HeaderSignals(invoiceNumber: nil, invoiceDate: nil, dueOffsetDaysHint: nil)
    }

    func parse(text: String) -> ParsedInvoiceData {
        let normalizedText = normalizeOCRText(text)
        let lines = normalizedText
            .split(separator: "\n")
            .map { normalizeOCRLine(String($0)) }
            .filter { !$0.isEmpty }
        let documentType = classifyDocumentType(from: lines)
        let headerSignals = documentType == .receipt ? HeaderSignals.empty : extractHeaderSignals(from: lines)
        let invoiceDate = documentType == .receipt ? nil : (headerSignals.invoiceDate ?? extractInvoiceDate(from: lines))
        let dueDate = documentType == .receipt ? nil : extractDueDate(from: lines)
        let dueOffsetDaysHint = documentType == .receipt ? nil : (headerSignals.dueOffsetDaysHint ?? extractDueOffsetDaysHint(from: lines))

        return ParsedInvoiceData(
            documentType: documentType,
            vendorName: extractVendorName(from: lines),
            paymentRecipient: extractPaymentRecipient(from: lines),
            category: extractCategory(from: lines),
            amount: extractAmount(from: lines, documentType: documentType),
            invoiceDate: invoiceDate,
            dueOffsetDaysHint: dueOffsetDaysHint,
            dueDate: dueDate,
            invoiceNumber: documentType == .receipt ? nil : (headerSignals.invoiceNumber ?? extractInvoiceNumber(from: lines)),
            iban: extractIBAN(from: lines, fullText: normalizedText),
            note: nil,
            extractedText: normalizedText
        )
    }

    private func normalizeOCRText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
            .map(normalizeOCRLine)
            .joined(separator: "\n")
    }

    private func normalizeOCRLine(_ raw: String) -> String {
        var value = raw.precomposedStringWithCompatibilityMapping
        value = value
            .replacingOccurrences(of: #"[​‌‍﻿]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[        ]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[‐‑‒–—―−]"#, with: "-", options: .regularExpression)
            .replacingOccurrences(of: #"[／⁄∕]"#, with: "/", options: .regularExpression)
            .replacingOccurrences(of: #"[：﹕]"#, with: ":", options: .regularExpression)
            .replacingOccurrences(of: #"\bD\s*E\s*[:;\.-]?\s*(\d)"#, with: "DE$1", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value
    }

    private func extractHeaderSignals(from lines: [String]) -> HeaderSignals {
        var signals = HeaderSignals.empty
        let numberLabels = ["rechnungsnummer", "rechnungsnr", "rechnung nr", "invoice no", "invoice number", "invoice nr", "belegnr", "rg nr"]
        let dateLabels = ["rechnungsdatum", "rechnung vom", "invoice date", "issue date", "belegdatum", "date:"]
        let dueLabels = ["zahlungsziel", "zahlbar", "fällig", "faellig", "due", "terms", "payment terms", "netto"]
        let serviceKeywords = ["leistungsdatum", "service date", "delivery date", "lieferdatum", "bestelldatum", "versanddatum"]
        let normalizedLines = lines.map { $0.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression) }

        for (idx, line) in normalizedLines.enumerated() {
            let lower = normalizedLower(line)
            let valueRange = idx...min(idx + 3, normalizedLines.count - 1)

            if signals.invoiceNumber == nil, numberLabels.contains(where: { lower.contains($0) }) {
                if let sameLine = line.firstCaptureGroup(for: #"(?i)(?:rechnungs?(?:nummer|[-\s]*nr\.?)|rg[-\s]*nr\.?|beleg(?:nummer|[-\s]*nr\.?)|invoice\s*(?:no|nr|number)\.?)\s*[:#-]?\s*([A-Z0-9][A-Z0-9\-/\.\s]{2,})"#),
                   let normalized = normalizeInvoiceNumberCandidate(sameLine) {
                    signals.invoiceNumber = normalized
                } else {
                    for j in valueRange {
                        if let token = firstStandaloneInvoiceNumberToken(in: normalizedLines[j]),
                           let normalized = normalizeInvoiceNumberCandidate(token) {
                            signals.invoiceNumber = normalized
                            break
                        }
                    }
                }
            }

            if signals.invoiceDate == nil,
               dateLabels.contains(where: { lower.contains($0) }),
               !serviceKeywords.contains(where: { lower.contains($0) }) {
                if let sameDate = parseFirstDate(in: line), sameDate <= calendar.startOfDay(for: Date()) {
                    signals.invoiceDate = sameDate
                } else {
                    for j in valueRange {
                        let nextLower = normalizedLower(normalizedLines[j])
                        if serviceKeywords.contains(where: { nextLower.contains($0) }) { continue }
                        if let parsed = parseFirstDate(in: normalizedLines[j]), parsed <= calendar.startOfDay(for: Date()) {
                            signals.invoiceDate = parsed
                            break
                        }
                    }
                }
            }

            if signals.dueOffsetDaysHint == nil, dueLabels.contains(where: { lower.contains($0) }) {
                for j in valueRange {
                    if let days = extractInlineDueDays(from: normalizedLower(normalizedLines[j])) {
                        signals.dueOffsetDaysHint = days
                        break
                    }
                }
            }

            if signals.invoiceNumber != nil, signals.invoiceDate != nil, signals.dueOffsetDaysHint != nil {
                break
            }
        }

        return signals
    }

    private func extractInlineDueDays(from lowerLine: String) -> Int? {
        let fromInvoicePattern = #"(?:due|payable|payment\s+due|zahlbar)\s*(?:within\s*)?(7|14|30)\s*(?:days?|tagen|tage|tag)\s*(?:from|after)?\s*(?:the\s*)?(?:invoice|invoice\s+receipt|receipt|rechnungsdatum)"#
        let dayPattern = #"(?:innerhalb\s+von\s+|in\s+|due\s+in\s+|net\s*)(\d{1,2})\s*(?:tagen|tage|tag|days?|d)\b|(\d{1,2})\s*(?:tagen|tage|tag|days?)\s*(?:net|netto)?\b"#
        let plainDaysPattern = #"\b(7|14|30)\s*(?:days?|tagen|tage|tag)\b"#

        if let token = lowerLine.firstCaptureGroup(for: fromInvoicePattern), let days = Int(token), [7, 14, 30].contains(days) {
            return days
        }
        if let token = lowerLine.firstCaptureGroup(for: dayPattern), let days = Int(token), [7, 14, 30].contains(days) {
            return days
        }
        if let token = lowerLine.firstCaptureGroup(for: plainDaysPattern), let days = Int(token), [7, 14, 30].contains(days) {
            return days
        }
        if lowerLine.contains("net 30") || lowerLine.contains("netto 30") { return 30 }
        if lowerLine.contains("net 14") || lowerLine.contains("netto 14") { return 14 }
        if lowerLine.contains("net 7") || lowerLine.contains("netto 7") { return 7 }
        return nil
    }

    func extractIBAN(from lines: [String], fullText: String) -> String? {
        let lowerLines = lines.map { normalizedLower($0) }
        let labelKeywords = ["iban", "account", "konto", "kontoinhaber", "payment", "pay", "zan", "tan", "baan", "bay"]
        let deLikePattern = #"\bD[EI1L][A-Z0-9]{2}(?:[ \t:/-]?[A-Z0-9]){10,40}\b"#
        let genericPattern = #"\b[A-Z]{2}\d{2}(?:[ \t:/-]?[A-Z0-9]){10,34}\b"#

        for (idx, line) in lines.enumerated() {
            guard labelKeywords.contains(where: { lowerLines[idx].contains($0) }) else { continue }
            if let normalized = Self.normalizeIBANValue(line) {
                return normalized
            }
            if let suffix = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true).last,
               let normalized = Self.normalizeIBANValue(String(suffix)) {
                return normalized
            }

            let windowText = lines[idx...min(idx + 3, lines.count - 1)].joined(separator: " ")
            if let normalized = Self.normalizeIBANValue(windowText) {
                return normalized
            }
            if let loose = Self.normalizeLooseGermanIBANValue(windowText), !loose.isEmpty {
                return loose
            }
            let compactWindow = windowText.replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
            if let normalized = Self.normalizeIBANValue(compactWindow) {
                return normalized
            }
            if let loose = Self.normalizeLooseGermanIBANValue(compactWindow), !loose.isEmpty {
                return loose
            }

            for nearby in idx...min(idx + 2, lines.count - 1) {
                for candidate in lines[nearby].uppercased().matches(for: deLikePattern) {
                    if let normalized = Self.normalizeIBANValue(candidate) {
                        return normalized
                    }
                }
                for candidate in lines[nearby].uppercased().matches(for: genericPattern) {
                    if let normalized = Self.normalizeIBANValue(candidate) {
                        return normalized
                    }
                }
            }

            if let noisyFromWindow = Self.extractGermanIBANFromNoisy(windowText.uppercased()) {
                return noisyFromWindow
            }
        }

        return extractIBAN(from: fullText)
    }

    func extractIBAN(from text: String) -> String? {
        let upper = text.uppercased()
        if let labeled = upper.firstCaptureGroup(
            for: #"(?i)\b(?:IBAN|I[^A-Z]{0,3}B[^A-Z]{0,3}A[^A-Z]{0,3}N|PAN|PANN)\b[^A-Z0-9]*([A-Z0-9][A-Z0-9 \t:/-]{12,60})"#
        ),
           let normalized = Self.normalizeIBANValue(labeled) {
            return normalized
        }
        if let paymentLabeled = upper.firstCaptureGroup(
            for: #"(?i)\b(?:PAY(?:MENT)?|ACCOUNT|PAY\.)\b[^A-Z0-9]*(D[EI1L][ A-Z0-9:/-]{12,60})"#
        ), let normalized = Self.normalizeIBANValue(paymentLabeled) {
            return normalized
        }

        let deLikePattern = #"\bD[EI1L][A-Z0-9]{2}(?:[ \t:/-]?[A-Z0-9]){10,40}\b"#
        for candidate in upper.matches(for: deLikePattern) {
            if let normalized = Self.normalizeIBANValue(candidate) {
                return normalized
            }
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
        let serviceKeywords = [
            "leistungsdatum", "service date", "delivery date", "lieferdatum",
            "bestelldatum", "versanddatum", "leistungszeitraum", "service period"
        ]

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
            let lower = lines[idx].lowercased()
            if serviceKeywords.contains(where: { lower.contains($0) }) { continue }
            if let parsed = parseFirstDate(in: lines[idx]), parsed <= calendar.startOfDay(for: Date()) {
                return parsed
            }
        }

        // 2) Table layouts: label in header row, value in subsequent row(s).
        for idx in keywordIndices {
            let nextRange = (idx + 1)...min(idx + 12, lines.count - 1)
            for j in nextRange {
                let lower = lines[j].lowercased()
                if dueKeywords.contains(where: { lower.contains($0) }) { continue }
                if serviceKeywords.contains(where: { lower.contains($0) }) {
                    continue
                }
                if let parsed = parseFirstDate(in: lines[j]), parsed <= calendar.startOfDay(for: Date()) {
                    return parsed
                }
            }
        }

        // 3) Score-based fallback in first lines to avoid service/order dates.
        var best: (score: Int, date: Date)?
        for line in lines.prefix(24) {
            let lower = line.lowercased()
            if dueKeywords.contains(where: { lower.contains($0) }) { continue }
            if serviceKeywords.contains(where: { lower.contains($0) }) { continue }
            guard let parsed = parseFirstDate(in: line), parsed <= calendar.startOfDay(for: Date()) else { continue }

            var score = 0
            if keywords.contains(where: { lower.contains($0) }) { score += 12 }
            if lower.contains("rechnungsdatum") || lower.contains("invoice date") || lower.contains("issue date") { score += 6 }
            if lower.contains("datum") || lower.contains("date") { score += 2 }
            if lower.contains("invoice") || lower.contains("rechnung") { score += 2 }
            if lower.contains("service") || lower.contains("leistung") || lower.contains("bestell") || lower.contains("versand") { score -= 8 }

            if best == nil || score > best!.score {
                best = (score, parsed)
            }
        }

        return best?.date
    }

    func extractDueOffsetDaysHint(from lines: [String]) -> Int? {
        let lowerLines = lines.map { $0.lowercased() }
        let dueKeywords = ["zahlbar", "zahlungsziel", "fällig", "faellig", "due", "net", "terms", "payment terms"]

        for (idx, line) in lowerLines.enumerated() {
            let hasContextKeyword: Bool = {
                if dueKeywords.contains(where: { line.contains($0) }) { return true }
                let from = max(0, idx - 8)
                let to = min(lowerLines.count - 1, idx + 2)
                if from <= to {
                    for j in from...to where dueKeywords.contains(where: { lowerLines[j].contains($0) }) {
                        return true
                    }
                }
                return false
            }()

            guard hasContextKeyword else { continue }
            let hasDayNumber = line.range(of: #"\b(7|14|30)\b"#, options: .regularExpression) != nil
            if !hasDayNumber { continue }

            if let days = extractInlineDueDays(from: line) {
                return days
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

        let headerHints = ["invoice no", "invoice nr", "invoice number", "rechnungsnr", "rechnungsnummer", "rg nr"]
        for (idx, line) in normalizedLines.enumerated() {
            let lower = normalizedLower(line)
            guard headerHints.contains(where: { lower.contains($0) }) else { continue }
            let nextRange = (idx + 1)...min(idx + 12, normalizedLines.count - 1)
            for j in nextRange {
                if let token = firstStandaloneInvoiceNumberToken(in: normalizedLines[j]),
                   let normalized = normalizeInvoiceNumberCandidate(token),
                   !normalized.isEmpty {
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
            #"\bR\d{6,10}\b"#,
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

    private func firstStandaloneInvoiceNumberToken(in line: String) -> String? {
        let upper = line.uppercased()
        let patterns = [
            #"\b(?:INV|RE|RG)[-\s]?\d{3,10}(?:[-/]\d{2,8})?\b"#,
            #"\bR\d{6,10}\b"#,
            #"\b\d{4}\s*/\s*\d{3,8}\b"#,
            #"\b\d{4}/\d{3,8}\b"#,
            #"\b[A-Z]{1,3}-\d{4}-\d{2,6}\b"#
        ]
        for pattern in patterns {
            if let range = upper.range(of: pattern, options: .regularExpression) {
                return String(upper[range])
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

        value = healInvoiceNumberOCRNoise(value)

        if let range = value.range(of: #"^(INV|RE)(\d{3,})$"#, options: .regularExpression),
           range.lowerBound == value.startIndex, range.upperBound == value.endIndex,
           let prefix = value.firstCaptureGroup(for: #"^(INV|RE)(\d{3,})$"#),
           let suffix = value.firstCaptureGroup(for: #"^(?:INV|RE)(\d{3,})$"#) {
            value = "\(prefix)-\(suffix)"
        }

        guard value.count >= 4 else { return nil }
        guard value.range(of: #"[A-Z0-9]"#, options: .regularExpression) != nil else { return nil }
        guard value.range(of: #"^\d{1,2}[./-]\d{1,2}[./-]\d{2,4}$"#, options: .regularExpression) == nil else { return nil }
        return value
    }

    private static func healInvoiceNumberOCRNoise(_ raw: String) -> String {
        var value = raw

        // Common OCR swap in DE invoices: RG000123 -> R6000123.
        if value.range(of: #"^R6\d{6}$"#, options: .regularExpression) != nil {
            let second = value.index(after: value.startIndex)
            value.replaceSubrange(second...second, with: "G")
        }

        // Normalize digit-like letters in numeric tail.
        let prefixes = ["RG", "INV-", "RE-", "R"]
        for prefix in prefixes where value.hasPrefix(prefix) {
            let start = value.index(value.startIndex, offsetBy: prefix.count)
            if start < value.endIndex {
                let tail = String(value[start...]).map { c -> Character in
                    switch c {
                    case "O", "D", "Q": return "0"
                    case "I", "L": return "1"
                    case "Z": return "2"
                    case "S": return "5"
                    case "B": return "8"
                    default: return c
                    }
                }
                value = prefix + String(tail)
            }
            break
        }
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
        let strongReceiptKeywords = [
            "kassenbon", "kassenbeleg", "ec-karte", "kartenzahlung", "barzahlung", "wechselgeld", "filiale"
        ]
        let invoiceKeywords = [
            "rechnung", "invoice", "rechnungsnummer", "rechnung nr", "zahlbar bis", "fällig", "faellig",
            "zahlungsempfänger", "zahlungsempfaenger", "iban", "due date"
        ]
        let strongInvoiceKeywords = [
            "rechnungsnr", "rechnungsnummer", "rechnungsdatum", "zahlungsziel", "leistungsdatum",
            "kundennr", "bestellnr", "verwendungszweck", "invoice no", "invoice number", "invoice date", "terms"
        ]

        let receiptHits = receiptKeywords.filter { text.contains($0) }.count
        let strongReceiptHits = strongReceiptKeywords.filter { text.contains($0) }.count
        let invoiceHits = invoiceKeywords.filter { text.contains($0) }.count
        let strongInvoiceHits = strongInvoiceKeywords.filter { text.contains($0) }.count

        if strongInvoiceHits >= 2 { return .invoice }
        if receiptHits >= 2 && strongReceiptHits >= 1 && invoiceHits == 0 && strongInvoiceHits == 0 { return .receipt }
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

        if normalized.count >= 2, normalized.hasPrefix("D") {
            let second = normalized[normalized.index(after: normalized.startIndex)]
            if second == "1" || second == "I" || second == "L" {
                normalized.replaceSubrange(
                    normalized.index(after: normalized.startIndex)...normalized.index(after: normalized.startIndex),
                    with: "E"
                )
            }
        }

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
                if let range = normalized.range(of: #"DE\d{20}"#, options: .regularExpression) {
                    normalized = String(normalized[range])
                } else if let directMapped = extractGermanIBANFromNoisy(normalized) {
                    normalized = directMapped
                } else if let healed = healGermanIBAN(normalized) {
                    normalized = healed
                } else {
                    return nil
                }
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

    private static func normalizeLooseGermanIBANValue(_ value: String?) -> String? {
        guard let value else { return nil }
        let upper = value.uppercased()
        // Only apply loose fallback for explicit bank labels directly tied to a DE... candidate.
        let labelBoundPattern = #"(?i)(?:IBAN|ZAN|TAN|BAY|BAAN|ACCOUNT|PAY)[^A-Z0-9]{0,8}D[EI1L][^A-Z0-9]{0,4}([0-9A-Z\s:/-]{14,36})(?:\bBIC\b|$)"#
        guard let payload = upper.firstCaptureGroup(for: labelBoundPattern) else { return nil }
        if upper.contains("UST") || upper.contains("VAT") || upper.contains("HRB") || upper.contains("AMTSGERICHT") {
            return nil
        }

        let mappedDigits = payload.compactMap { c -> Character? in
            switch c {
            case "0"..."9": return c
            case "O", "D", "Q": return "0"
            case "I", "L": return "1"
            case "Z": return "2"
            case "S": return "5"
            case "G": return "6"
            case "T", "Y": return "7"
            case "B": return "8"
            default: return nil
            }
        }
        guard mappedDigits.count >= 16 else { return nil }
        let digits = String(mappedDigits.prefix(20))
        return "DE" + digits
    }

    private static func extractGermanIBANFromNoisy(_ raw: String) -> String? {
        guard raw.count >= 8 else { return nil }
        let mapped = raw.map { c -> Character in
            switch c {
            case "O", "D", "Q": return "0"
            case "I", "L": return "1"
            case "Z": return "2"
            case "S": return "5"
            case "G": return "6"
            case "T", "Y": return "7"
            case "B": return "8"
            default: return c
            }
        }
        let healed = String(mapped)
        if let range = healed.range(of: #"DE\d{20}"#, options: .regularExpression) {
            return String(healed[range])
        }
        return nil
    }

    private static func healGermanIBAN(_ raw: String) -> String? {
        var adapted = raw
        if !adapted.hasPrefix("DE"), adapted.hasPrefix("D"), adapted.count >= 2 {
            adapted.replaceSubrange(
                adapted.index(after: adapted.startIndex)...adapted.index(after: adapted.startIndex),
                with: "E"
            )
        }
        guard adapted.hasPrefix("DE"), adapted.count >= 10 else { return nil }

        let tail = Array(adapted.dropFirst(2))
        guard tail.count >= 2 else { return nil }

        func mapDigitLike(_ c: Character) -> Character {
            switch c {
            case "O", "D", "Q": return "0"
            case "I", "L": return "1"
            case "Z": return "2"
            case "S": return "5"
            case "G": return "6"
            case "T", "Y": return "7"
            case "B": return "8"
            default: return c
            }
        }

        var check = ""
        for c in tail.prefix(2) {
            let m = mapDigitLike(c)
            guard m.isNumber else { return nil }
            check.append(m)
        }

        var bodyDigits = ""
        for c in tail.dropFirst(2) {
            let m = mapDigitLike(c)
            if m.isNumber {
                bodyDigits.append(m)
            }
        }
        guard bodyDigits.count >= 18 else { return nil }
        bodyDigits = String(bodyDigits.prefix(18))
        return "DE" + check + bodyDigits
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
