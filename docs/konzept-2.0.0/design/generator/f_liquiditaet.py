# -*- coding: utf-8 -*-
"""Liquidität (Termine als Liste oder Kalender), Verlauf (Saldolinie), Kontostand aktualisieren (Abgleich).
Alle drei rechnen aus EINEM Buchungsplan, der aus Verträgen, Einnahmen, Rechnungen und Terminen für jeden Horizont erzeugt wird."""
from common import *
from d_objekte import tpl, EXTRA_CSS

# Planer: erzeugt Buchungen ab Sa 24.10.2026 (Tag 0) bis Tag `days`.
JS_PLAN = r'''
  base() { return new Date(2026, 9, 24); }
  dateOf(d) { var x = this.base(); x.setDate(x.getDate() + d); return x; }
  dayIdx(y, m, d) { var a = new Date(y, m, d), b = this.base(); return Math.round((a - b) / 86400000); }
  dayLabel(d) { var x = this.dateOf(d); return ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'][x.getDay()] + ' ' + x.getDate() + '. ' + this.MON[x.getMonth()]; }
  shortLabel(d) { var x = this.dateOf(d); return x.getDate() + '.' + (x.getMonth() + 1) + '.'; }
  monthLabel(y, m) { return ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'][m] + ' ' + y; }
  plan(days) {
    var self = this, out = [], seen = {};
    var push = function (d, b) { if (d < 0 || d > days) return; var id = b.id + '@' + d; if (seen[id]) return; seen[id] = 1; out.push(Object.assign({ d: d, uid: id }, b)); };
    // feste Einzelposten
    push(1, { id: 'sw', amt: -142, name: 'Stadtwerke – Nachzahlung', sub: 'Rechnung · überfällig seit 21. Okt.', area: 'w', kind: 'rechnung', href: 'Rechnung.dc.html', over: true });
    push(6, { id: 'ak', amt: -212.40, name: 'Autohaus Keller – Inspektion', sub: 'Rechnung · fällig 30. Okt.', area: 'm', kind: 'rechnung', href: 'Review.dc.html' });
    push(this.dayIdx(2026, 10, 2), { id: 'reifen', amt: -40, name: 'Reifenwechsel · VW ID.3', sub: 'Termin · Planbetrag · aus Rücklage HU/Reifen', area: 'm', kind: 'termin', href: 'Termin.dc.html' });
    push(this.dayIdx(2026, 10, 12), { id: 'hu', amt: -150, name: 'HU/AU · VW ID.3', sub: 'Termin · Planbetrag · aus Rücklage HU/Reifen', area: 'm', kind: 'termin', href: 'Termin.dc.html' });
    push(this.dayIdx(2026, 10, 20), { id: 'zahn', amt: 0, name: 'Zahnarzt Vorsorge · Ben', sub: 'Termin ohne Betrag', area: 'h', kind: 'termin', href: 'Termin.dc.html' });
    push(this.dayIdx(2026, 11, 15), { id: 'zs', amt: 0, name: 'Zählerstände Strom und Gas', sub: 'Termin · Wohnung', area: 'w', kind: 'termin', href: 'Termin.dc.html' });
    push(this.dayIdx(2027, 6, 15), { id: 'urlaub', amt: -1800, name: 'Urlaub Juli', sub: 'Sparziel · aus Rücklage (1.800 € angespart)', area: 'h', kind: 'termin', href: 'Ruecklage.dc.html' });
    // Monatsverträge und Einnahmen
    var monthly = [
      ['miete', 1, -950, 'Miete Hauptstr. 12', 'w', 'Miete'], ['strom', 1, -98, 'Stadtwerke Strom', 'w', 'Strom'], ['gas', 1, -112, 'Stadtwerke Gas', 'w', 'Gas'], ['inet', 1, -39.99, 'Telekom Internet', 'w', 'Internet'],
      ['leas', 1, -289, 'VW Leasing ID.3', 'm', 'Leasing'], ['enbw', 1, -9.99, 'EnBW mobility+', 'm', 'Ladetarif'], ['fit', 1, -29.90, 'FitnessFirst', 'h', 'Fitness'],
      ['tick', 3, -58, 'Deutschlandticket', 'm', 'Ticket'], ['spot', 3, -17.99, 'Spotify Family', 'h', 'Spotify'], ['icl', 8, -2.99, 'iCloud+', 'h', 'iCloud'], ['mob', 15, -19.99, 'Telekom Mobilfunk', 'h', 'Mobilfunk'], ['nfx', 29, -12.99, 'Netflix', 'h', 'Netflix'],
      ['geh', 30, 3400, 'Gehalt', 'x', 'Gehalt'], ['kg', 5, 250, 'Kindergeld', 'x', 'Kindergeld']
    ];
    // Variable Ausgaben: Rest der Oktober-Budgets, danach die vollen Monatsbudgets (Lebensmittel 450 + Freizeit 150 + Mobilität variabel 300)
    push(7, { id: 'var', amt: -61.40, name: 'Variable Ausgaben (Budgets, noch offen)', sub: 'Lebensmittel 38,00 · Mobilität variabel 23,40 · bis Monatsende', area: 'h', kind: 'var', href: 'Budgets.dc.html' });
    for (var k = 0; k <= 13; k++) { var y = 2026 + Math.floor((9 + k) / 12), m = (9 + k) % 12; var dim = new Date(y, m + 1, 0).getDate();
      monthly.forEach(function (r) { var d = self.dayIdx(y, m, Math.min(r[1], dim)); push(d, { id: r[0], amt: r[2], name: r[3], short: r[5], sub: r[2] > 0 ? 'Einnahme · monatlich' : 'Vertrag · monatlich', area: r[4], kind: r[2] > 0 ? 'einnahme' : 'fix', href: r[2] > 0 ? 'Einnahmen.dc.html' : 'Vertrag.dc.html' }); });
      if (k > 0) push(self.dayIdx(y, m, 15), { id: 'var', amt: -900, name: 'Variable Ausgaben (Budgets)', sub: 'Lebensmittel 450 · Freizeit 150 · Mobilität variabel 300 · Planwert zur Monatsmitte', area: 'h', kind: 'var', href: 'Budgets.dc.html' }); }
    // Quartal und Jahr
    [[2027, 0, 15], [2027, 3, 15], [2027, 6, 15], [2027, 9, 15]].forEach(function (q) { push(self.dayIdx(q[0], q[1], q[2]), { id: 'rf', amt: -55.08, name: 'Rundfunkbeitrag', sub: 'Vertrag · vierteljährlich · Monatsanteil 18,36 in den Fixkosten', area: 'w', kind: 'jahr', href: 'Vertrag.dc.html' }); });
    push(3, { id: 'huk', amt: -487.20, name: 'Kfz-Versicherung HUK24', sub: 'Jahresbeitrag · aus Rücklage gedeckt', area: 'm', kind: 'jahr', href: 'Vertrag.dc.html' });
    push(this.dayIdx(2027, 9, 27), { id: 'huk', amt: -487.20, name: 'Kfz-Versicherung HUK24', sub: 'Jahresbeitrag · aus Rücklage', area: 'm', kind: 'jahr', href: 'Vertrag.dc.html' });
    push(this.dayIdx(2027, 2, 1), { id: 'hausrat', amt: -94, name: 'Hausrat Allianz', sub: 'Jahresbeitrag · aus Rücklage', area: 'w', kind: 'jahr', href: 'Vertrag.dc.html' });
    push(this.dayIdx(2027, 2, 1), { id: 'haft', amt: -68, name: 'Privathaftpflicht', sub: 'Jahresbeitrag · aus Rücklage', area: 'h', kind: 'jahr', href: 'Vertrag.dc.html' });
    push(this.dayIdx(2027, 4, 15), { id: 'kfzst', amt: -144, name: 'Kfz-Steuer', sub: 'jährlich · aus Rücklage', area: 'm', kind: 'jahr', href: 'Termin.dc.html' });
    out.sort(function (a, b) { return a.d - b.d || b.amt - a.amt; });
    return out;
  }
  running(list, start) { var bal = start, out = [], min = { bal: start, d: 0 }; var byDay = {}; list.forEach(function (b) { byDay[b.d] = (byDay[b.d] || 0) + b.amt; }); Object.keys(byDay).map(Number).sort(function (a, b) { return a - b; }).forEach(function (d) { bal += byDay[d]; out.push({ d: d, bal: bal }); if (bal < min.bal) min = { bal: bal, d: d }; }); return { points: out, min: min, end: bal }; }
'''
HORIZONS = "[[7, '7 Tage'], [14, '14 Tage'], [30, '30 Tage'], [91, '3 Monate'], [182, '6 Monate'], [273, '9 Monate'], [365, '1 Jahr']]"
MON_JS = "this.MON = ['Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sep.', 'Okt.', 'Nov.', 'Dez.'];"

CAL_CSS = """
.cal{display:grid;grid-template-columns:repeat(7,minmax(0,1fr));gap:2px;padding:6px 8px 10px}
.cal .wd{font-size:11px;color:#637894;text-align:center;padding:4px 0}
.cal button{height:44px;border:0;background:none;border-radius:10px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;font:inherit;font-size:14px;color:#16243A;cursor:pointer;padding:0}
.cal button.dim{color:#B9C2CE}
.cal button.on{background:#2A5480;color:#FFFFFF}
.cal button.today{font-weight:700;text-decoration:underline}
.cal .dots{display:flex;gap:2px;height:5px}
.cal .dots i{width:5px;height:5px;border-radius:3px;display:block}
.hchips{display:flex;gap:8px;overflow-x:auto;scrollbar-width:none;padding: 0 20px}
.hchips::-webkit-scrollbar{display:none}
"""


def build():
    # ================================================================ Liquidität – Termine (Liste | Kalender)
    body = tpl('''  <div class="hdr" style="padding-bottom: 16px">
    <div style="display: flex; align-items: center; justify-content: space-between">
      <h1 style="margin: 0; font-size: 28px; font-weight: 700; letter-spacing: -0.5px">Liquidität</h1>
      <p class="ttl">Stand Sa 24. Okt.</p>
    </div>
    <div style="display: flex; align-items: flex-end; justify-content: space-between; gap: 12px; margin-top: 14px">
      <div><p style="margin: 0; font-size: 13px; opacity: .8">Kontostand heute</p><p class="big" style="margin: 2px 0 0; font-size: 36px">{{balFmt}} €</p></div>
      <a href="Kontostand.dc.html" style="height: 36px; padding: 0 14px; border-radius: 18px; background: #FFFFFF; color: #1C3250; font-size: 14px; font-weight: 600; display: inline-flex; align-items: center; text-decoration: none; flex: none">Aktualisieren</a>
    </div>
    <p style="margin: 10px 0 0; font-size: 13px; opacity: .85">{{outlook}}</p>
    <sc-if value="{{warn}}" hint-placeholder-val="{{false}}"><p style="margin: 6px 0 0; font-size: 13px; color: #FFD7A8">{{warn}}</p></sc-if>
    <div class="seg dark" style="margin-top: 14px"><button class="on">Termine</button><a href="Verlauf.dc.html" style="flex: 1; text-align: center; font-size: 13px; font-weight: 600; color: rgba(255,255,255,.8); padding: 6px 0; text-decoration: none">Verlauf</a></div>
  </div>

  <div class="hchips" style="margin-top: 14px"><sc-for list="{{hchips}}" as="c" hint-placeholder-count="7"><button class="{{c.cls}}" onClick="{{c.pick}}">{{c.label}}</button></sc-for></div>
  <div style="padding: 10px 20px 0 20px; display: flex; gap: 6px; flex-wrap: wrap"><sc-for list="{{chips}}" as="c" hint-placeholder-count="4"><button class="{{c.cls}}" style="height: 28px; padding: 0 10px; font-size: 12px" onClick="{{c.pick}}">{{c.label}}</button></sc-for></div>

  <sc-for list="{{groups}}" as="g" hint-placeholder-count="4">
  <div style="padding: 14px 20px 0 20px">
    <h2 class="h2" style="margin-bottom: 6px">{{g.title}} <span>{{g.meta}}</span></h2>
    <div class="card">
      <sc-for list="{{g.items}}" as="b" hint-placeholder-count="2">
        <button class="row" onClick="{{b.open}}"><span class="dot" style="{{b.dotst}}"></span><div class="mid"><p class="n" style="{{b.nst}}">{{b.name}}</p><p class="s">{{b.sub}}</p></div><p class="v" style="{{b.vst}}">{{b.val}}</p>[CHEV]</button>
        <div class="sep"></div>
      </sc-for>
      <sc-if value="{{g.saldo}}" hint-placeholder-val="{{false}}"><div class="row" style="background: #F3F5F8; cursor: default"><div class="mid"><p class="n">{{g.saldoLabel}}</p></div><p class="v" style="{{g.saldoSt}}">{{g.saldo}}</p></div></sc-if>
    </div>
  </div>
  </sc-for>
  <sc-if value="{{empty}}" hint-placeholder-val="{{false}}"><p class="note" style="margin: 16px 24px 0">{{emptyText}}</p></sc-if>
  <p class="note" style="margin: 14px 24px 0">{{pruef}}</p>
''') + '''<sc-if value="{{sel}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>{{selName}}</h3><p>{{selText}}</p><sc-if value="{{selHasParts}}" hint-placeholder-val="{{false}}"><div class="card" style="margin-bottom: 12px"><sc-for list="{{selParts}}" as="p" hint-placeholder-count="3"><div class="f" style="min-height: 40px"><p class="v" style="font-weight: 500">{{p.n}}</p><p class="v" style="flex: none; width: auto; font-variant-numeric: tabular-nums">{{p.v}}</p></div><div class="sep"></div></sc-for></div></sc-if><div style="display: flex; gap: 10px; flex-wrap: wrap"><sc-if value="{{selCanPay}}" hint-placeholder-val="{{true}}"><button class="btn pri" onClick="{{markPaid}}">{{payLabel}}</button></sc-if><a class="btn sec2" href="{{selHref}}">Öffnen</a><button class="btn" style="flex: 0 0 auto; padding: 0 14px; background: #F3F5F8; color: #637894" onClick="{{closeSel}}">Schließen</button></div></div></div></sc-if>'''
    logic = r'''  constructor(p) { super(p); this.state = { area: 'all', h: 14, paid: {}, sel: null, toast: '' }; ''' + MON_JS + r''' this.START = 2410; this.PUFFER = 1500; }
''' + JS_SEG + JS_PLAN + r'''
  renderVals() {
    var self = this, s = this.state, col = { w: '#E8A33D', m: '#3C8DBC', h: '#4CAF7A', x: '#215F33' };
    var all = this.plan(365);
    var isPaid = function (b) { return !!s.paid[b.uid]; };
    var bal = this.START + all.filter(isPaid).reduce(function (a, b) { return a + b.amt; }, 0);
    var planned = all.filter(function (b) { return !isPaid(b) && b.d <= s.h; });
    var inArea = function (b) { return s.area === 'all' || b.area === s.area; };
    var shown = planned.filter(inArea);
    var run = this.running(planned.filter(function (b) { return b.amt !== 0; }), bal);
    var inflow = shown.filter(function (b) { return b.amt > 0; }).reduce(function (a, b) { return a + b.amt; }, 0), outflow = shown.filter(function (b) { return b.amt < 0; }).reduce(function (a, b) { return a + b.amt; }, 0);
    var hLabel = (''' + HORIZONS + r''').filter(function (x) { return x[0] === s.h; })[0][1];
    var fmtItem = function (b) { return { name: b.name, sub: b.sub, dotst: 'background: ' + (b.over ? '#E03C31' : col[b.area]), nst: b.over ? 'color: #943333' : '', vst: b.amt > 0 ? 'color: #215F33' : '', val: b.amt === 0 ? '–' : (b.amt > 0 ? '+' : '') + eur(b.amt), open: function () { self.setState({ sel: b.uid }); } }; };
    // Tagesgruppen: Fixkosten eines Tages und Bereichs zu einer Zeile zusammenfassen
    var bundle = function (items) { var out = [], fixBy = {}; items.forEach(function (b) { if (b.kind === 'fix') { (fixBy[b.area] = fixBy[b.area] || []).push(b); } else out.push(b); });
      Object.keys(fixBy).forEach(function (a) { var l = fixBy[a].slice().sort(function (p, q) { return p.amt - q.amt; }); if (l.length === 1) out.push(l[0]); else out.push({ uid: 'bundle:' + l.map(function (b) { return b.uid; }).join(','), d: l[0].d, amt: l.reduce(function (x, b) { return x + b.amt; }, 0), name: l.map(function (b) { return b.short || b.name; }).join(', '), sub: l.length + ' Fixkosten · ' + ({ w: 'Wohnen', m: 'Mobilität', h: 'Haushalt' })[a], area: a, kind: 'fix', href: 'Vertraege.dc.html', parts: l }); });
      return out.sort(function (a, b) { return b.amt - a.amt; }); };
    var groups = [];
    if (s.h <= 30) {
      var byDay = {}; shown.forEach(function (b) { (byDay[b.d] = byDay[b.d] || []).push(b); });
      Object.keys(byDay).map(Number).sort(function (a, b) { return a - b; }).forEach(function (d) { var items = byDay[d], sum = items.reduce(function (a, b) { return a + b.amt; }, 0), over = items.some(function (b) { return b.over; });
        var after = run.points.filter(function (p) { return p.d <= d; }).slice(-1)[0];
        groups.push({ title: over ? 'Überfällig' : self.dayLabel(d), meta: (d === 1 ? 'sofort' : 'in ' + d + ' Tagen') + ' · ' + (sum > 0 ? '+' : '') + eur(sum) + ' €', items: bundle(items).map(fmtItem), saldo: s.area === 'all' && after ? eur(after.bal) : '', saldoLabel: 'Kontostand danach', saldoSt: after && after.bal < self.PUFFER ? 'color: #943333' : '' }); });
    } else {
      var byMon = {}; shown.forEach(function (b) { var x = self.dateOf(b.d), k = x.getFullYear() * 12 + x.getMonth(); (byMon[k] = byMon[k] || []).push(b); });
      Object.keys(byMon).map(Number).sort(function (a, b) { return a - b; }).forEach(function (k) { var items = byMon[k], y = Math.floor(k / 12), m = k % 12, rows = [];
        var ein = items.filter(function (b) { return b.amt > 0; }), fix = items.filter(function (b) { return b.kind === 'fix'; }), rest = items.filter(function (b) { return b.amt <= 0 && b.kind !== 'fix'; });
        if (ein.length) rows.push({ uid: 'ein' + k, d: ein[0].d, amt: ein.reduce(function (a, b) { return a + b.amt; }, 0), name: 'Einnahmen', sub: ein.map(function (b) { return b.name; }).join(', '), area: 'x', kind: 'einnahme', href: 'Einnahmen.dc.html', parts: ein });
        if (fix.length) rows.push({ uid: 'fix' + k, d: fix[0].d, amt: fix.reduce(function (a, b) { return a + b.amt; }, 0), name: 'Fixkosten & Kredite', sub: fix.length + ' Verträge', area: fix[0].area, kind: 'fix', href: 'Vertraege.dc.html', parts: fix });
        rows = rows.concat(rest);
        var lastDay = self.dayIdx(y, m + 1, 0), after = run.points.filter(function (p) { return p.d <= Math.min(lastDay, s.h); }).slice(-1)[0];
        groups.push({ title: self.monthLabel(y, m), meta: items.length + ' Posten · ' + eur(items.reduce(function (a, b) { return a + b.amt; }, 0)) + ' €', items: rows.map(fmtItem), saldo: s.area === 'all' && after ? eur(after.bal) : '', saldoLabel: 'Saldo Monatsende', saldoSt: after && after.bal < self.PUFFER ? 'color: #943333' : '' }); });
    }
    // Auswahl-Sheet
    var selB = null; if (s.sel) { all.forEach(function (b) { if (b.uid === s.sel) selB = b; }); if (!selB && s.sel.indexOf('bundle:') === 0) { var ids = s.sel.slice(7).split(','); var parts = all.filter(function (b) { return ids.indexOf(b.uid) >= 0; }); if (parts.length) selB = { uid: s.sel, name: parts.length + ' Fixkosten am ' + self.dayLabel(parts[0].d), amt: parts.reduce(function (a, b) { return a + b.amt; }, 0), d: parts[0].d, href: 'Vertraege.dc.html', parts: parts }; }
      if (!selB && (s.sel.indexOf('ein') === 0 || s.sel.indexOf('fix') === 0)) { groups.forEach(function (g) { }); } }
    var selParts = selB && selB.parts ? selB.parts.map(function (b) { return { n: b.name, v: (b.amt > 0 ? '+' : '') + eur(b.amt) }; }) : [];
    var endBal = bal + inflow + outflow;
    return {
      toast: s.toast,
      balFmt: eur(bal),
      outlook: s.area === 'all' ? hLabel + ': Zuflüsse +' + eur(inflow) + ' · Abflüsse ' + eur(outflow) + ' → ' + eur(endBal) + ' € am ' + this.dayLabel(s.h) : hLabel + ' · ' + ({ w: 'Wohnen', m: 'Mobilität', h: 'Haushalt' })[s.area] + ': Abflüsse ' + eur(outflow) + ' €',
      warn: s.area === 'all' && run.min.bal < this.PUFFER ? 'Unter dem Mindestpuffer (' + eur(this.PUFFER, 0) + ' €) am ' + this.dayLabel(run.min.d) + ': ' + eur(run.min.bal) + ' €' : '',
      hchips: (''' + HORIZONS + r''').map(function (x) { return { label: x[1], cls: s.h === x[0] ? 'chip lt on' : 'chip lt', pick: function () { self.setState({ h: x[0] }); } }; }),
      chips: this.chipItems('area', [['all', 'Alle'], ['w', 'Wohnen'], ['m', 'Mobilität'], ['h', 'Haushalt']], true),
      groups: groups, empty: groups.length === 0, emptyText: 'Keine geplanten Buchungen in dieser Auswahl.',
      pruef: s.area === 'all' ? 'Prüfung: ' + eur(bal) + ' + ' + eur(inflow) + ' − ' + eur(-outflow) + ' = ' + eur(endBal) + ' €. Rücklagen verändern den Kontostand nicht; ihre Verwendung (HUK, HU, Urlaub) schon.' : 'Ein Konto lässt sich nicht je Bereich aufteilen – „Alle“ zeigt den Saldo.',
      sel: !!selB, selName: selB ? selB.name : '', selHref: selB ? selB.href : 'Main.dc.html', selHasParts: selParts.length > 0, selParts: selParts,
      selText: selB ? (selB.amt === 0 ? 'Termin ohne Planbetrag – erscheint im Kalender und in der Liste, nicht im Verlauf.' : (isPaid(selB) ? 'Als gebucht markiert – Kontostand ' + eur(bal) + ' €. Rückgängig setzt die Planung wieder ein.' : (selB.amt > 0 ? '+' : '') + eur(selB.amt) + ' € am ' + self.dayLabel(selB.d) + '. „Gebucht“ schreibt den Kontostand fort, sobald die Buchung auf dem Konto ist.')) : '',
      selCanPay: !!selB && selB.amt !== 0 && !selB.parts, payLabel: selB && isPaid(selB) ? 'Rückgängig' : 'Als gebucht markieren',
      markPaid: function () { if (!selB) return; var p = Object.assign({}, s.paid); p[selB.uid] = !p[selB.uid]; self.setState({ paid: p, sel: null }); self.say(p[selB.uid] ? selB.name + ' gebucht · Kontostand ' + eur(bal + selB.amt) + ' €' : 'Wieder geplant'); },
      closeSel: this.go('sel', null)
    };
  }'''
    page("Liquiditaet.dc.html", "Liquidität – Termine", body, logic, 'l', EXTRA_CSS + CAL_CSS)

    # ================================================================ Verlauf
    body = tpl('''  <div class="hdr">
    <div class="nav"><a class="back" href="Liquiditaet.dc.html">[BACK]Liquidität</a><p class="ttl">Verlauf</p><a class="act" href="Kontostand.dc.html">Aktualisieren</a></div>
    <p class="sub" style="margin-top: 14px">Kontostand · zuletzt heute 09:12</p>
    <div style="display: flex; align-items: baseline; justify-content: space-between; gap: 14px"><p class="big" style="margin: 4px 0 0">2.410,00 €</p><p style="margin: 0; font-size: 13px; opacity: .85; text-align: right">{{endLine}}</p></div>
    <div class="seg dark" style="margin-top: 14px"><a href="Liquiditaet.dc.html" style="flex: 1; text-align: center; font-size: 13px; font-weight: 600; color: rgba(255,255,255,.8); padding: 6px 0; text-decoration: none">Termine</a><button class="on">Verlauf</button></div>
  </div>

  <div class="hchips" style="margin-top: 14px"><sc-for list="{{hchips}}" as="c" hint-placeholder-count="7"><button class="{{c.cls}}" onClick="{{c.pick}}">{{c.label}}</button></sc-for></div>

  <div style="padding: 14px 20px 0 20px">
    <div class="card" style="padding: 14px 14px 8px">
      <div style="display: flex; align-items: baseline; justify-content: space-between; padding: 0 4px"><p style="margin: 0; font-size: 15px; font-weight: 700">{{title}}</p><p style="margin: 0; font-size: 12px; color: #637894">{{meta}}</p></div>
      <svg width="100%" height="170" viewBox="0 0 350 170" preserveAspectRatio="none" role="img" aria-label="Kontostand-Verlauf" style="display: block; margin-top: 8px">
        <line x1="10" y1="{{yPuffer}}" x2="340" y2="{{yPuffer}}" stroke="#E08A1E" stroke-dasharray="4 3"/>
        <text x="12" y="{{yPufferT}}" font-size="9" fill="#704F2E">Puffer {{pufferFmt}}</text>
        <path d="{{area}}" fill="#2A5480" opacity=".08"/>
        <path d="{{path}}" fill="none" stroke="#2A5480" stroke-width="2" stroke-linejoin="round"/>
        <circle cx="{{minX}}" cy="{{minY}}" r="3.5" fill="#E08A1E" stroke="#FFFFFF" stroke-width="1.5"/>
        <text x="{{minX}}" y="{{minLabelY}}" font-size="9" fill="#704F2E" text-anchor="{{minAnchor}}">{{minFmt}}</text>
        <text x="{{t0x}}" y="166" font-size="10" fill="#637894" text-anchor="start">{{t0}}</text><text x="{{t1x}}" y="166" font-size="10" fill="#637894" text-anchor="middle">{{t1}}</text><text x="{{t2x}}" y="166" font-size="10" fill="#637894" text-anchor="middle">{{t2}}</text><text x="{{t3x}}" y="166" font-size="10" fill="#637894" text-anchor="middle">{{t3}}</text><text x="{{t4x}}" y="166" font-size="10" fill="#637894" text-anchor="end">{{t4}}</text>
      </svg>
    </div>
    <p class="note">{{calc}}</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <div class="f"><p class="l">Mindestpuffer</p><input class="in num" value="{{puffer}}" onChange="{{setPuffer}}" inputmode="decimal"><span style="font-size: 14px; color: #637894">€</span></div>
      <div class="sep"></div>
      <div class="f"><p class="v wrap" style="{{pufferSt}}">{{pufferNote}}</p></div>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Größte Einzelposten <span>ohne Monatsfixkosten und Budgets</span></h2>
    <div class="card">
      <sc-for list="{{big}}" as="b" hint-placeholder-count="4">
        <a class="row" href="{{b.href}}"><span class="dot" style="{{b.dotst}}"></span><div class="mid"><p class="n" style="font-weight: 500">{{b.name}}</p><p class="s">{{b.sub}}</p></div><p class="v" style="{{b.vst}}">{{b.val}}</p>[CHEV]</a>
        <div class="sep"></div>
      </sc-for>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Kontostand-Historie</h2>
    <div class="card">
      <div class="row"><div class="mid"><p class="n">Sa 24. Okt. · 09:12</p><p class="s">manuell · Abweichung zur Planung 0,00 €</p></div><p class="v">2.410,00</p></div>
      <div class="sep"></div>
      <div class="row"><div class="mid"><p class="n">Di 20. Okt.</p><p class="s">nach Bons REWE, dm · Abweichung −4,10 € (Bargeld)</p></div><p class="v">2.532,57</p></div>
      <div class="sep"></div>
      <div class="row"><div class="mid"><p class="n">Do 1. Okt.</p><p class="s">nach Miete, Leasing, Abschlägen</p></div><p class="v">2.964,65</p></div>
    </div>
  </div>
''')
    logic = r'''  constructor(p) { super(p); this.state = { h: 30, puffer: '1.500', toast: '' }; ''' + MON_JS + r''' this.START = 2410; }
''' + JS_SEG + JS_PLAN + r'''
  renderVals() {
    var self = this, s = this.state, R = s.h, puffer = num(s.puffer), col = { w: '#E8A33D', m: '#3C8DBC', h: '#4CAF7A', x: '#215F33' };
    var list = this.plan(R).filter(function (b) { return b.amt !== 0; });
    var run = this.running(list, this.START);
    var pts = [{ d: 0, bal: this.START }].concat(run.points); if (pts[pts.length - 1].d < R) pts.push({ d: R, bal: run.end });
    var vals = pts.map(function (p) { return p.bal; }).concat([puffer]); var mn = Math.min.apply(null, vals) - 200, mx = Math.max.apply(null, vals) + 300;
    var x0 = 10, x1 = 340, y0 = 14, y1 = 150;
    var X = function (d) { return x0 + d / R * (x1 - x0); }, Y = function (v) { return y1 - (v - mn) / (mx - mn) * (y1 - y0); };
    var dpath = ''; pts.forEach(function (p, i) { var prev = pts[i - 1]; if (i === 0) dpath = 'M' + X(p.d).toFixed(1) + ',' + Y(p.bal).toFixed(1); else dpath += ' L' + X(p.d).toFixed(1) + ',' + Y(prev.bal).toFixed(1) + ' L' + X(p.d).toFixed(1) + ',' + Y(p.bal).toFixed(1); });
    var area = dpath + ' L' + x1 + ',' + y1 + ' L' + x0 + ',' + y1 + ' Z';
    var ticks = [0, 1, 2, 3, 4].map(function (i) { return Math.round(R * i / 4); });
    var hLabel = (''' + HORIZONS + r''').filter(function (x) { return x[0] === R; })[0][1];
    var inflow = list.filter(function (b) { return b.amt > 0; }).reduce(function (a, b) { return a + b.amt; }, 0), outflow = list.filter(function (b) { return b.amt < 0; }).reduce(function (a, b) { return a + b.amt; }, 0);
    var big = list.filter(function (b) { return b.amt < 0 && b.kind !== 'fix' && b.kind !== 'var'; }).sort(function (a, b) { return a.amt - b.amt; }).slice(0, 5);
    var below = run.points.filter(function (p) { return p.bal < puffer; });
    return {
      toast: s.toast,
      hchips: (''' + HORIZONS + r''').map(function (x) { return { label: x[1], cls: R === x[0] ? 'chip lt on' : 'chip lt', pick: function () { self.setState({ h: x[0] }); } }; }),
      title: 'Saldo · ' + hLabel, meta: 'Ende ' + eur(run.end) + ' € am ' + this.shortLabel(R),
      endLine: hLabel + ': +' + eur(inflow) + ' / ' + eur(outflow) + ' → ' + eur(run.end) + ' €',
      yPuffer: Y(puffer).toFixed(1), yPufferT: (Y(puffer) - 4).toFixed(1), pufferFmt: eur(puffer, 0),
      path: dpath, area: area,
      minX: X(run.min.d).toFixed(1), minY: Y(run.min.bal).toFixed(1), minLabelY: (Y(run.min.bal) + 13).toFixed(1), minFmt: eur(run.min.bal, 0), minAnchor: run.min.d < R * 0.15 ? 'start' : (run.min.d > R * 0.85 ? 'end' : 'middle'),
      t0: this.shortLabel(ticks[0]), t0x: X(ticks[0]).toFixed(1), t1: this.shortLabel(ticks[1]), t1x: X(ticks[1]).toFixed(1), t2: this.shortLabel(ticks[2]), t2x: X(ticks[2]).toFixed(1), t3: this.shortLabel(ticks[3]), t3x: X(ticks[3]).toFixed(1), t4: this.shortLabel(ticks[4]), t4x: X(ticks[4]).toFixed(1),
      calc: 'Saldo = Kontostand ' + eur(this.START) + ' + Einnahmen ' + eur(inflow) + ' − Abflüsse ' + eur(-outflow) + ' = ' + eur(run.end) + ' €. Rücklagen-Raten sind kein Abfluss; die Jahresbeträge (HUK, Hausrat, Kfz-Steuer) und der Urlaub erscheinen an ihrem Zahltag.',
      puffer: s.puffer, setPuffer: this.set('puffer'),
      pufferSt: below.length ? 'color: #943333' : 'color: #215F33',
      pufferNote: below.length ? 'An ' + below.length + ' Tagen unter dem Puffer, erstmals am ' + this.dayLabel(below[0].d) + ' (' + eur(below[0].bal) + ' €). Vorschlag: Inspektion nach dem Gehalt am 30. zahlen.' : 'Alle Tage über dem Puffer.',
      big: big.map(function (b) { return { name: b.name, sub: self.dayLabel(b.d) + ' · ' + b.sub, href: b.href, dotst: 'background: ' + col[b.area], vst: b.amt > 0 ? 'color: #215F33' : '', val: (b.amt > 0 ? '+' : '') + eur(b.amt) }; })
    };
  }'''
    page("Verlauf.dc.html", "Liquidität – Verlauf", body, logic, 'l', EXTRA_CSS + CAL_CSS)

    # ================================================================ Kontostand aktualisieren
    body = tpl('''  <div class="bar"><a href="Liquiditaet.dc.html">Abbrechen</a><p>Kontostand</p><button style="font-weight: 700" onClick="{{save}}">Sichern</button></div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card" style="padding: 18px 16px 14px">
      <p style="margin: 0; font-size: 13px; color: #637894; text-align: center">Neuer Kontostand · Girokonto</p>
      <div style="display: flex; align-items: baseline; justify-content: center; gap: 6px; margin-top: 8px"><input class="in num" style="font-size: 40px; font-weight: 700; letter-spacing: -0.9px; max-width: 200px; text-align: right; border-bottom-width: 2px" value="{{amt}}" onChange="{{setAmt}}" inputmode="decimal" placeholder="0,00"><span style="font-size: 28px; color: #9AA5B4; font-weight: 700">€</span></div>
      <div style="display: flex; justify-content: center; gap: 8px; margin-top: 10px"><button class="{{d1cls}}" onClick="{{dateToday}}">So 25. Okt.</button><button class="{{d3cls}}" onClick="{{dateMo}}">Mo 27. Okt.</button></div>
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
    logic = r'''  constructor(p) { super(p); this.state = { amt: '1.922,80', day: 3, checks: { 'sw@1': false }, mark: true, rem: true, diffSheet: false, okSheet: false, okText: '', toast: '' }; ''' + MON_JS + r''' this.START = 2410; }
''' + JS_SEG + JS_PLAN + r'''
  renderVals() {
    var self = this, s = this.state, entered = num(s.amt);
    var due = this.plan(s.day).filter(function (b) { return b.amt !== 0; });
    var isOn = function (b) { return s.checks[b.uid] !== undefined ? s.checks[b.uid] : true; };
    var checked = due.filter(isOn);
    var expected = this.START + checked.reduce(function (a, b) { return a + b.amt; }, 0);
    var diff = entered - expected, abs = Math.abs(diff), ok = abs < 0.005;
    return {
      toast: s.toast,
      amt: s.amt, setAmt: this.set('amt'),
      dateLabel: s.day === 1 ? 'So 25. Okt.' : 'Mo 27. Okt.', d1cls: s.day === 1 ? 'chip lt on' : 'chip lt', d3cls: s.day === 3 ? 'chip lt on' : 'chip lt', dateToday: function () { self.setState({ day: 1 }); }, dateMo: function () { self.setState({ day: 3 }); },
      items: due.map(function (b) { var on = isOn(b); return { name: b.name, sub: self.dayLabel(b.d) + ' · ' + b.sub, val: (b.amt > 0 ? '+' : '') + eur(b.amt), vst: on ? (b.amt > 0 ? 'color: #215F33' : '') : 'color: #943333; text-decoration: line-through', cst: on ? 'background: #D6EDDB; color: #215F33' : 'background: #FBE9E7; color: #943333', mark: on ? '✓' : '✕', flip: function () { var c = Object.assign({}, s.checks); c[b.uid] = !on; self.setState({ checks: c }); } }; }),
      noItems: due.length === 0,
      expected: eur(expected),
      diffText: !(entered > 0) ? 'Kontostand eingeben' : (ok ? '0,00 € · passt zur Planung' : (diff > 0 ? '+' : '−') + eur(abs) + ' € ' + (diff > 0 ? 'mehr' : 'weniger') + ' als geplant'),
      diffSt: !(entered > 0) ? 'color: #9AA5B4' : (ok ? 'color: #215F33; font-weight: 600' : 'color: #943333; font-weight: 600'),
      note: 'Antippen schaltet eine Buchung auf „noch nicht abgebucht“ (✕) oder „abgebucht“ (✓). Erwartet = 2.410,00 + Summe der abgebuchten Posten. ' + (ok ? 'Alles erfasst.' : (entered > 0 ? 'Eine Differenz ist eine Buchung, die Mnemor noch nicht kennt – z. B. Bargeld oder eine Kartenzahlung ohne Bon.' : '')),
      markCls: this.tog('mark'), flipMark: this.flip('mark'), remCls: this.tog('rem'), flipRem: this.flip('rem'),
      save: function () {
        if (!(entered > 0)) { self.say('Bitte den Kontostand eingeben'); return; }
        if (!ok) { self.setState({ diffSheet: true }); return; }
        self.setState({ okSheet: true, okText: eur(entered) + ' € am ' + (s.day === 1 ? '25. Okt.' : '27. Okt.') + (s.mark && checked.length ? ' · ' + checked.length + ' Buchungen als bezahlt markiert (' + checked.map(function (b) { return b.name; }).join(', ') + ')' : '') + '. Der Verlauf wird ab diesem Stand neu gerechnet.' });
      },
      diffSheet: s.diffSheet, closeDiff: this.go('diffSheet', false),
      diffTitle: (diff > 0 ? '+' : '−') + eur(abs) + ' € nicht erfasst',
      diffBody: diff < 0 ? 'Vom Konto sind ' + eur(abs) + ' € mehr abgegangen als geplant. Als Buchung erfassen (Bon, Kartenzahlung, Abhebung) – dann stimmen Budget und Sparpotenzial wieder.' : 'Auf dem Konto sind ' + eur(abs) + ' € mehr als geplant – vermutlich eine Einnahme oder Rückerstattung. Als Einnahme erfassen oder trotzdem sichern.',
      okSheet: s.okSheet, okText: s.okText
    };
  }'''
    page("Kontostand.dc.html", "Kontostand aktualisieren", body, logic, 'l', EXTRA_CSS + CAL_CSS)

    # ================================================================ Kalender (einfaches Hilfsmittel, von der Übersicht aus)
    body = tpl('''  <div class="hdr" style="padding-bottom: 16px">
    <div class="nav"><a class="back" href="Main.dc.html">[BACK]Übersicht</a><p class="ttl">Kalender</p><button class="act" onClick="{{today}}">Heute</button></div>
    <div style="display: flex; align-items: center; justify-content: space-between; margin-top: 14px"><button class="chip" style="width: 36px; padding: 0; justify-content: center" onClick="{{calPrev}}" aria-label="Vormonat">‹</button><h1 style="margin: 0; font-size: 24px">{{calTitle}}</h1><button class="chip" style="width: 36px; padding: 0; justify-content: center" onClick="{{calNext}}" aria-label="Folgemonat">›</button></div>
    <p class="sub">{{calMonthLine}}</p>
  </div>

  <div style="padding: 14px 20px 0 20px">
    <div class="card">
      <div class="cal">
        <span class="wd">Mo</span><span class="wd">Di</span><span class="wd">Mi</span><span class="wd">Do</span><span class="wd">Fr</span><span class="wd">Sa</span><span class="wd">So</span>
        <sc-for list="{{cells}}" as="c" hint-placeholder-count="35"><button class="{{c.cls}}" onClick="{{c.pick}}" aria-label="{{c.aria}}"><span>{{c.n}}</span><span class="dots"><sc-for list="{{c.dots}}" as="x" hint-placeholder-count="0"><i style="{{x.st}}"></i></sc-for></span></button></sc-for>
      </div>
      <div style="display: flex; gap: 12px; padding: 0 14px 12px; font-size: 11px; color: #637894; flex-wrap: wrap"><span><span class="dot" style="background: #215F33; width: 7px; height: 7px; margin-right: 4px"></span>Einnahme</span><span><span class="dot" style="background: #E8A33D; width: 7px; height: 7px; margin-right: 4px"></span>Wohnen</span><span><span class="dot" style="background: #3C8DBC; width: 7px; height: 7px; margin-right: 4px"></span>Mobilität</span><span><span class="dot" style="background: #4CAF7A; width: 7px; height: 7px; margin-right: 4px"></span>Haushalt</span><span><span class="dot" style="background: #E03C31; width: 7px; height: 7px; margin-right: 4px"></span>überfällig</span></div>
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <h2 class="h2" style="margin-bottom: 6px">{{dayTitle}} <span>{{dayMeta}}</span></h2>
    <div class="card">
      <sc-for list="{{items}}" as="b" hint-placeholder-count="2">
        <a class="row" href="{{b.href}}"><span class="dot" style="{{b.dotst}}"></span><div class="mid"><p class="n" style="{{b.nst}}">{{b.name}}</p><p class="s">{{b.sub}}</p></div><p class="v" style="{{b.vst}}">{{b.val}}</p>[CHEV]</a>
        <div class="sep"></div>
      </sc-for>
      <sc-if value="{{noItems}}" hint-placeholder-val="{{false}}"><div class="f"><p class="v ph">{{emptyText}}</p></div></sc-if>
    </div>
    <p class="note">Nur ein Blick auf die Tage – Beträge und Saldo rechnet die Liquidität. Termine mit Erinnerung stehen auch im iOS-Kalender „Mnemor“ (Einstellungen).</p>
  </div>
''')
    logic = r'''  constructor(p) { super(p); this.state = { cal: 0, selDay: 0, toast: '' }; ''' + MON_JS + r''' }
''' + JS_SEG + JS_PLAN + r'''
  renderVals() {
    var self = this, s = this.state, col = { w: '#E8A33D', m: '#3C8DBC', h: '#4CAF7A', x: '#215F33' };
    var all = this.plan(365);
    var cy = 2026 + Math.floor((9 + s.cal) / 12), cm = (9 + s.cal) % 12, first = new Date(cy, cm, 1), dim = new Date(cy, cm + 1, 0).getDate(), lead = (first.getDay() + 6) % 7, cells = [];
    for (var i = 0; i < 42; i++) { var dn = i - lead + 1; if (dn < 1 || dn > dim) { cells.push({ n: '', cls: 'dim', aria: '', dots: [], pick: function () {} }); continue; }
      (function (dn) { var d = self.dayIdx(cy, cm, dn), its = all.filter(function (b) { return b.d === d; }), dots = [];
        if (its.some(function (b) { return b.amt > 0; })) dots.push({ st: 'background: #215F33' });
        ['w', 'm', 'h'].forEach(function (a) { if (its.some(function (b) { return b.amt <= 0 && b.area === a; })) dots.push({ st: 'background: ' + (its.some(function (b) { return b.over && b.area === a; }) ? '#E03C31' : col[a]) }); });
        cells.push({ n: String(dn), cls: (d === s.selDay ? 'on' : '') + (d === 0 ? ' today' : '') + (d < 0 ? ' dim' : ''), aria: dn + '.' + (cm + 1) + '.', dots: dots.slice(0, 3), pick: function () { self.setState({ selDay: d }); } }); })(dn);
    }
    var monthItems = all.filter(function (b) { var x = self.dateOf(b.d); return x.getFullYear() === cy && x.getMonth() === cm; });
    var items = s.selDay >= 0 ? all.filter(function (b) { return b.d === s.selDay; }) : [];
    var sum = items.reduce(function (a, b) { return a + b.amt; }, 0);
    return {
      toast: s.toast,
      calTitle: this.monthLabel(cy, cm), calPrev: function () { if (s.cal > 0) self.setState({ cal: s.cal - 1, selDay: -1 }); else self.say('Vergangene Monate: Rechnungen › Bezahlt'); }, calNext: function () { if (s.cal < 11) self.setState({ cal: s.cal + 1, selDay: -1 }); else self.say('Planung reicht 12 Monate'); },
      today: function () { self.setState({ cal: 0, selDay: 0 }); },
      calMonthLine: monthItems.length + ' Posten · ' + monthItems.filter(function (b) { return b.kind === 'termin'; }).length + ' Termine · Zahltage ' + monthItems.filter(function (b) { return b.amt > 0; }).map(function (b) { return self.shortLabel(b.d); }).filter(function (v, i, a) { return a.indexOf(v) === i; }).join(', '),
      cells: cells,
      dayTitle: s.selDay >= 0 ? this.dayLabel(s.selDay) : 'Tag wählen', dayMeta: s.selDay >= 0 ? (items.length ? items.length + ' Posten · ' + (sum > 0 ? '+' : '') + eur(sum) + ' €' : 'nichts geplant') : '',
      items: items.map(function (b) { return { name: b.name, sub: b.sub, href: b.href, dotst: 'background: ' + (b.over ? '#E03C31' : col[b.area]), nst: b.over ? 'color: #943333' : '', vst: b.amt > 0 ? 'color: #215F33' : '', val: b.amt === 0 ? '–' : (b.amt > 0 ? '+' : '') + eur(b.amt) }; }),
      noItems: items.length === 0, emptyText: s.selDay < 0 ? 'Tag antippen.' : (s.selDay === 0 ? 'Heute ist nichts fällig.' : 'Nichts geplant.')
    };
  }'''
    page("Kalender.dc.html", "Kalender", body, logic, 'u', EXTRA_CSS + CAL_CSS)


if __name__ == "__main__":
    build()
