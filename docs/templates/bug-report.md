# Bug Report Template (Mnemor / BillRemind)

Dieses Template ist verpflichtend fuer neue Bugs und orientiert sich an:
- `/Users/jonasweiss/Documents/New project/BillRemind/Readme_Absicherung_und_Support.md` (Abschnitt 14)

## 1) Metadaten

- Ticket-ID:
- Datum:
- Melder:
- Status: `neu | in triage | in bearbeitung | verifiziert | released | geschlossen`
- Prioritaet: `P0 | P1 | P2 | P3`
- Datensicherheitsrisiko: `hoch | mittel | niedrig`

## 2) Umgebung (Pflicht)

- App-Version:
- Buildnummer:
- iOS-Version:
- Geraetemodell:
- Sprache in App: `DE | EN`
- Betroffener Bereich:
  - `Scan Rechnung`
  - `Scan Kassenbon`
  - `PDF-Import`
  - `Review`
  - `Rechnungen`
  - `Ausgaben`
  - `Einnahmen`
  - `Auswertung`
  - `Export`
  - `Settings`
  - `Backup/Restore`
  - `Sonstiges`

## 3) Problem

- Kurzbeschreibung:
- Erwartetes Verhalten:
- Ist-Verhalten:

## 4) Reproduktion (nummeriert, Pflicht)

1.
2.
3.

Ergebnis nach Reproduktion:
- `immer`
- `sporadisch`
- `nicht reproduzierbar`

## 5) Belege

- Screenshot(s):
- Video:
- Log-Auszug / Fehlermeldung:

## 6) Eingrenzung (Triage/Entwicklung)

- Kategorie:
  - `Datenmodell`
  - `UI-State`
  - `Parsing/OCR`
  - `Export/Restore`
  - `Sonstiges`
- Minimal reproduzierbarer Fall:
- Vermutete Ursache:
- Workaround vorhanden: `ja | nein`
- Workaround:

## 7) Fix-Plan

- Geplante Aenderung (kurz):
- Betroffene Datei(en):
- Risiko des Fixes: `hoch | mittel | niedrig`
- Hinweis bei Persistenz:
  - `Keine Schema-Aenderung`
  - `Additive Schema-Aenderung`
  - `Migration noetig`

## 8) Verifikation nach Fix

- Parse/Build erfolgreich: `ja | nein`
- Betroffener Use-Case getestet: `ja | nein`
- Regression geprueft:
  - Speichern: `ja | nein`
  - Anzeigen Listen/Details: `ja | nein`
  - Auswertung: `ja | nein`
  - Export: `ja | nein`
  - Backup/Restore (falls relevant): `ja | nein`
- Ergebnis:

## 9) Release-Entscheidung

- In Release enthalten: `ja | nein`
- Release-Version:
- Rollout-Stufe:
  - `intern`
  - `testflight`
  - `produktion`
- Beobachtung 24h abgeschlossen: `ja | nein`
- Beobachtung 48h abgeschlossen: `ja | nein`

## 10) Abschluss

- Root Cause (final):
- Getroffene Massnahmen:
- Restrisiko:
- Follow-up Tasks:

