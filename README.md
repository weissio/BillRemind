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

## Tests ausführen
1. In Xcode: `Product > Test`
2. Oder per CLI:
   - `xcodebuild test -project BillRemind.xcodeproj -scheme BillRemind -destination 'platform=iOS Simulator,name=iPhone 15'`

## Limitations / Next Steps
- OCR-Heuristiken sind bewusst einfach gehalten (MVP) und nicht für alle Rechnungslayouts robust.
- Kein PDF-Import, nur Kamera-Scan.
- Keine Cloud-Synchronisation über Geräte.
- Keine Exportfunktionen (z. B. CSV/PDF) für Freelancer/Buchhaltung.

Empfohlene nächste Schritte:
- PDF-Import + VisionKit `VNDocumentCameraViewController`
- iCloud Sync (CloudKit)
- Verbesserte NLP/Regex-Heuristiken mit Länderprofilen
- Export/Sharing für Steuerberater
