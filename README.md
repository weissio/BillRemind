# BillRemind (iOS MVP)

BillRemind ist eine lokale iOS-App (SwiftUI + SwiftData), mit der Privatpersonen Rechnungen scannen, OCR-Felder prüfen und Erinnerungen für Zahlungsziele setzen können.

## Setup
1. In den Projektordner wechseln:
   - `cd /Users/jonasweiss/Documents/New project/BillRemind`
2. Projekt öffnen:
   - `open BillRemind.xcodeproj`
3. Falls Xcode eine fehlende iOS-Plattform meldet, in Xcode unter `Settings > Platforms` die passende iOS-Simulator-Runtime installieren.
4. In Xcode ein iOS-17+ Simulatorgerät wählen und starten.

Hinweis: `project.yml` ist enthalten. Eine Regenerierung mit `xcodegen` ist optional.

## Features
- Home mit Filtern: `Offen | Bezahlt | Alle`
- Rechnung scannen (Kamera), OCR via Apple Vision
- Heuristische Extraktion: Anbieter, Betrag, Fälligkeitsdatum, Rechnungsnummer, IBAN
- Review-Form mit editierbaren Feldern vor dem Speichern
- Lokale Persistenz via SwiftData
- Detailansicht mit Bildvorschau, Statuswechsel, Reminder, Löschen
- Lokale Notifications (`UNUserNotificationCenter`) für Erinnerungen
- Settings mit konfigurierbarem Standard-Reminder-Offset (`0/1/2/3/7` Tage)

## Privacy
- Alle Daten bleiben lokal auf dem Gerät.
- Bilder werden in der App-Sandbox gespeichert (`Documents/InvoicesImages`).
- Kein Login, kein Backend, keine Cloud-Übertragung.

## Betrieb & Support
- Absicherung, Update-Strategie, Incident-Runbook und Übergabe:
  - `/Users/jonasweiss/Documents/New project/BillRemind/Readme_Absicherung_und_Support.md`
- Release-Datensicherheits-Checkliste:
  - `/Users/jonasweiss/Documents/New project/BillRemind/docs/data-safety-release-checklist.md`
- OCR-Hardening-Roadmap (Kassenbon + Rechnungen):
  - `/Users/jonasweiss/Documents/New project/BillRemind/docs/ocr-hardening-plan.md`

## Tests ausführen
1. In Xcode: `Product > Test`
2. Oder per CLI:
   - `xcodebuild test -project BillRemind.xcodeproj -scheme BillRemind -destination 'platform=iOS Simulator,name=iPhone 15'`
3. OCR-Korpus-Pflichtlauf (vor Merge/Release):
   - `make ocr-check`
   - Report liegt danach in `Testdaten/OCR-Korpus/report/latest.md`

CI:
- GitHub Actions Workflow `OCR Corpus Check` fuehrt `make ocr-check` bei Push/PR automatisch aus.

## Limitations / Next Steps
- OCR ist produktiv nutzbar, aber noch nicht für alle Sonderlayouts gleich robust
  (z. B. stark unstrukturierte Belege, sehr schwache Bildqualität, exotische Felder).
- Keine Cloud-Synchronisation über Geräte.
- Export ist vorhanden, kann aber funktional noch erweitert werden
  (z. B. stärkere Buchhaltungs-/Steuerberater-Workflows).

Empfohlene nächste Schritte:
- OCR weiter robustifizieren:
  - Layout-Typisierung (klassische Rechnung, Kassenbon, Abo, Versicherung, Energie)
  - Feld-Erkennung mit Prioritätsregeln je Layout-Typ
  - Confidence-Scoring pro Feld und gezielte Review-Hinweise
  - Ausbau von Regex/NLP-Regeln inkl. Testdatenkatalog pro Dokumenttyp
- iCloud Sync (CloudKit) als optionaler Sync-Modus
- Export/Sharing weiter ausbauen (z. B. Buchhaltungs-Templates, strukturierte Exporte)
