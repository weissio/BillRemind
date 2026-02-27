import Foundation

enum ParserFixtures {
    static let germanInvoice = """
    Muster GmbH
    Musterstraße 5
    Rechnungsnr: RG-2024-001
    Gesamtbetrag: 1.234,56 EUR
    Zahlbar bis 12.03.2026
    IBAN: DE89 3704 0044 0532 0130 00
    """

    static let englishInvoice = """
    ACME Ltd.
    Invoice No: INV-7788
    Total €99,95
    Due date 2026-04-01
    """

    static let shortDateInvoice = """
    Beispiel AG
    RG-Nr: 2025-XY
    Summe 249,90 €
    Fällig am 05.02.26
    """

    static let invoiceWithDateAmountNoise = """
    ACME Services GmbH
    Rechnungsdatum: 19.02.2026
    Rechnungsnummer: A-2026-19
    Zu zahlen: 87,40 EUR
    """

    static let invoiceWithFromAndRecipient = """
    RECHNUNG
    From
    Weber IT Services Bahnhofstraße 8 76133 Karlsruhe
    Empfänger
    Autohaus Becker GmbH Buchhaltung Motorstraße 9 93047 Regensburg
    Netto: 2.670,00 € VAT 19%: 507,30 €
    Total (gross): 3.177,30 €
    Rechnungsnummer: 0002-26 Invoice Date: 10.01.2026
    Bankverbindung (IBAN): DE07223206171999470018
    """

    static let invoiceWithRechnungNrHyphen = """
    RECHNUNG
    Rechnung-Nr.: INV-00006 Datum: 29.01.2026
    """

    static let invoiceWithSellerOfRecordPhrase = """
    Rechnung
    Der Verkauf erfolgte im Namen und auf Rechnung der adidas AG.
    Hilfe und Kontakt
    """

    static let invoiceWithOCRNoisyIBANAndTerms = """
    INVOICE
    Invoice No.
    R6001439
    Invoice Date
    04.11.2025
    Terms
    14 days
    Pay. D1 57 7768 9853 4130 0123 11 - BIC: GENODEFF
    """

    static let invoiceWithDueFromInvoiceReceipt = """
    INVOICE
    Invoice No: INV-00999
    Invoice Date: 10.02.2026
    Due 30 days from invoice receipt
    """

    static let invoiceWithServiceDateAndInvoiceDate = """
    Rechnung
    Leistungsdatum: 03.01.2026
    Rechnungsdatum: 15.01.2026
    """

    static let invoiceWithSeparatedHeaderValues = """
    RECHNUNG
    Rechnungsnummer
    RG000205
    Rechnungsdatum
    11.02.2026
    Zahlungsziel
    7 Tage netto
    """
}
