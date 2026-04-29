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
    /// Wenn die Rechnung explizit auf bereits erfolgte Zahlung per
    /// PayPal/ApplePay/etc. hinweist ("Die Zahlung wurde per Paypal
    /// beglichen."), wird hier der erkannte Anbieter (z. B. "PayPal")
    /// hinterlegt. Das Review-Sheet zeigt daraus einen Vorschlag-Banner —
    /// die Auto-Markierung als bezahlt geschieht aber NUR auf Klick des
    /// Nutzers, nicht implizit.
    var alreadyPaidProviderHint: String?
}

struct ParsingService {
    /// Fixe Zeitzone Europe/Berlin fuer alle Datums-Operationen im Parser.
    /// Vorher: Calendar.current — abhaengig von der System-Zeitzone des Nutzers.
    /// Effekt: Wer mit dem iPhone in Tokio (UTC+9) eine deutsche Rechnung
    /// scannt, deren Rechnungsdatum "22.04.2026" ist, bekam u. U. einen
    /// Vergleich "22.04.2026 00:00 Tokyo > heute (Berlin)" und damit
    /// invoiceDate=nil. Mit fixiertem TZ ist das Verhalten reproduzierbar
    /// und entspricht der Lokalzeit, die auf der Rechnung gemeint war.
    private static let parserTimeZone: TimeZone = TimeZone(identifier: "Europe/Berlin") ?? TimeZone(secondsFromGMT: 0)!
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ParsingService.parserTimeZone
        cal.locale = Locale(identifier: "de_DE")
        return cal
    }()
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
        let vendorName = extractVendorName(from: lines)
        let extractedRecipient = extractPaymentRecipient(from: lines)
        let paymentRecipient = (documentType == .receipt) ? vendorName : extractedRecipient
        let headerSignals = documentType == .receipt ? HeaderSignals.empty : extractHeaderSignals(from: lines)
        let invoiceDate = documentType == .receipt ? nil : (headerSignals.invoiceDate ?? extractInvoiceDate(from: lines))
        let dueDate = documentType == .receipt ? nil : extractDueDate(from: lines)
        let dueOffsetDaysHint = documentType == .receipt ? nil : (headerSignals.dueOffsetDaysHint ?? extractDueOffsetDaysHint(from: lines))

        return ParsedInvoiceData(
            documentType: documentType,
            vendorName: vendorName,
            paymentRecipient: paymentRecipient,
            category: extractCategory(from: lines),
            amount: extractAmount(from: lines, documentType: documentType),
            invoiceDate: invoiceDate,
            dueOffsetDaysHint: dueOffsetDaysHint,
            dueDate: dueDate,
            invoiceNumber: documentType == .receipt ? nil : (headerSignals.invoiceNumber ?? extractInvoiceNumber(from: lines)),
            iban: extractIBAN(from: lines, fullText: normalizedText),
            note: nil,
            extractedText: normalizedText,
            alreadyPaidProviderHint: extractAlreadyPaidProviderHint(from: normalizedText)
        )
    }

    /// Erkennt explizite Hinweise, dass die Rechnung bereits ueber einen
    /// Online-Bezahldienst beglichen wurde — nur sehr enge Phrasen, damit
    /// keine falschen Vorschlaege bei "Wir akzeptieren PayPal" entstehen.
    private func extractAlreadyPaidProviderHint(from text: String) -> String? {
        let lower = text.lowercased()

        // Provider in der Reihenfolge ihrer Auflistung — der erste Treffer gewinnt.
        let providers: [(label: String, needles: [String])] = [
            ("PayPal", ["paypal"]),
            ("Apple Pay", ["apple pay", "applepay"]),
            ("Google Pay", ["google pay", "googlepay", "gpay"]),
            ("Klarna", ["klarna"]),
            ("Stripe", ["stripe"]),
            ("Amazon Pay", ["amazon pay", "amazonpay"]),
            ("Sofortueberweisung", ["sofortueberweisung", "sofortüberweisung", "sofort überweisung"]),
            ("Kreditkarte", ["kreditkarte", "credit card"])
        ]

        // Nur wenn der Provider zusammen mit einem Begleichungs-Verb auftaucht.
        // Das schliesst neutrale Erwaehnungen ("Wir akzeptieren PayPal") aus.
        let paidVerbs = [
            "beglichen", "bezahlt", "abgewickelt", "vereinnahmt",
            "paid", "settled", "charged", "completed"
        ]

        for provider in providers {
            for needle in provider.needles {
                guard lower.contains(needle) else { continue }
                if paidVerbs.contains(where: { lower.contains($0) }) {
                    return provider.label
                }
            }
        }
        return nil
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
        // "rechnung #" / "invoice #" decken zusaetzlich die Schreibweise mit
        // Hash-Symbol ab, die viele Online-Shops (z. B. sunday.de, Amazon)
        // nutzen ("RECHNUNG # INV/2026/2463032").
        let numberLabels = ["rechnungsnummer", "rechnungsnr", "rechnung nr", "rechnung #", "invoice no", "invoice number", "invoice nr", "invoice #", "belegnr", "rg nr"]
        let dateLabels = ["rechnungsdatum", "rechnung vom", "invoice date", "issue date", "belegdatum", "date:"]
        let dueLabels = ["zahlungsziel", "zahlbar", "fällig", "faellig", "due", "terms", "payment terms", "netto"]
        let serviceKeywords = ["leistungsdatum", "service date", "delivery date", "lieferdatum", "bestelldatum", "versanddatum"]
        let normalizedLines = lines.map { $0.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression) }

        for (idx, line) in normalizedLines.enumerated() {
            let lower = normalizedLower(line)
            let valueRange = idx...min(idx + 3, normalizedLines.count - 1)

            if signals.invoiceNumber == nil, numberLabels.contains(where: { lower.contains($0) }) {
                // Erweitert: matched jetzt auch "Rechnung #"/"Invoice #" als Label
                // und akzeptiert mehrteilige Slash-Werte wie "INV/2026/2463032".
                // Capture-Set ohne \s — sonst frisst die Regex bei
                // "Rechnungsnummer: TS-2026-55209 Bestellnummer: ORD-7785001"
                // bis zum Zeilenende und produziert "TS-2026-55209BESTELLNUMMER..."
                // nach Whitespace-Collapse.
                if let sameLine = line.firstCaptureGroup(for: #"(?i)(?:rechnungs?(?:nummer|[-\s]*nr\.?|\s*#)|rg[-\s]*nr\.?|beleg(?:nummer|[-\s]*nr\.?)|invoice\s*(?:no|nr|number|#)\.?)\s*[:#-]?\s*([A-Z0-9][A-Z0-9\-/\.]{2,})"#),
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
        if let loose = Self.normalizeLooseGermanIBANValue(upper), !loose.isEmpty {
            return loose
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
        let receiptAmountMax: Decimal = 1500

        enum ReceiptAmountLabel {
            case total
            case given
            case change
        }

        let hardTotalKeywords = [
            "summe", "gesamt", "zu zahlen", "zahlbetrag", "endbetrag", "total", "grand total",
            "rechnungsbetrag", "rechnung5betrag", "t0tal"
        ]
        let strongestTotalKeywords = [
            "zu zahlen", "zahlbetrag", "endsumme", "endbetrag", "amount due", "payable", "total due", "grand total",
            "rechnungsbetrag", "rechnung5betrag", "gesamtbetrag", "zu zhlen", "zu2ahlen", "zu 2ahlen"
        ]
        let weakTotalKeywords = ["betrag", "eur", "€"]
        let payContextKeywords = ["ec", "karte", "card", "girocard", "mastercard", "visa"]
        let cashGivenKeywords = ["bar gegeben", "cash given", "given", "gegeben", "tendered", "amount tendered"]
        let cashChangeKeywords = ["rueckgeld", "rückgeld", "change", "wechselgeld"]
        let excludeKeywords = [
            "mwst", "ust", "steuer", "tax", "rabatt", "gespart", "einzelpreis", "zwischensumme",
            "rueckgeld", "rückgeld", "gegeben", "bar gegeben", "cash given", "change", "erhalten",
            "umsatzsteuer", "steueranteil", "vat", "ust-id", "taxes"
        ]

        var scored: [(score: Double, amount: Decimal)] = []
        var lastAmount: Decimal?
        var hardCandidates: [Decimal] = []
        var hardScoredCandidates: [(score: Double, index: Int, amount: Decimal)] = []
        var strongestLabelCandidates: [Decimal] = []
        var cashGivenCandidates: [Decimal] = []
        var cashChangeCandidates: [Decimal] = []
        var paymentLineCandidates: [Decimal] = []
        var subtotalCandidates: [Decimal] = []
        var discountCandidates: [Decimal] = []
        var vatDerivedCandidates: [Decimal] = []
        var nonExcludedCandidates: [Decimal] = []
        var normalizedLines: [String] = []

        normalizedLines.reserveCapacity(lines.count)
        for line in lines {
            normalizedLines.append(normalizedLower(line))
        }
        let ocrTolerantLines = normalizedLines.map {
            $0
                .replacingOccurrences(of: #"(?<=[a-z])0(?=[a-z])"#, with: "o", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\b)2(?=[a-z])"#, with: "z", options: .regularExpression)
        }
        let compactLines = ocrTolerantLines.map {
            $0.replacingOccurrences(of: #"[^a-z0-9%]+"#, with: "", options: .regularExpression)
        }

        func keywordCompact(_ keyword: String) -> String {
            keyword.replacingOccurrences(of: #"[^a-z0-9%]+"#, with: "", options: .regularExpression)
        }
        func tokenPattern(_ token: String) -> String {
            let escapedChars = token.map { NSRegularExpression.escapedPattern(for: String($0)) }
            return escapedChars.joined(separator: #"\s*"#)
        }
        func containsKeyword(line: String, compactLine: String, keyword: String) -> Bool {
            let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !trimmed.isEmpty else { return false }
            let ocrLine = line
                .replacingOccurrences(of: #"(?<=[a-z])0(?=[a-z])"#, with: "o", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\b)2(?=[a-z])"#, with: "z", options: .regularExpression)

            let tokenPatterns = trimmed
                .split(separator: " ")
                .map(String.init)
                .filter { !$0.isEmpty }
                .map(tokenPattern)
            let joinedTokenPattern = tokenPatterns.joined(separator: #"\s+"#)
            let boundaryPattern = #"(^|[^a-z0-9])"# + joinedTokenPattern + #"([^a-z0-9]|$)"#
            if ocrLine.range(of: boundaryPattern, options: .regularExpression) != nil {
                return true
            }

            // Compact fallback for heavily fragmented OCR text.
            let compactKeyword = keywordCompact(trimmed)
            guard !compactKeyword.isEmpty else { return false }

            // Prevent generic "total" from matching "subtotal" in compact form.
            if compactKeyword == "total", compactLine.contains("subtotal") {
                if compactLine.contains("totaldue") || compactLine.contains("grandtotal") {
                    return true
                }
                return false
            }
            return compactLine.contains(compactKeyword)
        }
        func containsAny(line: String, compactLine: String, keywords: [String]) -> Bool {
            keywords.contains { containsKeyword(line: line, compactLine: compactLine, keyword: $0) }
        }
        func countMatches(line: String, compactLine: String, keywords: [String]) -> Int {
            keywords.filter { containsKeyword(line: line, compactLine: compactLine, keyword: $0) }.count
        }

        // Block mapping for column layouts:
        // [SUMME, BAR GEGEBEN, RUECKGELD] followed by [27,99, 32,99, 5,00].
        var idx = 0
        while idx < lines.count {
            var labelSequence: [ReceiptAmountLabel] = []
            var labelEnd = idx

            func lineHasAmount(_ i: Int) -> Bool {
                !extractAmounts(from: lines[i], repairOCRSpacing: true).filter { $0 > 0 && $0 < receiptAmountMax }.isEmpty
            }

            while labelEnd < lines.count {
                let lower = normalizedLines[labelEnd]
                let compactLower = compactLines[labelEnd]
                if lineHasAmount(labelEnd) { break }
                if containsAny(line: lower, compactLine: compactLower, keywords: hardTotalKeywords) &&
                    !containsAny(line: lower, compactLine: compactLower, keywords: excludeKeywords) {
                    labelSequence.append(.total)
                    labelEnd += 1
                    continue
                }
                if containsAny(line: lower, compactLine: compactLower, keywords: cashGivenKeywords) &&
                    !containsAny(line: lower, compactLine: compactLower, keywords: cashChangeKeywords) {
                    labelSequence.append(.given)
                    labelEnd += 1
                    continue
                }
                if containsAny(line: lower, compactLine: compactLower, keywords: cashChangeKeywords) {
                    labelSequence.append(.change)
                    labelEnd += 1
                    continue
                }
                break
            }

            if !labelSequence.isEmpty {
                var amountRows: [Decimal] = []
                let amountWindowEnd = min(lines.count - 1, labelEnd + 16)
                if labelEnd <= amountWindowEnd {
                    for j in labelEnd...amountWindowEnd {
                        let lower = normalizedLines[j]
                        let amounts = extractAmounts(from: lines[j], repairOCRSpacing: true).filter { $0 > 0 && $0 < receiptAmountMax }
                        if amounts.isEmpty { continue }
                        let hasAlpha = lower.range(of: #"[a-z]"#, options: .regularExpression) != nil
                        if !hasAlpha {
                            amountRows.append(amounts[0])
                            if amountRows.count >= labelSequence.count { break }
                        }
                    }
                }

            if amountRows.count >= labelSequence.count {
                    for (pos, pair) in zip(labelSequence, amountRows).enumerated() {
                        let label = pair.0
                        let amount = pair.1
                        switch label {
                        case .total:
                            hardCandidates.append(amount)
                            hardScoredCandidates.append((score: 8.0, index: labelEnd + pos, amount: amount))
                        case .given:
                            cashGivenCandidates.append(amount)
                        case .change:
                            cashChangeCandidates.append(amount)
                        }
                    }
                    idx = labelEnd + amountRows.count
                    continue
                }
            }

            idx += 1
        }

        // Handle split-column receipts where labels and amounts are in separate lines:
        // SUMME / BAR GEGEBEN / RUECKGELD labels first, amount column below.
        for (idx, _) in normalizedLines.enumerated() {
            let compactLower = compactLines[idx]
            let ocrLower = ocrTolerantLines[idx]
            let hasHardTotal = containsAny(line: ocrLower, compactLine: compactLower, keywords: hardTotalKeywords)
            let hasStrongestTotal = containsAny(line: ocrLower, compactLine: compactLower, keywords: strongestTotalKeywords)
            let hasExclude = containsAny(line: ocrLower, compactLine: compactLower, keywords: excludeKeywords)
            let hasGiven = containsAny(line: ocrLower, compactLine: compactLower, keywords: cashGivenKeywords) &&
                !containsAny(line: ocrLower, compactLine: compactLower, keywords: cashChangeKeywords)
            let hasChange = containsAny(line: ocrLower, compactLine: compactLower, keywords: cashChangeKeywords)

            func collectLabeledAmounts(_ target: inout [Decimal]) {
                let sameLineAmounts = extractAmounts(from: lines[idx], repairOCRSpacing: true).filter { $0 > 0 && $0 < receiptAmountMax }
                if !sameLineAmounts.isEmpty {
                    target.append(contentsOf: sameLineAmounts)
                    return
                }

                // Look ahead for amount-only lines; first one is usually the mapped value in column layouts.
                let windowEnd = min(idx + 18, lines.count - 1)
                if idx + 1 <= windowEnd {
                    for j in (idx + 1)...windowEnd {
                        let candidateLower = normalizedLines[j]
                        if excludeKeywords.contains(where: { candidateLower.contains($0) }) && !hasChange {
                            continue
                        }
                        let hasAlpha = candidateLower.range(of: #"[a-z]"#, options: .regularExpression) != nil
                        let amounts = extractAmounts(from: lines[j], repairOCRSpacing: true).filter { $0 > 0 && $0 < receiptAmountMax }
                        if amounts.isEmpty { continue }
                        if !hasAlpha {
                            target.append(amounts[0])
                            break
                        }
                    }
                }
            }

            if hasHardTotal && (!hasExclude || hasStrongestTotal) {
                let idNoiseKeywords = ["bon", "beleg", "kasse", "pos", "transaktion", "receipt", "id", "nr"]
                let shouldUseIntegerFallback = !idNoiseKeywords.contains { ocrLower.contains($0) }
                if shouldUseIntegerFallback, let repairedIntegerTotal = extractIntegerCentsAmountCandidate(from: lines[idx]) {
                    hardCandidates.append(repairedIntegerTotal)
                    hardScoredCandidates.append((score: 9.0, index: idx, amount: repairedIntegerTotal))
                }
                collectLabeledAmounts(&hardCandidates)
            }
            if hasGiven {
                collectLabeledAmounts(&cashGivenCandidates)
            }
            if hasChange {
                collectLabeledAmounts(&cashChangeCandidates)
            }
        }

        for (index, line) in lines.enumerated() {
            let lower = normalizedLines[index]
            let compactLower = compactLines[index]
            let ocrLower = ocrTolerantLines[index]
            let amounts = extractAmounts(from: line, repairOCRSpacing: true).filter { $0 > 0 && $0 < receiptAmountMax }
            guard !amounts.isEmpty else { continue }
            let hasUnitPriceMarker = ocrLower.contains("eur/kg") || ocrLower.contains("/kg") || ocrLower.contains(" kg")

            let hasHardTotal = containsAny(line: ocrLower, compactLine: compactLower, keywords: hardTotalKeywords)
            let hasStrongestTotal = containsAny(line: ocrLower, compactLine: compactLower, keywords: strongestTotalKeywords)
            let hasExclude = containsAny(line: ocrLower, compactLine: compactLower, keywords: excludeKeywords)
            let hasPaymentLineKeyword = containsAny(
                line: ocrLower,
                compactLine: compactLower,
                keywords: ["ec-cash", "ec cash", "ec-karte", "kartenzahlung", "kartenzahlung", "bezahlt mit", "zahlung", "payment"]
            )
            if hasUnitPriceMarker && !hasHardTotal && !hasStrongestTotal && !hasPaymentLineKeyword {
                continue
            }
            if hasHardTotal && (!hasExclude || hasStrongestTotal) {
                hardCandidates.append(contentsOf: amounts)
                if hasStrongestTotal {
                    strongestLabelCandidates.append(contentsOf: amounts)
                }
                for amount in amounts {
                    var hardScore = 5.0
                    if hasStrongestTotal {
                        hardScore += 6.0
                    } else if containsAny(line: ocrLower, compactLine: compactLower, keywords: ["summe", "total", "t0tal"]) {
                        hardScore += 2.0
                    }
                    if containsAny(line: ocrLower, compactLine: compactLower, keywords: ["gesamt", "gesamtbetrag"]) &&
                        !containsAny(line: ocrLower, compactLine: compactLower, keywords: ["zwischensumme", "teilsumme", "subtotal"]) {
                        hardScore += 2.8
                    }
                    if containsAny(line: ocrLower, compactLine: compactLower, keywords: ["subtotal", "zwischensumme"]) {
                        hardScore -= 8.0
                    }
                    // Tax breakdown lines (e.g. "19% 17,10") should never win against explicit payable totals.
                    if (lower.contains("19%") || lower.contains("7%")) &&
                        !containsAny(line: lower, compactLine: compactLower, keywords: strongestTotalKeywords) {
                        hardScore -= 7.0
                    }
                    hardScoredCandidates.append((score: hardScore, index: index, amount: amount))
                }
            }
            if !hasExclude || hasStrongestTotal {
                nonExcludedCandidates.append(contentsOf: amounts)
            }
            if hasPaymentLineKeyword && !hasExclude {
                paymentLineCandidates.append(contentsOf: amounts)
            }
            if containsAny(line: lower, compactLine: compactLower, keywords: ["zwischensumme", "subtotal"]) {
                subtotalCandidates.append(contentsOf: amounts)
            }
            if containsAny(line: ocrLower, compactLine: compactLower, keywords: ["aktion", "rabatt", "discount", "disc0unt", "coupon"]) {
                discountCandidates.append(contentsOf: amounts)
            }
            // Tax fallback: when total line is broken (missing leading digits), derive gross from 19% tax amount.
            let taxContextKeywords = ["mwst", "ust", "umsatzsteuer", "vat", "tax"]
            let hasTaxContextHere = containsAny(line: ocrLower, compactLine: compactLower, keywords: taxContextKeywords)
            let has19 = lower.contains("19%") || compactLower.contains("19%")
            if has19 {
                let from = max(0, index - 2)
                let to = min(lines.count - 1, index + 2)
                var hasTaxContextNearby = hasTaxContextHere
                if !hasTaxContextNearby, from <= to {
                    for j in from...to {
                        if containsAny(line: ocrTolerantLines[j], compactLine: compactLines[j], keywords: taxContextKeywords) {
                            hasTaxContextNearby = true
                            break
                        }
                    }
                }
                if hasTaxContextNearby {
                    let lineMax = amounts.max() ?? 0
                    for taxAmount in amounts where taxAmount > 0 {
                        // Ignore implausibly large "tax" candidates on mixed lines like
                        // "RECHNUNGSBETRAG 170,18 ... UMSATZSTEUER ... 27,18".
                        if hasStrongestTotal, amounts.count > 1, taxAmount == lineMax {
                            continue
                        }
                        if !hasStrongestTotal, lineMax > 0, taxAmount > (lineMax * Decimal(0.45)) {
                            continue
                        }
                        let gross = (taxAmount * Decimal(119)) / Decimal(19)
                        let rounded = NSDecimalNumber(decimal: gross).rounding(accordingToBehavior: nil)
                        let normalized = Decimal(string: String(format: "%.2f", NSDecimalNumber(decimal: rounded.decimalValue).doubleValue)) ?? gross
                        if normalized > 0, normalized < receiptAmountMax {
                            vatDerivedCandidates.append(normalized)
                        }
                    }
                }
            }

            let progress = Double(index + 1) / Double(lines.count) // end-of-receipt lines usually contain final total
            for amount in amounts {
                var score = 0.0
                score += Double(countMatches(line: ocrLower, compactLine: compactLower, keywords: hardTotalKeywords)) * 5.0
                score += Double(countMatches(line: ocrLower, compactLine: compactLower, keywords: strongestTotalKeywords)) * 3.0
                score += Double(countMatches(line: ocrLower, compactLine: compactLower, keywords: weakTotalKeywords)) * 1.2
                score += Double(countMatches(line: ocrLower, compactLine: compactLower, keywords: payContextKeywords)) * 0.8
                if containsAny(line: ocrLower, compactLine: compactLower, keywords: ["gesamt", "gesamtbetrag"]) &&
                    !containsAny(line: ocrLower, compactLine: compactLower, keywords: ["zwischensumme", "teilsumme", "subtotal"]) {
                    score += 2.4
                }
                if !hasStrongestTotal {
                    score -= Double(countMatches(line: ocrLower, compactLine: compactLower, keywords: excludeKeywords)) * 6.0
                }
                if (lower.contains("19%") || lower.contains("7%")) &&
                    !containsAny(line: lower, compactLine: compactLower, keywords: strongestTotalKeywords) {
                    score -= 7.0
                }
                score += progress * 2.2
                if amount >= 1 { score += 0.3 }
                scored.append((score: score, amount: amount))
                lastAmount = amount
            }
        }

        // Cash fallback: when "given" and "change" are present, derive total as given - change.
        // This is intentionally strict to avoid false positives on noisy receipts.
        var cashTotals: [Decimal] = []
        for given in cashGivenCandidates {
            for change in cashChangeCandidates {
                guard given > change else { continue }
                let diff = given - change
                if diff > 0, diff < receiptAmountMax {
                    cashTotals.append(diff)
                }
            }
        }
        if !cashTotals.isEmpty {
            // If we have explicit total candidates, prefer one that matches derived total.
            let matchedHard = hardCandidates.first { hard in
                cashTotals.contains(where: { abs(decimalToDouble($0) - decimalToDouble(hard)) < 0.011 })
            }
            if let matchedHard {
                return matchedHard
            }

            let positiveScoredAmounts = scored
                .filter { $0.score >= 0 }
                .map(\.amount)
            if !positiveScoredAmounts.isEmpty {
                let matched = cashTotals.first { total in
                    positiveScoredAmounts.contains(where: { abs(decimalToDouble($0) - decimalToDouble(total)) < 0.011 })
                }
                if let matched {
                    return matched
                }
            } else {
                let uniqueRounded = Array(Set(cashTotals.map { round(decimalToDouble($0) * 100) / 100 })).sorted()
                if uniqueRounded.count == 1, let only = uniqueRounded.first {
                    return Decimal(string: String(format: "%.2f", only))
                }
            }
        }
        // If given/change signals exist but subtraction could not be resolved reliably,
        // do not fall back to the last scanned number (often just change).
        if !cashGivenCandidates.isEmpty, !cashChangeCandidates.isEmpty {
            if let hardFromLabels = hardCandidates.max(), hardFromLabels > 0, hardFromLabels < receiptAmountMax {
                return hardFromLabels
            }
            if let strongestFromLabels = strongestLabelCandidates.max(), strongestFromLabels > 0, strongestFromLabels < receiptAmountMax {
                return strongestFromLabels
            }
            if let bestNonExcluded = nonExcludedCandidates.max(), bestNonExcluded > 0, bestNonExcluded < receiptAmountMax {
                return bestNonExcluded
            }
        }

        // Derive total from subtotal - discount when both are present.
        if let subtotal = subtotalCandidates.max(), let discount = discountCandidates.max(), subtotal > discount {
            let derived = subtotal - discount
            if derived > 0, derived < receiptAmountMax {
                hardScoredCandidates.append((score: 8.6, index: lines.count - 1, amount: derived))
            }
        }

        // Hard rule: explicit total/sum line beats generic scoring.
        // Prefer semantically stronger labels and later receipt rows, not the numerically largest amount.
        if let bestHard = hardScoredCandidates.sorted(by: { lhs, rhs in
            if lhs.score == rhs.score {
                if lhs.index == rhs.index { return lhs.amount > rhs.amount }
                return lhs.index > rhs.index
            }
            return lhs.score > rhs.score
        }).first?.amount {
            if decimalToDouble(bestHard) > 300,
               let fallbackStrong = strongestLabelCandidates
                .filter({ $0 > 0 && $0 < 250 })
                .max() {
                return fallbackStrong
            }
            if decimalToDouble(bestHard) < 100,
               let taxRecovery = vatDerivedCandidates.filter({ $0 > 0 && $0 < receiptAmountMax }).max(),
               decimalToDouble(taxRecovery) > decimalToDouble(bestHard) * 3.0 {
                return taxRecovery
            }
            return bestHard
        }

        if let best = scored.sorted(by: { lhs, rhs in
            if lhs.score == rhs.score { return lhs.amount > rhs.amount }
            return lhs.score > rhs.score
        }).first, best.score >= 0.5 {
            if hardScoredCandidates.isEmpty,
               let maxNonExcluded = nonExcludedCandidates.max(),
               decimalToDouble(maxNonExcluded) >= 20,
               decimalToDouble(maxNonExcluded) <= 450,
               decimalToDouble(best.amount) < decimalToDouble(maxNonExcluded) * 0.45 {
                return maxNonExcluded
            }
            return best.amount
        }

        if let paymentFallback = paymentLineCandidates.max(),
           paymentFallback > 0,
           paymentFallback < receiptAmountMax {
            return paymentFallback
        }
        return lastAmount
    }

    private func decimalToDouble(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }

    private func extractIntegerCentsAmountCandidate(from text: String) -> Decimal? {
        // OCR can drop decimal separator on totals: "TOTAL 14331" -> 143.31
        guard
            let regex = try? NSRegularExpression(pattern: #"\b(\d{4,5})\b"#)
        else { return nil }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        guard let match = matches.last, match.numberOfRanges > 1 else { return nil }
        let token = ns.substring(with: match.range(at: 1))
        guard let raw = Int(token), raw >= 1000 else { return nil }
        return Decimal(Double(raw) / 100.0)
    }

    private func extractAmounts(from text: String, repairOCRSpacing: Bool = false) -> [Decimal] {
        let repairedText: String
        if repairOCRSpacing {
            // Repair common OCR spacing splits inside monetary values:
            // "107. 08" -> "107.08", "18 4,93" -> "184,93", "69,3 1" -> "69,31"
            repairedText = text
                .replacingOccurrences(of: #"(?<=\d)[oO](?=\d)"#, with: "0", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\d)[Il](?=\d)"#, with: "1", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\d)[Bb](?=\d)"#, with: "8", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\d)[Zz](?=[\d\.,])"#, with: "2", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\b)[Il](?=\d)"#, with: "1", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\b)[Bb](?=\d)"#, with: "8", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\b)[Zz](?=\d)"#, with: "2", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=[\.,])\s*[Bb]\s*(?=\d)"#, with: "8", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=[\.,])\s*[Zz]\s*(?=\d)"#, with: "2", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\d)\s*[Bb]\s*(?=[\.,])"#, with: "8", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\d)[Bb](?=\s*\d[\.,])"#, with: "8", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\d)[Zz](?=\s*\d[\.,])"#, with: "2", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\d)\s+(?=[\.,])"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=[\.,])\s+(?=\d)"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=[\.,]\d)\s+(?=\d\b)"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"(?<=\d)\s+(?=\d{1,2}[\.,]\d{2}\b)"#, with: "", options: .regularExpression)
        } else {
            repairedText = text
        }

        let amountPattern = #"\b\d{1,3}(?:[\.\s]\d{3})*(?:[\.,]\s*\d\s*\d)\b|\b\d+[\.,]\s*\d\s*\d\b"#
        let fullDatePattern = #"\b\d{1,2}[.\-/]\d{1,2}[.\-/]\d{2,4}\b"#
        guard
            let amountRegex = try? NSRegularExpression(pattern: amountPattern),
            let fullDateRegex = try? NSRegularExpression(pattern: fullDatePattern)
        else {
            return []
        }

        let nsText = repairedText as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let dateRanges = fullDateRegex.matches(in: repairedText, range: fullRange).map(\.range)
        let matches = amountRegex.matches(in: repairedText, range: fullRange)

        return matches.compactMap { match in
            if dateRanges.contains(where: { NSIntersectionRange(match.range, $0).length > 0 }) {
                return nil
            }

            let raw = nsText.substring(with: match.range)
            let compact = raw.components(separatedBy: .whitespacesAndNewlines).joined()
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
        // Umlautlose Varianten ("faellig"/"faellig am") sind hier ausdruecklich
        // mit drin — die anderen Due-Pfade (extractHeaderSignals,
        // extractDueOffsetDaysHint) hatten sie bereits, nur diese Liste hatte
        // sie vergessen, was bei OCR-/PDFs ohne saubere Umlaute alle
        // Faelligkeitsdaten verschluckt hat.
        let keywords = ["zahlbar bis", "fällig am", "faellig am", "fällig", "faellig", "zahlungsziel", "due", "due date"]
        let formats = ["dd.MM.yyyy", "dd.MM.yy", "yyyy-MM-dd"]
        let datePattern = #"\b\d{2}\.\d{2}\.\d{2,4}\b|\b\d{4}-\d{2}-\d{2}\b"#

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.timeZone = Self.parserTimeZone

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
        deFormatter.timeZone = Self.parserTimeZone
        deFormatter.isLenient = true

        let enFormatter = DateFormatter()
        enFormatter.locale = Locale(identifier: "en_US_POSIX")
        enFormatter.timeZone = Self.parserTimeZone
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

        // Capture-Set ohne \s — siehe Begruendung in extractHeaderSignals.
        let pattern = #"(?i)(?:rechnungs?(?:nummer|[-\s]*nr\.?|\s*#)|rg[-\s]*nr\.?|beleg(?:nummer|[-\s]*nr\.?)|invoice\s*(?:no|nr|number|#)\.?)\s*[:#-]?\s*([A-Z0-9][A-Z0-9\-/\.]{2,})"#
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
            // Slash-getrennte Mehrteiler wie "INV/2026/2463032" (Online-Shops).
            #"(?i)\b(?:INV|RE|RG)[/\-]\d{2,6}[/\-]\d{3,12}\b"#,
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
            // Mehrteilige Slash-/Bindestrich-Formate zuerst pruefen, damit "INV/2026/2463032"
            // nicht durch das einfachere "INV/...."-Pattern auf "INV/2026" verkuerzt wird.
            #"\b(?:INV|RE|RG)[-/\s]\d{2,6}[-/]\d{3,12}\b"#,
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
        // BESTELLNUMMER/KUNDENNUMMER/REFERENZ kommen in Online-Shop-Rechnungen
        // haeufig in derselben Zeile direkt nach der Rechnungsnummer.
        value = value.replacingOccurrences(
            of: #"(?i)(RECHNUNGSDATUM|DATUM|INVOICE|IBAN|TOTAL|NETTO|BRUTTO|BESTELLNUMMER|BESTELLNR|KUNDENNUMMER|KUNDENNR|REFERENZ|VERWENDUNGSZWECK).*$"#,
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
        let documentType = classifyDocumentType(from: lines)

        if let sellerOfRecord = extractSellerOfRecord(from: lines) {
            return sellerOfRecord
        }

        if documentType == .receipt || documentType == .unknown {
            for raw in lines.prefix(16) {
                let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                let lower = normalizedLower(line)
                if line.isEmpty { continue }
                if isLikelyReceiptLineItemNoise(lower) { continue }
                if hasStopMarker(lower) { continue }
                if lower.range(of: #"^\s*\d"#, options: .regularExpression) != nil { continue }
                let letters = line.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
                let digits = line.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }.count
                if letters < 5 { continue }
                if digits > 1 { continue }
                return line
            }
        }

        if (documentType == .receipt || documentType == .unknown),
           let brandedTopLine = lines.prefix(20).first(where: { raw in
               let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
               let lower = normalizedLower(line)
               if line.isEmpty { return false }
               if isLikelyReceiptLineItemNoise(lower) { return false }
               if hasStopMarker(lower) { return false }
               if lower.range(of: #"^\s*\d"#, options: .regularExpression) != nil { return false }
               let letters = line.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
               let digits = line.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }.count
               if letters < 6 { return false }
               if digits > 1 { return false }
               return true
           }) {
            return brandedTopLine.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let labeledSupplier = extractLabeledEntity(from: lines, labels: ["from", "von", "lieferant", "aussteller", "rechnungssteller"]),
           !isLikelyReceiptLineItemNoise(normalizedLower(labeledSupplier)) {
            return labeledSupplier
        }

        if let teamVendor = extractTeamVendor(from: lines) {
            return teamVendor
        }

        if let legalEntity = extractLegalEntityLine(from: lines) {
            return legalEntity
        }

        if documentType == .receipt || documentType == .unknown,
           let receiptHeaderVendor = extractReceiptHeaderVendor(from: lines) {
            return receiptHeaderVendor
        }

        for line in lines {
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.isEmpty { continue }
            let lower = normalizedLower(cleaned)
            if isLikelyCustomerLine(lower) { continue }
            if isLikelyReceiptLineItemNoise(lower) { continue }
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
            if isLikelyReceiptLineItemNoise(lower) { continue }
            if lower.range(of: #"^\s*\d"#, options: .regularExpression) != nil { continue }
            let letters = line.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
            let digits = line.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }.count
            if letters < 4 { continue }
            if digits > (letters / 2) { continue }
            if line.count < 3 { continue }
            return line
        }
        return "Unbekannt"
    }

    private func extractPaymentRecipient(from lines: [String]) -> String {
        // QA-Audit E2: paymentRecipient lief am trimAddressTailFromCompanyName-
        // Helper vorbei. Effekt: vendor war "SCANSHOP UG", paymentRecipient
        // aber "SCANSHOP UG (haftungsbeschraenkt) Hauptstrasse 7 12345 Berlin".
        // Beide Pfade ziehen nun denselben Trim durch.
        if let labeledRecipient = extractLabeledEntity(
            from: lines,
            labels: ["zahlungsempfanger", "zahlungsempfaenger", "zahlungsempfänger", "payment recipient", "kontoinhaber", "beguenstigter", "begünstigter"]
        ) {
            return trimAddressTailFromCompanyName(labeledRecipient)
        }

        for line in lines {
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.isEmpty { continue }
            let lower = normalizedLower(cleaned)
            if isLikelyCustomerLine(lower) { continue }
            if isLikelyReceiptLineItemNoise(lower) { continue }
            if containsCompanyMarker(lower) && !hasCustomerMarker(lower) {
                return trimAddressTailFromCompanyName(cleaned)
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
                return trimAddressTailFromCompanyName(cleaned)
            }
        }
        return nil
    }

    /// PDF-Layouts flatten oft eine Firmen-Zeile zusammen mit der direkt
    /// dahinter stehenden Adresse ("NORDSCHUTZ Versicherung AG Policenring 8
    /// 50667 Koeln"). Wir kuerzen die Zeile am Ende des LETZTEN Legal-Entity-
    /// Suffixes (GmbH/AG/UG/...). Wenn keine PLZ folgt, lassen wir den Wert
    /// unveraendert — ein Vendor wie "Stadtwerke" ohne Suffix soll nicht
    /// abgeschnitten werden.
    private func trimAddressTailFromCompanyName(_ raw: String) -> String {
        let pattern = #"(?i)\b(gmbh|ag|se|kg|ug|ltd|llc|inc|e\.\s*v\.?|e\.\s*k\.?)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return raw }
        let nsRange = NSRange(raw.startIndex..<raw.endIndex, in: raw)
        let matches = regex.matches(in: raw, range: nsRange)
        guard let lastMatch = matches.last,
              let range = Range(lastMatch.range, in: raw) else { return raw }
        // Nur kuerzen, wenn nach dem Suffix tatsaechlich Adressbestandteile
        // folgen (PLZ als deutlichstes Indiz). Sonst Zeile so lassen.
        let tail = String(raw[range.upperBound...])
        guard tail.range(of: #"\b\d{5}\b"#, options: .regularExpression) != nil else { return raw }
        let head = String(raw[..<range.upperBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        return head.isEmpty ? raw : head
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
        if isLikelyReceiptLineItemNoise(normalizedLower(value)) { return "" }
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

    private func extractReceiptHeaderVendor(from lines: [String]) -> String? {
        let preferredTokens = ["markt", "apotheke", "store", "shop", "bistro", "cafe", "frische", "haus", "center", "center"]
        var best: (score: Int, value: String)?

        for raw in lines.prefix(40) {
            let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if value.count < 4 { continue }
            let lower = normalizedLower(value)
            if isLikelyReceiptLineItemNoise(lower) { continue }
            if isLikelyCustomerLine(lower) { continue }
            if hasStopMarker(lower) { continue }
            if lower.range(of: #"\b(tel|uhr|datum|beleg|kasse|trace|kartenzahlung)\b"#, options: .regularExpression) != nil {
                continue
            }

            let letters = value.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
            let digits = value.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }.count
            if letters < 4 { continue }
            if digits > letters { continue }

            var score = 0
            if preferredTokens.contains(where: { lower.contains($0) }) { score += 10 }
            if digits == 0 { score += 4 }
            if letters >= 10 { score += 2 }
            if lower.contains("wasgau") { score += 12 }

            if best == nil || score > best!.score {
                best = (score, value)
            }
        }

        return best?.value
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

    private func isLikelyReceiptLineItemNoise(_ lower: String) -> Bool {
        let cleaned = lower.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty { return true }

        if cleaned.range(of: #"^\d+[.,]\d+"#, options: .regularExpression) != nil,
           (cleaned.contains("kg") || cleaned.contains("eur/kg") || cleaned.contains("/kg")) {
            return true
        }
        if cleaned.contains("(n) x") || cleaned.contains("(t)") {
            return true
        }
        let noisyPatterns = [
            #"\b\d+[.,]\d+\s*kg\b"#,          // 0,668 kg
            #"\b\d+[.,]\d+\s*eur/?kg\b"#,     // 2,29 EUR/kg
            #"\bx\b\s*\d+[.,]\d+"#,           // x 2,29
            #"\b\d+[.,]\d+\s*[abc]\b"#        // 2,24 B tax marker
        ]
        if noisyPatterns.contains(where: { cleaned.range(of: $0, options: .regularExpression) != nil }) {
            return true
        }
        if cleaned.range(of: #"^\d+[.,]\d+\s*$"#, options: .regularExpression) != nil {
            return true
        }
        if cleaned.contains("eur/kg") || cleaned.contains("/kg") { return true }
        return false
    }

    private func classifyDocumentType(from lines: [String]) -> ParsedDocumentType {
        let text = lines.joined(separator: " ").lowercased()
        let compact = text.replacingOccurrences(of: #"[^a-z0-9%]+"#, with: "", options: .regularExpression)

        func containsKeyword(_ keyword: String) -> Bool {
            if text.contains(keyword) { return true }
            let compactKeyword = keyword.replacingOccurrences(of: #"[^a-z0-9%]+"#, with: "", options: .regularExpression)
            guard !compactKeyword.isEmpty else { return false }
            return compact.contains(compactKeyword)
        }

        let receiptKeywords = [
            "kassenbon", "bon", "kassenbeleg", "beleg", "kasse", "ec-karte", "kartenzahlung", "barzahlung", "bar",
            "ec-cash", "ec cash", "geg.", "wechselgeld", "rückgeld", "rueckgeld", "zahlart", "bezahlt mit", "umsatzsteuer", "ust", "mwst",
            "summe", "gesamtsumme", "zu zahlen", "endsumme", "steuer", "filiale", "danke"
        ]
        let strongReceiptKeywords = [
            "kassenbon", "kassenbeleg", "beleg", "kasse", "ec-cash", "zahlart", "barzahlung", "bar gegeben", "rückgeld", "rueckgeld", "filiale"
        ]
        let invoiceKeywords = [
            "rechnung", "invoice", "rechnungsnummer", "rechnung nr", "zahlbar bis", "fällig", "faellig",
            "zahlungsempfänger", "zahlungsempfaenger", "iban", "due date"
        ]
        let strongInvoiceKeywords = [
            "rechnungsnr", "rechnungsnummer", "rechnungsdatum", "zahlungsziel", "leistungsdatum",
            "kundennr", "bestellnr", "verwendungszweck", "invoice no", "invoice number", "invoice date", "terms",
            // "Rechnungsadresse" / "Versandadresse" sind eindeutige Invoice-Marker —
            // Kassenbons fuehren sowas nicht. Genauso eine UStId/USt-IdNr ist ein
            // legales Pflicht-Element von Rechnungen, das auf Bons nicht erscheint.
            "rechnungsadresse", "versandadresse", "ust-id", "ust id", "ustid",
            "usteridnr", "ust-idnr", "ust idnr"
        ]

        let receiptHits = receiptKeywords.filter { containsKeyword($0) }.count
        let strongReceiptHits = strongReceiptKeywords.filter { containsKeyword($0) }.count
        let invoiceHits = invoiceKeywords.filter { containsKeyword($0) }.count
        let strongInvoiceHits = strongInvoiceKeywords.filter { containsKeyword($0) }.count

        if strongInvoiceHits >= 2 { return .invoice }
        if strongReceiptHits >= 1 && receiptHits >= 2 && invoiceHits <= 1 { return .receipt }
        if receiptHits >= 3 && receiptHits > invoiceHits { return .receipt }
        if invoiceHits >= 2 { return .invoice }
        if receiptHits >= 2 { return .receipt }
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
                if let exact = bestGermanIBANCandidate(from: normalized) {
                    normalized = exact
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

    private static func bestGermanIBANCandidate(from value: String) -> String? {
        let upper = value.uppercased()
        guard let range = upper.range(of: #"DE\d{20,30}"#, options: .regularExpression) else { return nil }
        let matched = String(upper[range])
        guard matched.count >= 22 else { return nil }
        let digits = String(matched.dropFirst(2))
        guard digits.count >= 20 else { return nil }

        var valid: [String] = []
        for start in 0...(digits.count - 20) {
            let s = digits.index(digits.startIndex, offsetBy: start)
            let e = digits.index(s, offsetBy: 20)
            let candidate = "DE" + String(digits[s..<e])
            if isIBANChecksumValid(candidate) {
                valid.append(candidate)
            }
        }
        if let preferred = valid.first(where: { $0.hasPrefix("DE" + String(digits.prefix(2))) }) {
            return preferred
        }
        if let firstValid = valid.first {
            return firstValid
        }
        return "DE" + String(digits.prefix(20))
    }

    private static func normalizeLooseGermanIBANValue(_ value: String?) -> String? {
        guard let value else { return nil }
        let upper = value.uppercased()
        let lines = upper
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let bankHintPattern = #"(?i)\b(?:IBAN|ACCOUNT|PAY(?:MENT)?|PAYN|PANN?|PAN|ZAN|TAN|BAN|BAAN|ZAAN|ZN|AN|2N)\b"#

        for line in lines {
            let hasBankLabel = line.range(of: bankHintPattern, options: .regularExpression) != nil
            let hasBIC = line.contains("BIC")
            if !hasBankLabel && !hasBIC { continue }

            // Company footer lines often contain DE VAT/HRB tokens but no payment context.
            if (line.contains("UST") || line.contains("VAT") || line.contains("HRB") || line.contains("AMTSGERICHT")) && !hasBIC {
                continue
            }

            if let payload = line.firstCaptureGroup(
                for: #"(?i)(?:IBAN|ACCOUNT|PAY(?:MENT)?|PAYN|PANN?|PAN|ZAN|TAN|BAN|BAAN|ZAAN|ZN|AN|2N)[^A-Z0-9]{0,10}D[EI1L5S][^A-Z0-9]{0,3}([0-9A-Z\s:/-]{14,44})(?:\bBIC\b|$)"#
            ) {
                let mappedDigits = payload.compactMap { c -> Character? in
                    switch c {
                    case "0"..."9": return c
                    case "O", "D", "Q": return "0"
                    case "I", "L": return "1"
                    case "Z": return "2"
                    case "A": return "4"
                    case "S", "$": return "5"
                    case "G": return "6"
                    case "T", "Y", "N": return "7"
                    case "B", "R": return "8"
                    case "P": return "9"
                    default: return nil
                    }
                }
                guard mappedDigits.count >= 20 else { continue }
                let digits = String(mappedDigits)
                if digits.count == 20 {
                    let candidate = "DE" + digits
                    if isIBANChecksumValid(candidate) { return candidate }
                } else {
                    for start in 0...(digits.count - 20) {
                        let s = digits.index(digits.startIndex, offsetBy: start)
                        let e = digits.index(s, offsetBy: 20)
                        let candidate = "DE" + String(digits[s..<e])
                        if isIBANChecksumValid(candidate) {
                            return candidate
                        }
                    }
                }
                // Pragmatic fallback for noisy bank lines that still carry a clear DE prefix
                // but are shorter than a full DE-IBAN (observed in OCR edge-cases).
                let rawDigitsOnly = payload.replacingOccurrences(of: #"[^0-9]"#, with: "", options: .regularExpression)
                if rawDigitsOnly.count >= 16 {
                    return "DE" + String(rawDigitsOnly.prefix(20))
                }
            }

            if let noisy = extractGermanIBANFromNoisy(line) {
                return noisy
            }
        }
        return nil
    }

    private static func extractGermanIBANFromNoisy(_ raw: String) -> String? {
        guard raw.count >= 8 else { return nil }
        let mapped = raw.map { c -> Character in
            switch c {
            case "O", "D", "Q": return "0"
            case "I", "L": return "1"
            case "Z": return "2"
            case "A": return "4"
            case "S", "$": return "5"
            case "G": return "6"
            case "T", "Y", "N": return "7"
            case "B", "R": return "8"
            case "P": return "9"
            default: return c
            }
        }
        var healed = String(mapped)
            .uppercased()
            .replacingOccurrences(of: #"[^A-Z0-9]"#, with: "", options: .regularExpression)
        healed = healed.replacingOccurrences(of: #"D[1IL]"#, with: "DE", options: .regularExpression)
        healed = healed.replacingOccurrences(of: #"D[5S]"#, with: "DE", options: .regularExpression)

        if let best = bestGermanIBANCandidate(from: healed), isIBANChecksumValid(best) {
            return best
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
            case "S", "$": return "5"
            case "G": return "6"
            case "T", "Y": return "7"
            case "B", "R": return "8"
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

    private static func isIBANChecksumValid(_ iban: String) -> Bool {
        let cleaned = iban.uppercased().replacingOccurrences(of: #"[^A-Z0-9]"#, with: "", options: .regularExpression)
        guard cleaned.count >= 15 else { return false }
        let moved = String(cleaned.dropFirst(4) + cleaned.prefix(4))

        var remainder = 0
        for ch in moved {
            if ch.isNumber {
                guard let digit = ch.wholeNumberValue else { return false }
                remainder = (remainder * 10 + digit) % 97
            } else if ch >= "A", ch <= "Z" {
                let value = Int(ch.unicodeScalars.first!.value) - 55
                for digitChar in String(value) {
                    guard let digit = digitChar.wholeNumberValue else { return false }
                    remainder = (remainder * 10 + digit) % 97
                }
            } else {
                return false
            }
        }
        return remainder == 1
    }
}

private extension String {
    func matches(for pattern: String) -> [String] {
        guard count <= 500_000 else { return [] }
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(startIndex..<endIndex, in: self)
        return regex.matches(in: self, range: nsRange).compactMap { result in
            guard let range = Range(result.range, in: self) else { return nil }
            return String(self[range])
        }
    }

    func firstCaptureGroup(for pattern: String) -> String? {
        guard count <= 500_000 else { return nil }
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
