# Agent-Briefing: BillRemind / Mnemor 2.0.0 – Gesamtstand 25.10.2026

Dieses Dokument ist der Einstieg für jeden, der Feedback geben oder weiterarbeiten soll – Mensch oder Agent. Es fasst das komplette Projekt zusammen und verweist auf die Dateien im Repo, die den jeweiligen Stand im Detail tragen. **Alles, was hier steht, liegt im Branch `release/2.0.0` dieses Repos** (GitHub `weissio/billremind`). Nichts davon setzt Zugriff auf externe Dokumente, Claude-Canvas oder den Mac des Autors voraus.

Lesereihenfolge für ein vollständiges Bild (ca. 60 Minuten):

1. dieses Briefing
2. `docs/konzept-2.0.0/startseiten-varianten.md` + die drei Übersichtsbilder `design/screenshots/uebersicht-varianten-*.png` – hier wird gerade entschieden
3. `docs/konzept-2.0.0/funktionsmodell.md` (Glossar, Dreistufen-Monatsrechnung, Funktionsliste)
4. `docs/konzept-2.0.0/darstellungsarchitektur.md` und `marktvergleich.md`
5. die 28 Screenshots der Detail-Screens in `design/screenshots/`

---

## 1. Was das Produkt ist

**BillRemind** (Marke in 2.0: **Mnemor**) ist eine iOS-App (SwiftUI + SwiftData, iOS 17+), die Privathaushalte ohne Bankzugriff führt: Rechnungen, Bons und PDFs werden per Kamera-OCR oder Import erfasst, bekommen Fälligkeit, IBAN, Status und Erinnerung; Verträge, Budgets, Rücklagen und Termine ergänzen das zu einer Haushaltsverwaltung. **Alles lokal auf dem iPhone, kein Login, kein Server.** Solo-Entwickler; Einmalkauf statt Abo ist die angestrebte Positionierung.

| Stand | Inhalt |
| --- | --- |
| **Im Store / Branch `main`** | 1.0.x: Rechnungen scannen (Apple Vision OCR, heuristischer Parser mit Lernfunktion), Review-Formular, Erinnerungen, Fixkosten, Einnahmen, einfache Liquidität, Export, Backup, Face-ID. Code in `App/ Models/ Services/ ViewModels/ Views/`, Tests in `Tests/`, OCR-Korpus-Pflichtlauf `make ocr-check`. |
| **In Arbeit / Branch `release/2.0.0`** | Konzeptphase abgeschlossen bis auf die Startseite: Marktvergleich, Funktionsmodell, Darstellungsarchitektur, klickbarer Prototyp mit 28 Screens und 16 Startseiten-Varianten. **Noch kein 2.0-Code**; Implementierung folgt (Datenmodell → OCR 2.0 → Screens). |

Zielgruppe und ihre Not (aus `startseiten-varianten.md`): *Habe ich etwas vergessen (Mahnung)? Reicht das Geld bis Monatsende? Wo ist der Zettel? Was läuft still weiter (Abos, Fristen)?* – und darunter oft Scham und Vermeidung gegenüber Finanzen. Stiftung Warentest deckelt manuelle Haushaltsbuch-Apps wegen überladener Startseiten bei „befriedigend"; die Startseite ist daher Prüfstein und Markenversprechen zugleich.

## 2. Die sechs USPs (aus `marktvergleich.md`)

1. **Rechnung rein, Fälligkeit raus** – Beleg wird Objekt mit Lebenszyklus (erkannt → fällig → erinnert → bezahlt). Kein Wettbewerber verbindet OCR mit Fälligkeits-/IBAN-/Statuslogik.
2. **Verträge & Abos ohne Kontozugriff** – Laufzeit, Kündigungsfrist, Wecker, Verknüpfung zur Fixkostenposition.
3. **Eine ehrliche Monatszahl, lokal berechnet** (heute „Noch frei").
4. **100 % lokal**, 5. **ein Preis, alle Module**, 6. **lernende Erkennung auf dem Gerät**.
Benannte Lücke: Teilen/Sync (für 2.1 vorgemerkt: iCloud-Sharing ohne Anbieter-Server).

## 3. Struktur der App 2.0 (verbindlich)

- **Tab-Leiste:** Übersicht · Rechnungen · Erfassen (Kamera, mittig) · Verträge · Liquidität. „Mehr" (Einnahmen, Budgets, Monatsrechnung, Kalender, Auswertung, Dokumente, Haushaltskasse, Einstellungen) über das …-Icon oben rechts. Jede Tab-Leiste führt zurück zur Übersicht.
- **Drei Bereiche:** Wohnen · Mobilität · Haushalt. Jeder Bereich führt Objekte (Wohnung/Haus/Garage; Fahrzeug/Ticket; Personen/Haustier) und Kategorien, Rücklagen, Termine. Zuordnungsregel: ortsgebunden → Wohnen (auch Internet, Rundfunk, Energie, Hausrat), personengebunden → Haushalt, fahrzeuggebunden → Mobilität.
- **Objekte:** Rechnung/Bon, Vertrag, Kategorie, Objekt, Rücklage (Arten: aus Vertrag, Sparziel, Kasse), Termin, Dokument. Verträge mit monatlicher/vierteljährlicher Abbuchung → Fixkosten-Monatsanteil; halbjährlich/jährlich → Rücklage-Rate.
- **Liquidität** ist der einzige Ort mit Kontostand (manuell gepflegt, Abgleich gegen geplante Buchungen); Kalender ist ein eigener Hilfsscreen (Übersicht-Kopf, Mehr), einseitig in den iOS-Kalender gespiegelt.

## 4. Die Monatsrechnung – Begriffe, die überall gleich heißen müssen

Entschieden am 25.10. nach Recherche (Finanzguru, Monarch, YNAB, Emma; Quellen in `funktionsmodell.md`). Sparen ist keine Ausgabe; Budgets sind Umschläge im Spielraum; Überschreitung macht nichts negativ.

```
MONATSANFANG · Plan                 Einnahmen 3.650,00 − Fixkosten 1.659,20 − Rücklagen-Raten 326,10 = Spielraum 1.664,70
IM MONAT · läuft                    Spielraum − Ausgegeben 1.010,60 − In Budgets reserviert 61,40 = Noch frei 592,70  ← Kopfzahl
MONATSENDE · voraussichtlich        Gespart = Rücklagen 326,10 + Überschuss 592,70 = 918,80 · Sparquote 25 %
```

| Begriff | Bedeutung | nicht mehr verwenden |
| --- | --- | --- |
| Spielraum | Einnahmen − Fixkosten & Kredite − Rücklagen-Raten | Verfügbares Einkommen |
| Noch frei | Spielraum − Ausgegeben − Reserviert | **Sparpotenzial**, Frei verfügbar |
| Ausgegeben | variable Ausgaben: bezahlt + offen (offene Rechnungen zählen ab Fälligkeit) | Ausgaben des Monats |
| Reserviert | je Budget: Budget − Ausgegeben, nie unter 0 | Budgets offen |
| Rücklagen-Raten / Sparen | zweite Verwendung des Einkommens; mindert Spielraum, zählt zum Gesparten | Kosten |
| Überschuss | Noch frei am Monatsende; kann in eine Rücklage übertragen werden | Ergebnis |
| Gespart | Rücklagen + Überschuss | Sparrate |

Budget überschritten (Freizeit 180/150): die 30 € stehen unter *Ausgegeben*, reserviert = 0, Kategorie rot „30,00 € über Budget", Angebot „Budget anheben" / „aus Lebensmittel decken". Verwendung einer Rücklage (HUK 487,20 am 27.10.) belastet den Monat nicht, nur den Kontostand.

**Hinweis:** Ältere Dateien (`navigation-und-faelligkeiten.md`, Teile des Marktvergleichs, Live-Dokumente außerhalb des Repos) verwenden noch „Sparpotenzial", „Frei verfügbar", „Akte", „Gebäude", „Ordner". Es gilt das Glossar in `funktionsmodell.md`.

## 5. Beispielmonat Oktober 2026 – jede Zahl in jedem Screen identisch

| Größe | € | Herleitung |
| --- | --- | --- |
| Einnahmen | 3.650,00 | Gehalt 3.400 (30.) + Kindergeld 250 (5.) |
| Fixkosten & Kredite | 1.659,20 | Wohnen 1.218,35 + Mobilität 356,99 + Haushalt 83,86 (16 Verträge) |
| Rücklagen-Raten | 326,10 | Urlaub 200 + HU/Reifen 60 + Kfz-Vers. 40,60 + Kfz-Steuer 12 + Hausrat 7,83 + Haftpflicht 5,67 |
| Spielraum | 1.664,70 | |
| Ausgegeben | 1.010,60 | bezahlt 656,20 (Laden 64,20 + 13 Bons/Rechnungen 592,00) + offen 354,40 (Stadtwerke 142 überfällig seit 21.10., Inspektion 212,40 fällig 30.10.) |
| In Budgets reserviert | 61,40 | Lebensmittel 38 (412/450) + Mobilität variabel 23,40 (276,60/300); Freizeit 180/150 → 0 |
| Noch frei | 592,70 | |
| Gespart | 918,80 | Sparquote 25 % |
| Bereiche | 2.995,90 | Wohnen 1.368,18 + Mobilität 746,19 + Haushalt 881,53 = Fixkosten + Ausgegeben + Rücklagen-Raten |
| Verträge | 1.713,30/Monat · 20.559,60/Jahr | 16 Verträge; Kfz-Steuer ist Termin mit Rücklage, kein Vertrag |
| Liquidität | Kontostand 2.410,00 · tiefster Stand 1.767,81 am 29.10. · Puffer 1.500 | Jahresende-Saldo der Planung 12.300,60 |
| Haushaltskasse | 86,50 | Einzahlungen 229,17 − 5 Bons 142,67 |

## 6. Der Prototyp (Design-Canvas, hier als Dateien)

- **28 Detail-Screens** in `docs/konzept-2.0.0/design/*.dc.html` – interaktive Artboards für Claude Design (eigenes Template-Format: `{{holes}}`, `<sc-for>`, `<sc-if>`, Logik als JS-Klasse). Im Browser zeigen die Dateien nur das Gerüst; **vollständige Bilder jedes Screens in `design/screenshots/*.png`** (390 pt breit, ganze Seitenhöhe).
- **Generator** in `design/generator/` (Python erzeugt die HTML-Dateien; `a_bereiche.py` Übersicht + Bereiche, `b_rechnungen.py`, `c_vertraege.py`, `d_objekte.py` Kategorie/Objekt/Rücklage/Termin/Monatsrechnung, `e_mehr.py` Budgets/Einnahmen/Mehr/Kasse/Dokumente/Auswertung/Einstellungen, `f_liquiditaet.py` Liquidität/Verlauf/Kontostand/Kalender, `g_varianten.py` die 16 Startseiten). Prüfungen: `check2.js` (jede Taste, jede Variable), `check3.js` (41 Soll-Werte des Beispielmonats), `render.js` + `shot.js` (Screenshots per Playwright). Alles grün, Stand dieses Commits.
- **Anordnung** in `design/canvas.json`: Reihe 1 Übersicht → Monatsrechnung, Einnahmen, Budgets, Mehr, Auswertung, Einstellungen, Dokumente, Haushaltskasse, Kalender · Reihe 2 Wohnen, Mobilität (`Akte.dc.html`), Haushalt, Kategorie, Kategorie anlegen, Objekt anlegen, Rücklage, Termin · Reihe 3 Rechnungen, Rechnung, Erfassen, Rechnung prüfen (`Review`), Verträge, Vertrag, Vertrag anlegen · Reihe 4 Liquidität, Verlauf, Kontostand · Reihe 5 verworfen (StartB/C/D) · Reihe 6 Startseiten-Varianten V01–V10 · Reihe 7 V11–V16.
- **Was im Prototyp funktioniert:** Eingaben rechnen (Budgets, Einnahmen, Rücklage, Kasse, Liquiditäts-Horizonte 7 Tage bis 1 Jahr, Kontostand-Abgleich), Formulare prüfen (IBAN-Prüfsumme, Pflichtfelder, Zuordnungsregel), jede Taste hat Wirkung (Sheets, Toasts). **Nicht im Prototyp:** Zustand über Screens hinweg, echte Kamera.

## 7. Die Startseite – offener Punkt, hier wird Feedback gebraucht

Chronologie der Versuche (alle Commits auf `release/2.0.0`):

| Version | Startseite | Urteil des Autors |
| --- | --- | --- |
| 24./25.10. | Hero-Zahl „Sparpotenzial" + dreizeiliger Formeltext + 4 Kacheln + Bereiche + Wisch-Karten „Fällig" | zu viel Text, Formel gespiegelt |
| v25 | Rechenkarte (5 Zeilen + Summe) statt Hero | zu viel für eine Startseite |
| v26 | eine Zahl, Rechnung aufklappbar | „Design wurde schlechter" |
| v27 | Kopfzahl + Balkenpaar mit Legende, Bereiche mit Anteilsbalken und Statuszeile, Fällig als Datumszeilen | „zu chaotisch", Statuszeilen unklar („warum steht das dort, was bei mehreren?") |
| v29 (aktuell `Main.dc.html`) | eine Zahl + ein Balken, Bereiche nur mit Zähler-Punkt, Fällig-Zeilen ohne Untertitel | „komplett verfehlt" |
| v30/31 | **16 Varianten V01–V16 zur Entscheidung** | offen |

Die 16 Varianten (Bilder: `uebersicht-varianten-V01-V05.png`, `-V06-V10.png`, `-V11-V16.png`; Begründung je Variante aus Sicht Designer, CEO, Psychologe, Vergleichsprodukt in `startseiten-varianten.md`):

V1 Heute (Aufgaben zuerst) · V2 Ampel (drei Zustände) · V3 Ruhe (eine Zahl, Weißraum) · V4 Zeitstrahl (Kontostand + 14 Tage) · V5 Eingang (Belege zuerst) · V6 Bereiche (große Kacheln) · V7 Monatsbrief (in Sätzen) · V8 Haushaltsbuch (Tabelle) · V9 Fokus (eine Karte, eine Handlung) · V10 Cockpit (alles) · V11 Kategorie-Raster · V12 Kategorienliste mit Balken · V13 Ring + größte Kategorien · V14 Bereiche aufgeklappt (Kategorien eingerückt) · V15 Fokus + Kategorie-Kacheln · V16 Umschläge (Budgets zuerst, „fest verplant" darunter).

Empfehlung des bisherigen Agenten: V9 (etwas steht an) + V3 (alles im Plan) als zwei Zustände derselben Seite; mit Kategorien auf der Startseite: V14 oder V16. Der Autor wünscht ausdrücklich **Kategorien auf der Startseite** (Anforderung vom 25.10.).

Zu klärende Fragen: (1) Grundstruktur der Startseite; (2) darf der Kontostand auf die Startseite (V4) oder bleibt er in der Liquidität; (3) wird „Eingang" (V5) ein Reiter in Rechnungen; (4) Statusinformation je Bereich: Zähler, Text, Balken oder nichts; (5) Darstellung der Monatsrechnung auf der Startseite: nur Zahl, Zahl + Balken, oder Dreistufen-Kurzform.

## 8. Weitere offene Entscheidungen (aus `funktionsmodell.md`)

Versicherungen im Lebensbereich oder gesammelt; Budget auf Bereich oder Unterkategorie; Umgang mit Alt-Kategorie „Abos" bei der Migration; finale Vertragstyp-Liste mit Standard-Kündigungsfristen; Onboarding-Vorlagen in 2.0.0 oder 2.1; Teilen/Sync (2.1).

## 9. Technischer Rahmen für die Implementierung

- SwiftUI + SwiftData, iOS 17+, `project.yml` (xcodegen optional), Marketing-Version aktuell 1.0.3 auf `main`; 2.0.0 bekommt additive Schema-Änderungen, Migration der 8 Alt-Kategorien, Backup/Restore N-1 → N (Pflicht laut `docs/data-safety-release-checklist.md`).
- OCR heute: `Services/OCRService.swift`, `ParsingService`, `SpatialParser`, `LayoutAwareOCR`, `LearningService` (Vendor-Profile). OCR 2.0 (Muss vor Launch): Vision-Dokumentenerkennung + Foundation Models auf dem Gerät, Heuristik als Prüfer/Fallback; Original-PDFs werden künftig gespeichert (`documentFileName`).
- Konventionen: `WORKING_CONVENTION.md`, `FOLDER_STRUCTURE.md`, `Readme_Absicherung_und_Support.md`; CI führt `make ocr-check` aus.
- Lokale Pfade in den alten READMEs (`/Users/jonasweiss/…`) sind Mac-Pfade des Autors und für Agenten irrelevant.

## 10. Was wir von Feedback-Agenten erwarten

1. Startseite: Wahl oder Kombination aus V01–V16 mit Begründung gegen die fünf Nöte der Zielgruppe; gern eine siebzehnte Struktur, wenn sie eine Lücke schließt.
2. Prüfung der Dreistufen-Monatsrechnung auf Verständlichkeit für Laien – Begriffe, Reihenfolge, was fehlt.
3. Kritik an Reihenfolge und Dichte der Detail-Screens anhand der Screenshots (Zeilenumbrüche und Dichte waren wiederholt Kritikpunkt; Stand jetzt: Name und Untertitel einzeilig, Werte zweizeilig getrennt).
4. Lücken gegenüber Finanzguru, YNAB, Monarch, Copilot, Buddy, Money Manager, Outbank/Finanzblick, Bobby – aber ohne Bankanbindung.
5. Risiken für Implementierung und Datenmigration.

Antworten bitte mit Bezug auf Dateinamen/Variantennummern, damit sie direkt in `funktionsmodell.md` bzw. `startseiten-varianten.md` übernommen werden können.
