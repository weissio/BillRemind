# -*- coding: utf-8 -*-
"""Verträge-Liste, Vertrag-Detail, Vertrag anlegen."""
from common import *

CONTRACTS = [
    # name, sub, amount per cycle, cycle(months), area, type, nextKündigung text, days to deadline (None), rücklage?
    dict(name="Miete Hauptstr. 12", sub="unbefristet · 3 Monate Kündigungsfrist", amt=950, cyc=1, area="Wohnen", typ="Wohnen & Leasing", kd=None),
    dict(name="Stadtwerke – Strom", sub="Abschlag · nächste Abbuchung 1. Nov.", amt=98, cyc=1, area="Wohnen", typ="Versorger & Gebühren", kd=26, kdsub="bis 19. Nov. zum Jahresende · 1.176,00 €/Jahr"),
    dict(name="Stadtwerke – Gas", sub="Abschlag · nächste Abbuchung 1. Nov.", amt=112, cyc=1, area="Wohnen", typ="Versorger & Gebühren", kd=None),
    dict(name="Telekom Internet & Festnetz", sub="Laufzeit bis 31. Mai 2027", amt=39.99, cyc=1, area="Wohnen", typ="Versorger & Gebühren", kd=None),
    dict(name="Rundfunkbeitrag", sub="vierteljährlich · nächste 15. Jan.", amt=55.08, cyc=3, area="Wohnen", typ="Versorger & Gebühren", kd=None),
    dict(name="Hausrat Allianz", sub="Jahresbeitrag 1. März", amt=94, cyc=12, area="Wohnen", typ="Versicherung", kd=None),
    dict(name="VW Leasing ID.3", sub="Kredit · bis Aug. 2028 · 22 Raten offen", amt=289, cyc=1, area="Mobilität", typ="Wohnen & Leasing", kd=None),
    dict(name="EnBW mobility+", sub="Ladetarif · monatlich kündbar", amt=9.99, cyc=1, area="Mobilität", typ="Versorger & Gebühren", kd=None),
    dict(name="Deutschlandticket", sub="monatlich kündbar bis zum 10.", amt=58, cyc=1, area="Mobilität", typ="Abo & Mitgliedschaft", kd=17, kdsub="bis 10. Nov. zum Monatsende · 696,00 €/Jahr"),
    dict(name="HUK24 Kfz-Versicherung", sub="Jahresbeitrag 27. Okt. · aus Rücklage", amt=487.20, cyc=12, area="Mobilität", typ="Versicherung", kd=37, kdsub="Wechsel bis 30. Nov. zum 1. Jan. · 487,20 €/Jahr"),
    dict(name="Telekom Mobilfunk", sub="Laufzeit bis 14. Feb. 2027", amt=19.99, cyc=1, area="Haushalt", typ="Versorger & Gebühren", kd=None),
    dict(name="Netflix", sub="nächste Abbuchung 29. Okt.", amt=12.99, cyc=1, area="Haushalt", typ="Abo & Mitgliedschaft", kd=None),
    dict(name="Spotify Family", sub="nächste Abbuchung 3. Nov.", amt=17.99, cyc=1, area="Haushalt", typ="Abo & Mitgliedschaft", kd=None),
    dict(name="iCloud+", sub="nächste Abbuchung 8. Nov.", amt=2.99, cyc=1, area="Haushalt", typ="Abo & Mitgliedschaft", kd=None),
    dict(name="FitnessFirst", sub="bis 15. Nov. kündbar", amt=29.90, cyc=1, area="Haushalt", typ="Abo & Mitgliedschaft", kd=22, kdsub="bis 15. Nov. kündigen, sonst +12 Monate · 358,80 €/Jahr"),
    dict(name="Privathaftpflicht", sub="Jahresbeitrag 1. März", amt=68, cyc=12, area="Haushalt", typ="Versicherung", kd=None),
]


def build():
    # ---------------------------------------------------------------- Verträge
    body = f'''  <div class="hdr" style="padding-bottom: 18px">
    <div style="display: flex; align-items: center; justify-content: space-between">
      <h1 style="margin: 0; font-size: 28px; font-weight: 700; letter-spacing: -0.5px">Verträge</h1>
      <a href="VertragNeu.dc.html" aria-label="Vertrag hinzufügen" style="width: 34px; height: 34px; border-radius: 17px; background: rgba(255,255,255,.14); color: #FFFFFF; display: inline-flex; align-items: center; justify-content: center; text-decoration: none"><svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg></a>
    </div>
    <p class="sub">{{{{summary}}}}</p>
    {chips("modeChips")}
  </div>

  <sc-if value="{{{{showKd}}}}" hint-placeholder-val="{{{{true}}}}">
  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Kündigungsfristen <span>nächste 60 Tage</span></h2>
    <div class="card">
      <sc-for list="{{{{kd}}}}" as="k" hint-placeholder-count="2">
        <a class="row" href="Vertrag.dc.html"><div class="mid"><p class="n" style="font-weight: 500; font-size: 16px">{{{{k.name}}}}</p><p class="s">{{{{k.kdsub}}}}</p></div><p class="v" style="{{{{k.vst}}}}">{{{{k.days}}}} Tage</p>{CHEV}</a>
        <div class="sep"></div>
      </sc-for>
    </div>
  </div>
  </sc-if>

  <sc-for list="{{{{groups}}}}" as="g" hint-placeholder-count="3">
  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">{{{{g.title}}}} <span>{{{{g.meta}}}}</span></h2>
    <div class="card">
      <sc-for list="{{{{g.items}}}}" as="c" hint-placeholder-count="3">
        <a class="row" href="Vertrag.dc.html"><span class="dot" style="{{{{c.dotst}}}}"></span><div class="mid"><p class="n" style="font-weight: 500; font-size: 16px">{{{{c.name}}}}</p><p class="s">{{{{c.sub}}}}</p></div><div class="vcol"><p class="v">{{{{c.amount}}}} €</p><p class="s">{{{{c.cyc}}}}</p></div></a>
        <div class="sep"></div>
      </sc-for>
    </div>
  </div>
  </sc-for>
  <p class="note" style="margin: 10px 24px 0">{{{{pruef}}}}</p>
'''
    logic = f'''  constructor(p) {{ super(p); this.state = {{ mode: 'typ', toast: '' }}; this.C = {json.dumps(CONTRACTS, ensure_ascii=False)}; }}
{JS_SEG}
  renderVals() {{
    var self = this, mode = this.state.mode, C = this.C;
    var colors = {{ 'Wohnen': '{W}', 'Mobilität': '{M}', 'Haushalt': '{H}' }};
    var monthly = function (c) {{ return c.amt / c.cyc; }};
    var total = C.reduce(function (a, c) {{ return a + monthly(c); }}, 0);
    var fmt = function (c) {{ return {{ name: c.name, sub: c.sub, amount: eur(c.amt), cyc: c.cyc === 1 ? 'monatlich' : (c.cyc === 3 ? 'je Quartal · ' + eur(monthly(c)) + '/Monat' : 'je Jahr · ' + eur(monthly(c)) + '/Monat'), dotst: 'background: ' + colors[c.area] }}; }};
    var groupBy = function (key, order) {{ return order.map(function (k) {{ var items = C.filter(function (c) {{ return c[key] === k; }}); return {{ title: k, meta: items.length + ' · ' + eur(items.reduce(function (a, c) {{ return a + monthly(c); }}, 0)) + ' €/Monat', items: items.map(fmt) }}; }}).filter(function (g) {{ return g.items.length; }}); }};
    var groups;
    if (mode === 'typ') groups = groupBy('typ', ['Versorger & Gebühren', 'Versicherung', 'Abo & Mitgliedschaft', 'Wohnen & Leasing']);
    else if (mode === 'bereich') groups = groupBy('area', ['Wohnen', 'Mobilität', 'Haushalt']);
    else {{ var k = C.filter(function (c) {{ return c.kd !== null; }}).sort(function (a, b) {{ return a.kd - b.kd; }}); groups = [{{ title: 'Jetzt kündbar oder wechselbar', meta: k.length + ' · ' + eur(k.reduce(function (a, c) {{ return a + monthly(c); }}, 0)) + ' €/Monat', items: k.map(function (c) {{ var o = fmt(c); o.sub = c.kdsub; return o; }}) }}]; }}
    var kd = C.filter(function (c) {{ return c.kd !== null && c.kd <= 60; }}).sort(function (a, b) {{ return a.kd - b.kd; }}).map(function (c) {{ return {{ name: c.name, kdsub: c.kdsub, days: c.kd, vst: c.kd <= 30 ? 'color: #2A5480' : 'color: #637894; font-weight: 500' }}; }});
    var fix = C.filter(function (c) {{ return c.cyc <= 3; }}).reduce(function (a, c) {{ return a + monthly(c); }}, 0);
    return {{
      toast: this.state.toast,
      summary: C.length + ' Verträge · ' + eur(total) + ' € im Monat · ' + eur(total * 12) + ' € im Jahr',
      modeChips: this.chipItems('mode', [['typ', 'Nach Typ'], ['bereich', 'Nach Bereich'], ['kuendbar', 'Kündbar']]),
      showKd: mode !== 'kuendbar', kd: kd, groups: groups,
      pruef: 'Prüfsumme: ' + eur(total) + ' €/Monat = Fixkosten ' + eur(fix) + ' (monatlich und vierteljährlich) + Vertrags-Rücklagen ' + eur(total - fix) + ' (jährlich: Kfz, Hausrat, Haftpflicht). Kfz-Steuer ist kein Vertrag → Termin mit Rücklage.'
    }};
  }}'''
    page("Vertraege.dc.html", "Verträge", body, logic, 'v')

    # ---------------------------------------------------------------- Vertrag (Detail)
    body = f'''  <div class="hdr">
    <div class="nav"><a class="back" href="Vertraege.dc.html">{BACK}Verträge</a><p class="ttl">Vertrag</p>{act_btn("{{editLabel}}", "toggleEdit")}</div>
    <span class="cap" style="background: rgba(255,255,255,.16); color: #FFFFFF; margin-top: 14px"><span class="dot" style="background: {W}; margin-right: 6px"></span>Wohnen › Strom · Versorger</span>
    <h1 style="margin-top: 10px">Stadtwerke Mainstadt · Strom</h1>
    <p class="sub">Wohnung Hauptstr. 12 · Kundennr. 4471120 · {{{{stateLine}}}}</p>
    <div style="display: flex; align-items: baseline; justify-content: space-between; gap: 14px; margin-top: 12px"><p class="big" style="margin: 0">{{{{abschlag}}}} €</p><p style="margin: 0; font-size: 13px; opacity: .85; text-align: right">monatlich · {{{{jahr}}}} €/Jahr</p></div>
  </div>

  <sc-if value="{{{{edit}}}}" hint-placeholder-val="{{{{false}}}}">
  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Bearbeiten</h2>
    <div class="card">
      <div class="f"><p class="l">Abschlag</p><input class="in num" value="{{{{abschlagIn}}}}" onChange="{{{{setAbschlag}}}}" inputmode="decimal"><span style="font-size: 14px; color: #637894">€ / Monat</span></div>
      <div class="sep"></div>
      {f_select("Zahltag", "payday", "setPayday", [("1","1. des Monats"),("15","15. des Monats"),("28","28. des Monats")])}
      <div class="sep"></div>
      {f_select("Kündigungsfrist", "notice", "setNotice", [("6w","6 Wochen zum Laufzeitende"),("4w","4 Wochen"),("3m","3 Monate"),("none","keine, jederzeit")])}
    </div>
    <p class="note">{{{{editEffect}}}}</p>
  </div>
  </sc-if>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <div class="f"><p class="l">Nächste Abbuchung</p><p class="v">{{{{nextDebit}}}}</p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Abschlag</p><p class="v">{{{{abschlag}}}} € <span style="color: #637894; font-weight: 400">· seit Jan. 2026</span></p></div>
      <div class="sep"></div>
      <a class="f" href="Rechnung.dc.html"><p class="l">Jahresabrechnung</p><p class="v" style="color: #943333">Nachzahlung 142,00 € · überfällig</p>{CHEV}</a>
      <div class="sep"></div>
      <button class="f" style="flex-wrap: wrap; row-gap: 4px; padding-top: 10px; padding-bottom: 12px" onClick="{{{{applyHint}}}}"><p class="l" style="width: 100%; font-size: 12px; text-transform: uppercase; letter-spacing: .3px">Vorschlag</p><p class="v wrap" style="font-size: 15px; font-weight: 500">{{{{hintText}}}}</p><span class="cap" style="{{{{hintSt}}}}">{{{{hintCap}}}}</span></button>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Laufzeit</h2>
    <div class="card">
      <div class="f"><p class="l">Laufzeit</p><p class="v wrap">seit 1. Jan. 2024 · bis 31. Dez. 2026, dann +12 Monate</p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Kündigungsfrist</p><p class="v wrap">{{{{noticeText}}}}</p></div>
      <div class="sep"></div>
      <button class="f" onClick="{{{{cycleRemind}}}}"><p class="l">Erinnerung</p><p class="v">{{{{remind}}}}</p>{CHEV}</button>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Verknüpft</h2>
    <div class="card">
      <a class="f" href="Kategorie.dc.html"><p class="l">Kategorie</p><p class="v">Strom · 240,00 € im Oktober</p>{CHEV}</a>
      <div class="sep"></div>
      <a class="f" href="Rechnungen.dc.html"><p class="l">Buchungen</p><p class="v">10 Abschläge 2026 · 1 Abrechnung</p>{CHEV}</a>
      <div class="sep"></div>
      <button class="f" onClick="{{{{openDocs}}}}"><p class="l">Dokumente</p><p class="v">Vertrag.pdf · Abrechnung 2025.pdf</p>{CHEV}</button>
      <div class="sep"></div>
      <a class="f" href="Termin.dc.html"><p class="l">Termin</p><p class="v">Zählerstand melden · 15. Dez.</p>{CHEV}</a>
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px; display: flex; gap: 10px">
    <button class="btn sec2" onClick="{{{{openLetter}}}}">Kündigungsschreiben</button>
    <button class="btn {{{{endCls}}}}" style="flex: 0 0 auto; padding: 0 16px" onClick="{{{{askEnd}}}}">{{{{endLabel}}}}</button>
  </div>
  <p class="note" style="margin: 10px 24px 0">„Beenden“ setzt ein Enddatum; der Vertrag bleibt in der Historie und fällt ab dem Folgemonat aus den Fixkosten.</p>

  <sc-if value="{{{{letter}}}}" hint-placeholder-val="{{{{false}}}}"><div class="sheetbg" style="align-items: stretch; background: #16243A"><div style="flex: 1; display: flex; flex-direction: column; color: #FFFFFF"><div style="display: flex; justify-content: space-between; align-items: center; padding: 56px 20px 10px"><button class="act" style="text-align: left" onClick="{{{{closeLetter}}}}">Fertig</button><p class="ttl">Kündigungsschreiben</p><button class="act" onClick="{{{{shareLetter}}}}">Teilen</button></div><div style="flex: 1; margin: 10px 24px 24px; background: #FFFFFF; border-radius: 8px; color: #16243A; padding: 26px 22px; font-size: 11.5px; line-height: 1.6; overflow: auto; white-space: pre-line">{{{{letterText}}}}</div></div></div></sc-if>
  <sc-if value="{{{{docs}}}}" hint-placeholder-val="{{{{false}}}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>Dokumente</h3><p>Originale bleiben auf dem iPhone, Teil des ZIP-Backups.</p><div class="card"><button class="f" onClick="{{{{shareDoc}}}}"><p class="v">Vertrag.pdf</p><p class="v ph" style="flex: none; width: auto">12. Dez. 2023 · 2 Seiten</p>{CHEV}</button><div class="sep"></div><button class="f" onClick="{{{{shareDoc}}}}"><p class="v">Abrechnung 2025.pdf</p><p class="v ph" style="flex: none; width: auto">3. Okt. 2026 · 3 Seiten</p>{CHEV}</button></div><div style="display: flex; gap: 10px; margin-top: 14px"><button class="btn sec2" onClick="{{{{closeDocs}}}}">Schließen</button><a class="btn pri" href="Erfassen.dc.html">Dokument hinzufügen</a></div></div></div></sc-if>
  {sheet("confirmEnd", "Vertrag beenden?", "{{endText}}", '<button class="btn sec2" onClick="{{cancelEnd}}">Abbrechen</button><button class="btn danger" onClick="{{doEnd}}">Beenden zum 31.12.</button>')}
'''
    logic = f'''  constructor(p) {{ super(p); this.state = {{ edit: false, abschlagIn: '98,00', abschlag: 98, payday: '1', notice: '6w', hint: false, remind: 0, letter: false, docs: false, confirmEnd: false, ended: false, toast: '' }}; }}
{JS_SEG}
  renderVals() {{
    var self = this, s = this.state, a = s.abschlag;
    var notices = {{ '6w': '6 Wochen · kündbar bis 19. Nov. 2026', '4w': '4 Wochen · kündbar bis 3. Dez. 2026', '3m': '3 Monate · kündbar bis 30. Sep. 2026 (verpasst → Verlängerung bis 31. Dez. 2027)', 'none': 'keine · jederzeit zum Monatsende' }};
    var reminds = ['4 Wochen vorher · 22. Okt. ✓', '2 Wochen vorher · 5. Nov.', '1 Woche vorher · 12. Nov.', 'aus'];
    var newA = num(s.abschlagIn) || a;
    return {{
      toast: s.toast,
      edit: s.edit, editLabel: s.edit ? 'Fertig' : 'Bearbeiten',
      toggleEdit: function () {{ if (s.edit) {{ self.setState({{ edit: false, abschlag: newA }}); if (newA !== a) self.say('Abschlag ' + eur(newA) + ' € · Fixkosten Wohnen ' + (newA > a ? '+' : '−') + eur(Math.abs(newA - a)) + ' €/Monat'); }} else self.setState({{ edit: true, abschlagIn: eur(a) }}); }},
      abschlagIn: s.abschlagIn, setAbschlag: this.set('abschlagIn'),
      payday: s.payday, setPayday: this.set('payday'), notice: s.notice, setNotice: this.set('notice'),
      editEffect: 'Neuer Abschlag ' + eur(newA) + ' € ab ' + s.payday + '. Nov. → Fixkosten Wohnen ' + eur(1218.35 - a + newA) + ' €, Sparpotenzial ' + eur(592.70 + a - newA) + ' €.',
      stateLine: s.ended ? 'beendet zum 31. Dez. 2026' : 'aktiv',
      abschlag: eur(a), jahr: eur(a * 12),
      nextDebit: s.ended ? '1. Nov. 2026 · letzte: 1. Dez. 2026' : s.payday + '. Nov. 2026 · Lastschrift',
      hintText: s.hint ? 'Übernommen: Abschlag 110 € ab Nov. – keine Nachzahlung 2027 bei gleichem Verbrauch.' : 'Abschlag auf 110 € anheben – dann keine Nachzahlung 2027. Übernehmen?',
      hintCap: s.hint ? 'Übernommen' : 'Übernehmen', hintSt: s.hint ? 'background: #D6EDDB; color: #215F33' : 'background: #E6EEF6; color: #2A5480',
      applyHint: function () {{ if (s.hint) {{ self.setState({{ hint: false, abschlag: 98, abschlagIn: '98,00' }}); }} else {{ self.setState({{ hint: true, abschlag: 110, abschlagIn: '110,00' }}); self.say('Abschlag 110,00 € ab 1. Nov. · Fixkosten Wohnen +12,00 €'); }} }},
      noticeText: notices[s.notice],
      remind: reminds[s.remind], cycleRemind: function () {{ self.setState({{ remind: (s.remind + 1) % reminds.length }}); }},
      openDocs: this.go('docs', true), closeDocs: this.go('docs', false), docs: s.docs, shareDoc: function () {{ self.say('PDF geöffnet'); }},
      openLetter: this.go('letter', true), closeLetter: this.go('letter', false), letter: s.letter, shareLetter: function () {{ self.say('Als PDF geteilt · Erinnerung „Bestätigung prüfen“ in 14 Tagen'); }},
      letterText: 'Arjen Muster\\nHauptstr. 12\\n76131 Mainstadt\\n\\nStadtwerke Mainstadt GmbH\\nKundenservice\\nEnergiestr. 1\\n76131 Mainstadt\\n\\nMainstadt, 24. Oktober 2026\\n\\nKündigung Stromliefervertrag · Kundennummer 4471120 · Zählernummer 1 EMH 00 2345 6789\\n\\nSehr geehrte Damen und Herren,\\n\\nhiermit kündige ich den oben genannten Stromliefervertrag fristgerecht zum nächstmöglichen Zeitpunkt, nach meiner Berechnung zum 31. Dezember 2026. Bitte bestätigen Sie mir den Eingang dieser Kündigung sowie das Vertragsende schriftlich.\\n\\nDen Zählerstand zum Vertragsende teile ich Ihnen gesondert mit. Ein eventuelles Guthaben überweisen Sie bitte auf das Ihnen bekannte Konto.\\n\\nMit freundlichen Grüßen\\n\\nArjen Muster',
      endCls: s.ended ? 'ok' : 'danger', endLabel: s.ended ? 'Beendet' : 'Beenden',
      askEnd: function () {{ if (s.ended) {{ self.setState({{ ended: false }}); self.say('Vertrag wieder aktiv'); }} else self.setState({{ confirmEnd: true }}); }},
      confirmEnd: s.confirmEnd, cancelEnd: this.go('confirmEnd', false),
      endText: 'Enddatum 31. Dez. 2026. Ab Januar fallen ' + eur(a) + ' €/Monat aus den Fixkosten; die Jahresabrechnung 2026 wird als letzte Buchung erwartet.',
      doEnd: function () {{ self.setState({{ confirmEnd: false, ended: true }}); self.say('Beendet zum 31.12.2026 · Fixkosten ab Jan. −' + eur(a) + ' €'); }}
    }};
  }}'''
    page("Vertrag.dc.html", "Vertrag Stadtwerke Strom", body, logic, 'v')

    # ---------------------------------------------------------------- Vertrag anlegen
    body = f'''  <div class="bar"><a href="Vertraege.dc.html">Abbrechen</a><p>Neuer Vertrag</p><button style="font-weight: 700" onClick="{{{{save}}}}">Sichern</button></div>

  <div style="padding: 18px 20px 0 20px">
    <a href="Review.dc.html" class="card" style="display: flex; align-items: center; gap: 12px; padding: 12px 16px; text-decoration: none; color: inherit">
      <span style="width: 36px; height: 36px; border-radius: 18px; background: #E6EEF6; color: #2A5480; display: inline-flex; align-items: center; justify-content: center; flex: none">{CAM}</span>
      <div style="flex: 1"><p style="margin: 0; font-size: 15px; font-weight: 600">Erste Rechnung oder Vertrag scannen</p><p style="margin: 2px 0 0; font-size: 12px; color: #637894">Füllt Anbieter, Betrag, Rhythmus und Kundennummer vor</p></div>{CHEV}
    </a>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <div class="card">
      {f_input("Name", "name", "setName", placeholder="z. B. ADAC Mitgliedschaft")}
      <div class="sep"></div>
      {f_input("Anbieter", "vendor", "setVendor", placeholder="Firma")}
      <div class="sep"></div>
      <div class="f" style="flex-direction: column; align-items: stretch; gap: 8px; padding-top: 10px; padding-bottom: 12px"><p class="l" style="width: auto">Bereich</p><div style="display: flex; gap: 8px"><sc-for list="{{{{areaChips}}}}" as="c" hint-placeholder-count="3"><button class="{{{{c.cls}}}}" onClick="{{{{c.pick}}}}">{{{{c.label}}}}</button></sc-for></div></div>
      <div class="sep"></div>
      {f_select("Kategorie", "cat", "setCat", [("Mitgliedschaft","Mitgliedschaft"),("Versicherung","Versicherung"),("Versorger","Versorger"),("Abo & Streaming","Abo & Streaming"),("Gebühr","Gebühr"),("neu","+ neue Kategorie …")])}
      <div class="sep"></div>
      <button class="f" onClick="{{{{cycleObj}}}}"><p class="l">Objekt</p><p class="v">{{{{objLabel}}}}</p>{CHEV}</button>
    </div>
    <p class="note">Kategorie-Vorschlag folgt der Regel: ortsgebunden → Wohnen, personengebunden → Haushalt, fahrzeuggebunden → Mobilität.</p>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <div class="card">
      <div class="f"><p class="l">Betrag</p><input class="in num" value="{{{{amount}}}}" onChange="{{{{setAmount}}}}" inputmode="decimal" placeholder="0,00"><span style="font-size: 14px; color: #637894">€</span></div>
      <div class="sep"></div>
      <div class="f" style="flex-direction: column; align-items: stretch; gap: 8px; padding-top: 10px; padding-bottom: 12px"><p class="l" style="width: auto">Rhythmus</p>{seg("cycSeg", size=12)}</div>
      <div class="sep"></div>
      <div class="f"><p class="l">{{{{shareLabel}}}}</p><p class="v">{{{{share}}}} € <span style="color: #637894; font-weight: 400">· {{{{shareNote}}}}</span></p></div>
      <div class="sep"></div>
      {f_input("Nächste Fälligkeit", "due", "setDue", placeholder="TT.MM.JJJJ")}
      <div class="sep"></div>
      {f_toggle("Rücklage bilden", "resCls", "flipRes", "{{resSub}}")}
      <div class="sep"></div>
      {f_select("Zahlart", "pay", "setPay", [("Lastschrift","Lastschrift"),("Überweisung","Überweisung"),("Kreditkarte","Kreditkarte"),("Bar","Bar")])}
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <div class="card">
      {f_input("Vertragsbeginn", "start", "setStart", placeholder="TT.MM.JJJJ")}
      <div class="sep"></div>
      {f_select("Mindestlaufzeit", "term", "setTerm", [("0","keine"),("12","12 Monate"),("24","24 Monate")])}
      <div class="sep"></div>
      {f_select("Kündigungsfrist", "notice", "setNotice", [("none","keine · jederzeit"),("4w","4 Wochen"),("6w","6 Wochen"),("3m","3 Monate zum Laufzeitende")])}
      <div class="sep"></div>
      {f_select("Erinnerung", "remind", "setRemind", [("7","7 Tage vor Fälligkeit"),("3","3 Tage vor Fälligkeit"),("0","keine"),("30","30 Tage vor Kündigungsfrist")])}
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <div class="card" style="padding: 14px 16px">
      <p style="margin: 0; font-size: 13px; font-weight: 600; color: #637894; text-transform: uppercase; letter-spacing: .3px">Wirkung auf den Monat</p>
      <p style="margin: 6px 0 0; font-size: 14px">{{{{effect}}}}</p>
    </div>
  </div>
  {sheet("done", "Vertrag angelegt", "{{doneText}}", '<a class="btn sec2" href="Vertraege.dc.html">Zu den Verträgen</a><a class="btn pri" href="Vertrag.dc.html">Vertrag öffnen</a>')}
  {sheet("err", "Noch etwas fehlt", "{{errText}}", '<button class="btn pri" onClick="{{closeErr}}">Ergänzen</button>')}
'''
    logic = f'''  constructor(p) {{ super(p); this.state = {{ name: 'ADAC Mitgliedschaft', vendor: 'ADAC e.V.', area: 'Mobilität', cat: 'Mitgliedschaft', obj: 0, amount: '94,00', cyc: 12, due: '01.02.2027', res: true, resTouched: false, pay: 'Lastschrift', start: '01.02.2026', term: '12', notice: '3m', remind: '30', done: false, err: false, errText: '', toast: '' }}; }}
{JS_SEG}
  renderVals() {{
    var self = this, s = this.state, amt = num(s.amount), cyc = s.cyc, share = amt / cyc;
    var objs = {{ 'Wohnen': ['Wohnung Hauptstr. 12', 'kein Objekt'], 'Mobilität': ['VW ID.3', 'Deutschlandticket', 'kein Objekt'], 'Haushalt': ['Anna', 'Ben', 'kein Objekt'] }}[s.area];
    var res = s.resTouched ? s.res : cyc >= 6;
    var isFix = cyc <= 3 || !res;
    var effect = amt > 0
      ? (isFix ? 'Fixkosten +' + eur(share) + ' €/Monat' : 'Rücklage-Rate +' + eur(share) + ' €/Monat, Abbuchung ' + eur(amt) + ' € am ' + s.due + ' aus der Rücklage') + ' → Sparpotenzial ' + eur(592.70 - share) + ' € statt 592,70 €. Bereich ' + s.area + ': ' + eur({{ 'Wohnen': 1368.18, 'Mobilität': 746.19, 'Haushalt': 881.53 }}[s.area] + share) + ' €.'
      : 'Betrag eingeben – die Wirkung auf Fixkosten, Rücklage und Sparpotenzial erscheint hier.';
    return {{
      toast: s.toast,
      name: s.name, setName: this.set('name'), vendor: s.vendor, setVendor: this.set('vendor'),
      areaChips: this.chipItems('area', [['Wohnen', 'Wohnen'], ['Mobilität', 'Mobilität'], ['Haushalt', 'Haushalt']], true),
      cat: s.cat, setCat: function (e) {{ var v = ev(e); if (v === 'neu') self.say('Öffnet „Kategorie anlegen“ – hier als Vorschau'); else self.setState({{ cat: v }}); }},
      cycleObj: function () {{ self.setState({{ obj: (s.obj + 1) % objs.length }}); }}, objLabel: objs[s.obj % objs.length],
      amount: s.amount, setAmount: this.set('amount'),
      cycSeg: this.segItems('cyc', [[1, 'monatlich'], [3, 'vierteljährlich'], [6, 'halbjährlich'], [12, 'jährlich']]),
      shareLabel: cyc === 1 ? 'Monatlich' : 'Monatsanteil', share: eur(share), shareNote: isFix ? 'geht in die Fixkosten' : 'geht als Rate in die Rücklage',
      due: s.due, setDue: this.set('due'),
      resCls: res ? 'tog' : 'tog off', flipRes: function () {{ self.setState({{ res: !res, resTouched: true }}); }}, resSub: cyc <= 3 ? 'bei monatlich/vierteljährlich nicht nötig' : 'Monatsrate zurücklegen, Abbuchung belastet den Monat nicht',
      pay: s.pay, setPay: this.set('pay'), start: s.start, setStart: this.set('start'), term: s.term, setTerm: this.set('term'), notice: s.notice, setNotice: this.set('notice'), remind: s.remind, setRemind: this.set('remind'),
      effect: effect,
      done: s.done, doneText: s.name + ' · ' + eur(amt) + ' € ' + ({{1: 'monatlich', 3: 'vierteljährlich', 6: 'halbjährlich', 12: 'jährlich'}})[cyc] + ' · ' + s.area + ' › ' + s.cat + (isFix ? ' · Fixkosten +' + eur(share) : ' · Rücklage ' + eur(share) + '/Monat') + ' €',
      err: s.err, errText: s.errText, closeErr: this.go('err', false),
      save: function () {{
        if (!s.name.trim()) {{ self.setState({{ err: true, errText: 'Bitte einen Namen eingeben.' }}); return; }}
        if (!(amt > 0)) {{ self.setState({{ err: true, errText: 'Bitte einen Betrag größer 0 eingeben.' }}); return; }}
        if (!/^\\d{{2}}\\.\\d{{2}}\\.\\d{{4}}$/.test(s.due)) {{ self.setState({{ err: true, errText: 'Nächste Fälligkeit als TT.MM.JJJJ eingeben, z. B. 01.02.2027.' }}); return; }}
        self.setState({{ done: true }});
      }}
    }};
  }}'''
    page("VertragNeu.dc.html", "Vertrag anlegen", body, logic, 'v')


if __name__ == "__main__":
    build()
