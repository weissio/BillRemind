# Darstellungsarchitektur 2.0.0 – welche Funktion wie angezeigt wird

Stand 25.10.2026. Die Funktionen stehen (siehe `funktionsmodell.md`). Dieses Dokument legt fest, **welche Frage** eine Funktion beantwortet, **welche Datenform** dahintersteckt und **welches Anzeigemuster** daraus folgt – abgeleitet aus dem, was sich in Finanzguru, Outbank/Finanzblick, YNAB, Copilot, Monarch, Buddy, Bobby/Abo-Manager und Money Manager bewährt hat. Regel: ein Muster je Datenform, keine Formeltexte, Zahlen stehen rechts, Text höchstens zwei Zeilen.

## Muster-Katalog

| Muster | Wofür | Vorbild |
| --- | --- | --- |
| **Kopfzahl** – eine Zahl, ein Label, eine Kontextzeile | Status des Monats | Finanzguru „Verfügbar bis Monatsende", YNAB „Ready to Assign" |
| **Balkenpaar** – Einnahmen voll; Verwendung segmentiert (Fixkosten · Sparen · Ausgegeben · Reserviert), Lücke = Noch frei | Zusammensetzung ohne Formel | Finanzguru „Dein Monat", Monarch Cash Flow |
| **Anteilszeile** – Icon, Name, dünner Anteilsbalken, Betrag rechts, Hinweis nur bei Abweichung | 3–6 Summen nebeneinander | Copilot Categories, Monarch Budget |
| **Datumszeile** – Tag/Monat als Block links, Name + Kategorie, Betrag + Status rechts | alles mit Fälligkeit | Rocket Money Upcoming, Bobby, Money Manager |
| **Fortschrittsbalken** – Soll/Ist, „noch x €" | Budgets, Rücklagen | YNAB, Buddy, Spendee |
| **Gruppenliste** – Rhythmusgruppen, Betrag je Monat rechts, Countdown-Chips für Kündbares | Verträge | Bobby, Finanzguru Verträge |
| **Zeitstrahl mit Saldo** – Tage als Gruppen, „Kontostand danach" je Tag, Horizont-Chips | Liquidität | Copilot Upcoming, Outbank Prognose |
| **Treppenlinie** – Verlauf mit Pufferlinie, Tiefpunkt markiert | Liquidität über Zeit | Monarch Net Worth, Finanzguru Prognose |
| **Monatssäulen + Balkenliste** – Säulen je Monat, Kategorien absteigend als Balken | Auswertung | Copilot Spending, Money Manager Stats |
| **Kalender mit Punkten** – Monatsraster, Punkte je Bereich, Tagesliste darunter | Termine | Money Manager Calendar, Apple Kalender |
| **Zentrale Aktion** – Kamera in der Tab-Mitte, Sheet mit drei Wegen | Erfassen | Finanzguru, Revolut |

## Funktion → Frage → Datenform → Muster → Screen

| Funktion | Frage des Nutzers | Datenform | Muster | Screen |
| --- | --- | --- | --- | --- |
| Noch frei | Wie stehe ich diesen Monat? | 1 Zahl | Kopfzahl, Kontext „von 1.664,70 € Spielraum · 354,40 € davon noch offen" | Übersicht (Kopf) |
| Monatsrechnung | Wo bleibt das Geld? | 3 Stufen: Plan → im Monat → Monatsende | Balkenpaar mit Legende; drei Blöcke mit Zwischensummen einen Tap tiefer | Übersicht → Monatsrechnung |
| Bereiche | Welcher Lebensbereich kostet wie viel? | 3 Summen | Anteilszeilen, Hinweis nur bei Abweichung | Übersicht → Bereich |
| Fällig | Was muss ich jetzt tun? | 0–n Posten mit Datum | Datumszeilen (max. 4), Rest in Rechnungen | Übersicht → Rechnungen |
| Rechnungen & Bons | Was ist offen, was bezahlt? | n Belege mit Datum/Status | Datumszeilen, gruppiert Überfällig / Diese Woche / Später / Bezahlt | Rechnungen |
| Kategorien je Bereich | Was steckt in Wohnen? | n Kategorien mit Betrag | Zeilen mit Betrag, Objekt-Chips oben, Prüfsumme unten | Bereich |
| Budgets | Wie viel darf ich noch ausgeben? | n Soll/Ist | Fortschrittsbalken, „noch x €" bzw. „x € über Budget" | Budgets, Bereich |
| Rücklagen & Sparziele | Bin ich auf Kurs? | n Soll/Ist mit Zieldatum | Fortschrittsbalken + Rate/Monat, Zieldatum | Bereich, Rücklage |
| Verträge | Was läuft laufend, was ist kündbar? | n Verträge mit Rhythmus | Gruppenliste; Kündbares als Countdown oben | Verträge, Vertrag |
| Termine | Wann passiert was? | Ereignisse | Kalender mit Punkten + Tagesliste; im Bereich als Zeilen | Kalender, Bereich |
| Liquidität | Reicht das Geld bis …? | Kontostand + Zeitreihe | Kopfzahl + Zeitstrahl mit Saldo; Verlauf als Treppenlinie | Liquidität, Verlauf |
| Kontostand | Stimmt die Planung mit der Bank? | 1 Eingabe + Abgleichliste | Betragseingabe, Abgleich mit ✓/✕, Differenz | Kontostand |
| Erfassen | Schnell rein | Aktion | Zentrale Aktion, drei Wege (Scan / PDF / manuell), Prüfscreen mit Feldsicherheit | Erfassen, Rechnung prüfen |
| Auswertung | Wie entwickelt sich das? | Zeitreihe je Monat, Kategorien | Monatssäulen + Balkenliste; Jahresblick als Kennzahlen | Auswertung |
| Haushaltskasse | Wo ist das Bargeld? | Einzahlungen/Entnahmen | Zeilen je Person, Bons als Datumszeilen | Haushaltskasse |

## Was daraus für die Startseite folgt

Die Startseite hat genau drei Blöcke – Kopfzahl mit Balkenpaar, drei Anteilszeilen, bis zu vier Datumszeilen – und sonst nichts. Kein Formeltext, keine Prüfsummen, keine Wisch-Karten. Alles Weitere liegt einen Tap tiefer: Monatsrechnung (Einzelposten), Bereich (Kategorien), Rechnungen (alle Fälligkeiten).

## Regeln für alle Screens

- Zahlen rechts, tabellarische Ziffern, Vorzeichen nur bei Abflüssen in gemischten Listen.
- Name eine Zeile (Ellipse), Untertitel eine Zeile; eine zweite Zeile nur als bewusst gesetzte eigene Zeile.
- Warnfarbe (Rot) nur für Überfälliges und Budgetüberschreitung; Bernstein für „bald"; Grün für Einnahmen und Erledigtes.
- Hinweise unter Listen nur dort, wo gerechnet wird (Prüfsumme im Bereich, Herleitung in der Monatsrechnung).
