import XCTest
@testable import BillRemind

final class ParsingServiceTests: XCTestCase {
    private let service = ParsingService()

    func testExtractsIBANAndNormalizes() {
        let iban = service.extractIBAN(from: ParserFixtures.germanInvoice)
        XCTAssertEqual(iban, "DE89370400440532013000")
    }

    func testExtractsAmountPreferingKeywords() {
        let lines = ParserFixtures.germanInvoice
            .split(separator: "\n")
            .map(String.init)
        let amount = service.extractAmount(from: lines, documentType: .invoice)
        XCTAssertEqual(amount, Decimal(string: "1234.56"))
    }

    func testIBANNormalizationRemovesTrailingBICNoise() {
        let iban = service.extractIBAN(from: "IBAN: DE12 5001 0517 5407 3249 31 BIC: INGDDEFFXXX")
        XCTAssertEqual(iban, "DE12500105175407324931")
    }

    func testExtractsDueDateFromDifferentFormats() {
        let germanLines = ParserFixtures.germanInvoice
            .split(separator: "\n")
            .map(String.init)
        let englishLines = ParserFixtures.englishInvoice
            .split(separator: "\n")
            .map(String.init)
        let shortLines = ParserFixtures.shortDateInvoice
            .split(separator: "\n")
            .map(String.init)

        XCTAssertNotNil(service.extractDueDate(from: germanLines))
        XCTAssertNotNil(service.extractDueDate(from: englishLines))
        XCTAssertNotNil(service.extractDueDate(from: shortLines))
    }

    func testExtractsInvoiceNumber() {
        let lines = ParserFixtures.englishInvoice
            .split(separator: "\n")
            .map(String.init)
        XCTAssertEqual(service.extractInvoiceNumber(from: lines), "INV-7788")
    }

    func testDoesNotReadInvoiceDateAsAmount() {
        let lines = ParserFixtures.invoiceWithDateAmountNoise
            .split(separator: "\n")
            .map(String.init)
        let amount = service.extractAmount(from: lines, documentType: .invoice)
        XCTAssertEqual(amount, Decimal(string: "87.40"))
    }
}
