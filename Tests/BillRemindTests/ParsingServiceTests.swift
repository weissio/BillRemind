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

    func testExtractsDueOffsetFromInvoiceReceiptPhrase() {
        let lines = ParserFixtures.invoiceWithDueFromInvoiceReceipt
            .split(separator: "\n")
            .map(String.init)
        XCTAssertEqual(service.extractDueOffsetDaysHint(from: lines), 30)
    }

    func testHealsInvoiceNumberRGWhenGReadAs6() {
        let normalized = ParsingService.normalizeInvoiceNumberValue("R6000011")
        XCTAssertEqual(normalized, "RG000011")
    }

    func testKeepsKnownGermanIBANPattern() {
        let iban = service.extractIBAN(from: "IBAN: DE12 5001 0517 0648 4898 90")
        XCTAssertEqual(iban, "DE12500105170648489890")
    }

    func testPrefersInvoiceDateOverServiceDate() {
        let lines = ParserFixtures.invoiceWithServiceDateAndInvoiceDate
            .split(separator: "\n")
            .map(String.init)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        XCTAssertEqual(formatter.string(from: service.extractInvoiceDate(from: lines) ?? .distantPast), "2026-01-15")
    }

    func testExtractsIBANFromLabeledLineWithNeighborNoise() {
        let text = """
        Rechnung Nr.: RG000086
        Invoice Date: 13.01.2026
        IBAN / Account: DE75776898534130012311
        """
        let parsed = service.parse(text: text)
        XCTAssertEqual(parsed.iban, "DE75776898534130012311")
    }

    func testExtractsHeaderSignalsFromSeparatedRows() {
        let parsed = service.parse(text: ParserFixtures.invoiceWithSeparatedHeaderValues)
        XCTAssertEqual(parsed.invoiceNumber, "RG000205")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        XCTAssertEqual(formatter.string(from: parsed.invoiceDate ?? .distantPast), "2026-02-11")
        XCTAssertEqual(parsed.dueOffsetDaysHint, 7)
    }

    func testNormalizesInvoiceNumberWithoutHyphenPrefix() {
        let number = ParsingService.normalizeInvoiceNumberValue("INV00181")
        XCTAssertEqual(number, "INV-00181")
    }

    func testExtractsSlashInvoiceNumberWithSpaces() {
        let text = """
        Rechnung
        Rechnungsnr.
        2026 / 00005
        Rechnungsdatum
        22.02.2026
        Zahlungsziel
        7 Tage
        """
        let parsed = service.parse(text: text)
        XCTAssertEqual(parsed.invoiceNumber, "2026/00005")
        XCTAssertEqual(parsed.dueOffsetDaysHint, 7)
    }

    /// Bug #2 aus QA-Report Release 104: bei einer Zeile mit zwei Labels
    /// hintereinander ("Rechnungsnummer: TS-2026-55209 Bestellnummer: ORD-...")
    /// wurde die Whitespace-tolerante Capture-Group bis zum Ende verbraucht
    /// und produzierte den Frankenstein-Wert "TS-2026-55209BESTELLNUMMER...".
    func testExtractsInvoiceNumberAndStopsAtNextLabel() {
        let text = """
        Rechnungsnummer: TS-2026-55209 Bestellnummer: ORD-7785001
        Rechnungsdatum: 20.02.2026
        """
        let parsed = service.parse(text: text)
        XCTAssertEqual(parsed.invoiceNumber, "TS-2026-55209")
    }

    /// Bug #1 aus QA-Report Release 104: extractDueDate hatte umlautlos
    /// "Faellig" / "Faellig am" nicht in der Keyword-Liste, obwohl die
    /// anderen Due-Pfade es kannten.
    func testExtractsDueDateFromUmlautFreeFaellig() {
        let text = """
        Rechnungsnummer: TS-2026-55209
        Rechnungsdatum: 20.02.2026
        Faellig am: 05.03.2026 Status: Offen
        """
        let parsed = service.parse(text: text)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        formatter.dateFormat = "yyyy-MM-dd"
        XCTAssertEqual(formatter.string(from: parsed.dueDate ?? .distantPast), "2026-03-05")
    }

    /// QA-Report Risiko: Adresse rutschte ins vendorName-Feld mit
    /// ("NORDSCHUTZ Versicherung AG Policenring 8 50667 Koeln").
    /// Die Trimming-Logik schneidet jetzt am letzten Legal-Suffix ab,
    /// wenn danach eine PLZ folgt.
    func testTrimsAddressTailFromCompanyName() {
        let text = """
        Rechnungsnummer: VS-2026-1148
        Rechnungsdatum: 20.02.2026
        NORDSCHUTZ Versicherung AG Policenring 8 50667 Koeln
        IBAN: DE11370400440532013000
        """
        let parsed = service.parse(text: text)
        XCTAssertEqual(parsed.vendorName, "NORDSCHUTZ Versicherung AG")
    }

    func testExtractsLooseGermanIBANFromNoisyBankLine() {
        let text = "ZAN: DE:317556830430148960 - BIC: DEUTDEFYX"
        let iban = service.extractIBAN(from: text)
        XCTAssertEqual(iban, "DE317556830430148960")
    }

    func testExtractsReceiptTotalFromCashGivenMinusChange() {
        let lines = ParserFixtures.receiptWithCashGivenAndChangeColumns
            .split(separator: "\n")
            .map(String.init)
        let amount = service.extractAmount(from: lines, documentType: .receipt)
        XCTAssertEqual(amount, Decimal(string: "27.99"))
    }

    func testMapsGivenChangeTotalLabelBlockByOrder() {
        let lines = ParserFixtures.receiptWithGivenChangeTotalBlock
            .split(separator: "\n")
            .map(String.init)
        let amount = service.extractAmount(from: lines, documentType: .receipt)
        XCTAssertEqual(amount, Decimal(string: "27.99"))
    }

}
