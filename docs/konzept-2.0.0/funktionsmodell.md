# Funktionsmodell Mnemor 2.0 – Kategorien, Objekte, OCR-Symbiose

24.10.2026 · @Arjen

Die Marktführer teilen nach **Lebensbereich** ein (Wohnen, Mobilität, Kommunikation …), zweistufig als Gruppe → Unterkategorie, und behandeln „Abo“ oder „Vertrag“ nicht als Kategorie, sondern als Eigenschaft bzw. eigenes Objekt neben der Kategorie. Mnemor 2.0 übernimmt das: Jede Buchung – ob OCR-Rechnung, Bon, Vertrag oder Fixkostenposition – hängt an genau einer Unterkategorie eines Lebensbereichs und trägt zusätzlich eine **Kostenart** (fix, variabel, Kredit). Ein Vertrag ist ein eigenes Objekt mit Laufzeit und Kündigungsfrist; eine per OCR erfasste Rechnung kann an ihn andocken und ersetzt dann im Monat den geplanten Betrag. So werden Rechnungen, Fixkosten und Budgets in einer Zahl „Noch frei“ zusammengeführt, ohne Doppelzählung (seit 25.10.: Spielraum → Noch frei, siehe Monatsrechnung).

## Wie die Marktführer einteilen

Sieben Systeme, ein Muster: zwei Ebenen, Lebensbereich oben, Zahlungsart als Merkmal. Die amtliche Statistik liefert die Bereichsnamen, die Verbraucherzentrale die zweite Achse (fest vs. veränderlich).

| System | Ebenen | Hauptgruppen (Auszug) | Abos / Verträge | Übernehmen |
| --- | --- | --- | --- | --- |
| [Monarch Money](https://help.monarch.com/hc/en-us/articles/360048883851) (US) | Gruppe → Kategorie | 13 Ausgabengruppen: Housing, Bills & Utilities, Auto & Transport, Food & Dining, Travel & Lifestyle, Shopping, Children, Education, Health & Wellness, Financial, Gifts & Donations, Other, Business; eigene Bäume für Income und Transfers | keine eigene Gruppe: Streaming unter Entertainment, Telefon unter Bills & Utilities, Versicherung und Kredit unter Financial; „recurring“ ist ein Merkmal der Buchung | Bereich vor Zahlungsart; Icon je Gruppe; Einnahmen als eigener Baum |
| [YNAB](https://support.ynab.com/en_us/category-templates-HknjS_RA.md) (US) | Gruppe → Kategorie, frei | typisch Bills / Needs / Wants / Savings Goals; Vorlagen je Lebenslage (Umzug, Familie, variables Einkommen) | Bills = alle festen Verpflichtungen, unabhängig vom Bereich | Gruppierung nach Verbindlichkeit als zweite Sicht; Kategorie-Vorlagen beim Onboarding |
| [Finanzguru](https://www.neuebanken.de/finanzguru-test/) (DE) | automatisch, eine Ebene sichtbar | Beispiele: Lebensmittel, Mobilität, Shopping, Abos | Verträge sind eigenes Objekt aus wiederkehrenden Buchungen: Monatskosten, nächste Abbuchung, Kündigungsfrist, Kündigen-Button, manuell ergänzbar | Vertrag als Objekt neben der Kategorie; Kündigungsfrist als Pflichtfeld |
| [finAPI](https://www.finapi.io/en/products/data-intelligence/categorization/) (Engine hinter vielen DE-Banking-Apps) | Label → über 200 Unterlabels | Rent, Living, Mobility, Insurance, Bank & Credit, Savings, Health & Wellness, Shopping & Entertainment, Hobbies & Social Life, Travelling, Children, Legal | erkennt Versicherungs-, Kredit- und Versorgerverträge als eigene Vertragstypen | Versicherung und Finanzen als eigene Gruppen; Vertragstypen Versicherung / Kredit / Versorger |
| [Finanzfluss Copilot](https://www.finanzfluss.de/copilot/hilfe/kategorien/) (DE) | Ober- → Unterkategorie, frei mit Icon und Farbe | nutzerdefiniert (Beispiel Hausbau → Möbel) | nicht gesondert | Sankey-Auswertung Einnahmen → Gruppen (Kann) |
| [MoneyStats](https://apps.apple.com/de/app/haushaltsbuch-moneystats/id1249678565) (DE) | Kategorien + Gruppen, frei | nutzerdefiniert, automatische Kategorisierung | wiederkehrende Buchungen als eigener Bereich mit Filter und Analyse; Budget über mehrere Kategorien | Multi-Kategorie-Budget; Budget-Historie |
| [Verbraucherzentrale NRW](https://www.verbraucherzentrale.nrw/wissen/geld-versicherungen/kredit-schulden-insolvenz/haushaltsbuch-fuehren-ueberblick-ueber-ihre-finanzen-52179) | feste vs. veränderliche Ausgaben | fest: Miete, Energie, Telefon, Beiträge; veränderlich: Essen & Trinken, Kleidung … | Jahresposten (Versicherung, Kfz-Steuer) auf Monat umlegen und als Rücklage führen; Verfügbar = Einnahmen − feste Ausgaben | Kostenart fest/variabel; Rücklage für Jahresverträge; Verfügbar-Formel |
| [Destatis LWR 2024](https://lebensmittelpraxis.de/handel-aktuell/49585-konsumausgaben-2024-deutsche-haushalte-geben-mehr-geld-fuer-freizeit-aus.html) (amtlich, COICOP) | 12 Abteilungen | Wohnen & Energie 36,3 %, Nahrungsmittel 14,0 %, Verkehr 13,8 %, Freizeit & Kultur 9,5 % von 3.257 €/Monat; dazu Bekleidung, Gesundheit, Post & Telekommunikation, Gaststätten, Bildung, Innenausstattung, Sonstiges | nicht Teil der Systematik | deutsche Bereichsnamen; Referenzanteile für Budget-Vorschläge |

Vier Regeln folgen daraus: (1) genau zwei Ebenen, nie mehr; (2) oben steht der Lebensbereich, nicht die Zahlungsart – „Abos“ als Kategorie verschwindet; (3) fest/variabel/Kredit ist eine zweite Achse, keine Kategorie; (4) Verträge sind Objekte mit Laufzeit, die an eine Unterkategorie hängen.

## Kategorie-Taxonomie Mnemor 2.0

Elf Lebensbereiche mit je 4–8 Unterkategorien, dazu Einnahmen als eigener Baum. Versicherungen, die zu einem Bereich gehören (Kfz, Wohngebäude, Hausrat), liegen in diesem Bereich; Personenversicherungen in „Versicherung & Vorsorge“. Jede Unterkategorie hat eine Standard-Kostenart, die der Nutzer je Buchung ändern kann.

| Bereich (Gruppe) | Unterkategorien | Standard-Kostenart | Typische Quelle |
| --- | --- | --- | --- |
| Wohnen | Miete / Hausgeld · Nebenkosten · Strom · Gas / Heizung · Wasser / Abfall · Internet & Festnetz · Rundfunkbeitrag · Instandhaltung & Reparatur · Einrichtung & Haushaltsgeräte · Gebäude- / Hausratversicherung · auf Abruf: Grundsteuer, Schornsteinfeger, Heizungswartung, Garten, Reinigung, Stellplatz | fix (außer Instandhaltung, Einrichtung) | Vertrag, Jahresabrechnung (OCR) |
| Lebensmittel & Haushalt | Supermarkt · Bäcker / Metzger · Drogerie · Getränke | variabel | Kassenbon (OCR) |
| Mobilität | Kfz-Rate / Leasing · Kfz-Versicherung · Kfz-Steuer · Kraftstoff / Laden · Werkstatt & Reifen · ÖPNV / Deutschlandticket · auf Abruf: Parken & Maut, Fahrrad & E-Bike, Carsharing, Bahn & Taxi | fix (Rate, Versicherung, Steuer, Ticket), sonst variabel | Vertrag, Rechnung, Bon |
| Kommunikation & Medien | Mobilfunk · Streaming · Software & Cloud · Zeitungen & Zeitschriften · Gaming (Internet / Festnetz liegt bei Wohnen) | fix | Vertrag / Abo |
| Versicherung & Vorsorge | Haftpflicht · Berufsunfähigkeit · Rechtsschutz · Zusatzkranken / Zahn · Unfall · Altersvorsorge / Riester / Lebensversicherung | fix | Vertrag, Jahresrechnung (OCR) |
| Gesundheit | Arzt & Zuzahlung · Apotheke · Brille / Hörgerät · Fitness & Sport | variabel (Fitness fix) | Rechnung, Bon, Vertrag |
| Freizeit & Kultur | Hobby · Verein & Mitgliedschaft · Veranstaltungen · Bücher, Spiele, Musik · Urlaub & Reisen | variabel (Verein fix) | Bon, Rechnung |
| Gastronomie & Genuss | Restaurant · Café & Imbiss · Lieferdienst | variabel | Bon |
| Kleidung & Pflege | Kleidung · Schuhe · Friseur & Kosmetik | variabel | Bon |
| Familie, Bildung & Haustier | Kita / Schule · Kinderbetreuung · Taschengeld · Kurse & Weiterbildung · Unterhalt · Haustier | fix (Kita, Unterhalt), sonst variabel | Vertrag, Rechnung |
| Finanzen & Steuern | Kredit-Rate · Kontoführung & Gebühren · Steuern & Nachzahlung · Sparen & Investieren · Spenden & Geschenke · Bargeldabhebung | Kredit (Rate), fix (Konto, Sparen), variabel | Kredit, Bescheid (OCR) |
| Sonstiges | Unkategorisiert · Sonstiges | variabel | – |
| Einnahmen | Gehalt / Lohn · Selbstständigkeit · Kindergeld & staatliche Leistungen · Kapitalerträge · Miete / Untermiete · Rückerstattung · Sonstige Einnahme | fix (Gehalt, Kindergeld), sonst einmalig | IncomeEntry |

**Drei Dimensionen statt einer.** Bisher trägt eine Rechnung nur `categoryRaw` (8 Werte, flach). Künftig:

1. **Bereich → Unterkategorie** (Pflicht, genau eine): beantwortet „wofür?“ und speist Budgets und Auswertung.
2. **Kostenart** `fix | variabel | kredit` (Pflicht, Standard aus der Unterkategorie): beantwortet „planbar?“ und speist Fixkosten-Reiter und „Frei verfügbar“.
3. **Vertragstyp** nur am Vertrag: `Versicherung | Versorger | Telekommunikation | Abo & Streaming | Mitgliedschaft | Miete & Leasing | Wartung & Service | Sonstiger Vertrag` – beantwortet „was für ein Vertrag?“ und steuert Kündigungsfrist-Vorgaben und Dokumentenerkennung.

**Migration der heutigen Kategorien** (additiv, bestehende `categoryRaw`-Werte bleiben gespeichert; neue Felder `categoryGroupRaw` und `subcategoryRaw` werden beim ersten Start aus der Tabelle befüllt):

| Heute | Künftig Bereich → Unterkategorie | Hinweis |
| --- | --- | --- |
| Wohnen | Wohnen → Nebenkosten (Standard); Strom/Gas über Anbieterprofil | Anbieterprofile mit Stadtwerke-/Energie-Mustern werden auf Strom bzw. Gas gemappt |
| Lebensmittel | Lebensmittel & Haushalt → Supermarkt | Drogerie-Händler (dm, Rossmann) über Händlerliste auf Drogerie |
| Versicherung | Versicherung & Vorsorge → Haftpflicht (Standard) | Kfz- und Gebäudeversicherungen beim ersten Review-Vorschlag in Mobilität bzw. Wohnen umhängen |
| Telefon & Internet | Kommunikation & Medien → Mobilfunk oder Internet / Festnetz | Anbieterprofil entscheidet |
| Abos | Kommunikation & Medien → Streaming (Standard); Verein/Fitness → Freizeit bzw. Gesundheit | Kategorie entfällt; alle Treffer erhalten Kostenart fix und einen Vertragsvorschlag |
| Steuern | Finanzen & Steuern → Steuern & Nachzahlung | – |
| Mobilität | Mobilität → Kraftstoff / Laden (Standard) | Werkstatt, Versicherung, Ticket über OCR-Schlüsselwörter |
| Sonstiges | Sonstiges → Sonstiges | – |

Eigene Unterkategorien bleiben möglich (wie heute eigene Kategorien), aber immer innerhalb eines der drei Bereiche Wohnen, Mobilität, Haushalt; eigene Bereiche nicht – sonst zerfallen Budget-Vorschläge und Auswertung.

**Zuordnungsregel (24.10.2026):** Was an der Wohnung hängt, gehört zu Wohnen (Internet & Festnetz, Rundfunkbeitrag, Energie, Hausrat, Grundsteuer); was an der Person hängt, zu Haushalt (Mobilfunk, Streaming, Mitgliedschaften, Versicherungen der Person); was am Fahrzeug hängt, zu Mobilität. Die Vorlagen von steuerschroeder.de und monsterdealz weichen hier voneinander ab (Internet einmal unter Wohnen, einmal unter Kommunikation); Mnemor folgt der Ortsbindung, weil Umzug, Nebenkostenabrechnung und Objekt-Zuordnung dann in einem Bereich bleiben.

**Kategorie anlegen auf Abruf:** Jeder Bereich zeigt unten „+ Kategorie anlegen“. Dort stehen zuerst die noch nicht angelegten Standardkategorien des Bereichs als Vorschläge (Wohnen: Grundsteuer, Gebäudeversicherung, Schornsteinfeger, Heizungswartung, Garten, Reinigung, Hausgeld / WEG, Stellplatz, Möbel & Einrichtung · Mobilität: Parken & Maut, Fahrrad & E-Bike, Carsharing, Taxi · Haushalt: Kinderbetreuung, Bildung, Geschenke, Spenden, Taschengeld); ein Tipp übernimmt Name, Kostenart und Symbol. Darunter eine eigene Kategorie mit Name, Bereich, Kostenart (variabel / fix / Kredit), Objekt, Symbol und optionalem Budget; nach dem Anlegen bietet die App passend Termin (z. B. Kehrung jährlich) und Rücklage (Jahresbetrag ÷ 12) an. Kategorien mit Buchungen werden ausgeblendet, nie gelöscht.

**Vertragsrhythmus und Fixkosten:** Verträge mit monatlicher oder vierteljährlicher Abbuchung zählen mit ihrem Monatsanteil zu den Fixkosten (Rundfunkbeitrag 55,08 € vierteljährlich → 18,36 €/Monat). Halbjährliche und jährliche Verträge laufen als Rücklage-Rate (Kfz-Versicherung 487,20 €/Jahr → 40,60 €/Monat); die Jahresabbuchung wird aus der Rücklage bedient und belastet den Monat nicht. Kfz-Steuer ist kein Vertrag, sondern Termin mit Rücklage.

## Objektmodell

&#91;embedded content: Objektmodell Mnemor 2.0 · 7 Objekte, eine Kategorieachse\]

Vier Buchungsobjekte (Rechnung, Vertrag, Fixkosten/Kredit, Einnahme) hängen an derselben Kategorieachse; Budgets messen gegen sie, Anbieterprofile füllen sie vor. Ein Vertrag erzeugt seine Fixkostenposition (Planbetrag), eine Rechnung kann einen Vertrag abrechnen – dann zählt im Monat der Ist-Betrag der Rechnung statt des Plans. Neu gegenüber heute sind Termin, ein optionales objectID (Akten-Objekt: Wohnung, Fahrzeug, Ticket, Person …) an Vertrag, Rechnung und Termin sowie `Contract`, `CategoryBudget` und die Kategoriefelder; `Invoice`, `InstallmentPlan`, `IncomeEntry` und `VendorProfile` bleiben und werden additiv erweitert.

## OCR-Symbiose: vom Scan zur Haushaltsbuch-Buchung

Die OCR bleibt, wie sie ist (Dokumenttyp, Anbieter, Betrag, Fälligkeit, IBAN, Rechnungsnummer, Confidence je Feld). Neu ist, was danach passiert: Das Ergebnis wird gegen Anbieterprofil, Verträge und Kategorie aufgelöst, bevor der Nutzer das Review sieht.

1. **Erfassen** – Kamera, PDF, Share-Sheet oder manuell; Dokumenttyp `invoice | receipt | unknown` wie heute.
2. **Anbieter auflösen** – Vendor-Name gegen Anbieterprofile; Treffer liefert Bereich → Unterkategorie, Zahlungsempfänger, Fälligkeits-Offset. Kein Treffer: Händlerliste (Supermarkt-, Drogerie-, Tankstellen-, Energie-, Telekom-Muster) liefert den Bereich; Unterkategorie bleibt Vorschlag mit niedriger Confidence.
3. **Vertrag prüfen** – Gibt es einen aktiven Vertrag mit gleichem Anbieter (oder gleicher Kundennummer/IBAN)? Dann wird die Rechnung als *Vertragsabrechnung* vorgeschlagen: Kostenart fix, Kategorie vom Vertrag, Verknüpfung gesetzt.
4. **Kostenart ableiten** – Kassenbon → variabel, bezahlt; Rechnung ohne Vertrag → variabel, offen; Rechnung mit Vertrag → fix; Schlüsselwörter „Abschlag“, „Beitrag“, „monatlich“, „Jahresbeitrag“, „Vertragsnummer“ erhöhen die Vertragswahrscheinlichkeit und lösen bei fehlendem Vertrag den Vorschlag „Vertrag anlegen?“ aus.
5. **Abweichung melden** – Betrag der Vertragsabrechnung weicht mehr als 5 % vom Planbetrag ab → Hinweis „Beitrag gestiegen/gesunken“ mit Angebot, den Planbetrag zu übernehmen.
6. **Review** – Ein Formular, drei Zeilen oben: Bereich → Unterkategorie (Chip), Kostenart (Segment), Vertrag (Chip oder „keiner“). Darunter wie heute Betrag, Fälligkeit, Empfänger, IBAN. Felder mit Confidence unter Schwelle sind markiert, nie vorbelegt.
7. **Buchen** – Speichern schreibt die Rechnung, aktualisiert das Anbieterprofil (Kategorie, Empfänger, Offset, Vertragsbezug) und, bei Vertragsabrechnung, den Monatswert der Fixkostenposition (Ist ersetzt Plan). Budget-Ist und „Frei verfügbar“ folgen automatisch.

| OCR-Signal | Haushaltsbuch-Wirkung |
| --- | --- |
| Dokumenttyp `receipt` | Kostenart variabel, Status bezahlt, Bereich aus Händlerliste, keine Fälligkeit, erscheint im Budget-Ist des Monats |
| Dokumenttyp `invoice`, kein Vertrag | Kostenart variabel, Status offen, Fälligkeit → „Jetzt handeln“, Betrag mindert „Frei verfügbar“ bis bezahlt |
| `invoice` + Anbieter hat aktiven Vertrag | Vertragsabrechnung: Kostenart fix, Monats-Ist der Fixkostenposition, keine Doppelzählung |
| `invoice` + Jahresbetrag (Versicherung, Kfz-Steuer) | Vorschlag Vertrag mit Intervall jährlich; Planbetrag/12 als monatliche Rücklage im Fixkosten-Reiter |
| Betrag ≠ Planbetrag des Vertrags | Hinweis Beitragsänderung, Ein-Tap-Übernahme |
| IBAN erkannt | Zahlungsempfänger, Vertrags-Matching (zweites Merkmal neben Name) |
| Schlüsselwort „Kündigung“, „Laufzeit bis“, „verlängert sich“ | Vorschlag, Laufzeitende und Kündigungsfrist in den Vertrag zu übernehmen |
| Niedrige Confidence bei Kategorie | Feld leer, Review-Hinweis; nach Korrektur lernt das Anbieterprofil |

Damit hängt der USP „Rechnung rein, Fälligkeit raus“ direkt am Haushaltsbuch: Eine Strom-Jahresabrechnung landet als Wohnen → Strom, verrechnet sich mit dem Abschlagsvertrag, meldet die Nachzahlung als offene Rechnung und korrigiert den Planbetrag fürs nächste Jahr – ohne dass der Nutzer eine Kategorie tippt.

## OCR 2.0: KI auf dem Gerät statt Regelwerk allein

Seit iOS 26 liefert Apple zwei Bausteine, die den heutigen Parser (1.970 Zeilen Heuristik in `ParsingService`) von der Hauptlast befreien – beide laufen ausschließlich auf dem Gerät, ohne Netz, ohne Server. Die Regeln bleiben als Prüfer und als Fallback für ältere Geräte. Vor dem Launch von 2.0.0 ist dieser Umbau Pflicht: Er entscheidet, ob der Kern-USP „Rechnung rein, Fälligkeit raus“ auf echten Dokumenten trägt.

| Stufe | Baustein | Was er liefert | Verfügbar |
| --- | --- | --- | --- |
| 1 – Lesen | [Vision `RecognizeDocumentsRequest`](https://developer.apple.com/documentation/vision/recognizedocumentsrequest.md) | Dokumentstruktur statt Textwolke: Absätze, Zeilen, Tabellen, Listen, Barcodes – für Kassenbons, Formulare, Rechnungen gedacht; ersetzt den eigenen `SpatialParser` | iOS 26+, alle Geräte, die iOS 26 ausführen |
| 2 – Verstehen | [Foundation Models `SystemLanguageModel`](https://developer.apple.com/videos/play/wwdc2026/241/) mit `@Generable`-Schema | Typisierte Extraktion: Dokumenttyp, Anbieter, Zahlungsempfänger, Betrag, Rechnungs- und Fälligkeitsdatum, Rechnungsnummer, IBAN, Kundennummer, Intervall-/Vertragshinweise, Vorschlag Bereich → Unterkategorie (Enum aus unserer Taxonomie); Ausgabe ist schemagebunden, nie freier Text | iOS 26+ auf iPhone 15 Pro und neuer mit aktivierter Apple Intelligence; Deutsch unterstützt; Kontext 4.096 Token (iOS 26), 8.192 (iOS 27) |
| 2b – Sehen | Bild-Eingabe im Prompt, eingebautes `OCRTool` | Bei schwachem Text (zerknitterter Bon, Foto schräg): das zugeschnittene Bild direkt ans Modell; Vision-gestütztes OCR als Tool | iOS 27+ |
| 3 – Prüfen | bestehender `ParsingService`, `LearningService`, `VendorProfile` | Jeden Modellwert gegen den Text prüfen (Betrag muss vorkommen, IBAN-Prüfsumme, Datum plausibel, Summe > Teilbeträge), Anbieterprofil hat Vorrang vor Modellvorschlag; auf Geräten ohne Modell einziger Pfad | heute, iOS 17+ |

**Regeln für den Umbau**

1. **Modell schlägt vor, Regeln entscheiden.** Confidence je Feld entsteht aus Übereinstimmung: Modell und Heuristik einig → hoch, uneinig → Review-Markierung, nur Modell → mittel. Das Modell liefert keine kalibrierte Sicherheit, deshalb nie allein vorbelegen.
2. **Kontext sparen.** Vor dem Prompt schneidet die Heuristik den Text auf Kopf, Summen- und Zahlungsblock; mehrseitige PDFs werden seitenweise verarbeitet. 4.096 Token reichen für eine typische Rechnung, nicht für ein Zehn-Seiten-PDF.
3. **Kein Private Cloud Compute.** iOS 27 bietet das größere Servermodell an – wir nutzen es nicht. Ein Byte Rechnungsdaten auf einem Apple-Server bricht das Versprechen „kein Anbieter-Server“, auch wenn es Apple ist. Entscheidung dokumentieren, Entitlement nicht beantragen.
4. **Verfügbarkeit prüfen, nie voraussetzen.** `SystemLanguageModel.default.availability` beim Start; nicht verfügbar (älteres iPhone, Apple Intelligence aus, Modell lädt noch) → Pfad 3, mit einem Satz in den Einstellungen, warum die Erkennung dort einfacher ist. Deployment-Target bleibt iOS 17; alles Neue hinter `#available(iOS 26, *)`.
5. **Lernen bleibt lokal.** Korrekturen fließen weiter in Anbieterprofile und gelernte Regeln; sie werden dem Modell als Few-Shot-Kontext mitgegeben („Bei diesem Anbieter heißt Fälligkeit ‚zahlbar bis‘“), nicht als Training.
6. **Messen, bevor umgeschaltet wird.** Der OCR-Korpus wächst von 17 auf mindestens 40 Fälle (je 10 Bon, Energie, Versicherung, Telekom/Abo, Onlinehandel, Handwerker, Behörde/Steuer). `make ocr-check` läuft beide Pipelines und berichtet je Feld: Treffer, Fehler, False Positives. Umschalten, wenn das Modell in jedem Feld mindestens gleichauf ist und keinen Betrag oder keine Fälligkeit falsch vorbelegt. Apples neues Evaluations-Framework (WWDC26) kann die Korpusläufe als Testziel ausführen.

**Aufwand:** Stufe 1 und 3 zusammen drei bis vier Tage, Stufe 2 mit Schema, Prompt und Korpusvergleich etwa eine Woche, Stufe 2b zwei Tage. Phase 2 und 3 des alten OCR-Hardening-Plans (Parser modularisieren, Layout-Cluster) entfallen damit weitgehend; was bleibt, ist der Korpusausbau und die Prüfregeln.

## Funktionsliste Release 2.0.0

Stand: eingefroren am 24.10.2026. Muss = ohne das kein 2.0.0; Soll = im Release, wenn die Zeit reicht; Kann = vorgemerkt für 2.1. Ergänzungen aus dem Reiter Navigation & Fälligkeiten stehen unter der Tabelle.

| Modul | Funktion | Prio | Neu / Bestand |
| --- | --- | --- | --- |
| Kategorien | Zweistufige Taxonomie (11 Bereiche, Unterkategorien), Kostenart je Buchung, Migration der 8 Alt-Kategorien beim ersten Start | Muss | neu |
| Kategorien | Eigene Unterkategorien innerhalb eines Bereichs anlegen, umbenennen, ausblenden | Muss | Bestand erweitert |
| Kategorien | Händler-/Anbieterliste (Supermarkt, Drogerie, Tankstelle, Energie, Telekom, Versicherer) für Erstvorschlag ohne Profil | Soll | neu |
| Rechnungen | OCR unverändert + Auflösung gegen Profil, Vertrag, Kategorie (Schritte 2–5) | Muss | neu |
| Rechnungen | Review-Formular mit Bereich/Unterkategorie, Kostenart, Vertrag oben; Confidence-Markierung statt Vorbelegung | Muss | Bestand umgebaut |
| Rechnungen | Vertragsabrechnung: Ist ersetzt Plan im Monat, Hinweis Beitragsänderung | Muss | neu |
| Rechnungen | Liste filterbar nach Bereich, Kostenart, Status; Suche | Soll | Bestand erweitert |
| Verträge & Abos | Objekt `Contract`: Anbieter, Vertragstyp, Unterkategorie, Betrag, Intervall (monatlich/vierteljährlich/jährlich), Beginn, Mindestlaufzeit, Verlängerung, Kündigungsfrist, Kundennummer, IBAN, Notiz, Dokumente | Muss | neu |
| Verträge & Abos | Kündigungswecker: lokale Benachrichtigung 30/14/7 Tage vor letztmöglichem Kündigungstag; Anzeige in „Jetzt handeln“ | Muss | neu |
| Verträge & Abos | Vertrag erzeugt/verknüpft Fixkostenposition; Jahresverträge als monatliche Rücklage | Muss | neu + Bestand |
| Verträge & Abos | Anlegen aus Rechnung („Vertrag anlegen?“) und manuell; Status aktiv/gekündigt/beendet | Muss | neu |
| Verträge & Abos | Kündigungsschreiben als PDF aus Vorlage, teilen per Share-Sheet | Soll | neu |
| Verträge & Abos | Jahreskosten-Übersicht je Vertragstyp, Sortierung nach nächster Kündigungschance | Soll | neu |
| Budgets | Objekt `CategoryBudget`: Bereich oder Unterkategorie, Monatsbetrag, Rollover ja/nein | Muss | neu |
| Budgets | Ist aus Rechnungen, Bons und Vertragsabrechnungen des Monats; Fortschritt, Warnung bei 80 % und 100 % (lokale Notification) | Muss | neu |
| Budgets | Budget-Vorschläge aus eigenen Vormonaten (Median 3 Monate) und Destatis-Anteilen als Startwert | Soll | neu |
| Budgets | Budget-Historie (6 Monate Balken je Bereich) | Kann | neu |
| Startseite | Monatskopf mit „Frei verfügbar“, drei Kacheln, „Jetzt handeln“, Budgets, 4-Wochen-Liquidität, Schnellaktionen (Detail siehe Design-Phase) | Muss | neu |
| Ausgaben | Reiter Fixkosten und Kredite wie heute, dritter Reiter Verträge; Fixkostenpositionen zeigen verknüpften Vertrag und Monats-Ist | Muss | Bestand erweitert |
| Einnahmen | Unterkategorien für Einnahmen (Gehalt, Kindergeld …), sonst unverändert | Soll | Bestand erweitert |
| Auswertung | Auswertung nach Bereich und Unterkategorie, Kostenart-Split fix/variabel/Kredit, Monatsvergleich | Muss | Bestand umgebaut |
| Auswertung | Sankey Einnahmen → Bereiche | Kann | neu |
| Export | CSV/Excel-Export mit Bereich, Unterkategorie, Kostenart, Vertrag; Backup-Schema um neue Objekte erweitert | Muss | Bestand erweitert |
| OCR | Phase 2: ReceiptParser/InvoiceParser getrennt, Confidence je Feld, negative Regeln; Korpus auf 40 Fälle | Muss | Bestand |
| OCR | Phase 3: Layout-Cluster (Energie, Versicherung, Telekom, Onlinehandel), Vertragsschlüsselwörter, Regression im CI | Soll | Bestand |
| Daten | Additive Schema-Änderungen, Migration der Kategorien testbar, Backup/Restore N-1 → N mit neuen Objekten | Muss | Pflicht laut Checkliste |

**Ergänzungen beim Einfrieren (24.10.2026), alle Muss:**

- Tab **Akten** mit Gebäude, Mobilität, Haushalt; je Akte Objekte (Gebäude: Wohnung, Haus, Garage, eigene · Mobilität: KFZ, ÖPNV, eigene · Haushalt: Personen, Haustier, eigene) als Unter-Akten mit gleichem Aufbau: Kopfzahlen → Termine (30 Tage) → Verträge → Rechnungen → Dokumente → Liquidität.
- Optionales Feld `objectID` an Rechnung, Vertrag und Termin; Tabs Rechnungen und Verträge & Abos bleiben die Gesamtlisten, die Akte filtert.
- Objekt **Termin** mit Vorlagen je Objekttyp, Wiederholung, Planbetrag, Erledigen erzeugt Folgetermin und optional Rechnung; Benachrichtigung je Art.
- Screen **Liquidität** (Bank-Icon) mit Reitern Termine (14-Tage-Liste + Monatskalender) und Verlauf (8-Wochen-Saldo aus Einnahmen, Verträgen, Rechnungen, Terminen), Filter nach Akte und Objekt; Button auf Start, in jeder Akte, in Verträge & Abos und unter Mehr. Die bisherige Liquiditätsplanung in der Auswertung geht darin auf.
- Tab-Leiste final: Start · Rechnungen · Akten · Verträge & Abos · Mehr (Einnahmen, Budgets, Auswertung, Einstellungen).

* **Dokumente (Muss, ergänzt 24.10.):** (1) Original behalten – importierte PDFs werden als Datei gespeichert (heute wird nur der Text extrahiert und die PDF verworfen), Fotos bleiben JPG; `imageFileName` wird zu `documentFileName` + Typ, additiv. (2) Kamera-Scan mit Zuschnitt und Entzerrung (VisionKit `VNDocumentCameraViewController`) statt Rohfoto. (3) Backup als ZIP mit JSON und allen Dokumenten, Wiederherstellung inklusive – heute sichert die JSON nur Dateinamen, Bilder gehen beim Gerätewechsel verloren. Dokumente ohne Betrag (Police, Fahrzeugschein, Leasingvertrag) sind dasselbe Objekt mit Typ „Dokument“ und optionalem Ablaufdatum (= Termin); bewusst ohne Ordnerhierarchie, Volltextsuche und Teilen.
* **OCR 2.0 (Muss vor Launch):** Umbau auf Vision-Dokumentenerkennung + Foundation Models auf dem Gerät, Heuristik als Prüfer und Fallback – ersetzt die Zeilen „OCR Phase 2/3“ in der Tabelle; Details im Abschnitt OCR 2.0.

- **Rücklagen (Muss, ergänzt 24.10.; liegen im jeweiligen Bereich Wohnen / Mobilität / Haushalt, nicht auf der Übersicht):** `Objekt Ruecklage mit zwei Arten` – *Rücklage* (Pflicht: entsteht automatisch aus Jahres- und Quartalsverträgen, Rate = Betrag / Monate bis Fälligkeit) und *Sparziel* (Wunsch: Zielbetrag + Zieldatum → Monatsrate, z. B. Urlaub 1.800 € bis 15.07. → 200 €/Monat). Felder: Name, Art, Zielbetrag, Zieldatum, Monatsrate, Stand, optional Vertrag und Ordner. Monatsraten mindern den Spielraum (Stufe „Monatsanfang · Plan“, Zeile „Rücklagen-Raten“) und zählen zum Gesparten; in der Liquidität erscheinen sie als „davon reserviert“, nicht als Abfluss. Vertragsabrechnung einer Jahresrechnung entnimmt aus der Rücklage statt den Monat zu belasten. Vorbild: YNAB Targets, Goodbudget, MoneyStats Sparziele – virtuell, ohne Konto.
- **Haushaltskasse (Soll, Ein-Geräte-Variante):** *Rücklagen-Art Kasse* mit Einzahlungen je Person (Objekte im Ordner Haushalt), Entnahmen, Saldo je Person; Bons können „aus der Kasse“ gebucht werden; PDF-Export der Abrechnung. Vorbild Tricount/Splid, nur auf einem Gerät. Eintragen durch mehrere Personen auf eigenen Telefonen erst mit dem Teilen in 2.1.

## Von Marktführern übernommene Erweiterungen

Jede Übernahme wird lokal umgesetzt – das Vorbild braucht dafür Kontodaten oder einen Server, Mnemor nimmt das Dokument.

| Erweiterung | Vorbild | Umsetzung in Mnemor | Prio |
| --- | --- | --- | --- |
| Gruppe → Kategorie mit Icon und Farbe je Gruppe | Monarch, Finanzfluss Copilot | 11 Bereiche mit festem SF-Symbol und Farbe; Unterkategorien erben | Muss |
| Vertragsordner mit Monatskosten, nächster Abbuchung, Kündigungsfrist | Finanzguru | `Contract` aus Rechnung oder manuell; nächste Abbuchung aus Intervall und Zahltag | Muss |
| Kündigen aus der App (Finanzguru per Fax-PDF) | Finanzguru, Rocket Money | Kündigungsschreiben als PDF aus Vorlage, Versand per Mail/Share-Sheet; kein Dienstleister dazwischen | Soll |
| „Left to spend“ / „In my pocket“ als Kopfzahl | Copilot, PocketGuard | „Frei verfügbar“ nach der Formel im Objektmodell, inkl. Kredite | Muss |
| Warnung bei gestiegener Lastschrift | Snoop | Vergleich Rechnungsbetrag vs. Planbetrag der Vertragsabrechnung, Hinweis mit Übernahme | Muss |
| Warnung vor auslaufender Gratisphase / Verlängerung | Snoop, Rocket Money | Kündigungswecker auf Basis Mindestlaufzeit + Frist; Probe-Abos als Vertrag mit Enddatum | Muss |
| Bills = feste Verpflichtungen als eigene Sicht | YNAB | Kostenart-Filter fix/variabel/Kredit in Auswertung und Rechnungsliste | Muss |
| Kategorie-Vorlagen je Lebenslage | YNAB | Onboarding-Vorlagen: Single zur Miete, Familie, Wohneigentum, Rentner – blenden Unterkategorien ein/aus | Soll |
| Multi-Kategorie-Budget und Budget-Historie | MoneyStats | Budget auf Bereich (= mehrere Unterkategorien) und Historie-Balken | Muss / Kann |
| Jahresposten monatlich zurücklegen | Verbraucherzentrale | Jahresverträge erzeugen Rücklage/12 im Fixkosten-Reiter; Rücklagenstand sichtbar | Muss |
| Budget-Vorschlag aus Referenzwerten | PocketGuard (Pace), Destatis-Anteile | Startwerte aus eigenen 3 Vormonaten, sonst Destatis-Anteil × Einnahmen | Soll |
| Sankey Einnahmen → Ausgaben | Finanzfluss Copilot | Auswertung, ein Monat, lokal gerendert mit Swift Charts | Kann |
| Haushalt teilen | Monarch, YNAB, Honeydue, MoneyStats | nicht in 2.0.0; Vorbereitung: alle neuen Objekte mit UUID und `updatedAt`, damit CloudKit-Sharing in 2.1 ohne Migration möglich ist | Kann (Vorbereitung Muss) |

Wo Akten (Gebäude, KFZ, Haushalt), Fälligkeiten und Liquidität in der Navigation sitzen: Navigation & Fälligkeiten

## Glossar (Stand 25.10.2026)

Ein Wort je Begriff – in Code (Enum-Namen, Strings), Store-Text, Hilfe und Benachrichtigungen identisch. Änderungen nur hier.

| Begriff in der App | Bedeutung | Nicht mehr verwenden |
| --- | --- | --- |
| Übersicht | Startseite (Tab 1) | Start, Haushalt, Dashboard |
| Spielraum | Plan am Monatsanfang: Einnahmen − Fixkosten & Kredite − Rücklagen-Raten; steht fest, sobald die Verträge stehen | Budget (als Gesamtzahl), Verfügbares Einkommen |
| Noch frei im ‹Monat› | Kopfzahl der Übersicht: Spielraum − Ausgegeben (bezahlte Bons und Rechnungen sowie offene Rechnungen ab Fälligkeit) − in Budgets reserviert; Monatsrechnung ohne Kontobezug | Sparpotenzial, Frei verfügbar, Verfügbar bis Monatsende |
| Ausgegeben | variable Ausgaben des Monats, bezahlt + offen | Ausgaben des Monats, variabel |
| Reserviert | je Budget: Budget − Ausgegeben, nie unter 0; Summe mindert Noch frei, bis das Geld ausgegeben ist oder der Monat endet | Budgets offen, Rest |
| Sparen / Rücklagen-Raten | zweite Verwendung des Einkommens neben Ausgeben; mindert den Spielraum, zählt zum Gesparten | Ausgabe, Kosten |
| Überschuss | Noch frei am Monatsende; kann in eine Rücklage übertragen werden | Sparpotenzial, Ergebnis |
| Gespart | Rücklagen-Raten + Überschuss; Sparquote = Gespart ÷ Einnahmen | Sparrate |
| Fällig | Block auf der Übersicht: überfällige und in 7 Tagen fällige Posten als Datumszeilen (max. 4); Kopfzeile „1 überfällig · 3 in 7 Tagen“ | Als Nächstes, Jetzt handeln |
| Ordner | veraltet – siehe Ergänzung unter der Tabelle: ohne Überschrift, Tab-Name offen | Akten, Akte, Bereiche (als UI-Wort) |
| Wohnen | Ordner und Bereich für Wohnung, Haus, Garage, eigene Objekte | Gebäude |
| Mobilität | Ordner und Bereich für KFZ, ÖPNV, eigene Objekte | KFZ (nur noch als Objekttyp) |
| Haushalt | Ordner für alle übrigen Bereiche; Objekte optional Personen, Haustier, eigene | – |
| Rechnungen | Tab 2: alle Rechnungen und Bons | Belege, Posteingang |
| Erfassen | Tab 3 (Kamera): Scan, PDF, manuell | Scannen, Rechnung erfassen (als Tab-Titel) |
| Verträge | Tab 5: alle Verträge und Abos | Verträge & Abos (nur in Überschriften) |
| Liquidität | eigener Screen mit Bank-Icon: Termine und Verlauf; nur dort erscheint der Kontostand | Bank, Kontoblick, Liquiditätsplanung |
| Termin | Objekt für HU, Wartung, Zählerstand u. ä. | Erinnerung, Aufgabe |
| Statuszeilen | Fakten, nicht Urteile: „Nachzahlung Strom überfällig“, „Budget Freizeit überschritten“, „HU am 12. Nov.“; im Budget selbst steht der Betrag „30,00 € über Budget“ | Bewertungen |
| Mehr | Zahnrad/… oben rechts: Einnahmen, Budgets, Auswertung, Einstellungen | Einstellungen als Tab |

**Ergänzt 24.10.: Rücklage = virtueller Geldtopf mit den Arten Vertrag (aus Jahresverträgen), Sparziel (z. B. Urlaubskasse) und Kasse (Haushaltskasse); liegt im jeweiligen Bereich, nicht auf der Übersicht. Nicht verwenden: Topf, Space, Pot, Umschlag. Die drei Bereiche stehen auf der Übersicht ohne Überschrift; „Ordner“ und „Akte“ entfallen als UI-Wörter, die Tab-Bezeichnung ist offen (vorläufig „Bereiche“).**

Im Reiter Navigation & Fälligkeiten stehen „Akte“ und „Gebäude“ noch in der Konzeptsprache; die Begriffe dort gelten als Ordner bzw. Wohnen.

## Monatsrechnung: drei Stufen, Regeln für Budgets und Rücklagen (ergänzt 25.10.)

Abgeleitet aus Finanzguru („frei verfügbares Einkommen“, Sparen als eigene Position), Monarch (Einkommen wird auf Spending und Saving verteilt; Töpfe Fixed / Non-monthly / Flexible), YNAB (Budgets als Umschläge, Überschreitung rot, nie negativ) und Emma („Left to spend = Budget − Committed − Past Spending“).

```
MONATSANFANG · Plan (steht fest)
  Einnahmen                         3.650,00
  − Fixkosten & Kredite            −1.659,20
  − Rücklagen-Raten (Sparen)         −326,10
  = Spielraum (variabel)            1.664,70

IM MONAT · läuft
  Spielraum                         1.664,70
  − Ausgegeben (bezahlt + offen)   −1.010,60
  − In Budgets reserviert              −61,40
  = Noch frei                         592,70   ← Kopfzahl der Übersicht

MONATSENDE · voraussichtlich
  Gespart = Rücklagen 326,10 + Überschuss 592,70 = 918,80 · Sparquote 25 %
```

**Budgets** sind Umschläge innerhalb des Spielraums, kein Abzug von den Einnahmen. *Reserviert* = Budget − Ausgegeben, nie unter 0; es wird abgezogen, weil das Geld bis Monatsende noch rausgeht, und ist am Monatsende automatisch 0. **Überschreitung** (Freizeit 180/150): die 30 € stehen bereits unter *Ausgegeben*, reserviert wird 0, die Kategorie zeigt rot „30,00 € über Budget“; der Spielraum ändert sich nicht, nur *Noch frei* sinkt über die echten Ausgaben. Angeboten werden „Budget anheben“ und „aus ‹anderem Budget› decken“ (verschiebt Budget, Gesamtsumme bleibt). Fixkosten haben kein Budget.

**Rücklagen-Raten** sind Sparen mit Zweck – die zweite Verwendung des Einkommens, keine Ausgabe. Sie mindern den Spielraum und zählen zum Gesparten. Die Verwendung einer Rücklage (HUK 487,20 am 27.10.) belastet den Monat nicht, nur den Kontostand in der Liquidität. Was am Monatsende frei bleibt, ist der *Überschuss* und kann in eine Rücklage übertragen werden.

**Anzeige:** Übersicht = Kopfzahl *Noch frei* + Balkenpaar (Einnahmen voll; Verwendung: Fixkosten dunkel · Sparen grün · Ausgegeben blau · Reserviert hell · Lücke = Noch frei) + Legende mit genau diesen fünf Wörtern. Die drei Stufen stehen in der Monatsrechnung; die Regeln für Budgets im Budgets-Screen.

## Design-Stand und Beispielmonat

Alle Module sind als klickbare Screens in [Mnemor 2.0 – App-Screens](https://claude.ai/artifact/ACDyBU4mp3qL8kMp6PbWxZ) durchgespielt (25 Screens, jeder Tipp führt weiter, die Tab-Leiste bringt immer zur Übersicht). Alle Zahlen stammen aus einem Beispielmonat Oktober 2026, der in jedem Modul dieselbe Summe ergibt:

| Größe | Betrag (€) | Herleitung |
| --- | --- | --- |
| Einnahmen | 3.650,00 | Gehalt 3.400 (30.) + Kindergeld 250 (5.) |
| Fixkosten & Kredite | 1.659,20 | Wohnen 1.218,35 + Mobilität 356,99 + Haushalt 83,86 |
| Ausgaben des Monats | 1.010,60 | bezahlt 656,20 + offen 354,40 (Stadtwerke 142 überfällig, Inspektion 212,40) |
| In Budgets reserviert | 61,40 | Lebensmittel 38,00 + Mobilität variabel 23,40; Freizeit überschritten → 0 |
| Rücklagen-Raten | 326,10 | Urlaub 200 + HU/Reifen 60 + Kfz-Vers. 40,60 + Kfz-Steuer 12 + Hausrat 7,83 + Haftpflicht 5,67 |
| Spielraum | 1.664,70 | 3.650,00 − 1.659,20 − 326,10 |
| Noch frei | 592,70 | 1.664,70 − 1.010,60 − 61,40 |
| Gespart | 918,80 | 326,10 + 592,70 · Sparquote 25 % |
| Summe der Bereiche | 2.995,90 | Wohnen 1.368,18 + Mobilität 746,19 + Haushalt 881,53 = Fixkosten + Ausgaben + Rücklagen |
| Verträge | 1.713,30 / Monat | 16 Verträge = Fixkosten 1.659,20 + Vertrags-Rücklagen 54,10 |
| Liquidität | 1.767,81 tiefster Stand | Kontostand 2.410 − 142 − 487,20 (27.) − 12,99 (29.); Gehalt am 30. |

Regel für jede Bereichsseite: Bereichssumme = fix + variabel + Rücklagen-Raten, mit Prüfsumme unter der Liste. Offene Rechnungen zählen ab Fälligkeit im Monat zu den Ausgaben, nicht erst bei Zahlung.

## Offene Entscheidungen und Quellen

- [ ] Kfz- und Gebäudeversicherung im Lebensbereich (Mobilität, Wohnen) oder alle Versicherungen unter „Versicherung & Vorsorge“? Vorschlag: Bereich, Vertragstyp Versicherung erlaubt die Quersicht.
- [ ] Budget auf Bereich (einfach, 11 Regler) oder auch auf Unterkategorie (feiner, mehr Pflege)? Vorschlag: beides, Unterkategorie optional.
- [ ] Zählen offene Budgets in „Frei verfügbar“ (konservativ) oder nur reale Posten? Vorschlag: Schalter in Einstellungen, Standard konservativ.
- [ ] Alt-Kategorie „Abos“: alle bestehenden Rechnungen automatisch nach Streaming oder Einzelprüfung beim ersten Start (Liste zum Durchtippen)?
- [ ] Vertragstyp-Liste final (8 Typen) und Standard-Kündigungsfristen je Typ (z. B. Versicherung 3 Monate zum Ablauf, Telekom 1 Monat nach Mindestlaufzeit).
- [ ] Onboarding-Vorlagen in 2.0.0 oder 2.1?

Quellen (geöffnet am 24.10.2026):

- [Monarch – Default Categories](https://help.monarch.com/hc/en-us/articles/360048883851)
- [YNAB – Category Templates](https://support.ynab.com/en_us/category-templates-HknjS_RA.md)
- [neuebanken.de – Finanzguru Test](https://www.neuebanken.de/finanzguru-test/)
- [finAPI – Categorization](https://www.finapi.io/en/products/data-intelligence/categorization/)
- [Finanzfluss Copilot – Hilfe Kategorien](https://www.finanzfluss.de/copilot/hilfe/kategorien/)
- [MoneyStats – App Store](https://apps.apple.com/de/app/haushaltsbuch-moneystats/id1249678565)
- [Verbraucherzentrale NRW – Haushaltsbuch führen](https://www.verbraucherzentrale.nrw/wissen/geld-versicherungen/kredit-schulden-insolvenz/haushaltsbuch-fuehren-ueberblick-ueber-ihre-finanzen-52179)
- [Lebensmittel Praxis – Destatis Konsumausgaben 2024](https://lebensmittelpraxis.de/handel-aktuell/49585-konsumausgaben-2024-deutsche-haushalte-geben-mehr-geld-fuer-freizeit-aus.html)
- Marktvergleich Haushaltsbuch-Apps & USPs Mnemor 2.0 (Dokument vom 24.10.2026)
