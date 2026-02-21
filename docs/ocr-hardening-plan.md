# OCR Hardening Plan (Kassenbons + Rechnungen)

Stand: 2026-02-21  
Scope: iOS App `BillRemind` / `Mnemor App`

## 1. Ziel

Die OCR-Erkennung soll fuer zwei Haupttypen deutlich robuster werden:
- Kassenbons (aktuell hohe Fehlerquote)
- Rechnungen mit unterschiedlichen Layouts (Abweichungen bei Anbieter, Betrag, Faelligkeit, Feldern)

Ergebnisziel:
- weniger manuelle Nacharbeit in der Review-Ansicht
- stabilere Felderkennung bei realen Dokumenten

## 2. Messbare Qualitätsziele (KPIs)

Mindestziele pro Dokumenttyp (auf Testkorpus):
- `Vendor/Anbieter` korrekt: >= 92%
- `Betrag` korrekt: >= 95%
- `Faelligkeit` korrekt (nur Rechnung): >= 90%
- `Status-Vorbelegung` korrekt:
  - Kassenbon: >= 99% `bezahlt`
  - Rechnung: >= 95% `offen` (wenn nichts Gegenteiliges erkennbar)
- `Feld leer statt falsch`:
  - lieber `nil` als falscher Wert; False-Positive-Rate < 5%

Review-Last-Ziel:
- Anteil Datensaetze mit manueller Korrektur <= 25% (gesamt)
- Kassenbon <= 35%, Rechnung <= 20%

## 3. Ist-Zustand (relevante Code-Stellen)

- OCR-Erfassung:
  - `/Users/jonasweiss/Documents/New project/BillRemind/Services/OCRService.swift`
- Parsing/Heuristik:
  - `/Users/jonasweiss/Documents/New project/BillRemind/Services/ParsingService.swift`
- Review-Verarbeitung:
  - `/Users/jonasweiss/Documents/New project/BillRemind/Views/ReviewInvoiceView.swift`
  - `/Users/jonasweiss/Documents/New project/BillRemind/ViewModels/ScanViewModel.swift`
- Modell:
  - `/Users/jonasweiss/Documents/New project/BillRemind/Models/Invoice.swift`

## 4. Hauptprobleme heute

1. Ein einheitlicher Parsing-Fluss fuer unterschiedliche Dokumenttypen.  
2. Kassenbons haben oft:
- keine IBAN
- keine klassische Rechnungsnummer
- keine Faelligkeit
- Positionszeilen mit vielen OCR-Stoerungen
3. Rechnungen variieren stark in Feldnamen/Position:
- "Rechnungsdatum", "Leistungsdatum", "Zahlbar bis", "Faellig am", "Due date", etc.
4. Kein expliziter "Dokumenttyp-Classifier" vor Feldextraktion.

## 5. Zielarchitektur fuer Parsing

Neue Pipeline:
1. `OCR normalize`
2. `DocumentType classify` (`invoice`, `receipt`, `unknown`)
3. Typ-spezifische Feldextraktion
4. Feld-Scoring + Confidence
5. Safety-Filter (unplausible Werte verwerfen)
6. Review-Hinweise generieren

### 5.1 Dokumenttyp-Klassifikation

Regelbasierte Initialversion:
- `receipt` Indikatoren:
  - "Kassenbon", "Bon", "MwSt", "USt", "Kasse", "Summe EUR", "Bar", "EC", "Kartenzahlung"
  - viele kurze Zeilen + Artikel-/Pos-Zeilenmuster
- `invoice` Indikatoren:
  - "Rechnung", "Invoice", "Rechnungsnummer", "Faellig", "Zahlbar bis", "IBAN"

Fallback:
- `unknown` => konservativ extrahieren + mehr Review-Hinweise.

## 6. Typ-spezifische Feldregeln

## 6.1 Kassenbon

Pflicht:
- Anbieter (Haendlername)
- Betrag gesamt
- Datum

Standardannahmen:
- Status automatisch `bezahlt`
- Faelligkeit leer (`nil`)
- Zahlungsempfaenger = Anbieter (wenn nichts besseres erkannt)
- Rechnungsnummer optional (oft nicht vorhanden)

Regeln:
- `Betrag`: priorisiere "SUMME", "ZU ZAHLEN", "GESAMT", "EC-KARTE", letzter valider Endbetrag
- `Datum`: priorisiere Bon-Datum Formate (`dd.MM.yyyy`, `dd/MM/yyyy`, `yyyy-MM-dd`)
- `IBAN`: bei Kassenbon standardmaessig ignorieren, ausser klares IBAN-Muster vorhanden

## 6.2 Rechnung

Pflicht:
- Anbieter
- Betrag

Optional:
- Faelligkeit, Rechnungsnummer, IBAN, Zahlungsempfaenger

Regeln:
- Faelligkeit nur aus due-keywords ableiten (nicht aus beliebigem Datum)
- Rechnungsnummer nur mit Label oder starkem Pattern
- Betrag priorisiert "zu zahlen", "gesamtbetrag", "summe", "total due"

## 7. Konkrete Umsetzungsphasen

## Phase 1 (Quick Wins, 2-4 Tage)

1. `DocumentType` einführen in Parsing
- Neue Enum + Klassifikation in `ParsingService`.
2. Kassenbon-Defaults erzwingen
- status = bezahlt
- dueDate = nil
3. Betragserkennung für Kassenbons verbessern
- Endbetrag-/Total-Regeln
4. Review-Hinweis klarer
- z. B. "Kassenbon erkannt, Faelligkeit nicht erwartet"

Akzeptanz:
- 20 Kassenbons durchlaufen, deutliche Reduktion offensichtlicher Fehler.

## Phase 2 (Stabilisierung, 1-2 Wochen)

1. Testkorpus strukturieren (real anonymisiert + synthetisch)
2. Parser-Regeln pro Typ modularisieren
- `ReceiptParser`
- `InvoiceParser`
3. Confidence-Scoring pro Feld verfeinern
4. Negative Regeln ergänzen (False Positives minimieren)

Akzeptanz:
- KPI-Ziele in Abschnitt 2 zu mindestens 80% erreicht.

## Phase 3 (Produktionshärtung, 2-4 Wochen)

1. Layout-Cluster fuer Rechnungen einführen:
- Energie/Versicherung/Abo/Onlinehandel/sonstige
2. Cluster-spezifische Keyword-Sets
3. Regression-Tests gegen festen Korpus
4. Telemetrie lokal fuer Debug (ohne Datenupload):
- nur anonymisierte Treffer-/Fehlermuster lokal sichtbar

Akzeptanz:
- KPI-Ziele voll erreicht, Regression unter Kontrolle.

## 8. Testkorpus und Teststrategie

Ordnerstruktur (vorgeschlagen):
- `/Users/jonasweiss/Documents/New project/BillRemind/Testdaten/OCR-Korpus/rechnung/`
- `/Users/jonasweiss/Documents/New project/BillRemind/Testdaten/OCR-Korpus/kassenbon/`
- `/Users/jonasweiss/Documents/New project/BillRemind/Testdaten/OCR-Korpus/expected/`

Bereits angelegt (Starterkorpus):
- `/Users/jonasweiss/Documents/New project/BillRemind/Testdaten/OCR-Korpus/`
- zentrale Falldefinition:
  - `/Users/jonasweiss/Documents/New project/BillRemind/Testdaten/OCR-Korpus/manifest.json`

`expected`-Datei pro Dokument:
- documentType
- vendor
- amount
- dueDate (oder `null`)
- statusSuggestion
- optional invoiceNumber/iban

Testlauf (manuell + skriptbar):
1. OCR-Text extrahieren
2. Parse-Ergebnis erzeugen
3. Gegen expected vergleichen
4. Fehlertyp markieren:
- wrong value
- missing value
- false positive

## 9. Support- und Produktregeln

Für Nutzerkommunikation:
- Kassenbons: "als bezahlt erfasst, falls nicht anders markiert"
- Rechnungen: "Faelligkeit wird nur bei klar erkennbarer Angabe gesetzt"

UI-Regel:
- Keine aggressiven Auto-Fills bei schwacher Confidence.
- Bei Unsicherheit lieber Feld leer + klarer Review-Hinweis.

## 10. Sofort umsetzbare Prioritäten (ab heute)

1. Parsing um `documentType` erweitern (hoch)
2. Kassenbon-Status/Due-Date Defaults fixieren (hoch)
3. Betragserkennung Kassenbon mit Endbetrag-Regel (hoch)
4. Mini-Testkorpus (10 Rechnung, 10 Kassenbon) aufbauen (hoch)
5. Fehlerraster dokumentieren (mittel)

## 11. Definition of Done (OCR-Hardening)

Erst "done", wenn:
- KPI-Ziele aus Abschnitt 2 erreicht sind
- kein kritischer False Positive bei Betrag/Faelligkeit mehr in Abnahmekorpus
- Release-Checkliste (`data-safety-release-checklist.md`) ohne offene OCR-Risiken durchlaufen
- Nutzerfeedback in Testphase keine systematischen OCR-Ausreisser mehr zeigt
