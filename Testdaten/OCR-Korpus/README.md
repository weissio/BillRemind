# OCR-Korpus (Starter)

Ziel:
- Messbare OCR-Qualitaet fuer Rechnungen und Kassenbons.
- Vergleich von Parser-Ergebnis gegen erwartete Sollwerte.

Ordner:
- `rechnung/` -> Quelldokumente fuer Rechnungstests
- `kassenbon/` -> Quelldokumente fuer Kassenbon-Tests
- `expected/rechnung/` -> Sollwerte je Rechnungsdokument
- `expected/kassenbon/` -> Sollwerte je Kassenbon-Dokument
- `manifest.json` -> zentrale Liste aller Faelle

## Expected-Format

Pflichtfelder:
- `document_type`: `invoice` | `receipt`
- `source_file`: Dateiname im jeweiligen Quellordner
- `expected.vendor_name`
- `expected.amount_value` (Double)
- `expected.status_suggestion` (`open` | `paid`)

Optionale Felder:
- `expected.payment_recipient`
- `expected.category`
- `expected.due_date` (`YYYY-MM-DD` oder `null`)
- `expected.invoice_number`
- `expected.iban`

## Test-Regel

Bei unsicheren Feldern gilt:
- lieber leer (`null`) als falsch.
- false positives sind kritischer als missing values.

## Checker ausfuehren

Aus dem Projektordner `BillRemind`:

```bash
/usr/bin/make ocr-check
```

Alternativ direkt:

```bash
/usr/bin/swiftc tools/ocr_corpus_check.swift Services/ParsingService.swift -framework PDFKit -o /tmp/ocr_corpus_check
/tmp/ocr_corpus_check
```

Ausgabe:
- `Testdaten/OCR-Korpus/report/latest.json`
- `Testdaten/OCR-Korpus/report/latest.md`

## Projektregel

- `make ocr-check` ist ein Pflichtlauf vor Merge/Release bei OCR- oder Parsing-Aenderungen.
