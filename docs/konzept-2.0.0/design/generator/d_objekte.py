# -*- coding: utf-8 -*-
"""Kategorie, Kategorie anlegen, Objekt anlegen, Rücklage, Termin, Monatsrechnung – alle Felder echt, jede Taste hat eine Wirkung."""
from common import *

def tpl(s):
    return (s.replace('[CHEV]', CHEV).replace('[BACK]', BACK).replace('[CHECK]', CHECK).replace('[CAM]', CAM)
             .replace('[W]', W).replace('[M]', M).replace('[H]', H))

SYMBOLS = [
    ("bolt", '<svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M13 2L4 14h7l-1 8 9-12h-7z"/></svg>'),
    ("home", '<svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 11l9-8 9 8M5 10v10h14V10"/></svg>'),
    ("tool", '<svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.7 6.3a4 4 0 0 0 5 5L13 18l-3 3-3-3 3-3-7-7 3-3 7 7"/></svg>'),
    ("leaf", '<svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 19C5 9 11 4 20 4c0 9-5 15-15 15z"/><path d="M5 19l7-7"/></svg>'),
    ("shield", '<svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/></svg>'),
    ("car", '<svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 11l1.5-4.5A2 2 0 0 1 8.4 5h7.2a2 2 0 0 1 1.9 1.5L19 11h1v6h-2v2h-3v-2H9v2H6v-2H4v-6z"/></svg>'),
]
SYM_JS = json.dumps([s[0] for s in SYMBOLS])
SYM_MARKUP = "".join(
    f'<button class="sym {{{{sym{i}}}}}" aria-label="Symbol {name}" onClick="{{{{pickSym{i}}}}}">{svg}</button>'
    for i, (name, svg) in enumerate(SYMBOLS))

EXTRA_CSS = """
.sym{width:40px;height:40px;border-radius:20px;border:1px solid #D1DBE8;background:#FFFFFF;color:#637894;display:inline-flex;align-items:center;justify-content:center;cursor:pointer;padding:0}
.sym.on{background:#2A5480;border-color:#2A5480;color:#FFFFFF}
.chk{width:24px;height:24px;border-radius:12px;flex:none;display:inline-flex;align-items:center;justify-content:center;border:2px solid #C4CCD6;background:none;padding:0;cursor:pointer;color:#FFFFFF}
.chk.on{background:#2A5480;border-color:#2A5480}
.month{display:flex;gap:6px;align-items:flex-end;height:96px;padding:0 4px}
.month button{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:flex-end;gap:4px;background:none;border:0;padding:0;cursor:pointer;font:inherit;height:100%}
.month i{display:block;width:100%;border-radius:5px 5px 0 0;background:#D1DBE8}
.month i.on{background:#2A5480}
.month span{font-size:11px;color:#637894}
.month span.on{color:#16243A;font-weight:700}
"""


def build():
    # ================================================================ Kategorie (Wohnen › Strom)
    body = tpl('''  <div class="hdr">
    <div class="nav"><a class="back" href="Wohnen.dc.html">[BACK]Wohnen</a><p class="ttl">Oktober 2026</p><button class="act" onClick="{{toggleEdit}}">{{editLabel}}</button></div>
    <div style="display: flex; align-items: center; gap: 10px; margin-top: 14px"><span class="dot" style="background: [W]; width: 12px; height: 12px"></span><h1 style="margin: 0">{{name}}</h1></div>
    <p class="sub" style="white-space: nowrap">{{sub}}</p>
    <p class="sub" style="margin-top: 2px">{{sub2}}</p>
  </div>

  <sc-if value="{{edit}}" hint-placeholder-val="{{false}}">
  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Kategorie bearbeiten</h2>
    <div class="card">
      <div class="f"><p class="l">Name</p><input class="in" value="{{nameDraft}}" onChange="{{setNameDraft}}"></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Kostenart</p><div class="seg"><sc-for list="{{kostenart}}" as="s" hint-placeholder-count="3"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Budget</p><input class="in num" value="{{budgetDraft}}" onChange="{{setBudgetDraft}}" inputmode="decimal" placeholder="kein Budget"><span style="font-size: 14px; color: #637894">€ / Monat</span></div>
      <div class="sep"></div>
      <div class="f"><p class="v wrap">{{budgetNote}}</p></div>
    </div>
    <div style="display: flex; gap: 10px; margin-top: 12px"><button class="btn pri sm" onClick="{{saveEdit}}">Sichern</button><button class="btn danger sm" onClick="{{askHide}}">Ausblenden</button></div>
  </div>
  </sc-if>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Buchungen im {{monthName}} <span>{{bookCount}} · {{monthSum}} €</span></h2>
    <div class="card">
      <sc-for list="{{bookings}}" as="b" hint-placeholder-count="2">
        <a class="row" href="{{b.href}}"><div class="mid"><p class="n">{{b.name}}</p><p class="s">{{b.sub}}</p></div><div style="text-align: right"><p class="v" style="{{b.vst}}">{{b.val}}</p><span class="cap" style="{{b.capst}}">{{b.cap}}</span></div></a>
        <div class="sep"></div>
      </sc-for>
      <sc-if value="{{noBookings}}" hint-placeholder-val="{{false}}"><div class="row"><p class="s">Keine Buchungen in diesem Monat.</p></div></sc-if>
    </div>
  </div>

  <div style="padding: 20px 20px 0 20px">
    <h2 class="h2">Letzte 6 Monate <span>Ø {{avg}} € · antippbar</span></h2>
    <div class="card" style="padding: 14px 16px 10px">
      <div class="month">
        <sc-for list="{{months}}" as="m" hint-placeholder-count="6"><button onClick="{{m.pick}}" aria-label="{{m.label}}"><i class="{{m.cls}}" style="{{m.st}}"></i><span class="{{m.cls}}">{{m.label}}</span></button></sc-for>
      </div>
    </div>
  </div>

  <div style="padding: 20px 20px 0 20px">
    <h2 class="h2">Zu dieser Kategorie</h2>
    <div class="card">
      <a class="row" href="Vertrag.dc.html"><div class="mid"><p class="n">Vertrag Stadtwerke Strom</p><p class="s">Abschlag 98,00 · seit 01/2024</p></div>[CHEV]</a>
      <div class="sep"></div>
      <a class="row" href="Budgets.dc.html"><div class="mid"><p class="n">Budget</p><p class="s">{{budgetLine}}</p></div>[CHEV]</a>
      <div class="sep"></div>
      <a class="row" href="Termin.dc.html"><div class="mid"><p class="n">Termin Zählerstand</p><p class="s">Di 15. Dez. · jährlich</p></div>[CHEV]</a>
      <div class="sep"></div>
      <button class="row" onClick="{{openDoc}}"><div class="mid"><p class="n">Dokumente</p><p class="s">Jahresabrechnung 2025 (PDF) · Vertrag (PDF)</p></div>[CHEV]</button>
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px; display: flex; gap: 10px">
    <a class="btn pri" href="Erfassen.dc.html">+ Rechnung</a>
    <a class="btn sec2" href="VertragNeu.dc.html">+ Vertrag</a>
  </div>
''') + DOC_OVERLAY_D + sheet("confirmHide", "Kategorie ausblenden?", "Buchungen bleiben erhalten und zählen weiter. Die Kategorie verschwindet nur aus den Listen und lässt sich in den Einstellungen wieder einblenden.", '<button class="btn sec2" onClick="{{cancelHide}}">Abbrechen</button><a class="btn danger" href="Wohnen.dc.html">Ausblenden</a>')
    logic = r'''  constructor(p) { super(p); this.state = { edit: false, name: 'Strom', nameDraft: 'Strom', kostenart: 'fix', budget: '', budgetDraft: '', month: 5, showDoc: false, confirmHide: false, toast: '' };
    this.MONTHS = [['Mai', 98, 1], ['Jun', 98, 1], ['Jul', 98, 1], ['Aug', 98, 1], ['Sep', 98, 1], ['Okt', 240, 2]];
    this.OKT = [
      { name: 'Nachzahlung Strom 2025', sub: 'Rechnung · fällig 21. Okt.', val: '142,00', vst: 'color: #943333', cap: 'überfällig', capst: 'background: #F7D4D1; color: #943333', href: 'Rechnung.dc.html' },
      { name: 'Abschlag Oktober', sub: 'Vertrag · 1. Okt. · monatlich', val: '98,00', vst: '', cap: 'abgebucht', capst: 'background: #D6EDDB; color: #215F33', href: 'Vertrag.dc.html' } ]; }
''' + JS_SEG + r'''
  renderVals() {
    var self = this, s = this.state, mi = s.month, mo = this.MONTHS[mi];
    var bookings = mi === 5 ? this.OKT : [{ name: 'Abschlag ' + mo[0], sub: 'Vertrag · 1. ' + mo[0] + '. · monatlich', val: '98,00', vst: '', cap: 'abgebucht', capst: 'background: #D6EDDB; color: #215F33', href: 'Vertrag.dc.html' }];
    var avg = this.MONTHS.reduce(function (a, m) { return a + m[1]; }, 0) / 6;
    var budget = num(s.budget);
    var fixNow = 98, varNow = mi === 5 ? 142 : 0;
    return {
      toast: s.toast,
      name: s.name,
      sub: eur(fixNow + varNow) + ' € im ' + (mi === 5 ? 'Oktober' : mo[0] + '.') + ' · fix ' + eur(fixNow) + ' · variabel ' + eur(varNow), sub2: 'Objekt Wohnung Hauptstr. 12',
      edit: s.edit, editLabel: s.edit ? 'Fertig' : 'Bearbeiten',
      toggleEdit: function () { self.setState({ edit: !s.edit, nameDraft: s.name, budgetDraft: s.budget }); },
      nameDraft: s.nameDraft, setNameDraft: this.set('nameDraft'),
      kostenart: this.segItems('kostenart', [['var', 'Variabel'], ['fix', 'Fix'], ['kredit', 'Kredit']]),
      budgetDraft: s.budgetDraft, setBudgetDraft: this.set('budgetDraft'),
      budgetNote: s.kostenart === 'fix' ? 'Fixkosten brauchen kein Budget – der Vertrag legt den Betrag fest. Ein Budget wirkt nur bei variabler Kostenart.' : (num(s.budgetDraft) > 0 ? 'Budget ' + eur(num(s.budgetDraft)) + ' € · Rest fließt in „Budgets noch offen“ und mindert Noch frei.' : 'Ohne Budget zählen nur die tatsächlichen Buchungen.'),
      saveEdit: function () { if (!s.nameDraft.trim()) { self.say('Name darf nicht leer sein'); return; } self.setState({ name: s.nameDraft.trim(), budget: s.kostenart === 'fix' ? '' : s.budgetDraft, edit: false }); self.say('Gespeichert'); },
      askHide: this.go('confirmHide', true), cancelHide: this.go('confirmHide', false), confirmHide: s.confirmHide,
      monthName: mi === 5 ? 'Oktober' : ({ Mai: 'Mai', Jun: 'Juni', Jul: 'Juli', Aug: 'August', Sep: 'September' })[mo[0]],
      bookCount: bookings.length, monthSum: eur(mo[1]),
      bookings: bookings, noBookings: bookings.length === 0,
      avg: eur(avg),
      months: this.MONTHS.map(function (m, i) { return { label: m[0], cls: i === mi ? 'on' : '', st: 'height: ' + Math.max(6, Math.round(m[1] / 240 * 60)) + 'px', pick: function () { self.setState({ month: i }); } }; }),
      budgetLine: s.kostenart === 'fix' ? 'keins – Fixkosten brauchen keins' : (budget > 0 ? eur(budget) + ' € im Monat' : 'kein Budget gesetzt'),
      openDoc: this.go('showDoc', true), closeDoc: this.go('showDoc', false), showDoc: s.showDoc, shareDoc: function () { self.say('PDF geteilt'); },
      docTitle: 'Jahresabrechnung 2025.pdf', docHead: 'Stadtwerke Mainstadt GmbH', docSub: 'Jahresabrechnung Strom 2025 · Kd 4471120',
      docLine1: 'Verbrauch 2.980 kWh · Abschläge 12 × 84,00 €', docLine2: 'Rechnungsbetrag 1.156,70 € · Nachzahlung 142,00 €', docLine3: 'Weitere Dokumente: Vertrag.pdf (03/2024)'
    };
  }'''
    page("Kategorie.dc.html", "Kategorie Wohnen › Strom", body, logic, 'u', EXTRA_CSS)

    # ================================================================ Kategorie anlegen
    body = tpl('''  <div class="bar"><a href="Wohnen.dc.html">Abbrechen</a><p>Neue Kategorie</p><button style="font-weight: 700" onClick="{{create}}">Anlegen</button></div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Bereich</h2>
    <div class="card" style="padding: 10px 12px"><div class="seg"><sc-for list="{{areas}}" as="s" hint-placeholder-count="3"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Vorschläge für {{areaLabel}} <span>{{sugCount}} noch nicht angelegt</span></h2>
    <div class="card">
      <div style="display: flex; flex-wrap: wrap; gap: 8px; padding: 12px 16px 14px">
        <sc-for list="{{sugs}}" as="c" hint-placeholder-count="6"><button class="{{c.cls}}" onClick="{{c.pick}}">{{c.label}}</button></sc-for>
      </div>
    </div>
    <p class="note">Antippen übernimmt Name, Kostenart und Symbol. Alles bleibt änderbar.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Eigene Kategorie</h2>
    <div class="card">
      <div class="f"><p class="l">Name</p><input class="in" value="{{name}}" onChange="{{setName}}" placeholder="z. B. Schornsteinfeger"></div>
      <div class="sep"></div>
      <sc-if value="{{ruleHint}}" hint-placeholder-val="{{false}}"><button class="f" onClick="{{applyRule}}"><p class="v wrap" style="color: #2A5480">{{ruleHint}}</p><span class="cap" style="background: #E6EEF6; color: #2A5480">Übernehmen</span></button><div class="sep"></div></sc-if>
      <div class="f"><p class="l">Kostenart</p><div class="seg"><sc-for list="{{kostenart}}" as="s" hint-placeholder-count="3"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Objekt</p><div style="display: flex; gap: 8px; flex-wrap: wrap"><sc-for list="{{objOptions}}" as="o" hint-placeholder-count="2"><button class="{{o.cls}}" onClick="{{o.pick}}">{{o.t}}</button></sc-for></div></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Symbol</p><div style="display: flex; gap: 8px; flex-wrap: wrap">''' + SYM_MARKUP + '''</div></div>
      <div class="sep"></div>
      <sc-if value="{{isVar}}" hint-placeholder-val="{{true}}"><div class="f"><p class="l">Budget</p><input class="in num" value="{{budget}}" onChange="{{setBudget}}" inputmode="decimal" placeholder="optional"><span style="font-size: 14px; color: #637894">€ / Monat</span></div></sc-if>
      <sc-if value="{{isFix}}" hint-placeholder-val="{{false}}"><div class="f"><p class="l">Jahresbetrag</p><input class="in num" value="{{yearly}}" onChange="{{setYearly}}" inputmode="decimal" placeholder="für Rücklage"><span style="font-size: 14px; color: #637894">€ / Jahr</span></div></sc-if>
    </div>
    <p class="note">{{kaNote}}</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Danach anlegen</h2>
    <div class="card">
      <div class="f"><p class="v wrap" style="font-weight: 500; font-size: 15px">Termin</p><p class="v ph" style="flex: none; width: auto; font-size: 13px; white-space: normal; text-align: right; max-width: 150px">{{terminText}}</p><button class="{{terminCls}}" aria-label="Termin anlegen" onClick="{{flipTermin}}"></button></div>
      <div class="sep"></div>
      <div class="f"><p class="v wrap" style="font-weight: 500; font-size: 15px">Rücklage</p><p class="v ph" style="flex: none; width: auto; font-size: 13px; white-space: normal; text-align: right; max-width: 150px">{{resText}}</p><button class="{{resCls}}" aria-label="Rücklage anlegen" onClick="{{flipRes}}"></button></div>
    </div>
    <p class="note">Regel: Ortsgebundenes (Internet, Rundfunkbeitrag, Energie, Hausrat) gehört zu Wohnen; Personengebundenes (Mobilfunk, Streaming, Mitgliedschaften) zu Haushalt; Fahrzeuggebundenes zu Mobilität.</p>
  </div>
''') + sheet("blocked", "Noch etwas fehlt", "{{blockMsg}}", '<button class="btn pri" onClick="{{closeBlocked}}">Verstanden</button>') \
      + sheet("done", "Kategorie angelegt", "{{doneMsg}}", '<a class="btn pri" href="{{targetHref}}">Zum Bereich {{areaLabel}}</a><a class="btn sec2" href="Termin.dc.html" style="flex: 0 0 auto; padding: 0 14px">Termin</a>')
    logic = r'''  constructor(p) { super(p); this.state = { area: 'wohnen', name: '', kostenart: 'fix', obj: '', sym: 0, budget: '', yearly: '', termin: false, res: false, blocked: false, blockMsg: '', done: false, doneMsg: '', toast: '' };
    this.SUG = {
      wohnen: [['Grundsteuer', 'fix', 1, 'jährlich · Bescheid', 420], ['Gebäudeversicherung', 'fix', 4, 'jährlich', 380], ['Schornsteinfeger', 'fix', 1, 'jährlich · Kehrung', 90], ['Heizungswartung', 'fix', 2, 'jährlich', 180], ['Garten', 'var', 3, '', 0], ['Reinigung', 'var', 1, '', 0], ['Hausgeld / WEG', 'fix', 1, 'monatlich', 0], ['Stellplatz', 'fix', 5, 'monatlich', 0], ['Möbel & Einrichtung', 'var', 1, '', 0]],
      mobilitaet: [['Parken & Maut', 'var', 5, '', 0], ['Fahrrad & E-Bike', 'var', 2, '', 0], ['Carsharing', 'var', 5, '', 0], ['Taxi', 'var', 5, '', 0], ['Bahn-Einzelfahrten', 'var', 5, '', 0]],
      haushalt: [['Kinderbetreuung', 'fix', 1, 'monatlich', 0], ['Bildung', 'var', 1, '', 0], ['Geschenke', 'var', 3, '', 0], ['Spenden', 'var', 4, '', 0], ['Taschengeld', 'fix', 1, 'monatlich', 0], ['Haustier', 'var', 3, '', 0]]
    };
    this.OBJS = { wohnen: [['', 'Kein Objekt (ganzer Bereich)'], ['whg', 'Wohnung Hauptstr. 12']], mobilitaet: [['', 'Kein Objekt (ganzer Bereich)'], ['vw', 'VW ID.3'], ['ticket', 'Deutschlandticket']], haushalt: [['', 'Kein Objekt (gemeinsam)'], ['anna', 'Anna'], ['ben', 'Ben']] };
    this.RULES = [[/internet|festnetz|dsl|glasfaser|rundfunk|strom|gas|wasser|hausrat|grundsteuer|miete|heizung/i, 'wohnen', 'ortsgebunden'], [/mobilfunk|handy|streaming|netflix|spotify|fitness|verein|mitglied|zahnarzt|arzt|kleidung/i, 'haushalt', 'personengebunden'], [/kfz|auto|reifen|werkstatt|tanken|laden|parken|maut|ticket|bahn|fahrrad|carsharing|taxi/i, 'mobilitaet', 'fahrzeuggebunden']]; }
''' + JS_SEG + r'''
  renderVals() {
    var self = this, s = this.state, area = s.area;
    var labels = { wohnen: 'Wohnen', mobilitaet: 'Mobilität', haushalt: 'Haushalt' }, hrefs = { wohnen: 'Wohnen.dc.html', mobilitaet: 'Akte.dc.html', haushalt: 'Haushalt.dc.html' };
    var sugs = this.SUG[area];
    var rule = null; this.RULES.forEach(function (r) { if (!rule && r[0].test(s.name) && r[1] !== area) rule = r; });
    var yearly = num(s.yearly), rate = yearly > 0 ? yearly / 12 : 0;
    var vals = {
      toast: s.toast,
      areas: this.segItems('area', [['wohnen', 'Wohnen'], ['mobilitaet', 'Mobilität'], ['haushalt', 'Haushalt']]),
      areaLabel: labels[area], targetHref: hrefs[area],
      sugCount: sugs.length,
      sugs: sugs.map(function (g) { return { label: g[0], cls: s.name === g[0] ? 'chip lt on' : 'chip lt', pick: function () { self.setState({ name: g[0], kostenart: g[1], sym: g[2], yearly: g[4] ? String(g[4]) : '', termin: !!g[3] && g[3].indexOf('jährlich') >= 0, res: g[4] > 0 }); } }; }),
      name: s.name, setName: this.set('name'),
      ruleHint: rule ? ('„' + s.name.trim() + '“ ist ' + rule[2] + ' → gehört zu ' + labels[rule[1]]) : '',
      applyRule: function () { if (rule) self.setState({ area: rule[1], obj: '' }); },
      kostenart: this.segItems('kostenart', [['var', 'Variabel'], ['fix', 'Fix'], ['kredit', 'Kredit']]),
      isVar: s.kostenart === 'var', isFix: s.kostenart === 'fix',
      objOptions: this.OBJS[area].map(function (o) { return { t: o[1], cls: s.obj === o[0] ? 'chip lt on' : 'chip lt', pick: function () { self.setState({ obj: o[0] }); } }; }),
      budget: s.budget, setBudget: this.set('budget'), yearly: s.yearly, setYearly: this.set('yearly'),
      kaNote: s.kostenart === 'var' ? 'Variabel: Buchungen zählen zu den Ausgaben des Monats; ein Budget macht den Rest in „Budgets noch offen“ sichtbar.' : (s.kostenart === 'fix' ? 'Fix: monatlicher oder vierteljährlicher Betrag zählt zu den Fixkosten; ein Jahresbetrag wird als Rücklage-Rate (÷ 12) geführt.' : 'Kredit: Rate zählt zu Fixkosten & Kredite, Restschuld im Tilgungsplan.'),
      terminCls: this.tog('termin'), flipTermin: this.flip('termin'), terminText: s.termin ? (s.name || 'Kategorie') + ' · jährlich · Erinnerung 14 Tage vorher' : 'kein Termin',
      resCls: this.tog('res'), flipRes: this.flip('res'), resText: s.res ? (rate > 0 ? eur(yearly) + ' €/Jahr → ' + eur(rate) + ' €/Monat' : 'Jahresbetrag oben eintragen') : 'keine Rücklage',
      blocked: s.blocked, blockMsg: s.blockMsg, closeBlocked: this.go('blocked', false),
      done: s.done, doneMsg: s.doneMsg,
      create: function () {
        if (!s.name.trim()) { self.setState({ blocked: true, blockMsg: 'Bitte einen Namen eingeben oder einen Vorschlag antippen.' }); return; }
        if (s.res && !(rate > 0)) { self.setState({ blocked: true, blockMsg: 'Für die Rücklage fehlt der Jahresbetrag.' }); return; }
        var msg = '„' + s.name.trim() + '“ liegt jetzt in ' + labels[area] + ' (' + ({ var: 'variabel', fix: 'fix', kredit: 'Kredit' })[s.kostenart] + ')';
        if (s.res) msg += ' · Rücklage ' + eur(rate) + ' €/Monat angelegt – mindert den Spielraum ab November';
        if (s.termin) msg += ' · Termin jährlich angelegt';
        if (num(s.budget) > 0 && s.kostenart === 'var') msg += ' · Budget ' + eur(num(s.budget)) + ' €';
        self.setState({ done: true, doneMsg: msg + '.' });
      }
    };
    for (var i = 0; i < 6; i++) { (function (i) { vals['sym' + i] = s.sym === i ? 'on' : ''; vals['pickSym' + i] = function () { self.setState({ sym: i }); }; })(i); }
    return vals;
  }'''
    page("KategorieNeu.dc.html", "Kategorie anlegen", body, logic, 'u', EXTRA_CSS)

    # ================================================================ Objekt anlegen
    body = tpl('''  <div class="bar"><a href="{{backHref}}">Abbrechen</a><p>Neues Objekt</p><button style="font-weight: 700" onClick="{{create}}">Anlegen</button></div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <div class="f"><p class="l">Bereich</p><div class="seg"><sc-for list="{{areas}}" as="s" hint-placeholder-count="3"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Typ</p><div class="seg"><sc-for list="{{types}}" as="s" hint-placeholder-count="3"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Name</p><input class="in" value="{{name}}" onChange="{{setName}}" placeholder="{{namePh}}"></div>
      <sc-for list="{{fields}}" as="x" hint-placeholder-count="2">
        <div class="sep"></div>
        <div class="f"><p class="l">{{x.label}}</p><input class="in" value="{{x.value}}" onChange="{{x.set}}" placeholder="{{x.ph}}"><span style="font-size: 14px; color: #637894; flex: none">{{x.unit}}</span></div>
      </sc-for>
      <sc-if value="{{isKfz}}" hint-placeholder-val="{{true}}">
        <div class="sep"></div>
        <button class="f" onClick="{{scan}}"><p class="l">Dokument</p><p class="v ph">{{scanText}}</p><span class="cap" style="background: #E6EEF6; color: #2A5480">[CAM] Scannen</span></button>
      </sc-if>
    </div>
    <p class="note">{{typeNote}}</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Termine anlegen <span>Vorlage {{typeLabel}}</span></h2>
    <div class="card">
      <sc-for list="{{templates}}" as="t" hint-placeholder-count="3">
        <div class="f"><button class="{{t.cls}}" aria-label="{{t.name}}" onClick="{{t.flip}}">[CHECK]</button><p class="v wrap">{{t.name}} <span style="color: #637894">· {{t.sub}}</span></p></div>
        <div class="sep"></div>
      </sc-for>
      <sc-if value="{{noTemplates}}" hint-placeholder-val="{{false}}"><div class="f"><p class="v ph">Für eigene Objekte gibt es keine Vorlage – Termine legst du danach im Bereich an.</p></div></sc-if>
    </div>
    <p class="note">{{tplNote}}</p>
  </div>
''') + sheet("blocked", "Noch etwas fehlt", "{{blockMsg}}", '<button class="btn pri" onClick="{{closeBlocked}}">Verstanden</button>') \
      + sheet("done", "Objekt angelegt", "{{doneMsg}}", '<a class="btn pri" href="{{backHref}}">Zum Bereich {{areaLabel}}</a>')
    logic = r'''  constructor(p) { super(p); this.state = { area: 'mobilitaet', type: 'kfz', name: '', f1: '', f2: '', scanned: false, checks: {}, blocked: false, blockMsg: '', done: false, doneMsg: '', toast: '' };
    this.TYPES = { wohnen: [['wohnung', 'Wohnung'], ['haus', 'Haus'], ['eigen', 'Eigenes']], mobilitaet: [['kfz', 'KFZ'], ['oepnv', 'ÖPNV'], ['eigen', 'Eigenes']], haushalt: [['person', 'Person'], ['tier', 'Haustier'], ['eigen', 'Eigenes']] };
    this.FIELDS = { kfz: [['Kennzeichen', 'KA-MN 77', ''], ['Kilometerstand', '12.480', 'km']], oepnv: [['Ticketart', 'Deutschlandticket', ''], ['Gültig ab', '01.11.2026', '']], wohnung: [['Adresse', 'Hauptstr. 12, 76131 Karlsruhe', ''], ['Wohnfläche', '78', 'm²']], haus: [['Adresse', 'Am Hang 4', ''], ['Baujahr', '1998', '']], person: [['Rolle', 'Kind, Partner …', ''], ['Geburtstag', 'optional', '']], tier: [['Tierart', 'Hund, Katze …', ''], ['Tierarzt', 'optional', '']], eigen: [['Beschreibung', 'wofür das Objekt steht', '']] };
    this.PH = { kfz: 'z. B. Motorrad BMW F 900', oepnv: 'z. B. Deutschlandticket Anna', wohnung: 'z. B. Wohnung Hauptstr. 12', haus: 'z. B. Ferienhaus', person: 'z. B. Ben', tier: 'z. B. Luna', eigen: 'Name' };
    this.TPL = { kfz: [['HU/AU', 'alle 24 Monate · Planbetrag 150 €', true], ['Kfz-Steuer', 'jährlich · Rücklage anlegen', true], ['Versicherungswechsel', 'Erinnerung 1. Nov.', true], ['Reifenwechsel', 'April / Oktober', false], ['Inspektion', 'jährlich oder nach km', false]],
      oepnv: [['Ticket verlängern / kündigen', 'monatlich bis zum 10.', true]],
      wohnung: [['Zählerstände', 'jährlich im Dezember', true], ['Nebenkostenabrechnung prüfen', 'jährlich', true], ['Rauchmelder', 'jährlich', false]],
      haus: [['Heizungswartung', 'jährlich', true], ['Schornsteinfeger', 'jährlich', true], ['Zählerstände', 'Dezember', true], ['Rauchmelder', 'jährlich', false], ['Grundsteuer', 'vierteljährlich', false]],
      person: [['Vorsorge', 'jährlich', true], ['Zahnarzt', 'halbjährlich', true]],
      tier: [['Impfung', 'jährlich', true], ['Tierarzt-Check', 'jährlich', false]], eigen: [] }; }
''' + JS_SEG + r'''
  renderVals() {
    var self = this, s = this.state, area = s.area, type = s.type;
    var labels = { wohnen: 'Wohnen', mobilitaet: 'Mobilität', haushalt: 'Haushalt' }, hrefs = { wohnen: 'Wohnen.dc.html', mobilitaet: 'Akte.dc.html', haushalt: 'Haushalt.dc.html' };
    var typeLabel = (this.TYPES[area].filter(function (t) { return t[0] === type; })[0] || ['', 'Eigenes'])[1];
    var tpls = this.TPL[type] || [];
    var checked = tpls.filter(function (t, i) { var c = s.checks[type + i]; return c === undefined ? t[2] : c; });
    var fields = (this.FIELDS[type] || []).map(function (f, i) { var key = 'f' + (i + 1); return { label: f[0], ph: f[1], unit: f[2], value: s[key], set: self.set(key) }; });
    return {
      toast: s.toast,
      backHref: hrefs[area], areaLabel: labels[area],
      areas: this.segItems('area', [['wohnen', 'Wohnen'], ['mobilitaet', 'Mobilität'], ['haushalt', 'Haushalt']]).map(function (a, i) { var orig = a.pick; var key = ['wohnen', 'mobilitaet', 'haushalt'][i]; a.pick = function () { self.setState({ area: key, type: self.TYPES[key][0][0], f1: '', f2: '', scanned: false }); }; return a; }),
      types: this.TYPES[area].map(function (t) { return { label: t[1], cls: type === t[0] ? 'on' : '', pick: function () { self.setState({ type: t[0], f1: '', f2: '', scanned: false }); } }; }),
      typeLabel: typeLabel,
      name: s.name, setName: this.set('name'), namePh: this.PH[type],
      fields: fields,
      isKfz: type === 'kfz',
      scan: function () { self.setState({ scanned: true, name: s.name || 'BMW F 900 R', f1: s.f1 || 'KA-MN 77', f2: s.f2 || '12.480' }); self.say('Fahrzeugschein gelesen: Name, Kennzeichen, Erstzulassung 03/2022'); },
      scanText: s.scanned ? 'Fahrzeugschein gespeichert (Dokument am Objekt)' : 'Fahrzeugschein scannen',
      typeNote: ({ kfz: 'Ein Fahrzeug bündelt Leasing, Versicherung, Steuer, Werkstatt, Laden und seine Termine. Kosten je km erscheinen, sobald ein Kilometerstand gepflegt ist.', oepnv: 'Ein Ticket ist ein Vertrag mit monatlicher Kündbarkeit; der Termin erinnert vor dem Stichtag.', wohnung: 'Wohnung bündelt Miete, Nebenkosten, Energie, Internet, Hausrat – alles Ortsgebundene.', haus: 'Haus bündelt Kredit, Grundsteuer, Gebäudeversicherung, Energie, Wartung.', person: 'Eine Person bündelt ihre Verträge (Mobilfunk, Fitness, Versicherung) und Termine; Lebensmittel bleiben gemeinsam.', tier: 'Ein Haustier bündelt Futter, Tierarzt, Versicherung, Steuer.', eigen: 'Eigene Objekte sind frei – z. B. Gartenparzelle, Boot, Wohnwagen.' })[type],
      templates: tpls.map(function (t, i) { var on = checked.indexOf(t) >= 0; return { name: t[0], sub: t[1], cls: on ? 'chk on' : 'chk', flip: function () { var c = Object.assign({}, s.checks); c[type + i] = !on; self.setState({ checks: c }); } }; }),
      noTemplates: tpls.length === 0,
      tplNote: tpls.length ? checked.length + ' von ' + tpls.length + ' Terminen werden mit angelegt; jeder bekommt Erinnerung und, wo sinnvoll, eine Rücklage.' : '',
      blocked: s.blocked, blockMsg: s.blockMsg, closeBlocked: this.go('blocked', false),
      done: s.done, doneMsg: s.doneMsg,
      create: function () {
        if (!s.name.trim()) { self.setState({ blocked: true, blockMsg: 'Bitte einen Namen eingeben' + (type === 'kfz' ? ' oder den Fahrzeugschein scannen.' : '.') }); return; }
        if (type === 'kfz' && !s.f1.trim()) { self.setState({ blocked: true, blockMsg: 'Für ein Fahrzeug fehlt das Kennzeichen.' }); return; }
        self.setState({ done: true, doneMsg: '„' + s.name.trim() + '“ (' + typeLabel + ') liegt jetzt in ' + labels[area] + (checked.length ? ' · ' + checked.length + ' Termine angelegt: ' + checked.map(function (t) { return t[0]; }).join(', ') : '') + '. Verträge und Rechnungen lassen sich dem Objekt jetzt zuordnen.' });
      }
    };
  }'''
    page("ObjektNeu.dc.html", "Objekt anlegen", body, logic, 'u', EXTRA_CSS)

    # ================================================================ Rücklage (Urlaub Juli)
    body = tpl('''  <div class="hdr">
    <div class="nav"><a class="back" href="Haushalt.dc.html">[BACK]Haushalt</a><p class="ttl">Rücklage</p><button class="act" onClick="{{toggleEdit}}">{{editLabel}}</button></div>
    <h1>{{name}}</h1>
    <p class="sub" style="white-space: nowrap">Sparziel · Haushalt › Urlaub &amp; Reisen</p>
    <p class="sub" style="margin-top: 2px">Ziel {{zielFmt}} € bis {{zieldatum}}</p>
    <div style="margin-top: 16px; display: flex; align-items: baseline; justify-content: space-between; gap: 14px"><p class="big" style="margin: 0">{{standFmt}} €</p><p style="margin: 0; font-size: 13px; opacity: .85; text-align: right">{{pct}} % · {{restText}}</p></div>
    <div style="height: 8px; border-radius: 4px; background: rgba(255,255,255,.18); margin-top: 10px; overflow: hidden"><div style="{{barSt}}"></div></div>
  </div>

  <sc-if value="{{edit}}" hint-placeholder-val="{{false}}">
  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Rücklage bearbeiten</h2>
    <div class="card">
      <div class="f"><p class="l">Name</p><input class="in" value="{{nameDraft}}" onChange="{{setNameDraft}}"></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Zielbetrag</p><input class="in num" value="{{zielDraft}}" onChange="{{setZielDraft}}" inputmode="decimal"><span style="font-size: 14px; color: #637894">€</span></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Zieldatum</p><input class="in" value="{{datumDraft}}" onChange="{{setDatumDraft}}"></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Monatsrate</p><input class="in num" value="{{rateDraft}}" onChange="{{setRateDraft}}" inputmode="decimal"><span style="font-size: 14px; color: #637894">€</span><button class="chip lt" style="height: 30px" onClick="{{calcRate}}">aus Ziel</button></div>
    </div>
    <p class="note">{{editNote}}</p>
    <div style="display: flex; gap: 10px; margin-top: 12px"><button class="btn pri sm" onClick="{{saveEdit}}">Sichern</button><button class="btn danger sm" onClick="{{askClose}}">Rücklage auflösen</button></div>
  </div>
  </sc-if>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <div class="f"><p class="l">Monatsrate</p><p class="v">{{rateFmt}} € <span style="color: #637894; font-weight: 400">· {{ratenText}}</span></p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Nächste Rate</p><p class="v">1. Nov. 2026</p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Wirkung</p><p class="v">Sparen · Spielraum −{{rateFmt}} €/Monat</p></div>
      <div class="sep"></div>
      <button class="f" onClick="{{cycleReached}}"><p class="l">Wenn erreicht</p><p class="v">{{reachedText}}</p>[CHEV]</button>
    </div>
  </div>

  <div style="padding: 20px 20px 0 20px">
    <h2 class="h2">Verlauf <span>seit Aug. 2026</span></h2>
    <div class="card">
      <sc-for list="{{hist}}" as="h" hint-placeholder-count="3">
        <div class="row"><div class="mid"><p class="n" style="font-weight: 500">{{h.name}}</p><p class="s">{{h.sub}}</p></div><p class="v" style="{{h.st}}">{{h.val}}</p></div>
        <div class="sep"></div>
      </sc-for>
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px; display: flex; gap: 10px">
    <button class="btn pri" onClick="{{openIn}}">Einzahlen</button>
    <button class="btn sec2" onClick="{{openOut}}">Entnehmen</button>
  </div>
  <p class="note" style="margin: 10px 24px 0">Rücklagen aus Verträgen (z. B. Kfz-Versicherung) füllen sich automatisch und werden bei der Jahresrechnung entnommen – ohne den Monat zu belasten.</p>
''') + '''<sc-if value="{{move}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>{{moveTitle}}</h3><p>{{moveText}}</p><div class="card" style="margin-bottom: 12px"><div class="f"><p class="l">Betrag</p><input class="in num" value="{{moveAmt}}" onChange="{{setMoveAmt}}" inputmode="decimal" placeholder="0,00"><span style="font-size: 14px; color: #637894">€</span></div><div class="sep"></div><div class="f"><p class="l">Notiz</p><input class="in" value="{{moveNote}}" onChange="{{setMoveNote}}" placeholder="optional"></div></div><div style="display: flex; gap: 10px"><button class="btn sec2" onClick="{{closeMove}}">Abbrechen</button><button class="btn pri" onClick="{{confirmMove}}">{{moveTitle}}</button></div></div></div></sc-if>''' \
      + sheet("confirmClose", "Rücklage auflösen?", "{{closeText}}", '<button class="btn sec2" onClick="{{cancelClose}}">Abbrechen</button><a class="btn danger" href="Haushalt.dc.html">Auflösen</a>')
    logic = r'''  constructor(p) { super(p); this.state = { name: 'Urlaub Juli', stand: 640, ziel: 1800, rate: 200, datum: '15. Juli 2027', edit: false, nameDraft: '', zielDraft: '', rateDraft: '', datumDraft: '', reached: 0, move: '', moveAmt: '', moveNote: '', confirmClose: false, toast: '',
    hist: [ { name: 'Rate Oktober', sub: '1. Okt. · automatisch', val: '+200,00', st: 'color: #215F33' }, { name: 'Rate September', sub: '1. Sep. · automatisch', val: '+200,00', st: 'color: #215F33' }, { name: 'Überschuss August', sub: '31. Aug. · manuell übertragen', val: '+240,00', st: 'color: #215F33' } ] }; }
''' + JS_SEG + r'''
  renderVals() {
    var self = this, s = this.state, rest = Math.max(0, s.ziel - s.stand), pct = s.ziel > 0 ? Math.min(100, Math.round(s.stand / s.ziel * 100)) : 0;
    var raten = s.rate > 0 ? Math.ceil(rest / s.rate) : 0;
    var reachedOpts = ['Erinnerung ' + s.datum + ' · dann schließen', 'Rate automatisch stoppen', 'weiter sparen (Ziel anheben)'];
    var dZ = num(s.zielDraft), dR = num(s.rateDraft);
    return {
      toast: s.toast,
      name: s.name, zielFmt: eur(s.ziel), zieldatum: s.datum, standFmt: eur(s.stand), pct: pct,
      restText: rest > 0 ? 'noch ' + eur(rest) + ' €' : 'Ziel erreicht',
      barSt: 'width: ' + pct + '%; height: 8px; border-radius: 4px; background: #FFFFFF',
      edit: s.edit, editLabel: s.edit ? 'Fertig' : 'Bearbeiten',
      toggleEdit: function () { self.setState({ edit: !s.edit, nameDraft: s.name, zielDraft: eur(s.ziel), rateDraft: eur(s.rate), datumDraft: s.datum }); },
      nameDraft: s.nameDraft, setNameDraft: this.set('nameDraft'), zielDraft: s.zielDraft, setZielDraft: this.set('zielDraft'), rateDraft: s.rateDraft, setRateDraft: this.set('rateDraft'), datumDraft: s.datumDraft, setDatumDraft: this.set('datumDraft'),
      calcRate: function () { var r = Math.max(0, dZ - s.stand) / 9; self.setState({ rateDraft: eur(r) }); self.say('9 Raten bis ' + s.datumDraft + ': ' + eur(r) + ' €/Monat'); },
      editNote: dZ > 0 ? 'Mit Ziel ' + eur(dZ) + ' € und Rate ' + eur(dR) + ' €: ' + (dR > 0 ? Math.ceil(Math.max(0, dZ - s.stand) / dR) + ' Raten' : 'keine Rate') + ' · Spielraum sinkt um ' + eur(dR) + ' €/Monat.' : 'Zielbetrag eingeben.',
      saveEdit: function () { if (!(dZ > 0)) { self.say('Zielbetrag fehlt'); return; } self.setState({ name: s.nameDraft.trim() || s.name, ziel: dZ, rate: dR, datum: s.datumDraft || s.datum, edit: false }); self.say('Gespeichert'); },
      askClose: this.go('confirmClose', true), cancelClose: this.go('confirmClose', false), confirmClose: s.confirmClose,
      closeText: eur(s.stand) + ' € werden freigegeben und erscheinen im Oktober unter Noch frei. Der Verlauf bleibt in der Auswertung.',
      rateFmt: eur(s.rate), ratenText: raten > 0 ? raten + ' Raten bis ' + s.datum.split(' ')[1] : 'Ziel erreicht – Rate läuft aus',
      reachedText: reachedOpts[s.reached], cycleReached: function () { self.setState({ reached: (s.reached + 1) % reachedOpts.length }); },
      hist: s.hist,
      move: !!s.move, moveTitle: s.move === 'in' ? 'Einzahlen' : 'Entnehmen',
      moveText: s.move === 'in' ? 'Einmalig zusätzlich zurücklegen, z. B. den Überschuss des Monats. Der Kontostand ändert sich nicht.' : 'Aus der Rücklage bezahlen. Der Betrag belastet den Monat nicht – er war schon zurückgelegt.',
      moveAmt: s.moveAmt, setMoveAmt: this.set('moveAmt'), moveNote: s.moveNote, setMoveNote: this.set('moveNote'),
      openIn: function () { self.setState({ move: 'in', moveAmt: '', moveNote: '' }); }, openOut: function () { self.setState({ move: 'out', moveAmt: '', moveNote: '' }); }, closeMove: this.go('move', ''),
      confirmMove: function () {
        var a = num(s.moveAmt); if (!(a > 0)) { self.say('Bitte einen Betrag eingeben'); return; }
        if (s.move === 'out' && a > s.stand) { self.say('Nur ' + eur(s.stand) + ' € in der Rücklage'); return; }
        var h = s.hist.slice(); var sign = s.move === 'in' ? 1 : -1;
        h.unshift({ name: (s.move === 'in' ? 'Einzahlung' : 'Entnahme') + (s.moveNote ? ' · ' + s.moveNote : ''), sub: '25. Okt. · manuell', val: (sign > 0 ? '+' : '−') + eur(a), st: sign > 0 ? 'color: #215F33' : 'color: #943333' });
        self.setState({ stand: s.stand + sign * a, hist: h, move: '' }); self.say((sign > 0 ? 'Eingezahlt ' : 'Entnommen ') + eur(a) + ' € · Stand ' + eur(s.stand + sign * a) + ' €');
      }
    };
  }'''
    page("Ruecklage.dc.html", "Rücklage Urlaub Juli", body, logic, 'u', EXTRA_CSS)

    # ================================================================ Termin (HU/AU)
    body = tpl('''  <div class="hdr">
    <div class="nav"><a class="back" href="Akte.dc.html">[BACK]Mobilität</a><p class="ttl">Termin</p><button class="act" onClick="{{toggleEdit}}">{{editLabel}}</button></div>
    <h1>HU/AU · VW ID.3</h1>
    <p class="sub" style="white-space: nowrap">{{dateLine}}</p>
    <p class="sub" style="margin-top: 2px">{{dateLine2}}</p>
  </div>

  <sc-if value="{{edit}}" hint-placeholder-val="{{false}}">
  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Termin bearbeiten</h2>
    <div class="card">
      <div class="f"><p class="l">Datum</p><input class="in" value="{{dateDraft}}" onChange="{{setDateDraft}}" placeholder="TT.MM.JJJJ"></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Planbetrag</p><input class="in num" value="{{planDraft}}" onChange="{{setPlanDraft}}" inputmode="decimal"><span style="font-size: 14px; color: #637894">€</span></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Wiederholung</p><select class="in" value="{{rec}}" onChange="{{setRec}}"><option value="24">alle 24 Monate</option><option value="12">jährlich</option><option value="6">halbjährlich</option><option value="0">einmalig</option></select></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Erinnerung</p><select class="in" value="{{rem}}" onChange="{{setRem}}"><option value="30">30 Tage vorher + 7 Tage vorher</option><option value="14">14 Tage vorher</option><option value="7">7 Tage vorher</option><option value="0">keine</option></select></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Kilometerstand</p><input class="in num" value="{{kmDraft}}" onChange="{{setKmDraft}}" inputmode="numeric"><span style="font-size: 14px; color: #637894">km</span></div>
    </div>
    <div style="display: flex; gap: 10px; margin-top: 12px"><button class="btn pri sm" onClick="{{saveEdit}}">Sichern</button><button class="btn danger sm" onClick="{{askDelete}}">Termin löschen</button></div>
  </div>
  </sc-if>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <div class="f"><p class="l">Planbetrag</p><p class="v">{{planFmt}} € <span style="color: #637894; font-weight: 400">· aus Rücklage HU und Reifen</span></p></div>
      <div class="sep"></div>
      <a class="f" href="Ruecklage.dc.html"><p class="l">Rücklage</p><p class="v">HU und Reifen · {{resLine}}</p>[CHEV]</a>
      <div class="sep"></div>
      <div class="f"><p class="l">Erinnerung</p><p class="v">{{remText}}</p></div>
      <div class="sep"></div>
      <a class="f" href="Kategorie.dc.html"><p class="l">Kategorie</p><p class="v">Werkstatt &amp; Reifen · Mobilität</p>[CHEV]</a>
      <div class="sep"></div>
      <div class="f"><p class="l">Kilometerstand</p><p class="v">{{kmFmt}} km <span style="color: #637894; font-weight: 400">· zuletzt 16. Okt.</span></p></div>
      <div class="sep"></div>
      <div class="f"><p class="v wrap" style="font-weight: 500; font-size: 15px">Im Systemkalender</p><p class="v ph" style="flex: none; width: auto; font-size: 13px">{{calText}}</p><button class="{{calCls}}" aria-label="Systemkalender" onClick="{{flipCal}}"></button></div>
    </div>
  </div>

  <div style="padding: 20px 20px 0 20px">
    <h2 class="h2">Bisher</h2>
    <div class="card">
      <sc-for list="{{hist}}" as="h" hint-placeholder-count="2">
        <div class="row"><div class="mid"><p class="n" style="font-weight: 500">{{h.name}}</p><p class="s">{{h.sub}}</p></div><p class="v">{{h.val}}</p></div>
        <div class="sep"></div>
      </sc-for>
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px; display: flex; gap: 10px">
    <button class="btn {{doneCls}}" onClick="{{openDone}}">{{doneLabel}}</button>
    <button class="btn sec2" style="flex: 0 0 auto; padding: 0 16px" onClick="{{openShift}}">Verschieben</button>
  </div>
  <p class="note" style="margin: 10px 24px 0">„Erledigt“ legt den nächsten Termin an, bucht den Beleg in Werkstatt &amp; Reifen und entnimmt den Betrag aus der Rücklage.</p>
''') + '''<sc-if value="{{shift}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>Termin verschieben</h3><p>Aktuell {{dateFmt}}. Erinnerungen werden mitverschoben.</p><div style="display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 12px"><button class="chip lt" onClick="{{shift7}}">+1 Woche</button><button class="chip lt" onClick="{{shift30}}">+1 Monat</button><button class="chip lt" onClick="{{shiftM7}}">−1 Woche</button></div><div class="card" style="margin-bottom: 12px"><div class="f"><p class="l">Neues Datum</p><input class="in" value="{{shiftDate}}" onChange="{{setShiftDate}}" placeholder="TT.MM.JJJJ"></div></div><div style="display: flex; gap: 10px"><button class="btn sec2" onClick="{{closeShift}}">Abbrechen</button><button class="btn pri" onClick="{{confirmShift}}">Verschieben</button></div></div></div></sc-if>''' \
      + '''<sc-if value="{{doneSheet}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>HU/AU erledigt?</h3><p>Mit Beleg: Werkstattrechnung scannen, Betrag ersetzt den Planbetrag {{planFmt}} € und wird aus der Rücklage entnommen. Ohne Beleg: Planbetrag wird gebucht.</p><div style="display: flex; gap: 10px"><a class="btn pri" href="Erfassen.dc.html">Beleg erfassen</a><button class="btn sec2" onClick="{{doneNoDoc}}">Ohne Beleg</button></div><button class="btn" style="margin-top: 10px; background: none; color: #637894" onClick="{{closeDone}}">Abbrechen</button></div></div></sc-if>''' \
      + sheet("confirmDelete", "Termin löschen?", "Die Wiederholung endet. Erledigte Termine bleiben in der Historie.", '<button class="btn sec2" onClick="{{cancelDelete}}">Abbrechen</button><a class="btn danger" href="Akte.dc.html">Löschen</a>')
    logic = r'''  constructor(p) { super(p); this.state = { date: new Date(2026, 10, 12), plan: 150, rec: '24', rem: '30', km: 61240, cal: true, edit: false, dateDraft: '', planDraft: '', kmDraft: '', shift: false, shiftDate: '', doneSheet: false, done: false, confirmDelete: false, toast: '',
    hist: [ { name: 'HU/AU bestanden', sub: '14. Nov. 2024 · Prüfstelle Süd', val: '139,90' }, { name: 'HU/AU bestanden', sub: '9. Nov. 2022', val: '129,00' } ] }; }
''' + JS_SEG + r'''
  fmtDate(d) { var days = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'], mons = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember']; return days[d.getDay()] + ', ' + d.getDate() + '. ' + mons[d.getMonth()] + ' ' + d.getFullYear(); }
  shortDate(d) { return ('0' + d.getDate()).slice(-2) + '.' + ('0' + (d.getMonth() + 1)).slice(-2) + '.' + d.getFullYear(); }
  parseDate(s) { var m = /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/.exec(String(s).trim()); return m ? new Date(Number(m[3]), Number(m[2]) - 1, Number(m[1])) : null; }
  renderVals() {
    var self = this, s = this.state, today = new Date(2026, 9, 25);
    var diff = Math.round((s.date - today) / 86400000);
    var recText = { '24': 'wiederholt sich alle 24 Monate', '12': 'jährlich', '6': 'halbjährlich', '0': 'einmalig' }[s.rec];
    var remText = s.rem === '0' ? 'keine' : s.rem + ' Tage vorher' + (s.rem === '30' ? ' + 7 Tage vorher · erste war 13. Okt.' : '');
    var shiftTo = function (days) { var d = new Date(s.date); d.setDate(d.getDate() + days); self.setState({ shiftDate: self.shortDate(d) }); };
    return {
      toast: s.toast,
      dateLine: s.done ? 'Erledigt am 25. Okt. 2026' : this.fmtDate(s.date) + ' · ' + (diff >= 0 ? 'in ' + diff + ' Tagen' : 'seit ' + (-diff) + ' Tagen überfällig'), dateLine2: s.done ? 'nächster Termin ' + this.fmtDate(s.date) : recText,
      dateFmt: this.fmtDate(s.date),
      edit: s.edit, editLabel: s.edit ? 'Fertig' : 'Bearbeiten',
      toggleEdit: function () { self.setState({ edit: !s.edit, dateDraft: self.shortDate(s.date), planDraft: eur(s.plan), kmDraft: String(s.km) }); },
      dateDraft: s.dateDraft, setDateDraft: this.set('dateDraft'), planDraft: s.planDraft, setPlanDraft: this.set('planDraft'), kmDraft: s.kmDraft, setKmDraft: this.set('kmDraft'),
      rec: s.rec, setRec: this.set('rec'), rem: s.rem, setRem: this.set('rem'),
      saveEdit: function () { var d = self.parseDate(s.dateDraft); if (!d) { self.say('Datum als TT.MM.JJJJ eingeben'); return; } self.setState({ date: d, plan: num(s.planDraft), km: Math.round(num(s.kmDraft)), edit: false }); self.say('Gespeichert · Planbetrag ' + eur(num(s.planDraft)) + ' € in der Liquidität am ' + self.shortDate(d)); },
      askDelete: this.go('confirmDelete', true), cancelDelete: this.go('confirmDelete', false), confirmDelete: s.confirmDelete,
      planFmt: eur(s.plan), resLine: '120 von 190 €' + (s.plan > 190 ? ' · Planbetrag übersteigt die Rücklage um ' + eur(s.plan - 190) + ' €' : ''),
      remText: remText, kmFmt: eur(s.km, 0),
      calCls: this.tog('cal'), flipCal: function () { self.setState({ cal: !s.cal }); self.say(s.cal ? 'Aus dem Kalender entfernt' : 'In Kalender „Mnemor“ eingetragen'); }, calText: s.cal ? 'Kalender „Mnemor“' : 'nicht eingetragen',
      hist: s.hist,
      doneCls: s.done ? 'ok' : 'pri', doneLabel: s.done ? 'Erledigt ✓' : 'Erledigt – Beleg erfassen',
      openDone: function () { if (s.done) { self.say('Nächster Termin ' + self.shortDate(s.date)); return; } self.setState({ doneSheet: true }); }, closeDone: this.go('doneSheet', false), doneSheet: s.doneSheet,
      doneNoDoc: function () { var h = s.hist.slice(); h.unshift({ name: 'HU/AU bestanden', sub: '25. Okt. 2026 · Planbetrag · aus Rücklage entnommen', val: eur(s.plan) }); var d = new Date(s.date); d.setMonth(d.getMonth() + Number(s.rec || 24)); self.setState({ done: true, doneSheet: false, hist: h, date: Number(s.rec) ? d : s.date }); self.say(eur(s.plan) + ' € aus Rücklage entnommen · Folgetermin ' + (Number(s.rec) ? self.shortDate(d) : 'keiner')); },
      shift: s.shift, openShift: function () { self.setState({ shift: true, shiftDate: self.shortDate(s.date) }); }, closeShift: this.go('shift', false),
      shiftDate: s.shiftDate, setShiftDate: this.set('shiftDate'), shift7: function () { shiftTo(7); }, shift30: function () { shiftTo(30); }, shiftM7: function () { shiftTo(-7); },
      confirmShift: function () { var d = self.parseDate(s.shiftDate); if (!d) { self.say('Datum als TT.MM.JJJJ eingeben'); return; } self.setState({ date: d, shift: false }); self.say('Verschoben auf ' + self.shortDate(d) + ' · Erinnerungen angepasst'); }
    };
  }'''
    page("Termin.dc.html", "Termin HU/AU", body, logic, 'u', EXTRA_CSS)

    # ================================================================ Monatsrechnung
    body = tpl('''  <div class="hdr">
    <div class="nav"><a class="back" href="Main.dc.html">[BACK]Übersicht</a><p class="ttl">Oktober 2026</p><span style="width: 60px"></span></div>
    <h1>Noch frei {{spar}} €</h1>
    <p class="sub">Drei Schritte: Plan am Monatsanfang, Verlauf im Monat, Ergebnis am Monatsende. Pfeile zeigen die Einzelposten.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Monatsanfang · Plan <span>steht fest</span></h2>
    <div class="card">
      <sc-for list="{{plan}}" as="r" hint-placeholder-count="3">
        <div class="row" style="padding-right: 8px"><a href="{{r.href}}" style="flex: 1; min-width: 0; text-decoration: none; color: inherit"><p class="n">{{r.name}}</p><p class="s">{{r.sub}}</p></a><p class="v" style="{{r.st}}">{{r.val}}</p><button class="chip lt" style="height: 30px; width: 30px; padding: 0; justify-content: center" aria-label="Einzelposten" onClick="{{r.toggle}}">{{r.arrow}}</button></div>
        <sc-if value="{{r.open}}" hint-placeholder-val="{{false}}"><div style="padding: 0 16px 10px 16px"><sc-for list="{{r.items}}" as="i" hint-placeholder-count="3"><div style="display: flex; justify-content: space-between; gap: 10px; font-size: 13px; color: #637894; padding: 3px 0"><span style="flex: 1; min-width: 0">{{i.n}}</span><span style="font-variant-numeric: tabular-nums; white-space: nowrap">{{i.v}}</span></div></sc-for></div></sc-if>
        <div class="sep"></div>
      </sc-for>
      <div class="row" style="background: #F3F5F8; border-radius: 0 0 18px 18px"><div class="mid"><p class="n">Spielraum (variabel)</p></div><p class="v" style="font-size: 17px">{{raum}}</p></div>
    </div>
  </div>
  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Im Monat <span>läuft</span></h2>
    <div class="card">
      <sc-for list="{{run}}" as="r" hint-placeholder-count="3">
        <div class="row" style="padding-right: 8px"><a href="{{r.href}}" style="flex: 1; min-width: 0; text-decoration: none; color: inherit"><p class="n">{{r.name}}</p><p class="s">{{r.sub}}</p></a><p class="v" style="{{r.st}}">{{r.val}}</p><button class="chip lt" style="height: 30px; width: 30px; padding: 0; justify-content: center" aria-label="Einzelposten" onClick="{{r.toggle}}">{{r.arrow}}</button></div>
        <sc-if value="{{r.open}}" hint-placeholder-val="{{false}}"><div style="padding: 0 16px 10px 16px"><sc-for list="{{r.items}}" as="i" hint-placeholder-count="3"><div style="display: flex; justify-content: space-between; gap: 10px; font-size: 13px; color: #637894; padding: 3px 0"><span style="flex: 1; min-width: 0">{{i.n}}</span><span style="font-variant-numeric: tabular-nums; white-space: nowrap">{{i.v}}</span></div></sc-for></div></sc-if>
        <div class="sep"></div>
      </sc-for>
      <div class="row" style="background: #F3F5F8; border-radius: 0 0 18px 18px"><div class="mid"><p class="n">Noch frei</p></div><p class="v" style="font-size: 17px; color: #215F33">{{spar}}</p></div>
    </div>
  </div>
  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Monatsende <span>voraussichtlich</span></h2>
    <div class="card">
      <div class="row"><div class="mid"><p class="n">Gespart</p><p class="s">Rücklagen {{resFmt}} + Überschuss {{spar}}</p></div><p class="v" style="color: #215F33">{{saved}}</p></div>
      <div class="sep"></div>
      <div class="row"><div class="mid"><p class="n">Sparquote</p><p class="s">Gespart ÷ Einnahmen</p></div><p class="v">{{quote}} %</p></div>
      <div class="sep"></div>
      <div class="row"><div class="mid"><p class="n">Bereiche zusammen</p><p class="s">Wohnen 1.368,18 · Mobilität 746,19 · Haushalt 881,53</p></div><p class="v">{{areas}}</p></div>
    </div>
    <p class="note">Bereiche = Fixkosten + Ausgaben + Rücklagen-Raten = {{areas2}} €. Der Kontostand kommt hier nicht vor – den gibt es nur in der Liquidität.</p>
  </div>

  <div style="padding: 16px 20px 0 20px; display: flex; gap: 10px">
    <button class="btn pri" onClick="{{openTransfer}}">Überschuss in Rücklage übertragen</button>
  </div>
''') + '''<sc-if value="{{transfer}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>Wohin übertragen?</h3><p>Der Monat ist noch nicht abgeschlossen – offene Posten können den Überschuss noch ändern. Übertragen wird am Monatsende mit dem dann gültigen Wert.</p><div class="card" style="margin-bottom: 12px"><sc-for list="{{targets}}" as="t" hint-placeholder-count="3"><button class="f" onClick="{{t.pick}}"><p class="v" style="font-weight: 500">{{t.name}}</p><p class="v ph" style="flex: none; width: auto; font-size: 13px">{{t.sub}}</p><span class="{{t.cls}}" style="width: 20px; height: 20px; border-width: 2px"></span></button><div class="sep"></div></sc-for></div><div style="display: flex; gap: 10px"><button class="btn sec2" onClick="{{closeTransfer}}">Abbrechen</button><button class="btn pri" onClick="{{confirmTransfer}}">Vormerken</button></div></div></div></sc-if>'''
    logic = r'''  constructor(p) { super(p); this.state = { open: {}, transfer: false, target: 0, planned: '', toast: '' };
    this.PLAN = [
      { name: 'Einnahmen', sub: 'Gehalt 3.400 · Kindergeld 250', val: 3650, sign: 1, href: 'Einnahmen.dc.html', items: [['Gehalt Muster AG (30. Okt.)', '3.400,00'], ['Kindergeld (5. Okt.)', '250,00']] },
      { name: 'Fixkosten & Kredite', sub: '16 Verträge · 3 Bereiche', val: 1659.20, sign: -1, href: 'Vertraege.dc.html', items: [['Wohnen · Miete, Strom, Gas, Internet, Rundfunk', '1.218,35'], ['Mobilität · Leasing, D-Ticket, Ladetarif', '356,99'], ['Haushalt · Mobilfunk, Streaming, Fitness', '83,86']] },
      { name: 'Rücklagen-Raten', sub: 'Sparen mit Zweck · 6 Raten', val: 326.10, sign: -1, href: 'Ruecklage.dc.html', items: [['Urlaub Juli (Sparziel)', '200,00'], ['HU und Reifen (Termin)', '60,00'], ['Kfz-Versicherung 487,20 ÷ 12', '40,60'], ['Kfz-Steuer 144 ÷ 12', '12,00'], ['Hausrat 94 ÷ 12', '7,83'], ['Haftpflicht 68 ÷ 12', '5,67']] }
    ];
    this.RUN = [
      { name: 'Ausgegeben', sub: 'bezahlt 656,20 · offen 354,40', val: 1010.60, sign: -1, href: 'Rechnungen.dc.html', items: [['Bons Lebensmittel, Freizeit · bezahlt', '592,00'], ['EnBW Laden · bezahlt 16. Okt.', '64,20'], ['Stadtwerke Nachzahlung · überfällig', '142,00'], ['Autohaus Keller · fällig 30. Okt.', '212,40']] },
      { name: 'In Budgets reserviert', sub: 'Budget − Ist, nie unter 0', val: 61.40, sign: -1, href: 'Budgets.dc.html', items: [['Lebensmittel 450 − 412', '38,00'], ['Mobilität variabel 300 − 276,60', '23,40'], ['Freizeit 150 − 180 · überschritten', '0,00']] }
    ];
    }
''' + JS_SEG + r'''
  renderVals() {
    var self = this, s = this.state;
    var raum = this.PLAN.reduce(function (a, r) { return a + r.sign * r.val; }, 0);
    var spar = raum + this.RUN.reduce(function (a, r) { return a + r.sign * r.val; }, 0);
    var res = 326.10, saved = res + spar, quote = Math.round(saved / 3650 * 100);
    var mkRows = function (list, key) { return list.map(function (r, i) { var id = key + i, open = !!s.open[id]; return { name: r.name, sub: r.sub, val: (r.sign > 0 ? '+' : '−') + eur(r.val), st: r.sign > 0 ? 'color: #215F33' : '', href: r.href, open: open, arrow: open ? '▾' : '▸', items: r.items.map(function (x) { return { n: x[0], v: x[1] }; }), toggle: function () { var o = Object.assign({}, s.open); o[id] = !open; self.setState({ open: o }); } }; }); };
    var targets = [['Urlaub Juli', 'Sparziel · 640 von 1.800 €'], ['HU und Reifen', 'Termin · 120 von 190 €'], ['Neue Rücklage anlegen', 'Name und Ziel im nächsten Schritt']];
    return {
      toast: s.toast,
      spar: eur(spar), raum: eur(raum), resFmt: eur(res), saved: eur(saved), quote: quote, areas: eur(1368.18 + 746.19 + 881.53), areas2: eur(1659.20 + 1010.60 + 326.10),
      plan: mkRows(this.PLAN, 'p'), run: mkRows(this.RUN, 'r'),
      transfer: s.transfer, openTransfer: this.go('transfer', true), closeTransfer: this.go('transfer', false),
      targets: targets.map(function (t, i) { return { name: t[0], sub: t[1], cls: s.target === i ? 'chk on' : 'chk', pick: function () { self.setState({ target: i }); } }; }),
      confirmTransfer: function () { self.setState({ transfer: false, planned: targets[s.target][0] }); self.say('Vorgemerkt: Überschuss am 31. Okt. → ' + targets[s.target][0]); }
    };
  }'''
    page("Monatsrechnung.dc.html", "Monatsrechnung", body, logic, 'u', EXTRA_CSS)


DOC_OVERLAY_D = '''<sc-if value="{{showDoc}}" hint-placeholder-val="{{false}}"><div class="sheetbg" style="align-items: stretch; background: #16243A"><div style="flex: 1; display: flex; flex-direction: column; color: #FFFFFF"><div style="display: flex; justify-content: space-between; align-items: center; padding: 56px 20px 10px"><button class="act" style="text-align: left" onClick="{{closeDoc}}">Fertig</button><p class="ttl">{{docTitle}}</p><button class="act" onClick="{{shareDoc}}">Teilen</button></div><div style="flex: 1; margin: 10px 24px 40px; background: #FFFFFF; border-radius: 8px; color: #16243A; padding: 26px 22px; font-size: 11px; line-height: 1.6; overflow: hidden"><p style="margin: 0; font-weight: 700; font-size: 14px">{{docHead}}</p><p style="margin: 2px 0 14px; color: #637894">{{docSub}}</p><p style="margin: 0">{{docLine1}}</p><p style="margin: 0">{{docLine2}}</p><p style="margin: 14px 0 0; font-weight: 700">{{docLine3}}</p></div></div></div></sc-if>'''

if __name__ == "__main__":
    build()
