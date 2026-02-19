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
}
