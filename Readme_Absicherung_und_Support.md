# Readme Absicherung und Support (BillRemind / Mnemor App)

Ziel dieses Dokuments:
- Betrieb, Wartung, Support und Updates so absichern, dass das Projekt auch ohne bisherige Hauptverantwortliche stabil weitergefuehrt werden kann.
- Datenverlust verhindern.
- Neue Entwickler schnell handlungsfaehig machen.

Dieses Dokument ergaenzt:
- `/Users/jonasweiss/Documents/New project/BillRemind/README.md`
- `/Users/jonasweiss/Documents/New project/BillRemind/docs/data-safety-release-checklist.md`
- `/Users/jonasweiss/Documents/New project/BillRemind/WORKING_CONVENTION.md`

## 1. Kurzueberblick Produkt und Architektur

BillRemind (Mnemor App) ist eine lokale iOS-App auf Basis von:
- `SwiftUI` (UI)
- `SwiftData` (Persistenz)
- `Vision` (OCR fuer Kamera/PDF)
- `UNUserNotificationCenter` (Reminder)

Wichtigster Grundsatz:
- Keine Cloud-Abhaengigkeit, kein Backend.
- Nutzerdaten bleiben lokal auf dem Geraet.

Architekturprinzip:
- `Views` zeigen Daten und UI-Interaktion.
- `ViewModels` enthalten UI-nahe Logik/Filter.
- `Services` kapseln OCR, Parsing, Notifications, Bildspeicher.
- `Models` definieren persistente Datenklassen (SwiftData).

## 2. Repostruktur und Verantwortlichkeiten

Arbeits-Repo:
- `/Users/jonasweiss/Documents/New project/BillRemind`

Wichtige Dateien/Ordner:
- App-Start:
  - `/Users/jonasweiss/Documents/New project/BillRemind/App/BillRemindApp.swift`
- Datenmodelle:
  - `/Users/jonasweiss/Documents/New project/BillRemind/Models/Invoice.swift`
  - `/Users/jonasweiss/Documents/New project/BillRemind/Models/AppSettings.swift`
  - `/Users/jonasweiss/Documents/New project/BillRemind/Models/Localization.swift`
- OCR/Parsing:
  - `/Users/jonasweiss/Documents/New project/BillRemind/Services/OCRService.swift`
  - `/Users/jonasweiss/Documents/New project/BillRemind/Services/ParsingService.swift`
- Speicher/Reminder:
  - `/Users/jonasweiss/Documents/New project/BillRemind/Services/ImageStore.swift`
  - `/Users/jonasweiss/Documents/New project/BillRemind/Services/NotificationService.swift`
- Kern-UI:
  - `/Users/jonasweiss/Documents/New project/BillRemind/Views/HomeView.swift`
  - `/Users/jonasweiss/Documents/New project/BillRemind/Views/ReviewInvoiceView.swift`
  - `/Users/jonasweiss/Documents/New project/BillRemind/Views/SettingsView.swift`
- Projektkonfiguration:
  - `/Users/jonasweiss/Documents/New project/BillRemind/BillRemind.xcodeproj/project.pbxproj`

Hinweis zum Parent-Ordner:
- Das Parent-Repo ist nur Sammelstruktur.
- App-Commits immer im BillRemind-Repo (siehe `WORKING_CONVENTION.md`).

## 3. Datenmodell und Persistenz (kritischer Bereich)

Persistente SwiftData-Modelle:
- `Invoice`
- `VendorProfile`
- `IncomeEntry`
- `InstallmentPlan`
- `InstallmentSpecialRepayment`

Initialisierung:
- In `BillRemindApp.swift` wird ein persistenter `ModelContainer` erstellt (`isStoredInMemoryOnly: false`).
- Falls Store-Initialisierung fehlschlaegt, startet die App absichtlich in einem Fehlerbildschirm (`DataStoreErrorView`) und **nicht** mit leerem In-Memory-Store.

Warum das wichtig ist:
- Verhindert "stilles" Starten mit leerem Datenstand (hohes Datenverlust-/Fehlinterpretationsrisiko).

## 4. Sicherheitsprinzipien fuer Updates (Pflicht)

Vor jedem Release beachten:
1. **Schema-Aenderungen nur additiv** (neue optionale Felder, Defaults).
2. Keine Umbenennung/Loeschung persistierter Felder ohne explizite Migrationsplanung.
3. Updatepfad `N-1 -> N` immer testen (wenn moeglich auch `N-2 -> N`).
4. Niemals Hotfix mit In-Memory-Fallback ausrollen.

Verbindliche Checkliste:
- `/Users/jonasweiss/Documents/New project/BillRemind/docs/data-safety-release-checklist.md`

## 5. Release- und Betriebsprozess (Standardablauf)

### 5.1 Entwicklung
- Kleine, klar abgegrenzte Aenderungen.
- Pro Aenderung: kurze Self-Review + Build + relevante Funktionspruefung.

### 5.2 Verifikation vor Release
- Build auf Simulator und mindestens einem realen iPhone.
- Kernfluss testen:
  - Scan Rechnung
  - Scan Kassenbon
  - PDF-Import
  - Manuell erfassen
  - Speichern/Statuswechsel offen-bezahlt
  - Fixkosten/Kredit
  - Einnahmen
  - Auswertung + Liquiditaetsplanung
  - Export

### 5.3 Rollout
- Erst TestFlight/Beta.
- Danach gestaffeltes Release.
- Support-Beobachtung in den ersten 48 Stunden.

## 6. Incident-Runbook (wenn etwas schiefgeht)

### Fall A: App startet nicht / Datenbankfehler
- Keine Deinstallation empfehlen.
- Geraet neustarten lassen.
- App neu starten.
- Falls weiter Fehler:
  - Version, iOS-Version, Geraetemodell dokumentieren.
  - Letzte App-Version notieren.
  - Vorherige und neue Buildnummer vergleichen.
  - Gezielt Store/Schema-Fix vorbereiten.

### Fall B: Nutzer meldet "Daten fehlen"
- Pruefen, ob Filter aktiv sind (`Offen/Bezahlt/Alle`, Monatsfilter, Bereich).
- Pruefen, ob Sprache/Format nur Anzeige veraendert.
- Erst danach von echtem Datenproblem ausgehen.
- Keine destruktiven Schnellfixes (kein "Reset Data").

### Fall C: OCR liefert schlechte Erkennung
- Belegqualitaet (Schaerfe, Licht, Zuschnitt) pruefen.
- Review-Ansicht zur Korrektur nutzen.
- Parsing-Regeln in `ParsingService.swift` gezielt erweitern (regex/keyword-basiert), nicht pauschal.

## 7. Support-Standardantworten (Kurzvorlagen)

### 7.1 Datensicherheit
"Alle Daten bleiben lokal auf Ihrem Geraet. Wir werten keine Inhalte kommerziell aus."

### 7.2 Bei Startproblemen
"Bitte App nicht deinstallieren. Bitte Geraet neu starten und erneut oeffnen. Wenn der Fehler bleibt, bitte iOS-Version und App-Version mitteilen."

### 7.3 OCR-Themen
"Bitte den Beleg moeglichst frontal, vollstaendig und scharf erfassen. In der Review-Ansicht koennen erkannte Felder direkt korrigiert werden."

## 8. Onboarding fuer neue Entwickler (ohne Vorwissen)

### 8.1 Umgebung
1. `cd "/Users/jonasweiss/Documents/New project/BillRemind"`
2. `open BillRemind.xcodeproj`
3. iOS 17+ Zielgeraet waehlen.

### 8.2 Verstehen des Codes (Lesereihenfolge)
1. `App/BillRemindApp.swift` (Start, Store, Lock, Error Handling)
2. `Models/Invoice.swift` (Domainmodell inkl. Einnahmen/Fixkosten/Kredite)
3. `Services/OCRService.swift` + `Services/ParsingService.swift`
4. `Views/HomeView.swift` und zugehoerige ViewModels
5. `Views/ReviewInvoiceView.swift`, `Views/SettingsView.swift`

### 8.3 Erste sichere Aenderung
- Kleine Text-/UI-Aenderung mit Build-Check und Funktionspruefung.
- Danach kleine Logik-Aenderung ohne Schema-Aenderung.
- Schema-Aenderungen erst nach Verstaendnis der Release-Checkliste.

## 9. Qualitaets-Gates (muss immer erfuellt sein)

- App startet ohne Fehler auf Simulator und iPhone.
- Bestehende Daten bleiben nach Update erhalten.
- Keine Regression in Kernfunktionen (Scan/Import/Manuell/Auswertung).
- Sprache DE/EN konsistent in Kernscreens.
- Keine Crashes bei leeren oder unvollstaendigen OCR-Ergebnissen.

## 10. "Wie wurde der Code erstellt?" (Nachvollziehbarkeit)

Der aktuelle Code entstand iterativ in mehreren Schritten:
- Fachlich: Anforderungsgetriebene Erweiterung der Kernfeatures (Rechnungen, Einnahmen, Fixkosten/Kredit, Auswertung).
- Technisch: Schrittweise Implementierung in SwiftUI/SwiftData mit manuellen Tests.
- Qualitaet: Fehlerbehebung nach Build- und Praxis-Feedback.

Verbindliche Quelle der Wahrheit:
- Git-Historie im BillRemind-Repo (Commits, Diffs, Zeitpunkte).
- Dokumentierte Checklisten und Konventionen in diesem Repo.

Wichtig:
- Neue Aenderungen immer nachvollziehbar committen (kleine Commits, klare Messages).
- Keine "grossen Sammel-Commits", damit Uebergabe und Ursachenanalyse moeglich bleiben.

## 11. Mindestumfang fuer jedes kuenftige Update

Vor Freigabe muss dokumentiert sein:
- Was wurde geaendert?
- Welche Risiken bestehen?
- Welche Tests wurden durchgefuehrt?
- Wie wurde Datenbestandsschutz verifiziert?
- Rollback-/Hotfix-Plan bei Problemen?

Empfehlung:
- Pro Release eine kurze Datei `docs/releases/<version>.md` mit obigen Punkten.

## 12. Verantwortungsuebergabe im Ernstfall

Wenn der bisherige Hauptverantwortliche ausfaellt, ist folgende Reihenfolge fuer Uebernahme sinnvoll:
1. Zugriff auf Repo + Xcode Buildfaehigkeit herstellen.
2. Dieses Dokument + Data-Safety-Checklist lesen.
3. Aktuelle App-Version bauen und Kernfluss testen.
4. Offene Issues priorisieren: Datenverlustrisiko > Crash > Logikfehler > UI.
5. Nur risikoarme Aenderungen zuerst ausrollen.

Damit bleibt der Betrieb auch unter Zeitdruck kontrollierbar und daten-sicher.
