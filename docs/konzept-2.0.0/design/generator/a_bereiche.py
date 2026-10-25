# -*- coding: utf-8 -*-
"""Übersicht + die drei Bereichsseiten (Wohnen, Mobilität, Haushalt) – Chips filtern, Summen rechnen live."""
from common import *

def bereich(fname, title, color, icon, name, objects, rows, reserves, termine, neu_hint, back_label="Übersicht"):
    """objects: [(id,label)], rows: dicts name, sub, warn, fix, var, res, obj, href; reserves: dicts name, sub, val, obj; termine: dicts name, sub, obj."""
    rows_js = json.dumps(rows, ensure_ascii=False)
    res_js = json.dumps(reserves, ensure_ascii=False)
    ter_js = json.dumps(termine, ensure_ascii=False)
    objs_js = json.dumps([["all", "Alle"]] + [list(o) for o in objects], ensure_ascii=False)
    body = f'''  <div class="hdr" style="padding-bottom: 24px">
    <div style="display: flex; align-items: center; justify-content: space-between">
      <a class="back" href="Main.dc.html">{BACK}{back_label}</a>
      <p class="ttl">Oktober 2026</p>
      <a href="Liquiditaet.dc.html" aria-label="Liquidität {name}" style="width: 34px; height: 34px; border-radius: 17px; background: rgba(255,255,255,.14); color: #FFFFFF; display: inline-flex; align-items: center; justify-content: center; text-decoration: none">{BANK}</a>
    </div>
    <div style="display: flex; align-items: center; gap: 12px; margin-top: 18px">
      <span style="width: 44px; height: 44px; border-radius: 22px; background: {color}; display: inline-flex; align-items: center; justify-content: center; flex: none; color: #FFFFFF">{icon}</span>
      <div>
        <h1 style="margin: 0; font-size: 28px; font-weight: 700; letter-spacing: -0.5px; line-height: 1.1">{name}</h1>
        <p style="margin: 3px 0 0; font-size: 13px; opacity: .8">{{{{sub}}}}</p>
      </div>
    </div>
    {chips("objChips", '<a class="chip" href="ObjektNeu.dc.html" aria-label="Objekt hinzufügen">+</a>')}
  </div>

  <div style="padding: 20px 20px 0 20px">
    <h2 class="h2">Kategorien <span>{{{{objLabel}}}} · {{{{total}}}} €</span></h2>
    <div class="card">
      <sc-for list="{{{{rows}}}}" as="r" hint-placeholder-count="6">
        <a class="row" href="{{{{r.href}}}}"><div class="mid"><p class="n" style="font-weight: 500; font-size: 16px">{{{{r.name}}}}</p><p class="s"><sc-if value="{{{{r.warn}}}}" hint-placeholder-val="{{{{false}}}}"><span style="color: #943333">{{{{r.warn}}}}</span> · </sc-if>{{{{r.sub}}}}</p></div><p class="{{{{r.vcls}}}}">{{{{r.val}}}}</p>{CHEV}</a>
        <div class="sep"></div>
      </sc-for>
      <a class="row" href="KategorieNeu.dc.html"><div class="mid"><p class="n" style="color: #2A5480">+ Kategorie anlegen</p><p class="s">{neu_hint}</p></div>{CHEV}</a>
    </div>
    <sc-if value="{{{{empty}}}}" hint-placeholder-val="{{{{false}}}}"><p class="note">Für dieses Objekt gibt es im Oktober keine Buchungen.</p></sc-if>
  </div>

  <sc-if value="{{{{hasRes}}}}" hint-placeholder-val="{{{{true}}}}">
  <div style="padding: 20px 20px 0 20px">
    <h2 class="h2">Rücklagen <span>in den Kategorien enthalten</span></h2>
    <div class="card">
      <sc-for list="{{{{res}}}}" as="x" hint-placeholder-count="2">
        <a class="row" href="Ruecklage.dc.html"><div class="mid"><p class="n" style="font-weight: 500; font-size: 16px">{{{{x.name}}}}</p><p class="s">{{{{x.sub}}}}</p></div><p class="v" style="{{{{x.vst}}}}">{{{{x.val}}}}</p>{CHEV}</a>
        <div class="sep"></div>
      </sc-for>
      <a class="row" href="Ruecklage.dc.html"><div class="mid"><p class="n" style="color: #2A5480">+ Rücklage oder Sparziel</p></div>{CHEV}</a>
    </div>
  </div>
  </sc-if>

  <sc-if value="{{{{hasTer}}}}" hint-placeholder-val="{{{{true}}}}">
  <div style="padding: 20px 20px 0 20px">
    <h2 class="h2">Termine</h2>
    <div class="card">
      <sc-for list="{{{{ter}}}}" as="t" hint-placeholder-count="1">
        <a class="row" href="Termin.dc.html"><div class="mid"><p class="n" style="font-weight: 500; font-size: 16px">{{{{t.name}}}}</p><p class="s">{{{{t.sub}}}}</p></div><p class="v m">{{{{t.val}}}}</p>{CHEV}</a>
        <div class="sep"></div>
      </sc-for>
      <a class="row" href="Termin.dc.html"><div class="mid"><p class="n" style="color: #2A5480">+ Termin</p></div>{CHEV}</a>
    </div>
  </div>
  </sc-if>
  <p class="note" style="margin: 10px 24px 0">{{{{pruef}}}}</p>
'''
    logic = f'''  constructor(p) {{ super(p); this.state = {{ obj: 'all', toast: '' }}; this.ROWS = {rows_js}; this.RES = {res_js}; this.TER = {ter_js}; this.OBJS = {objs_js}; }}
{JS_SEG}
  renderVals() {{
    var self = this, o = this.state.obj;
    var keep = function (x) {{ return o === 'all' || x.obj === o || x.obj === 'all'; }};
    var rows = this.ROWS.filter(keep), fix = 0, vr = 0, rs = 0;
    rows.forEach(function (r) {{ fix += r.fix; vr += r.var; rs += r.res; }});
    var total = fix + vr + rs;
    var objLabel = (this.OBJS.filter(function (x) {{ return x[0] === o; }})[0] || ['', 'Alle'])[1];
    return {{
      toast: this.state.toast,
      objChips: this.chipItems('obj', this.OBJS),
      objLabel: objLabel,
      sub: eur(total) + ' € im Oktober · fix ' + eur(fix) + ' · variabel ' + eur(vr) + ' · Rücklagen ' + eur(rs),
      total: eur(total),
      empty: rows.length === 0,
      rows: rows.map(function (r) {{ var t = r.fix + r.var + r.res; return {{ name: r.name, sub: r.sub, warn: r.warn || '', href: r.href || 'Kategorie.dc.html', val: eur(t), vcls: (r.fix + r.var) > 0 ? 'v' : 'v m' }}; }}),
      res: this.RES.filter(keep).map(function (x) {{ return {{ name: x.name, sub: x.sub, val: x.val, vst: x.ok ? 'color: #215F33' : '' }}; }}),
      hasRes: this.RES.filter(keep).length > 0,
      ter: this.TER.filter(keep).map(function (t) {{ return {{ name: t.name, sub: t.sub, val: t.val || '–' }}; }}),
      hasTer: this.TER.filter(keep).length > 0,
      pruef: 'Prüfsumme ' + objLabel + ': fix ' + eur(fix) + ' + variabel ' + eur(vr) + ' + Rücklagen-Raten ' + eur(rs) + ' = ' + eur(total) + ' €' + (o === 'all' ? '' : ' · gemeinsame Posten nur unter „Alle“')
    }};
  }}'''
    page(fname, title, body, logic, 'u')


def build():
    # ---------------- Wohnen
    bereich("Wohnen.dc.html", "Wohnen (Bereich)", W, ICON["home"], "Wohnen",
        [("whg", "Wohnung Hauptstr. 12")],
        [
            dict(name="Miete / Hausgeld", sub="fix · 1. Okt.", fix=950, var=0, res=0, obj="whg"),
            dict(name="Strom", sub="98,00 Abschlag", warn="142,00 Nachzahlung überfällig", fix=98, var=142, res=0, obj="whg"),
            dict(name="Gas / Heizung", sub="Abschlag · 1. Okt.", fix=112, var=0, res=0, obj="whg"),
            dict(name="Internet & Festnetz", sub="fix · Telekom · 1. Okt.", fix=39.99, var=0, res=0, obj="whg"),
            dict(name="Rundfunkbeitrag", sub="fix · 55,08 vierteljährlich · Monatsanteil", fix=18.36, var=0, res=0, obj="whg", href="Vertrag.dc.html"),
            dict(name="Wasser / Abfall", sub="in den Nebenkosten enthalten", fix=0, var=0, res=0, obj="whg"),
            dict(name="Instandhaltung & Reparatur", sub="variabel · kein Budget", fix=0, var=0, res=0, obj="whg"),
            dict(name="Hausratversicherung", sub="Rücklage-Rate · 94,00 jährlich", fix=0, var=0, res=7.83, obj="whg"),
        ],
        [dict(name="Hausratversicherung", sub="94,00 bis 1. März · 7,83/Monat", val="62,64 / 94,00", obj="whg")],
        [dict(name="Zählerstände Strom und Gas", sub="Di 15. Dez. · jährlich", obj="whg")],
        "Grundsteuer, Gebäudeversicherung, Schornsteinfeger, Garten …")

    # ---------------- Mobilität
    bereich("Akte.dc.html", "Mobilität (Bereich)", M, ICON["car"], "Mobilität",
        [("vw", "VW ID.3"), ("ticket", "Deutschlandticket")],
        [
            dict(name="Kfz-Rate / Leasing", sub="fix · 1. Okt.", fix=289, var=0, res=0, obj="vw"),
            dict(name="Werkstatt & Reifen", sub="60,00 Rücklage HU/Reifen", warn="Inspektion 212,40 offen · fällig 30. Okt.", fix=0, var=212.40, res=60, obj="vw"),
            dict(name="Kraftstoff / Laden", sub="9,99 Ladetarif fix · 64,20 geladen", fix=9.99, var=64.20, res=0, obj="vw"),
            dict(name="ÖPNV / Deutschlandticket", sub="fix · 3. Okt.", fix=58, var=0, res=0, obj="ticket"),
            dict(name="Kfz-Versicherung", sub="Rücklage-Rate · 487,20 jährlich", fix=0, var=0, res=40.60, obj="vw"),
            dict(name="Kfz-Steuer", sub="Rücklage-Rate · 144,00 jährlich", fix=0, var=0, res=12, obj="vw"),
        ],
        [
            dict(name="Kfz-Versicherung", sub="487,20 bis 27. Okt. · 40,60/Monat", val="487,20 gedeckt", ok=True, obj="vw"),
            dict(name="HU und Reifen", sub="190 bis 12. Nov. · 60/Monat · Reifenwechsel 2. Nov.", val="120 / 190", obj="vw"),
            dict(name="Kfz-Steuer", sub="144 bis 15. Mai · 12/Monat", val="60 / 144", obj="vw"),
        ],
        [
            dict(name="HU/AU · VW ID.3", sub="Do 12. Nov. · alle 24 Monate · Planbetrag 150", val="150,00", obj="vw"),
            dict(name="Reifenwechsel", sub="Mo 2. Nov. · April / Oktober", obj="vw"),
            dict(name="Deutschlandticket kündbar", sub="bis 10. Nov. zum Monatsende", obj="ticket"),
        ],
        "Parken &amp; Maut, Fahrrad &amp; E-Bike, Carsharing, Taxi …")

    # ---------------- Haushalt
    bereich("Haushalt.dc.html", "Haushalt (Bereich)", H, ICON["bag"], "Haushalt",
        [("anna", "Anna"), ("ben", "Ben")],
        [
            dict(name="Lebensmittel & Haushalt", sub="Budget 450 · noch 38,00 frei", fix=0, var=412, res=0, obj="all"),
            dict(name="Freizeit & Kultur", sub="29,90 Fitness fix", warn="Budget 150 um 30,00 überschritten", fix=29.90, var=180, res=0, obj="ben"),
            dict(name="Kommunikation & Medien", sub="Mobilfunk, Netflix, Spotify, iCloud · fix · Internet → Wohnen", fix=53.96, var=0, res=0, obj="anna"),
            dict(name="Versicherung & Vorsorge", sub="Privathaftpflicht · Rücklage-Rate · 68,00 jährlich", fix=0, var=0, res=5.67, obj="anna"),
            dict(name="Urlaub & Reisen", sub="Sparziel Urlaub · Rücklage-Rate", fix=0, var=0, res=200, obj="all", href="Ruecklage.dc.html"),
            dict(name="Gastronomie, Kleidung, Gesundheit, Haustier", sub="keine Buchungen im Oktober", fix=0, var=0, res=0, obj="all"),
        ],
        [
            dict(name="Urlaub Juli", sub="1.800 bis 15. Juli · 200/Monat", val="640 / 1.800", obj="all"),
            dict(name="Privathaftpflicht", sub="68,00 bis 1. März · 5,67/Monat", val="45,36 / 68,00", obj="anna"),
        ],
        [
            dict(name="Zahnarzt Vorsorge · Ben", sub="Fr 20. Nov. · halbjährlich", obj="ben"),
            dict(name="FitnessFirst kündbar", sub="bis 15. Nov. · sonst +12 Monate", obj="ben"),
        ],
        "Kinderbetreuung, Bildung, Geschenke, Spenden, Taschengeld …")

    # ---------------- Übersicht (Main)
    body = f'''  <div class="hdr" style="padding: 56px 20px 64px">
    <div style="display: flex; align-items: center; justify-content: space-between">
      <div style="display: flex; gap: 6px; align-items: center">
        <button class="chip" style="height: 28px; padding: 0 10px" onClick="{{{{prevMonth}}}}" aria-label="Vormonat">‹</button>
        <p class="ttl">{{{{monthLabel}}}}</p>
        <button class="chip" style="height: 28px; padding: 0 10px" onClick="{{{{nextMonth}}}}" aria-label="Folgemonat">›</button>
      </div>
      <a href="Mehr.dc.html" aria-label="Mehr" style="width: 34px; height: 34px; border-radius: 17px; background: rgba(255,255,255,.14); color: #FFFFFF; display: inline-flex; align-items: center; justify-content: center; text-decoration: none"><svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><circle cx="6" cy="12" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="18" cy="12" r="2"/></svg></a>
    </div>
    <p style="margin: 22px 0 0; font-size: 14px; opacity: .8">{{{{headline}}}}</p>
    <p style="margin: 4px 0 0; font-size: 44px; font-weight: 700; letter-spacing: -1px; line-height: 1; font-variant-numeric: tabular-nums">{{{{spar}}}} €</p>
    <p style="margin: 10px 0 0; font-size: 13px; opacity: .8">{{{{formula}}}}</p>
  </div>

  <div style="padding: 0 20px; margin-top: -40px">
    <a href="Monatsrechnung.dc.html" class="card" style="display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 0; padding: 14px 6px; text-decoration: none; color: inherit">
      <div style="text-align: center; border-right: 1px solid #EEF1F5"><p style="margin: 0; font-size: 11.5px; color: #637894">Einnahmen</p><p style="margin: 4px 0 0; font-size: 15px; font-weight: 700; font-variant-numeric: tabular-nums; color: #215F33">{{{{k.ein}}}}</p></div>
      <div style="text-align: center; border-right: 1px solid #EEF1F5"><p style="margin: 0; font-size: 11.5px; color: #637894">Fixkosten</p><p style="margin: 4px 0 0; font-size: 15px; font-weight: 700; font-variant-numeric: tabular-nums">{{{{k.fix}}}}</p></div>
      <div style="text-align: center; border-right: 1px solid #EEF1F5"><p style="margin: 0; font-size: 11.5px; color: #637894">Ausgaben</p><p style="margin: 4px 0 0; font-size: 15px; font-weight: 700; font-variant-numeric: tabular-nums">{{{{k.aus}}}}</p></div>
      <div style="text-align: center"><p style="margin: 0; font-size: 11.5px; color: #637894">davon offen</p><p style="margin: 4px 0 0; font-size: 15px; font-weight: 700; font-variant-numeric: tabular-nums; color: #943333">{{{{k.offen}}}}</p></div>
    </a>
  </div>

  <div style="padding: 24px 20px 0 20px">
    <div class="card">
      <a class="row" href="Wohnen.dc.html" style="min-height: 56px; padding: 6px 16px"><span class="c" style="background: {W}; width: 36px; height: 36px; border-radius: 18px">{ICON["home"]}</span><div class="mid"><p class="n" style="font-size: 16px">Wohnen</p><p class="s" style="font-size: 12.5px">{{{{a.ws}}}}</p></div><p class="v" style="font-size: 16px">{{{{a.w}}}} €</p>{CHEV}</a>
      <div class="sep" style="margin-left: 64px"></div>
      <a class="row" href="Akte.dc.html" style="min-height: 56px; padding: 6px 16px"><span class="c" style="background: {M}; width: 36px; height: 36px; border-radius: 18px">{ICON["car"]}</span><div class="mid"><p class="n" style="font-size: 16px">Mobilität</p><p class="s" style="font-size: 12.5px">{{{{a.ms}}}}</p></div><p class="v" style="font-size: 16px">{{{{a.mo}}}} €</p>{CHEV}</a>
      <div class="sep" style="margin-left: 64px"></div>
      <a class="row" href="Haushalt.dc.html" style="min-height: 56px; padding: 6px 16px"><span class="c" style="background: {H}; width: 36px; height: 36px; border-radius: 18px">{ICON["bag"]}</span><div class="mid"><p class="n" style="font-size: 16px">Haushalt</p><p class="s" style="font-size: 12.5px">{{{{a.hs}}}}</p></div><p class="v" style="font-size: 16px">{{{{a.h}}}} €</p>{CHEV}</a>
    </div>
    <p class="note">Summe der Bereiche {{{{sumAreas}}}} € = Fixkosten {{{{k.fix2}}}} + Ausgaben {{{{k.aus2}}}} + Rücklagen {{{{k.res}}}}</p>
  </div>

  <div style="padding: 22px 0 0 20px">
    <div style="display: flex; align-items: baseline; justify-content: space-between; padding: 0 20px 10px 4px">
      <h2 style="margin: 0; font-size: 17px; font-weight: 700; letter-spacing: -0.3px">Fällig</h2>
      <a href="Rechnungen.dc.html" style="font-size: 14px; font-weight: 600; text-decoration: none">{{{{dueLine}}}}</a>
    </div>
    <div style="display: flex; gap: 10px; overflow-x: auto; scroll-snap-type: x mandatory; padding-right: 20px; scrollbar-width: none; -webkit-overflow-scrolling: touch">
      <sc-for list="{{{{due}}}}" as="d" hint-placeholder-count="3">
        <a class="inv" href="{{{{d.href}}}}" style="flex: none; width: 272px; scroll-snap-align: start">
          <div style="flex: 1; min-width: 0"><p class="n">{{{{d.name}}}}</p><p class="a">{{{{d.amount}}}} €</p><p class="d">{{{{d.sub}}}}</p></div>
          <div style="display: flex; flex-direction: column; align-items: flex-end"><span class="cap" style="{{{{d.capst}}}}">{{{{d.cap}}}}</span><span class="urg" style="{{{{d.urgst}}}}"><i style="{{{{d.dotst}}}}"></i>{{{{d.urg}}}}</span></div>
        </a>
      </sc-for>
    </div>
    <p class="note" style="margin: 10px 24px 0 4px">Nach rechts wischen: {{{{dueCount}}}} Posten, überfällig zuerst. Antippen öffnet Rechnung oder Vertrag.</p>
  </div>
'''
    logic = f'''  constructor(p) {{ super(p); this.state = {{ m: 0, toast: '' }}; }}
{JS_SEG}
  renderVals() {{
    var self = this, m = this.state.m;
    var months = ['Oktober 2026', 'September 2026', 'August 2026'];
    // Beispielmonat Oktober; Vormonate als Vergleich (abgeschlossen: keine offenen Posten)
    var D = [
      {{ ein: 3650, fix: 1659.20, bez: 656.20, off: 354.40, bud: 61.40, res: 326.10, w: 1368.18, mo: 746.19, h: 881.53, ws: 'Nachzahlung Strom überfällig', ms: 'Inspektion 212,40 € offen · HU 12. Nov.', hs: 'Budget Freizeit überschritten' }},
      {{ ein: 3650, fix: 1659.20, bez: 824.70, off: 0, bud: 0, res: 326.10, w: 1300.00, mo: 640.00, h: 870.00, ws: 'abgeschlossen', ms: 'abgeschlossen', hs: 'abgeschlossen' }},
      {{ ein: 3701.30, fix: 1659.20, bez: 754.70, off: 0, bud: 0, res: 326.10, w: 1290.00, mo: 590.00, h: 860.00, ws: 'Rückerstattung Strom 51,30', ms: 'abgeschlossen', hs: 'abgeschlossen' }}
    ];
    var d = D[m], aus = d.bez + d.off, spar = d.ein - d.fix - aus - d.bud - d.res;
    var dueAll = [
      {{ name: 'Stadtwerke Mainstadt', amount: eur(142), sub: 'Fällig: 21. Okt. 2026 · Wohnen', cap: 'Offen', capst: 'background: #F7D4D1; color: #943333', urg: 'Überfällig', urgst: 'color: #E03C31', dotst: 'background: #E03C31', href: 'Rechnung.dc.html' }},
      {{ name: 'HUK24 Kfz-Versicherung', amount: eur(487.20), sub: 'Fällig: 27. Okt. 2026 · aus Rücklage', cap: 'Offen', capst: 'background: #EDE3C9; color: #704F2E', urg: 'Bald fällig', urgst: 'color: #E08A1E', dotst: 'background: #E08A1E', href: 'Vertrag.dc.html' }},
      {{ name: 'Netflix', amount: eur(12.99), sub: 'Fällig: 29. Okt. 2026 · Haushalt', cap: 'Abo', capst: 'background: #EDE3C9; color: #704F2E', urg: 'Bald fällig', urgst: 'color: #E08A1E', dotst: 'background: #E08A1E', href: 'Vertrag.dc.html' }},
      {{ name: 'Autohaus Keller', amount: eur(212.40), sub: 'Fällig: 30. Okt. 2026 · Mobilität', cap: 'Offen', capst: 'background: #EDE3C9; color: #704F2E', urg: 'Bald fällig', urgst: 'color: #E08A1E', dotst: 'background: #E08A1E', href: 'Review.dc.html' }}
    ];
    var due = m === 0 ? dueAll : [];
    return {{
      toast: this.state.toast,
      monthLabel: months[m],
      prevMonth: function () {{ if (m < months.length - 1) self.setState({{ m: m + 1 }}); else self.say('Ältere Monate: Mehr › Auswertung'); }},
      nextMonth: function () {{ if (m > 0) self.setState({{ m: m - 1 }}); else self.say('Oktober ist der laufende Monat'); }},
      headline: (m === 0 ? 'Sparpotenzial im ' : 'Ergebnis im ') + months[m].split(' ')[0],
      spar: eur(spar),
      formula: eur(d.ein) + ' Einnahmen − ' + eur(d.fix) + ' Fixkosten − ' + eur(aus) + ' Ausgaben − ' + eur(d.bud) + ' Budgets offen − ' + eur(d.res) + ' Rücklagen',
      k: {{ ein: eur(d.ein, 0), fix: eur(d.fix, 0), aus: eur(aus, 0), offen: eur(d.off), fix2: eur(d.fix), aus2: eur(aus), res: eur(d.res) }},
      a: {{ ws: d.ws, ms: d.ms, hs: d.hs, w: eur(d.w, 0), mo: eur(d.mo, 0), h: eur(d.h, 0) }},
      sumAreas: eur(d.w + d.mo + d.h),
      due: due,
      dueCount: due.length,
      dueLine: m === 0 ? '1 überfällig · 3 in 7 Tagen' : 'nichts offen'
    }};
  }}'''
    page("Main.dc.html", "Übersicht", body, logic, 'u')


if __name__ == "__main__":
    build()
