# -*- coding: utf-8 -*-
"""Rechnungen-Liste, Rechnung-Detail, Rechnung prüfen (Review), Erfassen."""
from common import *

DOC_THUMB = '<span style="width: 64px; height: 84px; flex: none; background: rgba(255,255,255,.95); border-radius: 5px; display: flex; flex-direction: column; gap: 5px; padding: 11px 9px; box-sizing: border-box"><i style="display: block; height: 3px; width: 60%; background: #B9C2CE; border-radius: 1px"></i><i style="display: block; height: 2px; width: 90%; background: #D1DBE8; border-radius: 1px"></i><i style="display: block; height: 2px; width: 80%; background: #D1DBE8; border-radius: 1px"></i><i style="display: block; height: 2px; width: 85%; background: #D1DBE8; border-radius: 1px"></i><i style="display: block; height: 3px; width: 45%; background: #B9C2CE; border-radius: 1px; margin-top: 8px; align-self: flex-end"></i></span>'

DOC_OVERLAY = '''<sc-if value="{{showDoc}}" hint-placeholder-val="{{false}}"><div class="sheetbg" style="align-items: stretch; background: #16243A"><div style="flex: 1; display: flex; flex-direction: column; color: #FFFFFF"><div style="display: flex; justify-content: space-between; align-items: center; padding: 56px 20px 10px"><button class="act" style="text-align: left" onClick="{{closeDoc}}">Fertig</button><p class="ttl">{{docTitle}}</p><button class="act" onClick="{{shareDoc}}">Teilen</button></div><div style="flex: 1; margin: 10px 24px 40px; background: #FFFFFF; border-radius: 8px; color: #16243A; padding: 26px 22px; font-size: 11px; line-height: 1.6; overflow: hidden"><p style="margin: 0; font-weight: 700; font-size: 14px">{{docHead}}</p><p style="margin: 2px 0 14px; color: #637894">{{docSub}}</p><p style="margin: 0">{{docLine1}}</p><p style="margin: 0">{{docLine2}}</p><p style="margin: 14px 0 0; font-weight: 700">{{docLine3}}</p><p style="margin: 14px 0 0; color: #637894">Original gespeichert · Zoom und Seitenwechsel wie in der Vorschau von iOS</p></div></div></div></sc-if>'''


def build():
    # ---------------------------------------------------------------- Rechnungen
    body = f'''  <div class="hdr" style="padding-bottom: 18px">
    <div style="display: flex; align-items: center; justify-content: space-between">
      <h1 style="margin: 0; font-size: 28px; font-weight: 700; letter-spacing: -0.5px">Rechnungen</h1>
      <button class="chip" style="width: 34px; padding: 0; justify-content: center" aria-label="Suchen" onClick="{{{{toggleSearch}}}}"><svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg></button>
    </div>
    <p class="sub">{{{{summary}}}}</p>
    <sc-if value="{{{{search}}}}" hint-placeholder-val="{{{{false}}}}"><input class="in" style="margin-top: 12px; width: 100%; box-sizing: border-box; color: #FFFFFF; border-bottom-color: rgba(255,255,255,.5); font-size: 16px" placeholder="Anbieter, Betrag oder Kategorie" value="{{{{q}}}}" onChange="{{{{setQ}}}}"></sc-if>
    <div style="margin-top: 14px">{seg("segs", dark=True)}</div>
  </div>

  <div style="padding: 16px 20px 0 20px; display: flex; flex-direction: column; gap: 10px">
    <sc-for list="{{{{groups}}}}" as="g" hint-placeholder-count="2">
      <h2 class="h2" style="margin: 6px 0 0">{{{{g.title}}}} <span>{{{{g.meta}}}}</span></h2>
      <sc-for list="{{{{g.items}}}}" as="it" hint-placeholder-count="2">
        <a class="inv" href="{{{{it.href}}}}">
          <div style="flex: 1; min-width: 0"><p class="n">{{{{it.name}}}}</p><p class="a">{{{{it.amount}}}} €</p><p class="d">{{{{it.sub}}}}</p></div>
          <div style="display: flex; flex-direction: column; align-items: flex-end"><span class="cap" style="{{{{it.capst}}}}">{{{{it.cap}}}}</span><sc-if value="{{{{it.urg}}}}" hint-placeholder-val="{{{{false}}}}"><span class="urg" style="{{{{it.urgst}}}}"><i style="{{{{it.dotst}}}}"></i>{{{{it.urg}}}}</span></sc-if></div>
        </a>
      </sc-for>
    </sc-for>
    <sc-if value="{{{{none}}}}" hint-placeholder-val="{{{{false}}}}"><p class="note">Keine Treffer für „{{{{q}}}}“.</p></sc-if>
  </div>
'''
    logic = f'''  constructor(p) {{ super(p); this.state = {{ tab: 'open', search: false, q: '', toast: '' }};
    this.ITEMS = [
      {{ name: 'Stadtwerke Mainstadt', amount: 142, due: '21. Okt. 2026', cat: 'Wohnen › Strom', st: 'over', href: 'Rechnung.dc.html', kind: 'Rechnung' }},
      {{ name: 'Autohaus Keller GmbH', amount: 212.40, due: '30. Okt. 2026', cat: 'Mobilität › Werkstatt & Reifen', st: 'soon', href: 'Review.dc.html', kind: 'Rechnung' }},
      {{ name: 'EnBW mobility+', amount: 64.20, due: '16. Okt. 2026', cat: 'Mobilität › Kraftstoff / Laden', st: 'paid', href: 'Rechnung.dc.html', kind: 'Rechnung' }},
      {{ name: 'Bäckerei Schmitt', amount: 12.60, due: '21. Okt. 2026', cat: 'Haushalt › Lebensmittel', st: 'paid', href: 'Rechnung.dc.html', kind: 'Bon' }},
      {{ name: 'Wochenmarkt', amount: 41.80, due: '18. Okt. 2026', cat: 'Haushalt › Lebensmittel', st: 'paid', href: 'Rechnung.dc.html', kind: 'Bon' }},
      {{ name: 'REWE', amount: 58.37, due: '15. Okt. 2026', cat: 'Haushalt › Lebensmittel', st: 'paid', href: 'Rechnung.dc.html', kind: 'Bon' }},
      {{ name: 'dm-drogerie markt', amount: 23.90, due: '14. Okt. 2026', cat: 'Haushalt › Lebensmittel', st: 'paid', href: 'Rechnung.dc.html', kind: 'Bon' }},
      {{ name: 'Kiosk', amount: 6.00, due: '13. Okt. 2026', cat: 'Haushalt › Freizeit', st: 'paid', href: 'Rechnung.dc.html', kind: 'Bon' }},
      {{ name: 'Schwimmbad', amount: 22.00, due: '12. Okt. 2026', cat: 'Haushalt › Freizeit', st: 'paid', href: 'Rechnung.dc.html', kind: 'Bon' }},
      {{ name: 'Kino Universum', amount: 34.00, due: '11. Okt. 2026', cat: 'Haushalt › Freizeit', st: 'paid', href: 'Rechnung.dc.html', kind: 'Bon' }},
      {{ name: 'REWE', amount: 87.45, due: '11. Okt. 2026', cat: 'Haushalt › Lebensmittel', st: 'paid', href: 'Rechnung.dc.html', kind: 'Bon' }},
      {{ name: 'Getränkemarkt', amount: 27.43, due: '8. Okt. 2026', cat: 'Haushalt › Lebensmittel', st: 'paid', href: 'Rechnung.dc.html', kind: 'Bon' }},
      {{ name: 'Lidl', amount: 64.12, due: '6. Okt. 2026', cat: 'Haushalt › Lebensmittel', st: 'paid', href: 'Rechnung.dc.html', kind: 'Bon' }},
      {{ name: 'Edeka', amount: 96.33, due: '4. Okt. 2026', cat: 'Haushalt › Lebensmittel', st: 'paid', href: 'Rechnung.dc.html', kind: 'Bon' }},
      {{ name: 'Konzertkarten (2×)', amount: 118.00, due: '2. Okt. 2026', cat: 'Haushalt › Freizeit', st: 'paid', href: 'Rechnung.dc.html', kind: 'Rechnung' }}
    ];
  }}
{JS_SEG}
  renderVals() {{
    var self = this, tab = this.state.tab, q = this.state.q.trim().toLowerCase();
    var all = this.ITEMS.filter(function (i) {{ return !q || (i.name + ' ' + i.cat + ' ' + eur(i.amount)).toLowerCase().indexOf(q) >= 0; }});
    var open = all.filter(function (i) {{ return i.st !== 'paid'; }}), paid = all.filter(function (i) {{ return i.st === 'paid'; }});
    var sum = function (l) {{ return l.reduce(function (a, b) {{ return a + b.amount; }}, 0); }};
    var fmt = function (i) {{
      var o = {{ name: i.name, amount: eur(i.amount), href: i.href }};
      if (i.st === 'over') {{ o.sub = 'Fällig: ' + i.due + ' · ' + i.cat; o.cap = 'Offen'; o.capst = 'background: #F7D4D1; color: #943333'; o.urg = 'Überfällig'; o.urgst = 'color: #E03C31'; o.dotst = 'background: #E03C31'; }}
      else if (i.st === 'soon') {{ o.sub = 'Fällig: ' + i.due + ' · ' + i.cat; o.cap = 'Offen'; o.capst = 'background: #EDE3C9; color: #704F2E'; o.urg = 'Bald fällig'; o.urgst = 'color: #E08A1E'; o.dotst = 'background: #E08A1E'; }}
      else {{ o.sub = (i.kind === 'Bon' ? 'Bon: ' : 'Bezahlt: ') + i.due + ' · ' + i.cat; o.cap = 'Bezahlt'; o.capst = 'background: #D6EDDB; color: #215F33'; o.urg = ''; o.urgst = ''; o.dotst = ''; }}
      return o;
    }};
    var groups = [];
    if (tab !== 'paid') {{
      var over = open.filter(function (i) {{ return i.st === 'over'; }}), soon = open.filter(function (i) {{ return i.st === 'soon'; }});
      if (over.length) groups.push({{ title: 'Überfällig', meta: over.length + ' · ' + eur(sum(over)) + ' €', items: over.map(fmt) }});
      if (soon.length) groups.push({{ title: 'Diese Woche', meta: soon.length + ' · ' + eur(sum(soon)) + ' €', items: soon.map(fmt) }});
    }}
    if (tab !== 'open') {{
      var list = tab === 'paid' ? paid : paid.slice(0, 3);
      if (list.length) groups.push({{ title: tab === 'paid' ? 'Bezahlt im Oktober' : 'Zuletzt bezahlt', meta: list.length + ' · ' + eur(sum(list)) + ' €', items: list.map(fmt) }});
    }}
    return {{
      toast: this.state.toast,
      summary: 'Oktober · ' + open.length + ' offen ' + eur(sum(open)) + ' € · bezahlt ' + eur(sum(paid)) + ' € (' + paid.length + ' Rechnungen und Bons)',
      search: this.state.search, q: this.state.q, setQ: this.set('q'),
      toggleSearch: function () {{ self.setState({{ search: !self.state.search, q: '' }}); }},
      segs: this.segItems('tab', [['open', 'Offen'], ['paid', 'Bezahlt'], ['all', 'Alle']]),
      groups: groups,
      none: groups.length === 0
    }};
  }}'''
    page("Rechnungen.dc.html", "Rechnungen", body, logic, 'r')

    # ---------------------------------------------------------------- Rechnung (Detail)
    body = f'''  <div class="hdr">
    <div class="nav"><a class="back" href="Rechnungen.dc.html">{BACK}Rechnungen</a><p class="ttl">Rechnung</p><a class="act" href="Review.dc.html">Bearbeiten</a></div>
    <div style="display: flex; gap: 14px; align-items: flex-start; margin-top: 16px">
      <button style="background: none; border: 0; padding: 0; cursor: pointer; display: flex" aria-label="Dokument ansehen" onClick="{{{{openDoc}}}}">{DOC_THUMB}</button>
      <div style="flex: 1; min-width: 0">
        <span class="cap" style="{{{{capst}}}}">{{{{cap}}}}</span>
        <h1 style="margin: 8px 0 0; font-size: 22px; font-weight: 700; letter-spacing: -0.4px; line-height: 1.15">Stadtwerke Mainstadt GmbH</h1>
        <p style="margin: 3px 0 0; font-size: 13px; opacity: .8">Nachzahlung Strom 2025 · Wohnen › Strom</p>
        <p style="margin: 10px 0 0; font-size: 32px; font-weight: 700; letter-spacing: -0.7px; line-height: 1; font-variant-numeric: tabular-nums">142,00 €</p>
      </div>
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px; display: flex; gap: 10px">
    <button class="btn {{{{payCls}}}}" onClick="{{{{togglePaid}}}}">{{{{payLabel}}}}</button>
    <button class="btn sec2" style="flex: 0 0 auto; padding: 0 16px" onClick="{{{{copyIban}}}}">IBAN kopieren</button>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <div class="f"><p class="l">Fällig</p><p class="v" style="{{{{dueSt}}}}">{{{{dueText}}}}</p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Rechnungsdatum</p><p class="v">3. Okt. 2026</p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Rechnungsnr.</p><p class="v">SW-2026-0217</p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Empfänger</p><p class="v">Stadtwerke Mainstadt GmbH</p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">IBAN</p><p class="v" style="font-variant-numeric: tabular-nums">DE12 5001 0517 5407 3249 31</p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Verwendung</p><p class="v">SW-2026-0217 Kd 4471120</p></div>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <a class="f" href="Vertrag.dc.html"><p class="l">Vertrag</p><p class="v">Stadtwerke Strom · Abschlag {{{{abschlag}}}}</p>{CHEV}</a>
      <div class="sep"></div>
      <button class="f" style="flex-wrap: wrap; row-gap: 4px; padding-top: 10px; padding-bottom: 12px" onClick="{{{{toggleHint}}}}"><p class="l" style="width: 100%; font-size: 12px; text-transform: uppercase; letter-spacing: .3px">Hinweis</p><p class="v wrap" style="font-size: 15px; font-weight: 500">{{{{hintText}}}}</p><span class="cap" style="{{{{hintCapSt}}}}">{{{{hintCap}}}}</span></button>
      <div class="sep"></div>
      <button class="f" onClick="{{{{cycleRemind}}}}"><p class="l">Erinnerung</p><p class="v">{{{{remind}}}}</p>{CHEV}</button>
      <div class="sep"></div>
      <div class="f"><p class="l">Erfasst</p><p class="v" style="font-weight: 400">4. Okt. per PDF aus Mail · Original gespeichert</p></div>
    </div>
    <p class="note">Hinweis antippen übernimmt den neuen Abschlag in den Vertrag; Erinnerung antippen wechselt den Rhythmus.</p>
  </div>

  <div style="padding: 14px 20px 0 20px; display: flex; gap: 10px">
    <button class="btn sec2 sm" onClick="{{{{share}}}}">Teilen</button>
    <button class="btn sec2 sm" onClick="{{{{openDoc}}}}">Dokument</button>
    <button class="btn danger sm" onClick="{{{{askDelete}}}}">Löschen</button>
  </div>
  {DOC_OVERLAY}
  {sheet("confirmDelete", "Rechnung löschen?", "Die Rechnung und das gespeicherte Original werden entfernt. Der Vertrag bleibt bestehen.", '<button class="btn sec2" onClick="{{cancelDelete}}">Abbrechen</button><a class="btn danger" href="Rechnungen.dc.html">Löschen</a>')}
'''
    logic = f'''  constructor(p) {{ super(p); this.state = {{ paid: false, hint: false, remind: 0, showDoc: false, confirmDelete: false, toast: '' }}; }}
{JS_SEG}
  renderVals() {{
    var self = this, paid = this.state.paid;
    var reminds = ['täglich bis bezahlt', '3 Tage vorher', 'am Fälligkeitstag', 'aus'];
    return {{
      toast: this.state.toast,
      cap: paid ? 'Bezahlt am 24. Okt.' : 'Überfällig seit 3 Tagen',
      capst: paid ? 'background: #D6EDDB; color: #215F33' : 'background: #F7D4D1; color: #943333',
      payCls: paid ? 'ok' : 'pri',
      payLabel: paid ? 'Bezahlt · rückgängig' : 'Als bezahlt markieren',
      togglePaid: function () {{ self.setState({{ paid: !paid }}); self.say(paid ? 'Wieder offen – 142,00 € zählen zu „davon offen“' : 'Bezahlt – Sparpotenzial unverändert, Liquidität −142,00 €'); }},
      copyIban: function () {{ self.say('IBAN DE12 5001 0517 5407 3249 31 kopiert'); }},
      dueText: paid ? '21. Okt. 2026 · bezahlt 24. Okt.' : '21. Okt. 2026 · 3 Tage überfällig',
      dueSt: paid ? 'color: #215F33' : 'color: #943333',
      abschlag: this.state.hint ? '110,00 ab Nov.' : '98,00',
      hintText: this.state.hint ? 'Abschlag ab 1. Nov. auf 110 € angehoben. Fixkosten Wohnen +12,00 €/Monat.' : 'Abschlag ab Nov. auf 110 € anheben? (Jahresverbrauch 2.980 kWh)',
      hintCap: this.state.hint ? 'Übernommen' : 'Übernehmen',
      hintCapSt: this.state.hint ? 'background: #D6EDDB; color: #215F33' : 'background: #E6EEF6; color: #2A5480',
      toggleHint: function () {{ self.setState({{ hint: !self.state.hint }}); }},
      remind: reminds[this.state.remind],
      cycleRemind: function () {{ self.setState({{ remind: (self.state.remind + 1) % reminds.length }}); }},
      share: function () {{ self.say('Teilen-Menü: PDF, Mail, Nachrichten'); }},
      openDoc: this.go('showDoc', true), closeDoc: this.go('showDoc', false), shareDoc: function () {{ self.say('Original als PDF geteilt'); }},
      docTitle: 'Jahresabrechnung 2025.pdf', docHead: 'Stadtwerke Mainstadt GmbH', docSub: 'Jahresabrechnung Strom 01.01.–31.12.2025 · Kd 4471120',
      docLine1: 'Verbrauch 2.980 kWh × 0,3412 €/kWh = 1.016,78 € · Grundpreis 139,92 €', docLine2: 'Abschläge 12 × 84,00 € = 1.008,00 € · Rechnungsbetrag 1.156,70 €', docLine3: 'Nachzahlung 142,00 € · zahlbar bis 21.10.2026 · Rechnungsnr. SW-2026-0217',
      askDelete: this.go('confirmDelete', true), cancelDelete: this.go('confirmDelete', false),
      showDoc: this.state.showDoc, confirmDelete: this.state.confirmDelete
    }};
  }}'''
    page("Rechnung.dc.html", "Rechnung Stadtwerke", body, logic, 'r')

    # ---------------------------------------------------------------- Review (Rechnung prüfen)
    body = f'''  <div class="bar"><a href="Erfassen.dc.html">Abbrechen</a><p>Rechnung prüfen</p><button style="font-weight: 700" onClick="{{{{save}}}}">Speichern</button></div>

  <div style="padding: 16px 20px 0 20px">
    <div class="card" style="display: flex; align-items: center; gap: 12px; padding: 12px 14px">
      <span style="width: 44px; height: 56px; flex: none; background: #F3F5F8; border: 1px solid #D1DBE8; border-radius: 4px; display: flex; flex-direction: column; gap: 4px; padding: 8px 6px; box-sizing: border-box"><i style="display: block; height: 3px; width: 60%; background: #B9C2CE"></i><i style="display: block; height: 2px; width: 90%; background: #D1DBE8"></i><i style="display: block; height: 2px; width: 80%; background: #D1DBE8"></i><i style="display: block; height: 2px; width: 85%; background: #D1DBE8"></i></span>
      <div style="flex: 1"><p style="margin: 0; font-size: 15px; font-weight: 600">Erkannt per Scan</p><p style="margin: 2px 0 0; font-size: 12px; color: #637894">{{{{confLine}}}}</p></div>
      <button class="chip lt" style="height: 30px" onClick="{{{{openDoc}}}}">Ansehen</button>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Zuordnung</h2>
    <div class="card">
      <button class="f" onClick="{{{{cycleCat}}}}"><p class="l">Kategorie</p><p class="v"><span class="dot" style="{{{{catDotSt}}}}; margin-right: 6px; vertical-align: middle"></span>{{{{catLabel}}}}</p>{CHEV}</button>
      <div class="sep"></div>
      <div class="f"><p class="l">Kostenart</p>{seg("kostenart")}</div>
      <div class="sep"></div>
      <button class="f" onClick="{{{{cycleObj}}}}"><p class="l">Objekt</p><p class="v">{{{{objLabel}}}}</p>{CHEV}</button>
      <div class="sep"></div>
      <button class="f" onClick="{{{{cycleContract}}}}"><p class="l">Vertrag</p><p class="v">{{{{contractLabel}}}}</p>{CHEV}</button>
    </div>
    <p class="note">Antippen wechselt den Vorschlag; neue Kategorie: <a href="KategorieNeu.dc.html">Kategorie anlegen</a>.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Rechnung <span>{{{{okCount}}}} von 8 Feldern sicher</span></h2>
    <div class="card">
      {f_input("Anbieter", "vendor", "setVendor")}
      <div class="sep"></div>
      <div class="f"><p class="l">Betrag</p><input class="in num" value="{{{{amount}}}}" onChange="{{{{setAmount}}}}" inputmode="decimal"><span style="font-size: 14px; color: #637894">€</span><span class="cap" style="{{{{amountSt}}}}">{{{{amountCap}}}}</span></div>
      <div class="sep"></div>
      {f_input("Rechnungsdatum", "invDate", "setInvDate")}
      <div class="sep"></div>
      <div class="f"><p class="l">Fällig</p><input class="in" value="{{{{due}}}}" onChange="{{{{setDue}}}}"><span class="cap" style="background: #E6EEF6; color: #2A5480; font-weight: 600">{{{{dueHint}}}}</span></div>
      <div class="sep"></div>
      {f_input("Rechnungsnr.", "invNo", "setInvNo")}
      <div class="sep"></div>
      <div class="f"><p class="l">IBAN</p><input class="in" value="{{{{iban}}}}" onChange="{{{{setIban}}}}"><span class="cap" style="{{{{ibanSt}}}}">{{{{ibanCap}}}}</span></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Empfänger</p><input class="in" value="{{{{payee}}}}" onChange="{{{{setPayee}}}}" placeholder="Bitte eintragen"><span class="cap" style="{{{{payeeSt}}}}">{{{{payeeCap}}}}</span></div>
    </div>
    <p class="note">Grün = Modell und Regeln einig. „Prüfen“ = unsicher, nie vorbelegt. Fälligkeit wurde aus „zahlbar bis 14 Tage“ ab Rechnungsdatum gerechnet.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <div class="f"><p class="l">Status</p>{seg("status")}</div>
      <div class="sep"></div>
      {f_toggle("Erinnerung 3 Tage vorher", "remindCls", "flipRemind", "Mo 27. Okt. 9:00")}
      <div class="sep"></div>
      {f_toggle("Original behalten", "keepCls", "flipKeep", "Foto, 1,2 MB")}
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card" style="padding: 14px 16px">
      <p style="margin: 0; font-size: 13px; font-weight: 600; color: #637894; text-transform: uppercase; letter-spacing: .3px">Wirkung</p>
      <p style="margin: 6px 0 0; font-size: 14px">{{{{effect}}}}</p>
    </div>
  </div>
  {DOC_OVERLAY}
  {sheet("blocked", "Noch nicht vollständig", "{{blockMsg}}", '<button class="btn pri" onClick="{{closeBlocked}}">Weiter prüfen</button>')}
'''
    logic = f'''  constructor(p) {{ super(p); this.state = {{ cat: 0, obj: 0, contract: 0, kostenart: 'var', status: 'open', remind: true, keep: true, vendor: 'Autohaus Keller GmbH', amount: '212,40', invDate: '16. Okt. 2026', due: '30. Okt. 2026', invNo: 'RE-2026-4471', iban: 'DE89 3704 0044 0532 0130 00', payee: '', showDoc: false, blocked: false, blockMsg: '', toast: '' }}; }}
{JS_SEG}
  ibanOk(s) {{ var t = String(s).replace(/\\s+/g, '').toUpperCase(); if (!/^DE\\d{{20}}$/.test(t)) return false; var r = t.slice(4) + '1314' + t.slice(2, 4); var m = 0; for (var i = 0; i < r.length; i++) m = (m * 10 + Number(r[i])) % 97; return m === 1; }}
  renderVals() {{
    var self = this, s = this.state;
    var cats = [['Mobilität › Werkstatt & Reifen', '{M}'], ['Mobilität › Kraftstoff / Laden', '{M}'], ['Wohnen › Instandhaltung', '{W}'], ['Haushalt › Sonstiges', '{H}']];
    var objs = ['VW ID.3', 'Deutschlandticket', 'kein Objekt'];
    var contracts = ['Keiner – einmalige Rechnung', 'VW Leasing ID.3 (Wartungsvertrag?)', 'Als neuen Vertrag anlegen'];
    var amt = num(s.amount), amountOk = amt > 0 && Math.abs(amt - 212.40) < 0.005, ibanOk = this.ibanOk(s.iban), payeeOk = s.payee.trim().length > 2;
    var ok = 5 + (amountOk ? 1 : 0) + (ibanOk ? 1 : 0) + (payeeOk ? 1 : 0);
    var ka = s.kostenart;
    var effect = s.status === 'paid'
      ? 'Bezahlt: ' + eur(amt) + ' € zählen zu den Ausgaben des Monats (bezahlt). Sparpotenzial unverändert, Liquidität −' + eur(amt) + ' €.'
      : (ka === 'fix' ? 'Fix: ' + eur(amt) + ' € ersetzen im Oktober den Planbetrag des gewählten Vertrags (Plan-zu-Ist).' : 'Offen bis ' + s.due + ': ' + eur(amt) + ' € zählen zu „davon offen“ und erscheinen in der Liquidität am Fälligkeitstag.');
    if (ka === 'kredit') effect = 'Kredit: ' + eur(amt) + ' € laufen als Rate in Fixkosten & Kredite; Restschuld wird im Tilgungsplan geführt.';
    return {{
      toast: s.toast,
      confLine: ok + ' von 8 Feldern sicher · ' + (s.keep ? 'Foto wird gespeichert' : 'Foto wird verworfen'),
      openDoc: this.go('showDoc', true), closeDoc: this.go('showDoc', false), shareDoc: function () {{ self.say('Scan als PDF geteilt'); }}, showDoc: s.showDoc,
      docTitle: 'Scan 24.10.2026', docHead: 'Autohaus Keller GmbH', docSub: 'Rechnung RE-2026-4471 · 16.10.2026 · VW ID.3, KA-MN 2024',
      docLine1: 'Inspektion 60.000 km inkl. Bremsflüssigkeit 178,49 € netto', docLine2: 'zzgl. 19 % USt 33,91 €', docLine3: 'Gesamt 212,40 € · zahlbar innerhalb 14 Tagen · IBAN DE89 3704 0044 0532 0130 00',
      cycleCat: function () {{ self.setState({{ cat: (s.cat + 1) % cats.length }}); }}, catLabel: cats[s.cat][0], catDotSt: 'background: ' + cats[s.cat][1],
      kostenart: this.segItems('kostenart', [['var', 'Variabel'], ['fix', 'Fix'], ['kredit', 'Kredit']]),
      cycleObj: function () {{ self.setState({{ obj: (s.obj + 1) % objs.length }}); }}, objLabel: objs[s.obj],
      cycleContract: function () {{ self.setState({{ contract: (s.contract + 1) % contracts.length }}); }}, contractLabel: contracts[s.contract],
      okCount: ok,
      vendor: s.vendor, setVendor: this.set('vendor'),
      amount: s.amount, setAmount: this.set('amount'), amountCap: amountOk ? '✓ im Text' : (amt > 0 ? 'abweichend' : 'fehlt'), amountSt: amountOk ? 'background: #D6EDDB; color: #215F33' : 'background: #EDE3C9; color: #704F2E',
      invDate: s.invDate, setInvDate: this.set('invDate'),
      due: s.due, setDue: this.set('due'), dueHint: 'Rechnungsdatum + 14 Tage',
      invNo: s.invNo, setInvNo: this.set('invNo'),
      iban: s.iban, setIban: this.set('iban'), ibanCap: ibanOk ? '✓ Prüfsumme' : 'Prüfen', ibanSt: ibanOk ? 'background: #D6EDDB; color: #215F33' : 'background: #EDE3C9; color: #704F2E',
      payee: s.payee, setPayee: this.set('payee'), payeeCap: payeeOk ? '✓' : 'Prüfen', payeeSt: payeeOk ? 'background: #D6EDDB; color: #215F33' : 'background: #EDE3C9; color: #704F2E',
      status: this.segItems('status', [['open', 'Offen'], ['paid', 'Bezahlt']]),
      remindCls: this.tog('remind'), flipRemind: this.flip('remind'), keepCls: this.tog('keep'), flipKeep: this.flip('keep'),
      effect: effect,
      blocked: s.blocked, blockMsg: s.blockMsg, closeBlocked: this.go('blocked', false),
      save: function () {{
        if (!payeeOk) {{ self.setState({{ blocked: true, blockMsg: 'Der Zahlungsempfänger fehlt. Mnemor speichert keine unsicheren Felder vorbelegt – bitte eintragen (z. B. „Autohaus Keller GmbH“).' }}); return; }}
        if (!(amt > 0)) {{ self.setState({{ blocked: true, blockMsg: 'Der Betrag fehlt oder ist 0.' }}); return; }}
        self.say('Gespeichert · Anbieterprofil gelernt: ' + s.vendor + ' → ' + cats[s.cat][0]);
      }}
    }};
  }}'''
    page("Review.dc.html", "Rechnung prüfen (nach Scan)", body, logic, 'r')

    # ---------------------------------------------------------------- Erfassen
    body = f'''  <div class="bar"><a href="Main.dc.html">Schließen</a><p>Erfassen</p><span style="width: 70px"></span></div>

  <div style="padding: 18px 20px 0 20px">
    <a href="Review.dc.html" class="card" style="display: flex; align-items: center; gap: 16px; padding: 18px 18px; text-decoration: none; background: #2A5480; color: #FFFFFF">
      <span style="width: 52px; height: 52px; border-radius: 26px; background: rgba(255,255,255,.16); display: inline-flex; align-items: center; justify-content: center; flex: none">{CAM}</span>
      <div style="flex: 1"><p style="margin: 0; font-size: 18px; font-weight: 700">Rechnung oder Bon scannen</p><p style="margin: 3px 0 0; font-size: 13px; opacity: .85">Kamera · mehrere Seiten · Kategorie und Fälligkeit werden erkannt</p></div>
      <svg class="chev" aria-hidden="true" viewBox="0 0 8 13" fill="none" stroke="rgba(255,255,255,.7)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1.5 1.5l5 5-5 5"/></svg>
    </a>
  </div>

  <div style="padding: 14px 20px 0 20px">
    <div class="card">
      <button class="row" onClick="{{{{pickPdf}}}}"><span class="c" style="background: #637894"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M7 3h7l5 5v13H7z"/><path d="M14 3v5h5"/></svg></span><div class="mid"><p class="n">PDF importieren</p><p class="s">Aus Dateien, Mail oder Teilen-Menü · Original wird gespeichert</p></div>{CHEV}</button>
      <div class="sep"></div>
      <button class="row" onClick="{{{{openManual}}}}"><span class="c" style="background: #637894"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z"/></svg></span><div class="mid"><p class="n">Manuell eingeben</p><p class="s">Ohne Beleg · z. B. Barzahlung, Überweisung</p></div>{CHEV}</button>
      <div class="sep"></div>
      <button class="row" onClick="{{{{openBon}}}}"><span class="c" style="background: #637894"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="3" width="16" height="18" rx="1"/><path d="M8 8h8M8 12h8M8 16h5"/></svg></span><div class="mid"><p class="n">Kassenbon</p><p class="s">Schneller Modus: Betrag, Händler, Kategorie – sofort bezahlt</p></div>{CHEV}</button>
    </div>
  </div>

  <sc-if value="{{{{form}}}}" hint-placeholder-val="{{{{false}}}}">
  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">{{{{formTitle}}}} <button onClick="{{{{closeForm}}}}">Abbrechen</button></h2>
    <div class="card">
      {f_input("Händler / Anbieter", "vendor", "setVendor", placeholder="z. B. REWE")}
      <div class="sep"></div>
      <div class="f"><p class="l">Betrag</p><input class="in num" value="{{{{amount}}}}" onChange="{{{{setAmount}}}}" inputmode="decimal" placeholder="0,00"><span style="font-size: 14px; color: #637894">€</span></div>
      <div class="sep"></div>
      {f_select("Kategorie", "cat", "setCat", [("Haushalt › Lebensmittel","Haushalt › Lebensmittel"),("Haushalt › Gastronomie","Haushalt › Gastronomie"),("Haushalt › Freizeit","Haushalt › Freizeit"),("Haushalt › Kleidung","Haushalt › Kleidung"),("Mobilität › Kraftstoff / Laden","Mobilität › Kraftstoff / Laden"),("Wohnen › Instandhaltung","Wohnen › Instandhaltung")])}
      <div class="sep"></div>
      <sc-if value="{{{{isManual}}}}" hint-placeholder-val="{{{{false}}}}">{f_input("Fällig am", "due", "setDue", placeholder="TT.MM.JJJJ")}<div class="sep"></div></sc-if>
      {f_input("Datum", "date", "setDate")}
      <div class="sep"></div>
      <div class="f"><p class="l">Zahlart</p>{seg("payKind")}</div>
    </div>
    <p class="note">{{{{formEffect}}}}</p>
    <div style="display: flex; gap: 10px; margin-top: 12px"><button class="btn pri" onClick="{{{{saveForm}}}}">{{{{saveLabel}}}}</button></div>
  </div>
  </sc-if>

  <div style="padding: 20px 20px 0 20px">
    <h2 class="h2">Weitere</h2>
    <div class="card">
      <a class="row" href="VertragNeu.dc.html"><span class="c" style="background: #2A5480"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"><path d="M17 2l4 4-4 4"/><path d="M3 11V9a4 4 0 0 1 4-4h14"/><path d="M7 22l-4-4 4-4"/><path d="M21 13v2a4 4 0 0 1-4 4H3"/></svg></span><div class="mid"><p class="n">Vertrag oder Abo</p><p class="s">Auch per Scan der ersten Rechnung</p></div>{CHEV}</a>
      <div class="sep"></div>
      <a class="row" href="Einnahmen.dc.html"><span class="c" style="background: #215F33"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V5M5 12l7-7 7 7"/></svg></span><div class="mid"><p class="n">Einnahme</p><p class="s">Gehalt, Kindergeld, Rückerstattung</p></div>{CHEV}</a>
      <div class="sep"></div>
      <a class="row" href="Termin.dc.html"><span class="c" style="background: {M}"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/></svg></span><div class="mid"><p class="n">Termin</p><p class="s">HU, Zählerstände, Wartung – mit Planbetrag</p></div>{CHEV}</a>
    </div>
  </div>

  <div style="padding: 20px 20px 0 20px">
    <h2 class="h2">Zuletzt erfasst <a href="Rechnungen.dc.html">Alle</a></h2>
    <div class="card">
      <sc-for list="{{{{recent}}}}" as="r" hint-placeholder-count="2">
        <a class="row" href="{{{{r.href}}}}"><div class="mid"><p class="n">{{{{r.name}}}}</p><p class="s">{{{{r.sub}}}}</p></div><sc-if value="{{{{r.cap}}}}" hint-placeholder-val="{{{{false}}}}"><span class="cap" style="background: #EDE3C9; color: #704F2E">{{{{r.cap}}}}</span></sc-if><p class="v">{{{{r.val}}}}</p>{CHEV}</a>
        <div class="sep"></div>
      </sc-for>
    </div>
  </div>
  {sheet("pdf", "PDF importieren", "Aus Dateien, Mail oder dem Teilen-Menü einer anderen App. Mnemor liest den Text, behält das Original und öffnet die Prüfung.", '<button class="btn sec2" onClick="{{closePdf}}">Abbrechen</button><a class="btn pri" href="Review.dc.html">Dateien öffnen</a>')}
'''
    logic = f'''  constructor(p) {{ super(p); this.state = {{ form: '', vendor: '', amount: '', cat: 'Haushalt › Lebensmittel', due: '', date: '24.10.2026', payKind: 'karte', pdf: false, toast: '',
    recent: [ {{ name: 'Autohaus Keller · Inspektion', sub: 'Heute · Scan · Empfänger noch prüfen', cap: 'Entwurf', val: '', href: 'Review.dc.html' }}, {{ name: 'REWE', sub: 'Gestern · Bon · Haushalt › Lebensmittel', cap: '', val: '58,37 €', href: 'Rechnung.dc.html' }} ] }}; }}
{JS_SEG}
  renderVals() {{
    var self = this, s = this.state, amt = num(s.amount), manual = s.form === 'manual';
    return {{
      toast: s.toast,
      pickPdf: this.go('pdf', true), closePdf: this.go('pdf', false), pdf: s.pdf,
      openManual: this.go('form', 'manual'), openBon: this.go('form', 'bon'), closeForm: this.go('form', ''),
      form: !!s.form, isManual: manual, formTitle: manual ? 'Manuell eingeben' : 'Kassenbon',
      vendor: s.vendor, setVendor: this.set('vendor'), amount: s.amount, setAmount: this.set('amount'),
      cat: s.cat, setCat: this.set('cat'), due: s.due, setDue: this.set('due'), date: s.date, setDate: this.set('date'),
      payKind: this.segItems('payKind', [['karte', 'Karte'], ['bar', 'Bar'], ['kasse', 'Haushaltskasse']]),
      formEffect: amt > 0 ? (manual && s.due ? eur(amt) + ' € offen bis ' + s.due + ' → „davon offen“ und Liquidität' : eur(amt) + ' € bezahlt → Ausgaben des Monats, Budget ' + s.cat.split(' › ')[1] + ' sinkt um ' + eur(amt) + ' €' + (s.payKind === 'kasse' ? ', Haushaltskasse −' + eur(amt) + ' €' : '')) : 'Betrag eingeben – die Wirkung auf Budget und Sparpotenzial erscheint hier.',
      saveLabel: manual ? 'Rechnung speichern' : 'Bon speichern',
      saveForm: function () {{
        if (!(amt > 0)) {{ self.say('Bitte einen Betrag eingeben'); return; }}
        if (!s.vendor.trim()) {{ self.say('Bitte Händler oder Anbieter eingeben'); return; }}
        var r = s.recent.slice(); r.unshift({{ name: s.vendor.trim(), sub: 'Heute · ' + (manual ? 'manuell' : 'Bon') + ' · ' + s.cat, cap: manual && s.due ? 'Offen' : '', val: eur(amt) + ' €', href: 'Rechnung.dc.html' }});
        self.setState({{ recent: r, form: '', vendor: '', amount: '', due: '' }}); self.say('Gespeichert · ' + eur(amt) + ' € in ' + s.cat);
      }},
      recent: s.recent
    }};
  }}'''
    page("Erfassen.dc.html", "Erfassen", body, logic, None)


if __name__ == "__main__":
    build()
