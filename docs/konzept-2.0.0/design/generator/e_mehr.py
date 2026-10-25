# -*- coding: utf-8 -*-
"""Budgets, Einnahmen, Mehr, Haushaltskasse, Dokumente, Auswertung, Einstellungen."""
from common import *
from d_objekte import tpl, EXTRA_CSS, DOC_OVERLAY_D

GEAR = '<svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>'
UP = '<svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V5M5 12l7-7 7 7"/></svg>'


def build():
    # ================================================================ Budgets
    body = tpl('''  <div class="hdr">
    <div class="nav"><a class="back" href="Mehr.dc.html">[BACK]Mehr</a><p class="ttl">Budgets</p><button class="act" onClick="{{openNew}}">Neu</button></div>
    <h1>Budgets im Oktober</h1>
    <div style="display: flex; align-items: baseline; justify-content: space-between; gap: 14px; margin-top: 12px"><p class="big" style="margin: 0">{{offen}} €</p><p style="margin: 0; font-size: 13px; opacity: .85; text-align: right">noch offen · {{count}} Budgets · {{geplant}} € geplant</p></div>
    <p class="sub">{{verbraucht}} € verbraucht · Überschreitungen werden nicht gegengerechnet</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Variable Kategorien <span>7 Tage bis Monatsende</span></h2>
    <div class="card">
      <sc-for list="{{rows}}" as="b" hint-placeholder-count="3">
        <div class="row" style="align-items: stretch; flex-direction: column; gap: 0; padding-top: 10px; padding-bottom: 10px; cursor: default">
          <div style="display: flex; align-items: center; gap: 10px"><span class="dot" style="{{b.dotst}}"></span><a href="{{b.href}}" style="flex: 1; min-width: 0; text-decoration: none; color: inherit"><p class="n">{{b.name}}</p></a><button class="chip lt" style="height: 30px; font-variant-numeric: tabular-nums" onClick="{{b.edit}}">{{b.amounts}}</button></div>
          <div class="bar2"><i style="{{b.barst}}"></i></div>
          <p class="s" style="{{b.stst}}">{{b.state}}</p>
        </div>
        <div class="sep"></div>
      </sc-for>
    </div>
    <p class="note">{{formula}} Dieser Betrag mindert das Sparpotenzial, weil er voraussichtlich noch ausgegeben wird.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Ohne Budget</h2>
    <div class="card">
      <sc-for list="{{without}}" as="w" hint-placeholder-count="3">
        <button class="f" onClick="{{w.add}}"><span class="dot" style="{{w.dotst}}"></span><p class="v">{{w.name}}</p><span style="font-size: 13px; color: #2A5480; font-weight: 600; flex: none">Budget setzen</span>[CHEV]</button>
        <div class="sep"></div>
      </sc-for>
      <sc-if value="{{noneWithout}}" hint-placeholder-val="{{false}}"><div class="f"><p class="v ph">Alle variablen Kategorien haben ein Budget.</p></div></sc-if>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <sc-if value="{{showSug}}" hint-placeholder-val="{{true}}"><div class="f" style="flex-direction: column; align-items: stretch; gap: 10px; padding-top: 12px; padding-bottom: 12px"><p class="v wrap"><b>Vorschlag:</b> Freizeit lag in 4 von 6 Monaten über 150 €. Budget auf 200 € anheben?</p><div style="display: flex; gap: 8px"><button class="btn sec2 sm" onClick="{{applySug}}">Auf 200 € setzen</button><button class="btn sm" style="background: #F3F5F8; color: #637894" onClick="{{dismissSug}}">Später</button></div></div><div class="sep"></div></sc-if>
      <div class="f"><p class="l">Fixkosten</p><p class="v wrap">Brauchen kein Budget – sie stehen als Vertrag fest. Abweichungen zeigt die Monatsrechnung.</p></div>
    </div>
    <p class="note">{{sparNote}}</p>
  </div>
''') + '''<sc-if value="{{sheet}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>{{sheetTitle}}</h3><p>{{sheetText}}</p><div class="card" style="margin-bottom: 12px"><sc-if value="{{isNew}}" hint-placeholder-val="{{false}}"><div class="f" style="align-items: flex-start; padding-top: 10px"><p class="l" style="padding-top: 6px">Kategorie</p><div style="display: flex; gap: 8px; flex-wrap: wrap"><sc-for list="{{catOptions}}" as="o" hint-placeholder-count="3"><button class="{{o.cls}}" onClick="{{o.pick}}">{{o.t}}</button></sc-for></div></div><div class="sep"></div></sc-if><div class="f"><p class="l">Monatsbudget</p><input class="in num" value="{{amt}}" onChange="{{setAmt}}" inputmode="decimal" placeholder="0,00"><span style="font-size: 14px; color: #637894">€</span></div><div class="sep"></div><div class="f"><p class="v wrap" style="font-weight: 500; font-size: 15px">Rest in den Folgemonat übertragen</p><button class="{{rollCls}}" aria-label="Rollover" onClick="{{flipRoll}}"></button></div></div><p>{{sheetHint}}</p><div style="display: flex; gap: 10px"><button class="btn sec2" onClick="{{closeSheet}}">Abbrechen</button><sc-if value="{{canRemove}}" hint-placeholder-val="{{false}}"><button class="btn danger" style="flex: 0 0 auto; padding: 0 14px" onClick="{{removeBudget}}">Entfernen</button></sc-if><button class="btn pri" onClick="{{saveSheet}}">Sichern</button></div></div></div></sc-if>'''
    logic = r'''  constructor(p) { super(p); this.state = { budgets: [ { id: 'lm', name: 'Lebensmittel', area: 'h', spent: 412, budget: 450, href: 'Kategorie.dc.html' }, { id: 'fz', name: 'Freizeit (ohne Fitness-Vertrag)', area: 'h', spent: 180, budget: 150, href: 'Kategorie.dc.html' }, { id: 'mv', name: 'Mobilität variabel (Laden, Werkstatt)', area: 'm', spent: 276.60, budget: 300, href: 'Akte.dc.html' } ],
    pool: [ { id: 'kl', name: 'Kleidung & Pflege', area: 'h', spent: 0 }, { id: 'ge', name: 'Gesundheit', area: 'h', spent: 0 }, { id: 'ga', name: 'Gastronomie', area: 'h', spent: 0 }, { id: 'ht', name: 'Haustier', area: 'h', spent: 0 }, { id: 'in', name: 'Instandhaltung & Reparatur', area: 'w', spent: 0 }, { id: 'gs', name: 'Geschenke & Spenden', area: 'h', spent: 0 } ],
    sheet: '', editId: '', newCat: 'kl', amt: '', roll: false, showSug: true, toast: '' }; }
''' + JS_SEG + r'''
  renderVals() {
    var self = this, s = this.state, col = { w: '#E8A33D', m: '#3C8DBC', h: '#4CAF7A' };
    var offen = 0, geplant = 0, verbraucht = 0, parts = [];
    s.budgets.forEach(function (b) { var r = Math.max(0, b.budget - b.spent); offen += r; geplant += b.budget; verbraucht += b.spent; parts.push(eur(r)); });
    var baseOffen = 61.40, delta = offen - baseOffen;
    var editing = s.budgets.filter(function (b) { return b.id === s.editId; })[0];
    var a = num(s.amt);
    return {
      toast: s.toast,
      offen: eur(offen), count: s.budgets.length, geplant: eur(geplant, 0), verbraucht: eur(verbraucht),
      rows: s.budgets.map(function (b) { var over = b.spent > b.budget, pct = b.budget > 0 ? Math.min(100, Math.round(b.spent / b.budget * 100)) : 100, left = b.budget - b.spent, c = over ? '#943333' : (pct >= 85 ? '#E08A1E' : '#2A5480');
        return { name: b.name, href: b.href, dotst: 'background: ' + col[b.area], amounts: eur(b.spent) + ' / ' + eur(b.budget, 0) + ' €', barst: 'width: ' + pct + '%; background: ' + c, stst: 'color: ' + c + '; font-weight: 600', state: over ? eur(-left) + ' € über Budget' : 'noch ' + eur(left) + ' €', edit: function () { self.setState({ sheet: 'edit', editId: b.id, amt: eur(b.budget), roll: !!b.roll }); } }; }),
      formula: 'Offen = Summe der positiven Reste: ' + parts.join(' + ') + ' = ' + eur(offen) + ' €.',
      without: s.pool.map(function (p) { return { name: p.name, dotst: 'background: ' + col[p.area], add: function () { self.setState({ sheet: 'new', newCat: p.id, amt: '', roll: false }); } }; }),
      noneWithout: s.pool.length === 0,
      showSug: s.showSug && s.budgets.some(function (b) { return b.id === 'fz' && b.budget < 200; }),
      applySug: function () { self.setState({ budgets: s.budgets.map(function (b) { return b.id === 'fz' ? Object.assign({}, b, { budget: 200 }) : b; }), showSug: false }); self.say('Freizeit-Budget 200 € · offen jetzt ' + eur(offen + 20) + ' €'); },
      dismissSug: function () { self.setState({ showSug: false }); },
      sparNote: Math.abs(delta) < 0.005 ? 'Sparpotenzial Oktober: 592,70 € (Budgets offen 61,40 €).' : 'Sparpotenzial Oktober jetzt ' + eur(592.70 - delta) + ' € (Budgets offen ' + eur(offen) + ' € statt 61,40 €).',
      sheet: !!s.sheet, isNew: s.sheet === 'new', canRemove: s.sheet === 'edit',
      sheetTitle: s.sheet === 'new' ? 'Budget setzen' : 'Budget ändern', sheetText: s.sheet === 'new' ? 'Ein Budget gilt pro Monat für eine variable Kategorie.' : (editing ? editing.name + ' · bisher ' + eur(editing.spent) + ' € ausgegeben' : ''),
      catOptions: s.pool.map(function (p) { return { t: p.name, cls: s.newCat === p.id ? 'chip lt on' : 'chip lt', pick: function () { self.setState({ newCat: p.id }); } }; }),
      amt: s.amt, setAmt: this.set('amt'), rollCls: this.tog('roll'), flipRoll: this.flip('roll'),
      sheetHint: a > 0 ? (editing ? (a > editing.spent ? 'Noch ' + eur(a - editing.spent) + ' € frei · Budgets offen ' + eur(offen - Math.max(0, editing.budget - editing.spent) + (a - editing.spent)) + ' €' : eur(editing.spent - a) + ' € über Budget – offen 0') : 'Noch ' + eur(a) + ' € frei – Budgets offen steigen auf ' + eur(offen + a) + ' €, Sparpotenzial sinkt entsprechend.') : 'Betrag eingeben.',
      openNew: function () { if (!s.pool.length) { self.say('Alle variablen Kategorien haben ein Budget'); return; } self.setState({ sheet: 'new', newCat: s.pool[0].id, amt: '', roll: false }); },
      closeSheet: this.go('sheet', ''),
      saveSheet: function () {
        if (!(a > 0)) { self.say('Bitte einen Betrag über 0 eingeben'); return; }
        if (s.sheet === 'new') { var p = s.pool.filter(function (x) { return x.id === s.newCat; })[0]; if (!p) { self.say('Kategorie wählen'); return; } self.setState({ budgets: s.budgets.concat([{ id: p.id, name: p.name, area: p.area, spent: p.spent, budget: a, roll: s.roll, href: 'Kategorie.dc.html' }]), pool: s.pool.filter(function (x) { return x.id !== p.id; }), sheet: '' }); self.say('Budget ' + p.name + ' ' + eur(a) + ' €'); }
        else { self.setState({ budgets: s.budgets.map(function (b) { return b.id === s.editId ? Object.assign({}, b, { budget: a, roll: s.roll }) : b; }), sheet: '' }); self.say('Budget geändert'); }
      },
      removeBudget: function () { var b = editing; if (!b) return; self.setState({ budgets: s.budgets.filter(function (x) { return x.id !== b.id; }), pool: s.pool.concat([{ id: b.id, name: b.name, area: b.area, spent: b.spent }]), sheet: '' }); self.say('Budget entfernt – Kategorie bleibt'); }
    };
  }'''
    page("Budgets.dc.html", "Budgets", body, logic, 'u', EXTRA_CSS)

    # ================================================================ Einnahmen
    body = tpl('''  <div class="hdr">
    <div class="nav"><a class="back" href="Monatsrechnung.dc.html">[BACK]Monatsrechnung</a><p class="ttl">Einnahmen</p><button class="act" onClick="{{openNew}}">Neu</button></div>
    <h1>Einnahmen im Oktober</h1>
    <div style="display: flex; align-items: baseline; justify-content: space-between; gap: 14px; margin-top: 12px"><p class="big" style="margin: 0">{{total}} €</p><p style="margin: 0; font-size: 13px; opacity: .85; text-align: right">{{received}} € eingegangen · {{expected}} € erwartet</p></div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Oktober <span>antippen: Status, Bearbeiten</span></h2>
    <div class="card">
      <sc-for list="{{items}}" as="i" hint-placeholder-count="2">
        <button class="row" onClick="{{i.open}}"><span class="c" style="background: #215F33">''' + UP + '''</span><div class="mid"><p class="n">{{i.name}}</p><p class="s">{{i.sub}}</p></div><div style="text-align: right"><p class="v" style="color: #215F33">+{{i.amt}}</p><p class="s">{{i.state}}</p></div>[CHEV]</button>
        <div class="sep"></div>
      </sc-for>
    </div>
    <p class="note">Wiederkehrende Einnahmen werden je Monat geplant und zählen ab dem Eingangstag in die Liquidität. Das Sparpotenzial rechnet immer mit dem vollen Monat: {{sparNote}}</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Wiederkehrend</h2>
    <div class="card">
      <sc-for list="{{recurring}}" as="r" hint-placeholder-count="2">
        <button class="f" onClick="{{r.open}}"><p class="l">{{r.name}}</p><p class="v">{{r.amt}} € · {{r.when}}</p>[CHEV]</button>
        <div class="sep"></div>
      </sc-for>
      <button class="f" onClick="{{openNew}}"><p class="v" style="color: #2A5480; font-weight: 600; flex: none; width: auto">+ Einnahme anlegen</p><p class="v ph" style="text-align: right; font-size: 13px">einmalig oder wiederkehrend</p>[CHEV]</button>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Letzte Monate</h2>
    <div class="card">
      <div class="row"><div class="mid"><p class="n">September</p><p class="s">Gehalt + Kindergeld</p></div><p class="v">3.650,00</p></div>
      <div class="sep"></div>
      <div class="row"><div class="mid"><p class="n">August</p><p class="s">+ Rückerstattung Stromabrechnung 51,30</p></div><p class="v">3.701,30</p></div>
      <div class="sep"></div>
      <div class="row"><div class="mid"><p class="n">Juli</p><p class="s">+ Urlaubsgeld 600,00</p></div><p class="v">4.250,00</p></div>
    </div>
  </div>
''') + '''<sc-if value="{{sheet}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>{{sheetTitle}}</h3><p>{{sheetText}}</p><div class="card" style="margin-bottom: 12px"><div class="f"><p class="l">Bezeichnung</p><input class="in" value="{{fName}}" onChange="{{setFName}}" placeholder="z. B. Rückerstattung"></div><div class="sep"></div><div class="f"><p class="l">Betrag</p><input class="in num" value="{{fAmt}}" onChange="{{setFAmt}}" inputmode="decimal" placeholder="0,00"><span style="font-size: 14px; color: #637894">€</span></div><div class="sep"></div><div class="f"><p class="l">Datum</p><input class="in" value="{{fDate}}" onChange="{{setFDate}}" placeholder="TT.MM.JJJJ"></div><div class="sep"></div><div class="f"><p class="l">Rhythmus</p><div class="seg"><sc-for list="{{fRec}}" as="s" hint-placeholder-count="3"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div><div class="sep"></div><div class="f"><p class="l">Status</p><div class="seg"><sc-for list="{{fSt}}" as="s" hint-placeholder-count="2"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div></div><div style="display: flex; gap: 10px"><button class="btn sec2" onClick="{{closeSheet}}">Abbrechen</button><sc-if value="{{canDelete}}" hint-placeholder-val="{{false}}"><button class="btn danger" style="flex: 0 0 auto; padding: 0 14px" onClick="{{deleteItem}}">Löschen</button></sc-if><button class="btn pri" onClick="{{saveSheet}}">Sichern</button></div></div></div></sc-if>'''
    logic = r'''  constructor(p) { super(p); this.state = { items: [ { id: 1, name: 'Gehalt', amt: 3400, date: '30.10.2026', rec: 'monat', st: 'exp', src: 'Muster AG', when: 'zum Monatsende' }, { id: 2, name: 'Kindergeld', amt: 250, date: '05.10.2026', rec: 'monat', st: 'in', src: 'Familienkasse', when: 'am 5.' } ],
    sheet: '', editId: 0, fName: '', fAmt: '', fDate: '', frec: 'einmal', fst: 'exp', toast: '', nextId: 3 }; }
''' + JS_SEG + r'''
  dayName(d) { var m = /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/.exec(d); if (!m) return d; var dt = new Date(Number(m[3]), Number(m[2]) - 1, Number(m[1])); return ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'][dt.getDay()] + ' ' + Number(m[1]) + '. ' + ['Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sep.', 'Okt.', 'Nov.', 'Dez.'][Number(m[2]) - 1]; }
  renderVals() {
    var self = this, s = this.state, total = 0, rec = 0, exp = 0;
    s.items.forEach(function (i) { total += i.amt; if (i.st === 'in') rec += i.amt; else exp += i.amt; });
    var recLabel = { einmal: 'einmalig', monat: 'monatlich', jahr: 'jährlich' };
    var editing = s.items.filter(function (i) { return i.id === s.editId; })[0];
    var openEdit = function (i) { return function () { self.setState({ sheet: 'edit', editId: i.id, fName: i.name, fAmt: eur(i.amt), fDate: i.date, frec: i.rec, fst: i.st }); }; };
    return {
      toast: s.toast,
      total: eur(total), received: eur(rec), expected: eur(exp),
      items: s.items.map(function (i) { return { name: i.name, sub: self.dayName(i.date) + ' · ' + recLabel[i.rec] + (i.src ? ' · ' + i.src : ''), amt: eur(i.amt), state: i.st === 'in' ? 'eingegangen' : 'erwartet', open: openEdit(i) }; }),
      sparNote: total === 3650 ? 'Einnahmen 3.650,00 € → Sparpotenzial 592,70 €.' : 'Einnahmen ' + eur(total) + ' € → Sparpotenzial ' + eur(592.70 + total - 3650) + ' €.',
      recurring: s.items.filter(function (i) { return i.rec !== 'einmal'; }).map(function (i) { return { name: i.name, amt: eur(i.amt), when: i.when || recLabel[i.rec], open: openEdit(i) }; }),
      openNew: function () { self.setState({ sheet: 'new', editId: 0, fName: '', fAmt: '', fDate: '25.10.2026', frec: 'einmal', fst: 'in' }); },
      sheet: !!s.sheet, canDelete: s.sheet === 'edit',
      sheetTitle: s.sheet === 'new' ? 'Einnahme anlegen' : 'Einnahme bearbeiten',
      sheetText: s.sheet === 'edit' && editing && editing.st === 'exp' ? 'Status auf „eingegangen“ setzen, sobald das Geld auf dem Konto ist – dann zählt es in der Liquidität ab heute.' : 'Einmalige Einnahmen zählen nur in diesem Monat; wiederkehrende werden jeden Monat eingeplant.',
      fName: s.fName, setFName: this.set('fName'), fAmt: s.fAmt, setFAmt: this.set('fAmt'), fDate: s.fDate, setFDate: this.set('fDate'),
      fRec: this.segItems('frec', [['einmal', 'Einmalig'], ['monat', 'Monatlich'], ['jahr', 'Jährlich']]),
      fSt: this.segItems('fst', [['exp', 'Erwartet'], ['in', 'Eingegangen']]),
      closeSheet: this.go('sheet', ''),
      saveSheet: function () {
        var a = num(s.fAmt); if (!s.fName.trim()) { self.say('Bezeichnung fehlt'); return; } if (!(a > 0)) { self.say('Betrag fehlt'); return; } if (!/^\d{1,2}\.\d{1,2}\.\d{4}$/.test(s.fDate.trim())) { self.say('Datum als TT.MM.JJJJ'); return; }
        var it = { id: s.sheet === 'new' ? s.nextId : s.editId, name: s.fName.trim(), amt: a, date: s.fDate.trim(), rec: s.frec, st: s.fst, src: editing ? editing.src : '', when: editing ? editing.when : '' };
        var items = s.sheet === 'new' ? s.items.concat([it]) : s.items.map(function (i) { return i.id === it.id ? it : i; });
        self.setState({ items: items, sheet: '', nextId: s.nextId + 1 }); self.say((s.sheet === 'new' ? 'Angelegt: ' : 'Gespeichert: ') + it.name + ' ' + eur(a) + ' €');
      },
      deleteItem: function () { self.setState({ items: s.items.filter(function (i) { return i.id !== s.editId; }), sheet: '' }); self.say('Gelöscht'); }
    };
  }'''
    page("Einnahmen.dc.html", "Einnahmen", body, logic, 'u', EXTRA_CSS)

    # ================================================================ Mehr
    body = tpl('''  <div class="hdr">
    <div class="nav"><a class="back" href="Main.dc.html">[BACK]Übersicht</a><p class="ttl">Mehr</p><span style="width: 60px"></span></div>
    <h1>Mehr</h1>
    <p class="sub">Planung, Auswertung, Daten – alles lokal auf diesem iPhone</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Planung</h2>
    <div class="card">
      <a class="row" href="Budgets.dc.html"><span class="c" style="background: [H]"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 19h16M6 16V9M11 16V5M16 16v-6"/></svg></span><div class="mid"><p class="n">Budgets</p><p class="s">3 Budgets · 61,40 € offen</p></div>[CHEV]</a>
      <div class="sep"></div>
      <a class="row" href="Einnahmen.dc.html"><span class="c" style="background: #215F33">''' + UP + '''</span><div class="mid"><p class="n">Einnahmen</p><p class="s">3.650,00 € im Oktober</p></div>[CHEV]</a>
      <div class="sep"></div>
      <a class="row" href="Monatsrechnung.dc.html"><span class="c" style="background: #2A5480"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M5 4h14v16H5zM9 9h6M9 13h6M9 17h3"/></svg></span><div class="mid"><p class="n">Monatsrechnung</p><p class="s">Sparpotenzial 592,70 € · Herleitung</p></div>[CHEV]</a>
      <div class="sep"></div>
      <a class="row" href="Auswertung.dc.html"><span class="c" style="background: [M]"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 17l6-6 4 4 8-8"/><path d="M14 7h7v7"/></svg></span><div class="mid"><p class="n">Auswertung</p><p class="s">Monatsvergleich, Jahresblick, Bereiche</p></div>[CHEV]</a>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Daten</h2>
    <div class="card">
      <a class="row" href="Dokumente.dc.html"><span class="c" style="background: #637894"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M4 5h6l2 2h8v12H4z"/></svg></span><div class="mid"><p class="n">Dokumente</p><p class="s">38 Originale · 112 MB · nach Bereich</p></div>[CHEV]</a>
      <div class="sep"></div>
      <button class="row" onClick="{{openBackup}}"><span class="c" style="background: #637894"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v12M7 10l5 5 5-5"/><path d="M4 17v3h16v-3"/></svg></span><div class="mid"><p class="n">Backup &amp; Export</p><p class="s">{{backupLine}}</p></div>[CHEV]</button>
      <div class="sep"></div>
      <a class="row" href="Kasse.dc.html"><span class="c" style="background: #637894"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M4 6h16v12H4zM4 10h16"/></svg></span><div class="mid"><p class="n">Haushaltskasse</p><p class="s">Bargeld · 86,50 € · 5 Bons aus der Kasse</p></div>[CHEV]</a>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <a class="row" href="Einstellungen.dc.html"><span class="c" style="background: #8A94A3">''' + GEAR + '''</span><div class="mid"><p class="n">Einstellungen</p><p class="s">Erinnerungen, Monatsstart, OCR, Datenschutz</p></div>[CHEV]</a>
      <div class="sep"></div>
      <button class="row" onClick="{{openHelp}}"><span class="c" style="background: #8A94A3"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.7.3-1 .8-1 1.5M12 17h.01"/></svg></span><div class="mid"><p class="n">Hilfe &amp; Support</p><p class="s">Anleitung, Kontakt, Version 2.0.0</p></div>[CHEV]</button>
    </div>
  </div>
''') + '''<sc-if value="{{backup}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>Backup &amp; Export</h3><p>{{backupText}}</p><div class="card" style="margin-bottom: 12px"><div class="f"><p class="v wrap" style="font-weight: 500; font-size: 15px">Belege und PDFs einschließen</p><p class="v ph" style="flex: none; width: auto; font-size: 13px">112 MB</p><button class="{{docsCls}}" aria-label="Belege einschließen" onClick="{{flipDocs}}"></button></div><div class="sep"></div><div class="f"><p class="l">Format</p><div class="seg"><sc-for list="{{fmt}}" as="s" hint-placeholder-count="3"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div><sc-if value="{{running}}" hint-placeholder-val="{{false}}"><div class="sep"></div><div class="f"><p class="v wrap">{{progressText}}</p></div><div style="margin: 0 16px 12px"><div class="bar2"><i style="{{progSt}}"></i></div></div></sc-if></div><div style="display: flex; gap: 10px"><button class="btn sec2" onClick="{{closeBackup}}">Schließen</button><button class="btn pri" onClick="{{runBackup}}">{{runLabel}}</button></div></div></div></sc-if>''' \
      + '''<sc-if value="{{help}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>Hilfe &amp; Support</h3><p>Mnemor 2.0.0 (Build 1) · iOS 17 oder neuer · Erkennung auf dem Gerät</p><div class="card" style="margin-bottom: 12px"><button class="f" onClick="{{helpGuide}}"><p class="v" style="font-weight: 500">Anleitung: Rechnung erfassen in 20 Sekunden</p>[CHEV]</button><div class="sep"></div><button class="f" onClick="{{helpContact}}"><p class="v" style="font-weight: 500">Kontakt: support@mnemor.de</p>[CHEV]</button><div class="sep"></div><button class="f" onClick="{{helpPrivacy}}"><p class="v" style="font-weight: 500">Datenschutz: keine Server, kein Konto</p>[CHEV]</button><div class="sep"></div><button class="f" onClick="{{helpDiag}}"><p class="v" style="font-weight: 500">Diagnose-Bericht erstellen (ohne Belegdaten)</p>[CHEV]</button></div><button class="btn sec2" onClick="{{closeHelp}}">Schließen</button></div></div></sc-if>'''
    logic = r'''  constructor(p) { super(p); this.state = { backup: false, docs: true, fmt: 'zip', running: false, prog: 0, last: '18. Okt., 112 MB', help: false, toast: '' }; }
''' + JS_SEG + r'''
  renderVals() {
    var self = this, s = this.state;
    return {
      toast: s.toast,
      backupLine: 'ZIP mit Daten und Belegen · letztes: ' + s.last,
      backup: s.backup, openBackup: this.go('backup', true), closeBackup: function () { self.setState({ backup: false, running: false, prog: 0 }); },
      backupText: s.fmt === 'zip' ? 'Vollständiges Backup: JSON-Datenbank plus alle Originale als ZIP in „Dateien“. Wiederherstellung inklusive Belegen.' : (s.fmt === 'csv' ? 'CSV für Excel/Numbers: Rechnungen, Verträge, Budgets mit Bereich, Kategorie, Kostenart.' : 'PDF-Bericht des Monats zum Weitergeben.'),
      docsCls: this.tog('docs'), flipDocs: this.flip('docs'),
      fmt: this.segItems('fmt', [['zip', 'Backup (ZIP)'], ['csv', 'CSV'], ['pdf', 'PDF']]),
      running: s.running, progressText: s.prog >= 100 ? 'Fertig: mnemor-2026-10-25.' + s.fmt + (s.fmt === 'zip' ? (s.docs ? ' (112 MB)' : ' (0,9 MB)') : '') + ' · in „Dateien“ gespeichert' : 'Wird erstellt … ' + s.prog + ' %',
      progSt: 'width: ' + s.prog + '%; background: #2A5480',
      runLabel: s.running && s.prog >= 100 ? 'Teilen' : 'Jetzt erstellen',
      runBackup: function () {
        if (s.running && s.prog >= 100) { self.say('Teilen-Menü: AirDrop, Dateien, Mail'); return; }
        self.setState({ running: true, prog: 0 });
        var step = function (p) { self.setState({ prog: p }); if (p < 100) setTimeout(function () { step(Math.min(100, p + 25)); }, 350); else self.setState({ last: '25. Okt., ' + (s.docs ? '112 MB' : '0,9 MB') }); };
        setTimeout(function () { step(25); }, 300);
      },
      help: s.help, openHelp: this.go('help', true), closeHelp: this.go('help', false),
      helpGuide: function () { self.say('Anleitung geöffnet (In-App)'); }, helpContact: function () { self.say('Mail an support@mnemor.de wird geöffnet'); }, helpPrivacy: function () { self.say('Datenschutzerklärung geöffnet'); }, helpDiag: function () { self.say('Diagnose-Bericht erstellt · nur Gerätedaten, keine Belege'); }
    };
  }'''
    page("Mehr.dc.html", "Mehr", body, logic, 'u', EXTRA_CSS)

    # ================================================================ Haushaltskasse
    body = tpl('''  <div class="hdr">
    <div class="nav"><a class="back" href="Mehr.dc.html">[BACK]Mehr</a><p class="ttl">Haushaltskasse</p><button class="act" onClick="{{openExport}}">PDF</button></div>
    <h1>Haushaltskasse</h1>
    <div style="display: flex; align-items: baseline; justify-content: space-between; gap: 14px; margin-top: 12px"><p class="big" style="margin: 0">{{saldo}} €</p><p style="margin: 0; font-size: 13px; opacity: .85; text-align: right">Bargeld · {{bonCount}} Bons im Oktober</p></div>
    <p class="sub">Einzahlungen je Person, Bons werden „aus der Kasse“ gebucht. Ein Gerät – Teilen kommt mit 2.1.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Einzahlungen im Oktober</h2>
    <div class="card">
      <sc-for list="{{persons}}" as="p" hint-placeholder-count="2">
        <button class="row" onClick="{{p.add}}"><span class="c" style="background: #4CAF7A; font-size: 13px; font-weight: 700">{{p.ini}}</span><div class="mid"><p class="n">{{p.name}}</p><p class="s">{{p.sub}}</p></div><p class="v" style="color: #215F33">+{{p.sum}}</p>[CHEV]</button>
        <div class="sep"></div>
      </sc-for>
      <div class="row"><div class="mid"><p class="n">Entnahmen (Bons)</p><p class="s">Lebensmittel, Bäcker, Markt</p></div><p class="v" style="color: #943333">−{{out}}</p></div>
    </div>
    <p class="note">Saldo = Einzahlungen {{inSum}} − Bons {{out}} = {{saldo}} €. Bons aus der Kasse zählen im Budget der Kategorie, nicht in der Liquidität des Kontos.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Bons aus der Kasse <a href="Erfassen.dc.html">+ Bon</a></h2>
    <div class="card">
      <sc-for list="{{bons}}" as="b" hint-placeholder-count="4">
        <a class="row" href="Rechnung.dc.html"><div class="mid"><p class="n" style="font-weight: 500">{{b.name}}</p><p class="s">{{b.sub}}</p></div><p class="v">−{{b.val}}</p>[CHEV]</a>
        <div class="sep"></div>
      </sc-for>
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px; display: flex; gap: 10px">
    <button class="btn pri" onClick="{{openIn}}">Einzahlen</button>
    <a class="btn sec2" href="Erfassen.dc.html">Bon erfassen</a>
  </div>
''') + '''<sc-if value="{{sheet}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>Einzahlen</h3><p>Bargeld in die Haushaltskasse. Der Kontostand ändert sich nur, wenn du es abhebst – das erfasst die Liquidität separat.</p><div class="card" style="margin-bottom: 12px"><div class="f"><p class="l">Person</p><div class="seg"><sc-for list="{{who}}" as="s" hint-placeholder-count="2"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div><div class="sep"></div><div class="f"><p class="l">Betrag</p><input class="in num" value="{{amt}}" onChange="{{setAmt}}" inputmode="decimal" placeholder="0,00"><span style="font-size: 14px; color: #637894">€</span></div></div><div style="display: flex; gap: 10px"><button class="btn sec2" onClick="{{closeSheet}}">Abbrechen</button><button class="btn pri" onClick="{{confirm}}">Einzahlen</button></div></div></div></sc-if>''' \
      + sheet("exportSheet", "Abrechnung als PDF", "Oktober 2026: Einzahlungen je Person, alle Bons mit Kategorie, Saldo. Zum Teilen oder Ablegen.", '<button class="btn sec2" onClick="{{closeExport}}">Abbrechen</button><button class="btn pri" onClick="{{doExport}}">PDF erstellen</button>')
    logic = r'''  constructor(p) { super(p); this.state = { dep: { anna: 120, ben: 109.17 }, bons: [ { name: 'Bäckerei Schmitt', sub: 'Mi 21. Okt. · Lebensmittel', val: 12.60 }, { name: 'Wochenmarkt', sub: 'So 18. Okt. · Lebensmittel', val: 41.80 }, { name: 'REWE', sub: 'Do 15. Okt. · Lebensmittel', val: 58.37 }, { name: 'dm-drogerie markt', sub: 'Mi 14. Okt. · Lebensmittel', val: 23.90 }, { name: 'Kiosk', sub: 'Di 13. Okt. · Freizeit', val: 6.00 } ], sheet: false, who: 'anna', amt: '', exportSheet: false, toast: '' }; }
''' + JS_SEG + r'''
  renderVals() {
    var self = this, s = this.state, inSum = s.dep.anna + s.dep.ben, out = s.bons.reduce(function (a, b) { return a + b.val; }, 0), saldo = inSum - out;
    var openFor = function (w) { return function () { self.setState({ sheet: true, who: w, amt: '' }); }; };
    return {
      toast: s.toast,
      saldo: eur(saldo), bonCount: s.bons.length, inSum: eur(inSum), out: eur(out),
      persons: [{ k: 'anna', name: 'Anna', ini: 'A' }, { k: 'ben', name: 'Ben', ini: 'B' }].map(function (p) { return { name: p.name, ini: p.ini, sub: s.dep[p.k] > 0 ? 'eingezahlt · antippen für weitere Einzahlung' : 'noch nichts eingezahlt', sum: eur(s.dep[p.k]), add: openFor(p.k) }; }),
      bons: s.bons.map(function (b) { return { name: b.name, sub: b.sub, val: eur(b.val) }; }),
      sheet: s.sheet, openIn: openFor(s.who), closeSheet: this.go('sheet', false),
      who: this.segItems('who', [['anna', 'Anna'], ['ben', 'Ben']]), amt: s.amt, setAmt: this.set('amt'),
      confirm: function () { var a = num(s.amt); if (!(a > 0)) { self.say('Betrag eingeben'); return; } var d = Object.assign({}, s.dep); d[s.who] += a; self.setState({ dep: d, sheet: false }); self.say(eur(a) + ' € von ' + (s.who === 'anna' ? 'Anna' : 'Ben') + ' · Saldo ' + eur(saldo + a) + ' €'); },
      exportSheet: s.exportSheet, openExport: this.go('exportSheet', true), closeExport: this.go('exportSheet', false), doExport: function () { self.setState({ exportSheet: false }); self.say('Haushaltskasse-Oktober-2026.pdf erstellt · Teilen-Menü'); }
    };
  }'''
    page("Kasse.dc.html", "Haushaltskasse", body, logic, 'u', EXTRA_CSS)

    # ================================================================ Dokumente
    body = tpl('''  <div class="hdr" style="padding-bottom: 18px">
    <div class="nav"><a class="back" href="Mehr.dc.html">[BACK]Mehr</a><p class="ttl">Dokumente</p><button class="act" onClick="{{toggleSearch}}">Suchen</button></div>
    <h1>Dokumente</h1>
    <p class="sub">{{summary}}</p>
    <sc-if value="{{search}}" hint-placeholder-val="{{false}}"><input class="in" style="margin-top: 12px; width: 100%; box-sizing: border-box; color: #FFFFFF; border-bottom-color: rgba(255,255,255,.5); font-size: 16px" placeholder="Anbieter, Typ oder Objekt" value="{{q}}" onChange="{{setQ}}"></sc-if>
    <div style="display: flex; gap: 8px; margin-top: 14px; flex-wrap: wrap"><sc-for list="{{chips}}" as="c" hint-placeholder-count="4"><button class="{{c.cls}}" onClick="{{c.pick}}">{{c.label}}</button></sc-for></div>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <div class="card">
      <sc-for list="{{docs}}" as="d" hint-placeholder-count="6">
        <button class="row" onClick="{{d.open}}"><span class="c" style="{{d.cst}}"><svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M7 3h7l5 5v13H7z"/><path d="M14 3v5h5"/></svg></span><div class="mid"><p class="n" style="font-weight: 500">{{d.name}}</p><p class="s">{{d.sub}}</p></div><p class="v m" style="font-size: 12px">{{d.size}}</p>[CHEV]</button>
        <div class="sep"></div>
      </sc-for>
      <sc-if value="{{none}}" hint-placeholder-val="{{false}}"><div class="f"><p class="v ph">Keine Dokumente für diese Auswahl.</p></div></sc-if>
    </div>
    <p class="note">Keine Ordner: Jedes Dokument hängt an seiner Rechnung, seinem Vertrag, Objekt oder Termin. Originale bleiben im Backup enthalten.</p>
  </div>
''') + DOC_OVERLAY_D
    logic = r'''  constructor(p) { super(p); this.state = { area: 'all', search: false, q: '', showDoc: false, cur: 0, toast: '' };
    this.DOCS = [
      { name: 'Jahresabrechnung 2025.pdf', sub: 'Stadtwerke · Rechnung 4. Okt. · Wohnung', area: 'w', size: '0,4 MB', head: 'Stadtwerke Mainstadt GmbH', s2: 'Jahresabrechnung Strom 2025', l1: 'Verbrauch 2.980 kWh', l2: 'Abschläge 1.008,00 €', l3: 'Nachzahlung 142,00 €' },
      { name: 'Mietvertrag.pdf', sub: 'Vertrag Miete · seit 2021 · Wohnung', area: 'w', size: '2,1 MB', head: 'Mietvertrag Hauptstr. 12', s2: 'Vermieter Hausverwaltung Rhein', l1: 'Kaltmiete 720 € · Nebenkosten 230 €', l2: 'Kündigungsfrist 3 Monate', l3: 'Kaution 2.160 €' },
      { name: 'Telekom Auftragsbestätigung.pdf', sub: 'Vertrag Internet · Mai 2025 · Wohnung', area: 'w', size: '0,3 MB', head: 'Telekom Deutschland', s2: 'MagentaZuhause M', l1: '39,99 €/Monat', l2: 'Laufzeit 24 Monate bis 31.05.2027', l3: 'Kündigungsfrist 1 Monat' },
      { name: 'Fahrzeugschein VW ID.3.jpg', sub: 'Objekt VW ID.3 · Scan', area: 'm', size: '1,8 MB', head: 'Zulassungsbescheinigung Teil I', s2: 'KA-MN 2024 · VW ID.3 Pro', l1: 'Erstzulassung 03/2022', l2: 'HU fällig 11/2026', l3: 'Halter: Anna Muster' },
      { name: 'Leasingvertrag VW.pdf', sub: 'Vertrag Leasing · bis 08/2028 · VW ID.3', area: 'm', size: '1,1 MB', head: 'VW Financial Services', s2: 'Privatleasing ID.3', l1: '289 €/Monat · 36 Monate', l2: '10.000 km/Jahr', l3: 'Restlaufzeit 22 Monate' },
      { name: 'HUK24 Police 2026.pdf', sub: 'Vertrag Kfz-Versicherung · VW ID.3', area: 'm', size: '0,6 MB', head: 'HUK24', s2: 'Kfz-Haftpflicht + Vollkasko', l1: 'Jahresbeitrag 487,20 €', l2: 'Hauptfälligkeit 1. Jan.', l3: 'SF-Klasse 12' },
      { name: 'Inspektion Autohaus Keller.jpg', sub: 'Rechnung · Scan 24. Okt. · VW ID.3', area: 'm', size: '1,2 MB', head: 'Autohaus Keller GmbH', s2: 'Rechnung RE-2026-4471', l1: 'Inspektion 60.000 km', l2: 'Gesamt 212,40 €', l3: 'zahlbar bis 30.10.2026' },
      { name: 'Haftpflicht Police.pdf', sub: 'Vertrag Versicherung · Anna', area: 'h', size: '0,5 MB', head: 'Privathaftpflicht', s2: 'Familientarif', l1: 'Jahresbeitrag 68,00 €', l2: 'Fälligkeit 1. März', l3: 'Deckung 50 Mio. €' },
      { name: 'FitnessFirst Vertrag.pdf', sub: 'Vertrag Mitgliedschaft · Ben', area: 'h', size: '0,2 MB', head: 'FitnessFirst', s2: 'Mitgliedschaft Premium', l1: '29,90 €/Monat', l2: 'Mindestlaufzeit bis 15.12.2026', l3: 'Kündigung 4 Wochen zum Laufzeitende' }
    ]; }
''' + JS_SEG + r'''
  renderVals() {
    var self = this, s = this.state, q = s.q.trim().toLowerCase(), col = { w: '#E8A33D', m: '#3C8DBC', h: '#4CAF7A' };
    var list = this.DOCS.filter(function (d) { return (s.area === 'all' || d.area === s.area) && (!q || (d.name + ' ' + d.sub).toLowerCase().indexOf(q) >= 0); });
    var cur = this.DOCS[s.cur];
    return {
      toast: s.toast,
      summary: list.length + ' von 38 Dokumenten · 112 MB auf diesem iPhone',
      search: s.search, q: s.q, setQ: this.set('q'), toggleSearch: function () { self.setState({ search: !s.search, q: '' }); },
      chips: this.chipItems('area', [['all', 'Alle'], ['w', 'Wohnen'], ['m', 'Mobilität'], ['h', 'Haushalt']]),
      docs: list.map(function (d) { return { name: d.name, sub: d.sub, size: d.size, cst: 'background: ' + col[d.area], open: function () { self.setState({ showDoc: true, cur: self.DOCS.indexOf(d) }); } }; }),
      none: list.length === 0,
      showDoc: s.showDoc, closeDoc: this.go('showDoc', false), shareDoc: function () { self.say(cur.name + ' geteilt'); },
      docTitle: cur.name, docHead: cur.head, docSub: cur.s2, docLine1: cur.l1, docLine2: cur.l2, docLine3: cur.l3
    };
  }'''
    page("Dokumente.dc.html", "Dokumente", body, logic, 'u', EXTRA_CSS)

    # ================================================================ Auswertung
    body = tpl('''  <div class="hdr">
    <div class="nav"><a class="back" href="Mehr.dc.html">[BACK]Mehr</a><p class="ttl">Auswertung</p><button class="act" onClick="{{openExport}}">Export</button></div>
    <h1>Auswertung</h1>
    <div style="margin-top: 14px"><div class="seg dark"><sc-for list="{{views}}" as="s" hint-placeholder-count="4"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div>
  </div>

  <sc-if value="{{isBars}}" hint-placeholder-val="{{true}}">
  <div style="padding: 18px 20px 0 20px">
    <div class="card" style="padding: 16px 14px 12px">
      <div style="display: flex; align-items: baseline; justify-content: space-between; padding: 0 4px"><p style="margin: 0; font-size: 15px; font-weight: 700">{{chartTitle}}</p><p style="margin: 0; font-size: 12px; color: #637894">{{chartMeta}}</p></div>
      <div style="display: flex; gap: 6px; margin-top: 12px; align-items: flex-end">
        <sc-for list="{{bars}}" as="b" hint-placeholder-count="6"><button style="flex: 1; display: flex; flex-direction: column; align-items: center; gap: 4px; background: none; border: 0; padding: 0; cursor: pointer; font: inherit" onClick="{{b.pick}}" aria-label="{{b.label}}"><p style="margin: 0; font-size: 10px; color: #637894; font-variant-numeric: tabular-nums">{{b.total}}</p><div style="{{b.colst}}"><i style="{{b.h}}"></i><i style="{{b.m}}"></i><i style="{{b.w}}"></i></div><p style="{{b.lst}}">{{b.label}}</p></button></sc-for>
      </div>
      <div style="display: flex; gap: 14px; justify-content: center; margin-top: 10px; font-size: 11.5px; color: #637894"><span><span class="dot" style="background: [W]; margin-right: 5px"></span>Wohnen</span><span><span class="dot" style="background: [M]; margin-right: 5px"></span>Mobilität</span><span><span class="dot" style="background: [H]; margin-right: 5px"></span>Haushalt</span></div>
    </div>
    <p class="note">{{selNote}}</p>
  </div>
  </sc-if>

  <sc-if value="{{isAreas}}" hint-placeholder-val="{{false}}">
  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Bereiche im Oktober <span>Anteil an 2.995,90 €</span></h2>
    <div class="card">
      <sc-for list="{{areaRows}}" as="a" hint-placeholder-count="3">
        <a class="row" href="{{a.href}}" style="align-items: stretch; flex-direction: column; gap: 0; padding-top: 10px; padding-bottom: 10px"><div style="display: flex; align-items: center; gap: 10px"><span class="dot" style="{{a.dotst}}"></span><p class="n" style="flex: 1">{{a.name}}</p><p class="v">{{a.val}} · {{a.pct}} %</p></div><div class="bar2"><i style="{{a.barst}}"></i></div><p class="s">{{a.sub}}</p></a>
        <div class="sep"></div>
      </sc-for>
    </div>
  </div>
  </sc-if>

  <sc-if value="{{isCats}}" hint-placeholder-val="{{false}}">
  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Größte Kategorien im Oktober <span>Top 8</span></h2>
    <div class="card">
      <sc-for list="{{cats}}" as="c" hint-placeholder-count="8">
        <a class="row" href="{{c.href}}"><span class="dot" style="{{c.dotst}}"></span><div class="mid"><p class="n" style="font-weight: 500">{{c.name}}</p><p class="s">{{c.sub}}</p></div><p class="v">{{c.val}}</p>[CHEV]</a>
        <div class="sep"></div>
      </sc-for>
    </div>
  </div>
  </sc-if>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Oktober im Vergleich zum Schnitt <span>Mai–Sep.</span></h2>
    <div class="card">
      <sc-for list="{{cmp}}" as="c" hint-placeholder-count="3">
        <a class="row" href="{{c.href}}"><span class="dot" style="{{c.dotst}}"></span><div class="mid"><p class="n">{{c.name}}</p><p class="s">{{c.sub}}</p></div><p class="v">{{c.val}}</p><span class="cap" style="{{c.capst}}">{{c.cap}}</span></a>
        <div class="sep"></div>
      </sc-for>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Jahresblick 2026 <span>hochgerechnet</span></h2>
    <div class="card">
      <div class="f"><p class="l">Einnahmen</p><p class="v">44.451,30 € · inkl. Urlaubsgeld</p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Fixkosten</p><p class="v">19.910,40 € · 45 % der Einnahmen</p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Sparpotenzial</p><p class="v">6.930,00 € · Ø 577,50 €/Monat</p></div>
    </div>
  </div>
''') + '''<sc-if value="{{exportSheet}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>Export</h3><p>Zahlen dieser Auswertung als Datei – lokal erstellt, dann Teilen-Menü.</p><div class="card" style="margin-bottom: 12px"><div class="f"><p class="l">Format</p><div class="seg"><sc-for list="{{exFmt}}" as="s" hint-placeholder-count="2"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div><div class="sep"></div><div class="f"><p class="l">Zeitraum</p><div class="seg"><sc-for list="{{exRange}}" as="s" hint-placeholder-count="3"><button class="{{s.cls}}" onClick="{{s.pick}}">{{s.label}}</button></sc-for></div></div></div><div style="display: flex; gap: 10px"><button class="btn sec2" onClick="{{closeExport}}">Abbrechen</button><button class="btn pri" onClick="{{doExport}}">Erstellen</button></div></div></div></sc-if>'''
    logic = r'''  constructor(p) { super(p); this.state = { view: '6m', sel: 5, exportSheet: false, exFmt: 'csv', exRange: 'monat', toast: '' };
    this.M6 = [['Mai', 1290, 610, 840], ['Jun', 1290, 655, 905], ['Jul', 1290, 1180, 1420], ['Aug', 1290, 590, 860], ['Sep', 1300, 640, 870], ['Okt', 1368.18, 746.19, 881.53]];
    this.Y = [['J', 1280, 600, 850], ['F', 1280, 590, 830], ['M', 1280, 620, 860], ['A', 1290, 700, 870], ['M', 1290, 610, 840], ['J', 1290, 655, 905], ['J', 1290, 1180, 1420], ['A', 1290, 590, 860], ['S', 1300, 640, 870], ['O', 1368.18, 746.19, 881.53], ['N', 1368, 760, 880], ['D', 1368, 700, 1150]]; }
''' + JS_SEG + r'''
  renderVals() {
    var self = this, s = this.state, year = s.view === 'jahr', data = year ? this.Y : this.M6, sel = Math.min(s.sel, data.length - 1);
    var totals = data.map(function (m) { return m[1] + m[2] + m[3]; }), mx = Math.max.apply(null, totals), avg = totals.reduce(function (a, b) { return a + b; }, 0) / totals.length;
    var d = data[sel], hh = year ? 110 : 150;
    var names = { Mai: 'Mai', Jun: 'Juni', Jul: 'Juli', Aug: 'August', Sep: 'September', Okt: 'Oktober' };
    var avg5 = function (idx) { return this.M6.slice(0, 5).reduce(function (a, m) { return a + m[idx]; }, 0) / 5; }.bind(this);
    var cmpRow = function (name, idx, href, dotc, sub) { var v = self.M6[5][idx], a = avg5(idx), p = Math.round((v - a) / a * 100); return { name: name, sub: sub, val: eur(v), href: href, dotst: 'background: ' + dotc, cap: (p > 0 ? '+' : '') + p + ' %', capst: p > 4 ? 'background: #F7D4D1; color: #943333' : (p >= 0 ? 'background: #EDE3C9; color: #704F2E' : 'background: #D6EDDB; color: #215F33') }; };
    var areasTot = 1368.18 + 746.19 + 881.53;
    return {
      toast: s.toast,
      views: this.segItems('view', [['6m', '6 Monate'], ['jahr', 'Jahr'], ['bereiche', 'Bereiche'], ['kat', 'Kategorien']]),
      isBars: s.view === '6m' || year, isAreas: s.view === 'bereiche', isCats: s.view === 'kat',
      chartTitle: year ? 'Ausgaben je Monat 2026' : 'Ausgaben je Monat', chartMeta: 'Ø ' + eur(avg, 0) + ' € · ' + (year ? 'Nov./Dez. geplant' : 'Okt. ' + eur(totals[5], 0) + ' €'),
      bars: data.map(function (m, i) { var t = m[1] + m[2] + m[3], on = i === sel, planned = year && i > 9; var seg = function (v, c) { return 'display: block; height: ' + Math.round(v / mx * hh) + 'px; background: ' + c + (planned ? '; opacity: .45' : '') + (on ? '' : '; opacity: ' + (planned ? '.35' : '.75')); };
        return { label: m[0], total: year ? '' : eur(t, 0), pick: function () { self.setState({ sel: i }); }, colst: 'width: ' + (year ? 18 : 26) + 'px; height: ' + hh + 'px; display: flex; flex-direction: column; justify-content: flex-end; border-radius: 6px; overflow: hidden' + (on ? '; outline: 2px solid #2A5480; outline-offset: 2px' : ''), h: seg(m[3], '#4CAF7A'), m: seg(m[2], '#3C8DBC'), w: seg(m[1], '#E8A33D'), lst: 'margin: 0; font-size: 11px; font-weight: ' + (on ? 700 : 500) + '; color: ' + (on ? '#16243A' : '#637894') }; }),
      selNote: (year ? 'Monat ' + (sel + 1) : names[d[0]]) + ': ' + eur(d[1] + d[2] + d[3]) + ' € = Wohnen ' + eur(d[1]) + ' + Mobilität ' + eur(d[2]) + ' + Haushalt ' + eur(d[3]) + (sel === 5 && !year ? ' – wie auf der Übersicht (Fixkosten + Ausgaben + Rücklagen).' : (d[2] > 1000 ? ' – Juli: Urlaub und Reifen.' : '.')),
      areaRows: [['Wohnen', 1368.18, 'Wohnen.dc.html', '#E8A33D', 'fix 1.218,35 · variabel 142,00 · Rücklagen 7,83'], ['Mobilität', 746.19, 'Akte.dc.html', '#3C8DBC', 'fix 356,99 · variabel 276,60 · Rücklagen 112,60'], ['Haushalt', 881.53, 'Haushalt.dc.html', '#4CAF7A', 'fix 83,86 · variabel 592,00 · Rücklagen 205,67']].map(function (a) { var p = Math.round(a[1] / areasTot * 100); return { name: a[0], val: eur(a[1]), pct: p, href: a[2], dotst: 'background: ' + a[3], barst: 'width: ' + p + '%; background: ' + a[3], sub: a[4] }; }),
      cats: [['Miete / Hausgeld', 950, 'w', 'Wohnen · fix'], ['Lebensmittel & Haushalt', 412, 'h', 'Haushalt · variabel · Budget 450'], ['Kfz-Rate / Leasing', 289, 'm', 'Mobilität · Kredit'], ['Werkstatt & Reifen', 272.40, 'm', 'Mobilität · 212,40 offen + 60 Rücklage'], ['Strom', 240, 'w', 'Wohnen · 98 Abschlag + 142 Nachzahlung'], ['Freizeit & Kultur', 209.90, 'h', 'Haushalt · Budget 150 überschritten'], ['Urlaub & Reisen', 200, 'h', 'Haushalt · Rücklage-Rate'], ['Gas / Heizung', 112, 'w', 'Wohnen · fix']].map(function (c) { return { name: c[0], val: eur(c[1]), sub: c[3] + ' · ' + Math.round(c[1] / areasTot * 100) + ' %', href: c[2] === 'w' ? 'Wohnen.dc.html' : (c[2] === 'm' ? 'Akte.dc.html' : 'Haushalt.dc.html'), dotst: 'background: ' + ({ w: '#E8A33D', m: '#3C8DBC', h: '#4CAF7A' })[c[2]] }; }),
      cmp: [cmpRow('Wohnen', 1, 'Wohnen.dc.html', '#E8A33D', 'Nachzahlung Strom 142 € einmalig'), cmpRow('Mobilität', 2, 'Akte.dc.html', '#3C8DBC', 'Inspektion 212,40 €'), cmpRow('Haushalt', 3, 'Haushalt.dc.html', '#4CAF7A', 'Freizeit über Budget, Lebensmittel im Plan')],
      exportSheet: s.exportSheet, openExport: this.go('exportSheet', true), closeExport: this.go('exportSheet', false),
      exFmt: this.segItems('exFmt', [['csv', 'CSV'], ['pdf', 'PDF']]), exRange: this.segItems('exRange', [['monat', 'Oktober'], ['6m', '6 Monate'], ['jahr', '2026']]),
      doExport: function () { self.setState({ exportSheet: false }); self.say('mnemor-auswertung-' + s.exRange + '.' + s.exFmt + ' erstellt · Teilen-Menü'); }
    };
  }'''
    page("Auswertung.dc.html", "Auswertung", body, logic, 'u', EXTRA_CSS)

    # ================================================================ Einstellungen
    def srow(label, var, handler):
        return f'<button class="f" onClick="{{{{{handler}}}}}"><p class="v wrap" style="font-weight: 500; font-size: 15px">{label}</p><p class="v ph" style="flex: none; width: auto; max-width: 150px; white-space: normal; text-align: right; font-size: 13px">{{{{{var}}}}}</p>{CHEV}</button>'
    def trow(label, sub, clsvar, handler):
        return f'<div class="f"><p class="v wrap" style="font-weight: 500; font-size: 15px">{label}</p><p class="v ph" style="flex: none; width: auto; max-width: 130px; white-space: normal; text-align: right; font-size: 13px">{sub}</p><button class="{{{{{clsvar}}}}}" aria-label="{label}" onClick="{{{{{handler}}}}}"></button></div>'
    body = tpl('''  <div class="hdr">
    <div class="nav"><a class="back" href="Mehr.dc.html">[BACK]Mehr</a><p class="ttl">Einstellungen</p><span style="width: 60px"></span></div>
    <h1>Einstellungen</h1>
    <p class="sub">Antippen wechselt den Wert – alles gilt sofort.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Monat &amp; Erinnerungen</h2>
    <div class="card">
      ''' + srow("Monatsbeginn", "monatText", "cycleMonat") + '''
      <div class="sep"></div>
      ''' + srow("Fällig-Fenster auf der Übersicht", "windowText", "cycleWindow") + '''
      <div class="sep"></div>
      ''' + srow("Erinnerung vor Fälligkeit", "remindText", "cycleRemind") + '''
      <div class="sep"></div>
      ''' + trow("Kündigungsfristen", "4 Wochen vorher", "kdCls", "flipKd") + '''
      <div class="sep"></div>
      ''' + trow("Kontostand-Erinnerung", "nach jeder Abbuchung", "ksCls", "flipKs") + '''
      <div class="sep"></div>
      ''' + srow("Systemkalender „Mnemor“", "calText", "cycleCal") + '''
    </div>
    <p class="note">{{monatNote}} {{calNote}}</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Erfassen</h2>
    <div class="card">
      ''' + srow("Erkennung auf dem Gerät", "ocrText", "cycleOcr") + '''
      <div class="sep"></div>
      ''' + trow("Originale behalten", "PDF und Scans", "keepCls", "flipKeep") + '''
      <div class="sep"></div>
      ''' + trow("Bon-Schnellmodus", "sofort als bezahlt", "bonCls", "flipBon") + '''
      <div class="sep"></div>
      <button class="f" onClick="{{askReset}}"><p class="v wrap" style="font-weight: 500; font-size: 15px">Lernregeln</p><p class="v ph" style="flex: none; width: auto; font-size: 13px">{{learnText}}</p>[CHEV]</button>
    </div>
    <p class="note">Keine Cloud, kein Konto: Texterkennung und Zuordnung laufen vollständig auf dem iPhone.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Bereiche &amp; Kategorien</h2>
    <div class="card">
      <a class="f" href="Wohnen.dc.html"><p class="v" style="font-weight: 500"><span class="dot" style="background: [W]; margin-right: 6px; vertical-align: middle"></span>Wohnen</p><p class="v ph" style="flex: none; width: auto; font-size: 13px">{{wCount}} Kategorien · 1 Objekt</p>[CHEV]</a>
      <div class="sep"></div>
      <a class="f" href="Akte.dc.html"><p class="v" style="font-weight: 500"><span class="dot" style="background: [M]; margin-right: 6px; vertical-align: middle"></span>Mobilität</p><p class="v ph" style="flex: none; width: auto; font-size: 13px">6 Kategorien · 2 Objekte</p>[CHEV]</a>
      <div class="sep"></div>
      <a class="f" href="Haushalt.dc.html"><p class="v" style="font-weight: 500"><span class="dot" style="background: [H]; margin-right: 6px; vertical-align: middle"></span>Haushalt</p><p class="v ph" style="flex: none; width: auto; font-size: 13px">10 Kategorien · 2 Personen</p>[CHEV]</a>
      <div class="sep"></div>
      <button class="f" onClick="{{restore}}"><p class="v wrap" style="font-weight: 500; font-size: 15px">Standardkategorien wiederherstellen</p><p class="v ph" style="flex: none; width: auto; font-size: 13px">{{restoreText}}</p>[CHEV]</button>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Sicherheit &amp; Daten</h2>
    <div class="card">
      ''' + trow("App-Sperre", "Face ID", "lockCls", "flipLock") + '''
      <div class="sep"></div>
      ''' + srow("Automatisches Backup", "backupText", "cycleBackup") + '''
      <div class="sep"></div>
      <button class="f" onClick="{{askWipe}}"><p class="v wrap" style="font-weight: 500; font-size: 15px; color: #943333">Alle Daten löschen</p>[CHEV]</button>
    </div>
  </div>
''') + sheet("resetSheet", "Lernregeln zurücksetzen?", "23 gelernte Anbieterprofile (Kategorie, Empfänger, Fälligkeits-Offset) werden gelöscht. Rechnungen bleiben erhalten; die Erkennung lernt neu.", '<button class="btn sec2" onClick="{{cancelReset}}">Abbrechen</button><button class="btn danger" onClick="{{doReset}}">Zurücksetzen</button>') \
      + '''<sc-if value="{{wipe}}" hint-placeholder-val="{{false}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>Alle Daten löschen?</h3><p>{{wipeText}}</p><sc-if value="{{wipe2}}" hint-placeholder-val="{{false}}"><div class="card" style="margin-bottom: 12px"><div class="f"><p class="l">Tippe LÖSCHEN</p><input class="in" value="{{wipeWord}}" onChange="{{setWipeWord}}" placeholder="LÖSCHEN"></div></div></sc-if><div style="display: flex; gap: 10px"><button class="btn sec2" onClick="{{cancelWipe}}">Abbrechen</button><button class="btn danger" onClick="{{nextWipe}}">{{wipeBtn}}</button></div></div></div></sc-if>'''
    logic = r'''  constructor(p) { super(p); this.state = { monat: 0, win: 1, rem: 1, kd: true, ks: true, cal: 1, ocr: 0, keep: true, bon: true, learn: 23, resetSheet: false, restored: false, lock: true, backup: 1, wipe: false, wipe2: false, wipeWord: '', toast: '' }; }
''' + JS_SEG + r'''
  cyc(key, n) { var self = this; return function () { var s = {}; s[key] = (self.state[key] + 1) % n; self.setState(s); }; }
  renderVals() {
    var self = this, s = this.state;
    var monat = ['1. des Monats', '15. des Monats', 'am Gehaltstag (30.)'], win = ['3 Tage', '7 Tage', '14 Tage'], rem = ['1 Tag · 9:00', '3 Tage · 9:00', '7 Tage · 9:00', 'aus'], ocr = ['Apple Intelligence · aktiv', 'nur Regelwerk (ohne KI)'], backup = ['aus', 'wöchentlich · in Dateien', 'täglich · in Dateien'];
    return {
      toast: s.toast,
      monatText: monat[s.monat], cycleMonat: this.cyc('monat', 3), windowText: win[s.win], cycleWindow: this.cyc('win', 3), remindText: rem[s.rem], cycleRemind: this.cyc('rem', 4),
      monatNote: 'Übersicht zeigt „Fällig“ für Überfälliges und die nächsten ' + win[s.win] + '; Sparpotenzial rechnet ab ' + monat[s.monat] + '.',
      kdCls: this.tog('kd'), flipKd: this.flip('kd'), ksCls: this.tog('ks'), flipKs: this.flip('ks'),
      calText: ['aus', 'Termine mit Erinnerung', 'alle Fälligkeiten (Rechnungen, Abbuchungen, Termine)'][s.cal], cycleCal: this.cyc('cal', 3),
      calNote: s.cal === 0 ? 'Kalender: nichts wird gespiegelt.' : (s.cal === 1 ? 'Kalender: HU, Wartung, Zählerstände erscheinen als Termine im iOS-Kalender „Mnemor“ – nur lesend gespiegelt, Daten bleiben in der App.' : 'Kalender: auch jede Rechnung und Abbuchung als ganztägiger Eintrag – gut für Familienkalender, aber voll.'),
      ocrText: ocr[s.ocr], cycleOcr: function () { self.setState({ ocr: (s.ocr + 1) % 2 }); self.say(s.ocr === 0 ? 'Nur Regelwerk: Erkennung einfacher, Felder öfter „Prüfen“' : 'Apple Intelligence aktiv – auf dem Gerät'); },
      keepCls: this.tog('keep'), flipKeep: this.flip('keep'), bonCls: this.tog('bon'), flipBon: this.flip('bon'),
      learnText: s.learn + ' Anbieter gelernt · zurücksetzen', askReset: this.go('resetSheet', true), cancelReset: this.go('resetSheet', false), resetSheet: s.resetSheet, doReset: function () { self.setState({ learn: 0, resetSheet: false }); self.say('Lernregeln zurückgesetzt'); },
      wCount: s.restored ? 17 : 9, restoreText: s.restored ? 'alle vorhanden' : '9 fehlen in Wohnen', restore: function () { if (s.restored) { self.say('Alle Standardkategorien sind vorhanden'); return; } self.setState({ restored: true }); self.say('9 Kategorien ergänzt (Grundsteuer, Gebäudeversicherung, Schornsteinfeger …)'); },
      lockCls: this.tog('lock'), flipLock: this.flip('lock'), backupText: backup[s.backup], cycleBackup: this.cyc('backup', 3),
      wipe: s.wipe, wipe2: s.wipe2, askWipe: function () { self.setState({ wipe: true, wipe2: false, wipeWord: '' }); }, cancelWipe: function () { self.setState({ wipe: false, wipe2: false }); },
      wipeText: s.wipe2 ? 'Letzte Sicherheit: Rechnungen, Verträge, Budgets, Rücklagen und alle Originale werden unwiderruflich entfernt. Letztes Backup: 18. Okt.' : 'Empfehlung: vorher ein Backup erstellen (Mehr › Backup & Export).',
      wipeWord: s.wipeWord, setWipeWord: this.set('wipeWord'), wipeBtn: s.wipe2 ? 'Endgültig löschen' : 'Weiter',
      nextWipe: function () { if (!s.wipe2) { self.setState({ wipe2: true }); return; } if (s.wipeWord.trim().toUpperCase() !== 'LÖSCHEN') { self.say('Zur Bestätigung LÖSCHEN eintippen'); return; } self.setState({ wipe: false, wipe2: false }); self.say('Im Prototyp nicht ausgeführt – in der App startet Mnemor leer neu'); }
    };
  }'''
    page("Einstellungen.dc.html", "Einstellungen", body, logic, 'u', EXTRA_CSS)


if __name__ == "__main__":
    build()
