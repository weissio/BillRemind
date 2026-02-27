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

    func testExtractsSupplierAndRecipientFromLabels() {
        let lines = ParserFixtures.invoiceWithFromAndRecipient
            .split(separator: "\n")
            .map(String.init)

        XCTAssertEqual(service.extractVendorName(from: lines), "Weber IT Services Bahnhofstraße 8 76133 Karlsruhe")
        XCTAssertEqual(service.parse(text: ParserFixtures.invoiceWithFromAndRecipient).paymentRecipient, "Weber IT Services Bahnhofstraße 8 76133 Karlsruhe")
    }

    func testPrefersGrossAmountOverNetAmount() {
        let lines = ParserFixtures.invoiceWithFromAndRecipient
            .split(separator: "\n")
            .map(String.init)
        let amount = service.extractAmount(from: lines, documentType: .invoice)
        XCTAssertEqual(amount, Decimal(string: "3177.30"))
    }

    func testExtractsInvoiceNumberFromRechnungNrHyphenFormat() {
        let lines = ParserFixtures.invoiceWithRechnungNrHyphen
            .split(separator: "\n")
            .map(String.init)
        XCTAssertEqual(service.extractInvoiceNumber(from: lines), "INV-00006")
    }

    func testRejectsInvalidGermanIBANWithTextNoise() {
        let iban = service.extractIBAN(from: "IBAN: DE123456789IBAN")
        XCTAssertNil(iban)
    }

    func testRejectsInvoiceTokenAsIBAN() {
        let iban = service.extractIBAN(from: "IBAN: RG000086INVOICEDATE")
        XCTAssertNil(iban)
    }

    func testNormalizeInvoiceNumberStripsInvoiceDateNoise() {
        let number = ParsingService.normalizeInvoiceNumberValue("RG000086 Invoice Date: 13.01.2026")
        XCTAssertEqual(number, "RG000086")
    }

    func testExtractsSellerNameFromSellerOfRecordPhrase() {
        let lines = ParserFixtures.invoiceWithSellerOfRecordPhrase
            .split(separator: "\n")
            .map(String.init)
        XCTAssertEqual(service.extractVendorName(from: lines), "adidas AG")
    }

    func testExtractsNoisyGermanIBANFromPaymentLine() {
        let iban = service.extractIBAN(from: ParserFixtures.invoiceWithOCRNoisyIBANAndTerms)
        XCTAssertEqual(iban, "DE57776898534130012311")
    }

    func testExtractsDueOffsetFromSeparatedTermsLayout() {
        let lines = ParserFixtures.invoiceWithOCRNoisyIBANAndTerms
            .split(separator: "\n")
            .map(String.init)
        XCTAssertEqual(service.extractDueOffsetDaysHint(from: lines), 14)
    }
}
