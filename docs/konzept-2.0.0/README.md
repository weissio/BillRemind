# Konzept Release 2.0.0 – Mnemor als Haushaltsverwaltung

Stand 24.10.2026. Ergebnis der Konzeptphase für 2.0.0: Marktvergleich, Funktionsmodell und ein klickbarer Screen-Prototyp mit einem durchgerechneten Beispielmonat. Die Implementierung folgt auf `release/2.0.0` (zuerst Datenmodell, dann OCR 2.0, dann Screens).

Die Dokumente leben weiterhin als bearbeitbare Claude-Docs; hier liegt der eingefrorene Stand.

| Datei | Inhalt | Live-Dokument |
| --- | --- | --- |
| `marktvergleich.md` | DE/US/UK-Haushaltsbuch-Apps, Muster & Lücken, sechs USPs | [Marktvergleich](https://claude.ai/artifact/14ebQFwB3GdiJ9q7B9MRuf) |
| `funktionsmodell.md` | Taxonomie, Zuordnungsregel, Objektmodell, OCR-Symbiose, OCR 2.0, eingefrorene Funktionsliste, Glossar, Beispielmonat | [Funktionsmodell](https://claude.ai/artifact/WQdw2oxroqdp27fwcHr1WR) |
| `navigation-und-faelligkeiten.md` | Zweiter Reiter des Funktionsmodells: Bereiche, Fälligkeiten, Liquidität, Termin-Objekt (Konzeptsprache, „Akte“ = Bereich, „Gebäude“ = Wohnen) | gleiches Dokument, Reiter 2 |
| `design/` | 27 interaktive Screens als Artboards (`*.dc.html`), `canvas.json` (Anordnung), `generator/` (erzeugt alle Screens, `check2.js`/`check3.js` prüfen jede Taste und 41 Soll-Werte), `screenshots/` (statischer Stand 24.10.) | [App-Screens](https://claude.ai/artifact/ACDyBU4mp3qL8kMp6PbWxZ) |

## Screens ansehen

Die Screens sind seit 25.10. interaktiv (Eingaben, Schalter, Sheets, Rechnungen) und brauchen die Laufzeit des Claude-Design-Canvas – dort „Play“ starten. Lokal im Browser zeigen die Dateien nur das Gerüst (`{{…}}`-Platzhalter). Erzeugen: `cd design/generator && for f in a_bereiche b_rechnungen c_vertraege d_objekte e_mehr f_liquiditaet; do python3 $f.py; done`, prüfen: `node check2.js && node check3.js` (aus `design/..`, erwartet `project/` → hier `design/`). `StartB/C/D` sind verworfene Startseiten-Varianten.

Reihen in `canvas.json`:

1. Übersicht → Monatsrechnung, Einnahmen, Budgets, Mehr, Auswertung, Einstellungen, Dokumente, Haushaltskasse
2. Wohnen, Mobilität (`Akte.dc.html`), Haushalt → Kategorie, Kategorie anlegen, Objekt anlegen, Rücklage, Termin
3. Rechnungen, Rechnung, Erfassen, Rechnung prüfen (`Review`), Verträge, Vertrag, Vertrag anlegen
4. Liquidität, Verlauf, Kontostand aktualisieren

## Beispielmonat Oktober 2026 (alle Screens rechnen damit)

| Größe | Betrag (€) | Herleitung |
| --- | --- | --- |
| Einnahmen | 3.650,00 | Gehalt 3.400 (30.) + Kindergeld 250 (5.) |
| Fixkosten & Kredite | 1.659,20 | Wohnen 1.218,35 + Mobilität 356,99 + Haushalt 83,86 |
| Ausgaben des Monats | 1.010,60 | bezahlt 656,20 + offen 354,40 (Stadtwerke 142 überfällig, Inspektion 212,40) |
| Budgets noch offen | 61,40 | Lebensmittel 38,00 + Mobilität variabel 23,40; Freizeit überschritten → 0 |
| Rücklagen-Raten | 326,10 | Urlaub 200 + HU/Reifen 60 + Kfz-Vers. 40,60 + Kfz-Steuer 12 + Hausrat 7,83 + Haftpflicht 5,67 |
| Sparpotenzial | 592,70 | 3.650,00 − 1.659,20 − 1.010,60 − 61,40 − 326,10 |
| Summe der Bereiche | 2.995,90 | Wohnen 1.368,18 + Mobilität 746,19 + Haushalt 881,53 = Fixkosten + Ausgaben + Rücklagen |
| Verträge | 1.713,30 / Monat | 16 Verträge = Fixkosten 1.659,20 + Vertrags-Rücklagen 54,10 |
| Liquidität | 1.767,81 tiefster Stand | 2.410 − 142 − 487,20 (27.) − 12,99 (29.); Gehalt 3.400 am 30. |

Regeln: Bereichssumme = fix + variabel + Rücklagen-Raten (Prüfsumme unter jeder Liste). Offene Rechnungen zählen ab Fälligkeit zu den Ausgaben. Verträge mit monatlicher/vierteljährlicher Abbuchung → Fixkosten-Monatsanteil; halbjährlich/jährlich → Rücklage-Rate. Zuordnung: ortsgebunden → Wohnen, personengebunden → Haushalt, fahrzeuggebunden → Mobilität.
