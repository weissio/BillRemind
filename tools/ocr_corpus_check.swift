import Foundation
import PDFKit

struct CorpusManifest: Decodable {
    struct CaseItem: Decodable {
        let id: String
        let document_type: String
        let source_file: String
        let expected_file: String
    }

    let version: Int
    let created_at: String
    let cases: [CaseItem]
}

struct ExpectedEnvelope: Decodable {
    struct Expected: Decodable {
        let vendor_name: String?
        let payment_recipient: String?
        let amount_value: Double?
        let category: String?
        let due_date: String?
        let status_suggestion: String?
        let invoice_number: String?
        let iban: String?
    }

    let document_type: String
    let source_file: String
    let expected: Expected
}

struct CheckResult: Encodable {
    struct FieldResult: Encodable {
        let field: String
        let expected: String?
        let actual: String?
        let ok: Bool
        let note: String?
    }

    let id: String
    let sourceFile: String
    let documentTypeExpected: String
    let documentTypeActual: String
    let passed: Bool
    let checks: [FieldResult]
}

struct Report: Encodable {
    let generatedAt: String
    let totalCases: Int
    let passedCases: Int
    let failedCases: Int
    let passRateCases: Double
    let totalFieldChecks: Int
    let passedFieldChecks: Int
    let passRateFields: Double
    let results: [CheckResult]
}

@main
struct OCRCorpusCheck {
    static func main() {
        do {
            let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
            let corpusDir = root.appendingPathComponent("Testdaten/OCR-Korpus", isDirectory: true)
            let manifestURL = corpusDir.appendingPathComponent("manifest.json")

            guard FileManager.default.fileExists(atPath: manifestURL.path) else {
                fputs("manifest.json not found at \(manifestURL.path)\n", stderr)
                exit(2)
            }

            let manifestData = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(CorpusManifest.self, from: manifestData)

            var results: [CheckResult] = []
            var totalFieldChecks = 0
            var passedFieldChecks = 0

            let parser = ParsingService()

            for item in manifest.cases {
                let sourceURL = corpusDir.appendingPathComponent(item.source_file)
                let expectedURL = corpusDir.appendingPathComponent(item.expected_file)

                let expectedData = try Data(contentsOf: expectedURL)
                let expectedEnvelope = try JSONDecoder().decode(ExpectedEnvelope.self, from: expectedData)

                let text = try loadText(from: sourceURL)
                let parsed = parser.parse(text: text)

                let actualType = parsed.documentType.rawValue
                var checks: [CheckResult.FieldResult] = []

                checks.append(compareExact(
                    field: "document_type",
                    expected: expectedEnvelope.document_type,
                    actual: actualType
                ))

                checks.append(compareText(
                    field: "vendor_name",
                    expected: expectedEnvelope.expected.vendor_name,
                    actual: parsed.vendorName
                ))

                checks.append(compareText(
                    field: "payment_recipient",
                    expected: expectedEnvelope.expected.payment_recipient,
                    actual: parsed.paymentRecipient
                ))

                checks.append(compareAmount(
                    field: "amount_value",
                    expected: expectedEnvelope.expected.amount_value,
                    actual: parsed.amount.map { NSDecimalNumber(decimal: $0).doubleValue }
                ))

                checks.append(compareText(
                    field: "category",
                    expected: expectedEnvelope.expected.category,
                    actual: parsed.category
                ))

                checks.append(compareDate(
                    field: "due_date",
                    expected: expectedEnvelope.expected.due_date,
                    actual: parsed.dueDate
                ))

                let statusSuggestion = (parsed.documentType == .receipt) ? "paid" : "open"
                checks.append(compareExact(
                    field: "status_suggestion",
                    expected: expectedEnvelope.expected.status_suggestion,
                    actual: statusSuggestion
                ))

                checks.append(compareText(
                    field: "invoice_number",
                    expected: expectedEnvelope.expected.invoice_number,
                    actual: parsed.invoiceNumber
                ))

                checks.append(compareIBAN(
                    field: "iban",
                    expected: expectedEnvelope.expected.iban,
                    actual: parsed.iban
                ))

                let passed = checks.allSatisfy { $0.ok }
                totalFieldChecks += checks.count
                passedFieldChecks += checks.filter(\.ok).count

                results.append(CheckResult(
                    id: item.id,
                    sourceFile: item.source_file,
                    documentTypeExpected: expectedEnvelope.document_type,
                    documentTypeActual: actualType,
                    passed: passed,
                    checks: checks
                ))
            }

            let passedCases = results.filter(\.passed).count
            let totalCases = results.count
            let failedCases = totalCases - passedCases
            let passRateCases = totalCases == 0 ? 0 : Double(passedCases) / Double(totalCases)
            let passRateFields = totalFieldChecks == 0 ? 0 : Double(passedFieldChecks) / Double(totalFieldChecks)

            let report = Report(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                totalCases: totalCases,
                passedCases: passedCases,
                failedCases: failedCases,
                passRateCases: passRateCases,
                totalFieldChecks: totalFieldChecks,
                passedFieldChecks: passedFieldChecks,
                passRateFields: passRateFields,
                results: results
            )

            let reportDir = corpusDir.appendingPathComponent("report", isDirectory: true)
            try FileManager.default.createDirectory(at: reportDir, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonOut = try encoder.encode(report)
            try jsonOut.write(to: reportDir.appendingPathComponent("latest.json"))

            let md = markdown(report: report)
            try md.data(using: .utf8)?.write(to: reportDir.appendingPathComponent("latest.md"))

            print("OCR corpus check completed")
            print("Cases: \(passedCases)/\(totalCases) passed (\(percent(passRateCases)))")
            print("Fields: \(passedFieldChecks)/\(totalFieldChecks) passed (\(percent(passRateFields)))")
            print("Report:")
            print("- \(reportDir.appendingPathComponent("latest.json").path)")
            print("- \(reportDir.appendingPathComponent("latest.md").path)")

            if failedCases > 0 {
                exit(1)
            }
        } catch {
            fputs("OCR corpus check failed: \(error)\n", stderr)
            exit(2)
        }
    }

    private static func loadText(from sourceURL: URL) throws -> String {
        switch sourceURL.pathExtension.lowercased() {
        case "txt":
            return try String(contentsOf: sourceURL, encoding: .utf8)
        case "pdf":
            guard let doc = PDFDocument(url: sourceURL) else {
                throw NSError(domain: "OCRCorpusCheck", code: 10, userInfo: [NSLocalizedDescriptionKey: "PDF could not be opened: \(sourceURL.lastPathComponent)"])
            }
            var chunks: [String] = []
            for idx in 0..<doc.pageCount {
                if let text = doc.page(at: idx)?.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !text.isEmpty {
                    chunks.append(text)
                }
            }
            return chunks.joined(separator: "\n")
        default:
            throw NSError(domain: "OCRCorpusCheck", code: 11, userInfo: [NSLocalizedDescriptionKey: "Unsupported file type: \(sourceURL.pathExtension)"])
        }
    }

    private static func compareExact(field: String, expected: String?, actual: String?) -> CheckResult.FieldResult {
        let e = normalizeOptional(expected)
        let a = normalizeOptional(actual)
        return CheckResult.FieldResult(field: field, expected: e, actual: a, ok: e == a, note: nil)
    }

    private static func compareText(field: String, expected: String?, actual: String?) -> CheckResult.FieldResult {
        let e = normalizeText(expected)
        let a = normalizeText(actual)
        return CheckResult.FieldResult(field: field, expected: e, actual: a, ok: e == a, note: nil)
    }

    private static func compareIBAN(field: String, expected: String?, actual: String?) -> CheckResult.FieldResult {
        let e = normalizeIBAN(expected)
        let a = normalizeIBAN(actual)
        return CheckResult.FieldResult(field: field, expected: e, actual: a, ok: e == a, note: nil)
    }

    private static func compareAmount(field: String, expected: Double?, actual: Double?) -> CheckResult.FieldResult {
        let e = expected
        let a = actual
        let ok: Bool
        if e == nil && a == nil {
            ok = true
        } else if let e, let a {
            ok = abs(e - a) <= 0.02
        } else {
            ok = false
        }
        return CheckResult.FieldResult(
            field: field,
            expected: e.map { String(format: "%.2f", $0) },
            actual: a.map { String(format: "%.2f", $0) },
            ok: ok,
            note: ok ? nil : "tolerance +/- 0.02"
        )
    }

    private static func compareDate(field: String, expected: String?, actual: Date?) -> CheckResult.FieldResult {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        let actualString = actual.map { formatter.string(from: $0) }
        let e = normalizeOptional(expected)
        let a = normalizeOptional(actualString)
        return CheckResult.FieldResult(field: field, expected: e, actual: a, ok: e == a, note: nil)
    }

    private static func normalizeOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizeText(_ value: String?) -> String? {
        guard let value else { return nil }
        let collapsed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .uppercased()
        return collapsed.isEmpty ? nil : collapsed
    }

    private static func normalizeIBAN(_ value: String?) -> String? {
        guard let value else { return nil }
        let normalized = value
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    private static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }

    private static func markdown(report: Report) -> String {
        var lines: [String] = []
        lines.append("# OCR Corpus Report")
        lines.append("")
        lines.append("- Generated: \(report.generatedAt)")
        lines.append("- Cases: \(report.passedCases)/\(report.totalCases) passed (\(percent(report.passRateCases)))")
        lines.append("- Fields: \(report.passedFieldChecks)/\(report.totalFieldChecks) passed (\(percent(report.passRateFields)))")
        lines.append("")
        lines.append("## Case Details")
        lines.append("")
        for result in report.results {
            let status = result.passed ? "PASS" : "FAIL"
            lines.append("### \(result.id) - \(status)")
            lines.append("- Source: `\(result.sourceFile)`")
            lines.append("- Document type expected/actual: `\(result.documentTypeExpected)` / `\(result.documentTypeActual)`")
            lines.append("")
            for check in result.checks {
                let icon = check.ok ? "OK" : "X"
                lines.append("- [\(icon)] \(check.field): expected=`\(check.expected ?? "null")` actual=`\(check.actual ?? "null")`")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}

