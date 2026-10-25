# -*- coding: utf-8 -*-
"""Liquidität (Termine), Verlauf (Saldolinie aus denselben Buchungen), Kontostand aktualisieren (Abgleich)."""
from common import *
from d_objekte import tpl, EXTRA_CSS

# Eine Buchungsliste für alle drei Screens: Tag-Offset ab Sa 24.10.2026 (Tag 0), Betrag, Bereich, Quelle, Link.
BOOKINGS_JS = r'''[
  { id: 'sw', d: 1, amt: -142.00, name: 'Stadtwerke – Nachzahlung', sub: 'Rechnung · überfällig seit 21. Okt.', area: 'w', kind: 'rechnung', href: 'Rechnung.dc.html' },
  { id: 'huk', d: 3, amt: -487.20, name: 'Kfz-Versicherung HUK24', sub: 'Jahresbeitrag · aus Rücklage gedeckt', area: 'm', kind: 'vertrag', href: 'Vertrag.dc.html' },
  { id: 'nfx', d: 5, amt: -12.99, name: 'Netflix', sub: 'Abo', area: 'h', kind: 'vertrag', href: 'Vertrag.dc.html' },
  { id: 'ak', d: 6, amt: -212.40, name: 'Autohaus Keller – Inspektion', sub: 'Rechnung · fällig 30. Okt.', area: 'm', kind: 'rechnung', href: 'Review.dc.html' },
  { id: 'geh', d: 6, amt: 3400.00, name: 'Gehalt', sub: 'Einnahme · Muster AG', area: 'x', kind: 'einnahme', href: 'Einnahmen.dc.html' },
  { id: 'miete', d: 8, amt: -1199.99, name: 'Miete, Strom, Gas, Internet', sub: '4 Fixkosten · Wohnen', area: 'w', kind: 'vertrag', href: 'Vertraege.dc.html' },
  { id: 'leas', d: 8, amt: -289.00, name: 'Leasing VW Financial', sub: 'Kredit · Mobilität', area: 'm', kind: 'vertrag', href: 'Vertrag.dc.html' },
  { id: 'enbw', d: 8, amt: -9.99, name: 'EnBW mobility+', sub: 'Ladetarif', area: 'm', kind: 'vertrag', href: 'Vertrag.dc.html' },
  { id: 'fit', d: 8, amt: -29.90, name: 'FitnessFirst', sub: 'Mitgliedschaft · Ben', area: 'h', kind: 'vertrag', href: 'Vertrag.dc.html' },
  { id: 'tick', d: 10, amt: -58.00, name: 'Deutschlandticket', sub: 'Abo · Mobilität', area: 'm', kind: 'vertrag', href: 'Vertrag.dc.html' },
  { id: 'spot', d: 10, amt: -17.99, name: 'Spotify Family', sub: 'Abo', area: 'h', kind: 'vertrag', href: 'Vertrag.dc.html' },
  { id: 'kg', d: 12, amt: 250.00, name: 'Kindergeld', sub: 'Einnahme · Familienkasse', area: 'x', kind: 'einnahme', href: 'Einnahmen.dc.html' },
  { id: 'icl', d: 15, amt: -2.99, name: 'iCloud+', sub: 'Abo', area: 'h', kind: 'vertrag', href: 'Vertrag.dc.html' },
  { id: 'hu', d: 19, amt: -150.00, name: 'HU/AU · VW ID.3', sub: 'Termin · Planbetrag · aus Rücklage', area: 'm', kind: 'termin', href: 'Termin.dc.html' },
  { id: 'mob', d: 22, amt: -19.99, name: 'Telekom Mobilfunk', sub: 'Vertrag · Anna', area: 'h', kind: 'vertrag', href: 'Vertrag.dc.html' },
  { id: 'zahn', d: 27, amt: 0, name: 'Zahnarzt Vorsorge · Ben', sub: 'Termin ohne Betrag', area: 'h', kind: 'termin', href: 'Termin.dc.html' },
  { id: 'geh2', d: 37, amt: 3400.00, name: 'Gehalt', sub: 'Einnahme · Muster AG', area: 'x', kind: 'einnahme', href: 'Einnahmen.dc.html' },
  { id: 'miete2', d: 38, amt: -1199.99, name: 'Miete, Strom, Gas, Internet', sub: '4 Fixkosten · Wohnen', area: 'w', kind: 'vertrag', href: 'Vertraege.dc.html' },
  { id: 'leas2', d: 38, amt: -289.00, name: 'Leasing VW Financial', sub: 'Kredit · Mobilität', area: 'm', kind: 'vertrag', href: 'Vertrag.dc.html' },
  { id: 'fix2', d: 38, amt: -39.89, name: 'EnBW, FitnessFirst', sub: '2 Fixkosten', area: 'h', kind: 'vertrag', href: 'Vertraege.dc.html' },
  { id: 'tick2', d: 40, amt: -75.99, name: 'Deutschlandticket, Spotify', sub: '2 Abos', area: 'm', kind: 'vertrag', href: 'Vertraege.dc.html' },
  { id: 'kg2', d: 42, amt: 250.00, name: 'Kindergeld', sub: 'Einnahme', area: 'x', kind: 'einnahme', href: 'Einnahmen.dc.html' },
  { id: 'zs', d: 52, amt: 0, name: 'Zählerstände Strom und Gas', sub: 'Termin · Wohnung', area: 'w', kind: 'termin', href: 'Termin.dc.html' },
  { id: 'mob2', d: 52, amt: -22.98, name: 'Mobilfunk, iCloud+', sub: '2 Verträge', area: 'h', kind: 'vertrag', href: 'Vertraege.dc.html' }
]'''

JS_DATES = r'''
  dateOf(d) { var x = new Date(2026, 9, 24); x.setDate(x.getDate() + d); return x; }
  dayLabel(d) { var x = this.dateOf(d); return ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'][x.getDay()] + ' ' + x.getDate() + '. ' + ['Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sep.', 'Okt.', 'Nov.', 'Dez.'][x.getMonth()]; }
  shortLabel(d) { var x = this.dateOf(d); return x.getDate() + '.' + (x.getMonth() + 1) + '.'; }
  running(list, start) { var bal = start, out = [], min = { bal: start, d: 0 }; var byDay = {}; list.forEach(function (b) { byDay[b.d] = (byDay[b.d] || 0) + b.amt; }); Object.keys(byDay).map(Number).sort(function (a, b) { return a - b; }).forEach(function (d) { bal += byDay[d]; out.push({ d: d, bal: bal }); if (bal < min.bal) min = { bal: bal, d: d }; }); return { points: out, min: min, end: bal }; }
'''


def build():
    # ================================================================ Liquidität – Termine
    body = tpl('''  <div class="hdr" style="padding-bottom: 18px">
    <div style="display: flex; align-items: center; justify-content: space-between">
      <h1 style="margin: 0; font-size: 28px; font-weight: 700; letter-spacing: -0.5px">Liquidität</h1>
      <p class="ttl">Stand Sa 24. Okt.</p>
    </div>
    <div style="display: flex; align-items: flex-end; justify-content: space-between; gap: 12px; margin-top: 14px">
      <div><p style="margin: 0; font-size: 13px; opacity: .8">{{balLabel}}</p><p class="big" style="margin: 2px 0 0; font-size: 36px">{{balFmt}} €</p></div>
      <a href="Kontostand.dc.html" style="height: 36px; padding: 0 14px; border-radius: 18px; background: #FFFFFF; color: #1C3250; font-size: 14px; font-weight: 600; display: inline-flex; align-items: center; text-decoration: none; flex: none">Aktualisieren</a>
    </div>
    <p style="margin: 10px 0 0; font-size: 13px; opacity: .8">{{minLine}}</p>
    <div class="seg dark" style="margin-top: 14px"><button class="on">Termine</button><a href="Verlauf.dc.html" style="flex: 1; text-align: center; font-size: 13px; font-weight: 600; color: rgba(255,255,255,.8); padding: 6px 0; text-decoration: none">Verlauf</a></div>
  </div>

  <div style="padding: 14px 20px 0 20px; display: flex; gap: 8px; flex-wrap: wrap">
    <sc-for list="{{chips}}" as="c" hint-placeholder-count="4"><button class="{{c.cls}}" onClick="{{c.pick}}">{{c.label}}</button></sc-for>
    <button class="{{horizonCls}}" onClick="{{flipHorizon}}">{{horizonLabel}}</button>
  </div>

  <sc-for list="{{days}}" as="g" hint-placeholder-count="4">
  <div style="padding: 16px 20px 0 20px">
    <h2 class="h2" style="margin-bottom: 6px">{{g.title}} <span>{{g.meta}}</span></h2>
    <div class="card">
      <sc-for list="{{g.items}}" as="b" hint-placeholder-count="2">
        <button class="row" onClick="{{b.open}}"><span class="dot" style="{{b.dotst}}"></span><div class="mid"><p class="n" style="{{b.nst}}">{{b.name}}</p><p class="s">{{b.sub}}</p></div><p class="v" style="{{b.vst}}">{{b.val}}</p>[CHEV]</button>
        <div class="sep"></div>
      </sc-for>
    </div>
  </div>
  </sc-for>
  <sc-if value="{{empty}}" hint-placeholder-val="{{false}}"><p class="note" style="margin: 16px 24px 0">Keine geplanten Buchungen in dieser Auswahl.</p></sc-if>
  <p class="note" style="margin: 14px 24px 0">{{pruef}}</p>
''') + '''<sc-if value="{{sel}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>{{selName}}</h3><p>{{selText}}</p><div style="display: flex; gap: 10px; flex-wrap: wrap"><sc-if value="{{selCanPay}}" hint-placeholder-val="{{true}}"><button class="btn pri" onClick="{{markPaid}}">{{payLabel}}</button></sc-if><a class="btn sec2" href="{{selHref}}">Öffnen</a><button class="btn" style="flex: 0 0 auto; padding: 0 14px; background: #F3F5F8; color: #637894" onClick="{{closeSel}}">Schließen</button></div></div></div></sc-if>'''
    logic = r'''  constructor(p) { super(p); this.state = { area: 'all', horizon: 14, paid: {}, sel: null, toast: '' }; this.B = ''' + BOOKINGS_JS + r'''; this.START = 2410; }
''' + JS_SEG + JS_DATES + r'''
  renderVals() {
    var self = this, s = this.state, col = { w: '#E8A33D', m: '#3C8DBC', h: '#4CAF7A', x: '#215F33' };
    var planned = this.B.filter(function (b) { return !s.paid[b.id]; });
    var bal = this.START + this.B.filter(function (b) { return s.paid[b.id]; }).reduce(function (a, b) { return a + b.amt; }, 0);
    var run = this.running(planned.filter(function (b) { return b.d <= 60 && b.amt !== 0; }), bal);
    var inArea = function (b) { return s.area === 'all' || b.area === s.area; };
    var shown = planned.filter(function (b) { return b.d <= s.horizon && inArea(b); });
    var groups = {}; shown.forEach(function (b) { (groups[b.d] = groups[b.d] || []).push(b); });
    var days = Object.keys(groups).map(Number).sort(function (a, b) { return a - b; }).map(function (d) { var items = groups[d], sum = items.reduce(function (a, b) { return a + b.amt; }, 0), over = d === 1 && items.some(function (b) { return b.id === 'sw'; });
      return { title: over ? 'Überfällig' : self.dayLabel(d), meta: (d === 1 ? 'sofort' : 'in ' + d + ' Tagen') + ' · ' + eur(sum) + ' €', items: items.map(function (b) { return { name: b.name, sub: b.sub, dotst: 'background: ' + (b.id === 'sw' ? '#E03C31' : col[b.area]), nst: b.id === 'sw' ? 'color: #943333' : '', vst: b.amt > 0 ? 'color: #215F33' : '', val: b.amt === 0 ? '–' : (b.amt > 0 ? '+' : '') + eur(b.amt), open: function () { self.setState({ sel: b.id }); } }; }) }; });
    var out14 = shown.filter(function (b) { return b.amt < 0; }).reduce(function (a, b) { return a + b.amt; }, 0), in14 = shown.filter(function (b) { return b.amt > 0; }).reduce(function (a, b) { return a + b.amt; }, 0);
    var sel = this.B.filter(function (b) { return b.id === s.sel; })[0];
    var areaName = { all: 'Alle', w: 'Wohnen', m: 'Mobilität', h: 'Haushalt' }[s.area];
    return {
      toast: s.toast,
      balLabel: s.area === 'all' ? 'Kontostand heute' : 'Abflüsse ' + areaName + ' · ' + s.horizon + ' Tage',
      balFmt: s.area === 'all' ? eur(bal) : eur(out14),
      minLine: s.area === 'all' ? 'Tiefster Stand ' + eur(run.min.bal) + ' € am ' + this.dayLabel(run.min.d) + ' · Gehalt 3.400 € am ' + this.dayLabel(6) : 'Ein Konto lässt sich nicht je Bereich aufteilen – hier zählen nur die Abflüsse des Bereichs.',
      chips: this.chipItems('area', [['all', 'Alle'], ['w', 'Wohnen'], ['m', 'Mobilität'], ['h', 'Haushalt']], true),
      horizonCls: s.horizon === 14 ? 'chip lt' : 'chip lt on', horizonLabel: s.horizon === 14 ? '14 Tage' : '60 Tage', flipHorizon: function () { self.setState({ horizon: s.horizon === 14 ? 60 : 14 }); },
      days: days, empty: days.length === 0,
      pruef: s.area === 'all' ? 'Prüfung: ' + eur(bal) + ' − Abflüsse ' + eur(-out14) + ' + Zuflüsse ' + eur(in14) + ' = ' + eur(bal + out14 + in14) + ' € nach ' + s.horizon + ' Tagen. Rücklagen verändern den Kontostand nicht; ihre Verwendung (HUK, HU) schon.' : 'Abflüsse ' + areaName + ' in ' + s.horizon + ' Tagen: ' + eur(-out14) + ' €. Umschalten auf „Alle“ zeigt den Saldo.',
      sel: !!sel, selName: sel ? sel.name : '', selHref: sel ? sel.href : 'Main.dc.html',
      selText: sel ? (sel.amt === 0 ? 'Termin ohne Planbetrag – erscheint nur in der Liste, nicht im Verlauf.' : (s.paid[sel.id] ? 'Als gebucht markiert: Kontostand ' + eur(bal) + ' €. Rückgängig setzt die Planung wieder ein.' : (sel.amt > 0 ? '+' : '') + eur(sel.amt) + ' € am ' + self.dayLabel(sel.d) + '. Als gebucht markieren, sobald die Buchung auf dem Konto ist – der Kontostand wird dann fortgeschrieben.')) : '',
      selCanPay: !!sel && sel.amt !== 0, payLabel: sel && s.paid[sel.id] ? 'Rückgängig' : 'Als gebucht markieren',
      markPaid: function () { if (!sel) return; var p = Object.assign({}, s.paid); p[sel.id] = !p[sel.id]; self.setState({ paid: p, sel: null }); self.say(p[sel.id] ? sel.name + ' gebucht · Kontostand ' + eur(bal + sel.amt) + ' €' : 'Wieder geplant'); },
      closeSel: this.go('sel', null)
    };
  }'''
    page("Liquiditaet.dc.html", "Liquidität – Termine", body, logic, 'l', EXTRA_CSS)

    # ================================================================ Verlauf
    body = tpl('''  <div class="hdr">
    <div class="nav"><a class="back" href="Liquiditaet.dc.html">[BACK]Liquidität</a><p class="ttl">Verlauf</p><a class="act" href="Kontostand.dc.html">Aktualisieren</a></div>
    <p class="sub" style="margin-top: 14px">Kontostand · zuletzt heute 09:12</p>
    <div style="display: flex; align-items: baseline; justify-content: space-between; gap: 14px"><p class="big" style="margin: 4px 0 0">2.410,00 €</p><p style="margin: 0; font-size: 13px; opacity: .85; text-align: right">{{minLine}}</p></div>
    <div class="seg dark" style="margin-top: 14px"><a href="Liquiditaet.dc.html" style="flex: 1; text-align: center; font-size: 13px; font-weight: 600; color: rgba(255,255,255,.8); padding: 6px 0; text-decoration: none">Termine</a><button class="on">Verlauf</button></div>
  </div>

  <div style="padding: 14px 20px 0 20px"><div class="seg"><sc-for list="{{ranges}}" as="s" hint-placeholder-count="3"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div>

  <div style="padding: 14px 20px 0 20px">
    <div class="card" style="padding: 14px 14px 8px">
      <div style="display: flex; align-items: baseline; justify-content: space-between; padding: 0 4px"><p style="margin: 0; font-size: 15px; font-weight: 700">{{title}}</p><p style="margin: 0; font-size: 12px; color: #637894">Ende {{endFmt}} €</p></div>
      <svg width="100%" height="170" viewBox="0 0 350 170" preserveAspectRatio="none" role="img" aria-label="Kontostand-Verlauf" style="display: block; margin-top: 8px">
        <line x1="10" y1="{{yPuffer}}" x2="340" y2="{{yPuffer}}" stroke="#E08A1E" stroke-dasharray="4 3"/>
        <text x="12" y="{{yPufferT}}" font-size="9" fill="#704F2E">Puffer {{pufferFmt}}</text>
        <line x1="10" y1="{{yZero}}" x2="340" y2="{{yZero}}" stroke="#E3E8EF"/>
        <path d="{{area}}" fill="#2A5480" opacity=".08"/>
        <path d="{{path}}" fill="none" stroke="#2A5480" stroke-width="2" stroke-linejoin="round"/>
        <circle cx="{{minX}}" cy="{{minY}}" r="4" fill="#E08A1E" stroke="#FFFFFF" stroke-width="1.5"/>
        <text x="{{minX}}" y="{{minLabelY}}" font-size="10" font-weight="700" fill="#704F2E" text-anchor="middle">{{minFmt}}</text>
        <text x="{{t0x}}" y="166" font-size="10" fill="#637894" text-anchor="start">{{t0}}</text><text x="{{t1x}}" y="166" font-size="10" fill="#637894" text-anchor="middle">{{t1}}</text><text x="{{t2x}}" y="166" font-size="10" fill="#637894" text-anchor="middle">{{t2}}</text><text x="{{t3x}}" y="166" font-size="10" fill="#637894" text-anchor="middle">{{t3}}</text><text x="{{t4x}}" y="166" font-size="10" fill="#637894" text-anchor="end">{{t4}}</text>
      </svg>
    </div>
    <p class="note">{{calc}}</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <div class="f"><p class="l">Mindestpuffer</p><input class="in num" value="{{puffer}}" onChange="{{setPuffer}}" inputmode="decimal"><span style="font-size: 14px; color: #637894">€</span></div>
      <div class="sep"></div>
      <div class="f"><p class="v wrap">{{pufferNote}}</p></div>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Kontostand-Historie</h2>
    <div class="card">
      <div class="row"><div class="mid"><p class="n">Sa 24. Okt. · 09:12</p><p class="s">manuell · Abweichung zur Planung 0,00 €</p></div><p class="v">2.410,00</p></div>
      <div class="sep"></div>
      <div class="row"><div class="mid"><p class="n">Di 20. Okt.</p><p class="s">nach Bons REWE, dm · Abweichung −4,10 € (Bargeld)</p></div><p class="v">2.532,57</p></div>
      <div class="sep"></div>
      <div class="row"><div class="mid"><p class="n">Do 15. Okt.</p><p class="s">nach Netflix-Abbuchung</p></div><p class="v">2.701,10</p></div>
      <div class="sep"></div>
      <div class="row"><div class="mid"><p class="n">Do 1. Okt.</p><p class="s">nach Miete, Leasing, Abschlägen</p></div><p class="v">2.964,65</p></div>
    </div>
  </div>
''')
    logic = r'''  constructor(p) { super(p); this.state = { range: 10, puffer: '1.500', toast: '' }; this.B = ''' + BOOKINGS_JS + r'''; this.START = 2410; }
''' + JS_SEG + JS_DATES + r'''
  renderVals() {
    var self = this, s = this.state, R = s.range, puffer = num(s.puffer);
    var list = this.B.filter(function (b) { return b.d <= R && b.amt !== 0; });
    var run = this.running(list, this.START);
    var pts = [{ d: 0, bal: this.START }].concat(run.points); if (pts[pts.length - 1].d < R) pts.push({ d: R, bal: run.end });
    var vals = pts.map(function (p) { return p.bal; }).concat([puffer]); var mn = Math.min.apply(null, vals) - 200, mx = Math.max.apply(null, vals) + 300;
    var x0 = 10, x1 = 340, y0 = 14, y1 = 150;
    var X = function (d) { return x0 + d / R * (x1 - x0); }, Y = function (v) { return y1 - (v - mn) / (mx - mn) * (y1 - y0); };
    var dpath = ''; pts.forEach(function (p, i) { var prev = pts[i - 1]; if (i === 0) dpath = 'M' + X(p.d).toFixed(1) + ',' + Y(p.bal).toFixed(1); else dpath += ' L' + X(p.d).toFixed(1) + ',' + Y(prev.bal).toFixed(1) + ' L' + X(p.d).toFixed(1) + ',' + Y(p.bal).toFixed(1); });
    var area = dpath + ' L' + x1 + ',' + y1 + ' L' + x0 + ',' + y1 + ' Z';
    var tickDays = R === 10 ? [0, 3, 6, 8, 10] : (R === 30 ? [0, 8, 15, 22, 30] : [0, 14, 28, 42, 56]);
    var steps = run.points.map(function (p) { var day = self.B.filter(function (b) { return b.d === p.d && b.d <= R && b.amt !== 0; }); return day.map(function (b) { return (b.amt > 0 ? '+' : '−') + eur(Math.abs(b.amt)); }).join(' ') + ' (' + self.shortLabel(p.d) + ') → ' + eur(p.bal); });
    return {
      toast: s.toast,
      ranges: this.segItems('range', [[10, '10 Tage'], [30, '30 Tage'], [56, '8 Wochen']]),
      title: 'Nächste ' + (R === 56 ? '8 Wochen' : R + ' Tage'), endFmt: eur(run.end),
      minLine: 'Tiefster Stand ' + eur(run.min.bal) + ' € am ' + this.dayLabel(run.min.d),
      yPuffer: Y(puffer).toFixed(1), yPufferT: (Y(puffer) - 4).toFixed(1), pufferFmt: eur(puffer, 0), yZero: Y(0).toFixed(1),
      path: dpath, area: area,
      minX: X(run.min.d).toFixed(1), minY: Y(run.min.bal).toFixed(1), minLabelY: (Y(run.min.bal) + 14).toFixed(1), minFmt: eur(run.min.bal),
      t0: this.shortLabel(tickDays[0]), t0x: X(tickDays[0]).toFixed(1), t1: this.shortLabel(tickDays[1]), t1x: X(tickDays[1]).toFixed(1), t2: this.shortLabel(tickDays[2]), t2x: X(tickDays[2]).toFixed(1), t3: this.shortLabel(tickDays[3]), t3x: X(tickDays[3]).toFixed(1), t4: this.shortLabel(tickDays[4]), t4x: X(tickDays[4]).toFixed(1),
      calc: 'Rechnung: ' + eur(this.START) + ' ' + steps.slice(0, 6).join(' · ') + (steps.length > 6 ? ' · …' : '') + '. Rücklagen verändern den Kontostand nicht.',
      puffer: s.puffer, setPuffer: this.set('puffer'),
      pufferNote: run.min.bal >= puffer ? 'Tiefster Stand liegt ' + eur(run.min.bal - puffer) + ' € über dem Mindestpuffer von ' + eur(puffer) + ' €. Ohne die Kfz-Rücklage (487,20 €) wären es ' + eur(run.min.bal - puffer - 487.20) + ' €.' : 'Achtung: am ' + this.dayLabel(run.min.d) + ' liegt der Stand ' + eur(puffer - run.min.bal) + ' € unter dem Mindestpuffer von ' + eur(puffer) + ' €. Vorschlag: Rechnung Autohaus Keller nach dem Gehalt am 30. zahlen.'
    };
  }'''
    page("Verlauf.dc.html", "Liquidität – Verlauf", body, logic, 'l', EXTRA_CSS)

    # ================================================================ Kontostand aktualisieren
    body = tpl('''  <div class="bar"><a href="Liquiditaet.dc.html">Abbrechen</a><p>Kontostand</p><button style="font-weight: 700" onClick="{{save}}">Sichern</button></div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card" style="padding: 18px 16px 14px">
      <p style="margin: 0; font-size: 13px; color: #637894; text-align: center">Neuer Kontostand · Girokonto</p>
      <div style="display: flex; align-items: baseline; justify-content: center; gap: 6px; margin-top: 8px"><input class="in num" style="font-size: 40px; font-weight: 700; letter-spacing: -0.9px; max-width: 200px; text-align: right; border-bottom-width: 2px" value="{{amt}}" onChange="{{setAmt}}" inputmode="decimal" placeholder="0,00"><span style="font-size: 28px; color: #9AA5B4; font-weight: 700">€</span></div>
      <div style="display: flex; justify-content: center; gap: 8px; margin-top: 10px"><button class="chip lt" onClick="{{dateToday}}">{{dateLabel}}</button><button class="chip lt" onClick="{{dateMo}}">Mo 27. Okt.</button></div>
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <h2 class="h2">Abgleich seit Sa 24. Okt. (2.410,00 €) <span>bis {{dateLabel}}</span></h2>
    <div class="card">
      <sc-for list="{{items}}" as="b" hint-placeholder-count="2">
        <button class="row" onClick="{{b.flip}}"><span class="c" style="{{b.cst}}">{{b.mark}}</span><div class="mid"><p class="n">{{b.name}}</p><p class="s">{{b.sub}}</p></div><p class="v" style="{{b.vst}}">{{b.val}}</p></button>
        <div class="sep"></div>
      </sc-for>
      <sc-if value="{{noItems}}" hint-placeholder-val="{{false}}"><div class="f"><p class="v ph">Bis zu diesem Datum sind keine Buchungen geplant.</p></div></sc-if>
      <div class="f"><p class="l">Erwartet</p><p class="v">{{expected}} €</p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Differenz</p><p class="v" style="{{diffSt}}">{{diffText}}</p></div>
    </div>
    <p class="note">{{note}}</p>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <div class="card">
      <div class="f"><p class="v wrap" style="font-weight: 500; font-size: 15px">Bestätigte Buchungen als bezahlt markieren</p><button class="{{markCls}}" aria-label="Als bezahlt markieren" onClick="{{flipMark}}"></button></div>
      <div class="sep"></div>
      <div class="f"><p class="v wrap" style="font-weight: 500; font-size: 15px">Erinnern, wenn die nächste Abbuchung ansteht</p><button class="{{remCls}}" aria-label="Erinnern" onClick="{{flipRem}}"></button></div>
    </div>
  </div>
''') + '''<sc-if value="{{diffSheet}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>{{diffTitle}}</h3><p>{{diffBody}}</p><div style="display: flex; gap: 10px; flex-wrap: wrap"><a class="btn pri" href="Erfassen.dc.html">Als Buchung erfassen</a><a class="btn sec2" href="Liquiditaet.dc.html">Trotzdem sichern</a></div><button class="btn" style="margin-top: 10px; background: none; color: #637894" onClick="{{closeDiff}}">Zurück</button></div></div></sc-if>''' \
      + sheet("okSheet", "Kontostand gespeichert", "{{okText}}", '<a class="btn pri" href="Liquiditaet.dc.html">Zur Liquidität</a>')
    logic = r'''  constructor(p) { super(p); this.state = { amt: '1.922,80', day: 3, checks: { sw: false, huk: true }, mark: true, rem: true, diffSheet: false, okSheet: false, okText: '', toast: '' }; this.B = ''' + BOOKINGS_JS + r'''; this.START = 2410; }
''' + JS_SEG + JS_DATES + r'''
  renderVals() {
    var self = this, s = this.state, entered = num(s.amt);
    var due = this.B.filter(function (b) { return b.d <= s.day && b.amt !== 0; });
    var checked = due.filter(function (b) { return s.checks[b.id] !== undefined ? s.checks[b.id] : true; });
    var expected = this.START + checked.reduce(function (a, b) { return a + b.amt; }, 0);
    var diff = entered - expected, abs = Math.abs(diff), ok = abs < 0.005;
    return {
      toast: s.toast,
      amt: s.amt, setAmt: this.set('amt'),
      dateLabel: s.day === 1 ? 'So 25. Okt.' : 'Mo 27. Okt.', dateToday: function () { self.setState({ day: 1 }); }, dateMo: function () { self.setState({ day: 3 }); },
      items: due.map(function (b) { var on = s.checks[b.id] !== undefined ? s.checks[b.id] : true; return { name: b.name, sub: self.dayLabel(b.d) + ' · ' + b.sub, val: (b.amt > 0 ? '+' : '') + eur(b.amt), vst: on ? (b.amt > 0 ? 'color: #215F33' : '') : 'color: #943333; text-decoration: line-through', cst: on ? 'background: #D6EDDB; color: #215F33' : 'background: #FBE9E7; color: #943333', mark: on ? '✓' : '✕', flip: function () { var c = Object.assign({}, s.checks); c[b.id] = !on; self.setState({ checks: c }); } }; }),
      noItems: due.length === 0,
      expected: eur(expected),
      diffText: !(entered > 0) ? 'Kontostand eingeben' : (ok ? '0,00 € · passt zur Planung' : (diff > 0 ? '+' : '−') + eur(abs) + ' € ' + (diff > 0 ? 'mehr' : 'weniger') + ' als geplant'),
      diffSt: !(entered > 0) ? 'color: #9AA5B4' : (ok ? 'color: #215F33; font-weight: 600' : 'color: #943333; font-weight: 600'),
      note: 'Antippen schaltet eine Buchung auf „noch nicht abgebucht“ (✕) oder „abgebucht“ (✓). Erwartet = 2.410,00 + Summe der abgebuchten Posten. ' + (ok ? 'Alles erfasst.' : (entered > 0 ? 'Eine Differenz ist eine Buchung, die Mnemor noch nicht kennt – z. B. Bargeld oder eine Kartenzahlung ohne Bon.' : '')),
      markCls: this.tog('mark'), flipMark: this.flip('mark'), remCls: this.tog('rem'), flipRem: this.flip('rem'),
      save: function () {
        if (!(entered > 0)) { self.say('Bitte den Kontostand eingeben'); return; }
        if (!ok) { self.setState({ diffSheet: true }); return; }
        self.setState({ okSheet: true, okText: eur(entered) + ' € am ' + (s.day === 1 ? '25. Okt.' : '27. Okt.') + (s.mark && checked.length ? ' · ' + checked.length + ' Buchungen als bezahlt markiert (' + checked.map(function (b) { return b.name; }).join(', ') + ')' : '') + '. Tiefster Stand wird neu berechnet.' });
      },
      diffSheet: s.diffSheet, closeDiff: this.go('diffSheet', false),
      diffTitle: (diff > 0 ? '+' : '−') + eur(abs) + ' € nicht erfasst',
      diffBody: diff < 0 ? 'Vom Konto sind ' + eur(abs) + ' € mehr abgegangen als geplant. Als Buchung erfassen (Bon, Kartenzahlung, Abhebung) – dann stimmen Budget und Sparpotenzial wieder.' : 'Auf dem Konto sind ' + eur(abs) + ' € mehr als geplant – vermutlich eine Einnahme oder Rückerstattung. Als Einnahme erfassen oder trotzdem sichern.',
      okSheet: s.okSheet, okText: s.okText
    };
  }'''
    page("Kontostand.dc.html", "Kontostand aktualisieren", body, logic, 'l', EXTRA_CSS)


if __name__ == "__main__":
    build()
