"""Zehn Startseiten-Varianten (statisch) – Designer, CEO, Psychologe, Vergleichsprodukte. Siehe docs/konzept-2.0.0/startseiten-varianten.md"""
from common import *

LOGIC = "  constructor(p) { super(p); this.state = { toast: '' }; }\n  renderVals() { return { toast: '' }; }"
CSS_V = """
.vh{background:#1C3250;color:#FFFFFF;padding:56px 20px 24px}
.vh .k{margin:0;font-size:14px;opacity:.8}
.vh .z{margin:6px 0 0;font-size:36px;font-weight:700;letter-spacing:-0.8px;line-height:1;font-variant-numeric:tabular-nums}
.vh .t{margin:8px 0 0;font-size:13px;opacity:.8}
.sec{padding:18px 20px 0}
.ttl2{margin:0 0 8px 4px;font-size:17px;font-weight:700;letter-spacing:-0.3px;display:flex;justify-content:space-between;align-items:baseline}
.ttl2 span{font-size:13px;font-weight:600;color:#2A5480}
.tile{background:#FFFFFF;border-radius:18px;box-shadow:0 2px 10px rgba(22,36,58,.06);padding:14px 16px;text-decoration:none;color:inherit;display:block}
.tile .tl{margin:0;font-size:12px;color:#637894}
.tile .tv{margin:6px 0 0;font-size:22px;font-weight:700;font-variant-numeric:tabular-nums;letter-spacing:-0.4px}
.tile .ts{margin:4px 0 0;font-size:12px;color:#637894}
.ring{width:64px;height:64px;border-radius:32px;display:inline-flex;align-items:center;justify-content:center;font-weight:700;font-size:15px;color:#16243A}
.big2{font-size:52px;font-weight:700;letter-spacing:-1.5px;line-height:1;font-variant-numeric:tabular-nums}
.week{display:grid;grid-template-columns:repeat(7,1fr);gap:4px;text-align:center}
.week .d{font-size:11px;color:#637894}
.week .n{font-size:15px;font-weight:600;margin-top:2px;height:30px;line-height:30px;border-radius:15px}
.week .n.on{background:#2A5480;color:#FFFFFF}
.week .p{height:6px;display:flex;justify-content:center;gap:2px;margin-top:3px}
.week .p i{width:5px;height:5px;border-radius:3px;display:inline-block}
.story{font-size:19px;line-height:1.45;font-weight:500;margin:0}
.story b{font-weight:700;color:#1C3250}
.focus{background:#FFFFFF;border-radius:22px;box-shadow:0 8px 30px rgba(22,36,58,.12);padding:22px 20px}
.tbl{width:100%;border-collapse:collapse;font-size:13px}
.tbl th{text-align:right;font-weight:600;color:#637894;padding:8px 6px;border-bottom:1px solid #EEF1F5;font-size:11.5px;text-transform:uppercase;letter-spacing:.3px}
.tbl th:first-child,.tbl td:first-child{text-align:left}
.tbl td{padding:9px 6px;border-bottom:1px solid #EEF1F5;text-align:right;font-variant-numeric:tabular-nums}
.tbl tr.sum td{font-weight:700;border-bottom:0}
.mini{display:flex;align-items:flex-end;gap:5px;height:44px}
.mini i{flex:1;background:#D7E3EE;border-radius:3px 3px 0 0;display:block}
.mini i.on{background:#2A5480}
.kpi{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.kpi .tile{padding:12px 14px}
.kpi .tv{font-size:19px}
.task{display:flex;align-items:center;gap:12px;padding:12px 16px;text-decoration:none;color:inherit}
.task .cb{width:24px;height:24px;border-radius:12px;border:2px solid #C4CCD6;flex:none}
.task .cb.on{background:#2F8F5B;border-color:#2F8F5B}
.task .n{margin:0;font-size:15px;font-weight:600;flex:1;min-width:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.task .s{margin:2px 0 0;font-size:12px;color:#637894}
.task .v{margin:0;font-size:15px;font-weight:600;font-variant-numeric:tabular-nums;white-space:nowrap}
.amp{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}
.amp .tile{text-align:center;padding:16px 8px}
.amp .dotb{width:14px;height:14px;border-radius:7px;display:inline-block;margin-bottom:8px}
.inb{display:flex;align-items:center;gap:12px;padding:12px 16px;text-decoration:none;color:inherit}
.inb .ic{width:40px;height:40px;border-radius:10px;background:#EEF1F5;display:inline-flex;align-items:center;justify-content:center;flex:none;color:#2A5480}
.inb .n{margin:0;font-size:15px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.inb .s{margin:2px 0 0;font-size:12px;color:#637894;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.unread{width:8px;height:8px;border-radius:4px;background:#2A5480;flex:none}
"""

def nav(title_left="Oktober 2026"):
    return f'''<div style="display: flex; align-items: center; justify-content: space-between">
      <p style="margin: 0; font-size: 15px; font-weight: 600; opacity: .9">{title_left}</p>
      <div style="display: flex; gap: 8px"><a href="Kalender.dc.html" class="chip" style="height: 34px; width: 34px; padding: 0; justify-content: center; border-radius: 17px" aria-label="Kalender">▦</a><a href="Mehr.dc.html" class="chip" style="height: 34px; width: 34px; padding: 0; justify-content: center; border-radius: 17px" aria-label="Mehr">…</a></div>
    </div>'''

def due_row(day, mon, name, status, amount, red=False, href="Rechnung.dc.html"):
    return f'<a class="row dr" href="{href}"><div class="dd" style="{"color: #E03C31" if red else ""}"><p class="d1">{day}</p><p class="d2">{mon}</p></div><div class="mid"><p class="n">{name}</p><p class="s" style="{"color: #E03C31" if red else ""}">{status}</p></div><p class="v">{amount} €</p></a><div class="sep" style="margin-left: 72px"></div>'

DUE4 = (due_row("21", "Okt.", "Stadtwerke Mainstadt", "überfällig", "142,00", True)
        + due_row("27", "Okt.", "HUK24 Kfz-Versicherung", "in 2 Tagen · aus Rücklage", "487,20", False, "Vertrag.dc.html")
        + due_row("29", "Okt.", "Netflix", "in 4 Tagen", "12,99", False, "Vertrag.dc.html")
        + due_row("30", "Okt.", "Autohaus Keller", "in 5 Tagen", "212,40", False, "Review.dc.html"))

def areas(sub=True):
    rows = [("Wohnen.dc.html", W, ICON["home"], "Wohnen", "1.368 €", "1 überfällig", "#E03C31"),
            ("Akte.dc.html", M, ICON["car"], "Mobilität", "746 €", "Inspektion offen", "#704F2E"),
            ("Haushalt.dc.html", H, ICON["bag"], "Haushalt", "882 €", "Freizeit über Budget", "#704F2E")]
    out = '<div class="card">'
    for i, (href, col, ic, name, val, st, stc) in enumerate(rows):
        s = f'<p class="s" style="color: {stc}">{st}</p>' if sub else ''
        out += f'<a class="row" href="{href}" style="min-height: 58px; padding: 8px 16px"><span class="c" style="background: {col}; width: 36px; height: 36px; border-radius: 18px">{ic}</span><div class="mid"><p class="n" style="font-size: 16px">{name}</p>{s}</div><p class="v" style="font-size: 16px">{val}</p>{CHEV}</a>'
        if i < 2: out += '<div class="sep" style="margin-left: 64px"></div>'
    return out + '</div>'


def build():
    # ---------------------------------------------------------------- V1 Heute
    body = f'''  <div class="vh">
    {nav()}
    <p class="k" style="margin-top: 22px">Sonntag, 25. Oktober</p>
    <p class="z" style="font-size: 26px; letter-spacing: -0.5px; line-height: 1.2">Eine Sache wartet heute.<br>Sonst ist alles im Plan.</p>
    <p class="t">Noch frei bis Monatsende: 592,70 €</p>
  </div>
  <div class="sec">
    <h2 class="ttl2">Heute <span>1 offen</span></h2>
    <div class="card">
      <a class="task" href="Rechnung.dc.html"><span class="cb"></span><div style="flex: 1; min-width: 0"><p class="n">Stadtwerke überweisen</p><p class="s">142,00 € · 4 Tage überfällig</p></div><span class="chip lt" style="height: 30px">Erledigt</span></a>
    </div>
  </div>
  <div class="sec">
    <h2 class="ttl2">Diese Woche <span>3</span></h2>
    <div class="card">
      <a class="task" href="Vertrag.dc.html"><span class="cb"></span><div style="flex: 1; min-width: 0"><p class="n">HUK24 bucht 487,20 € ab</p><p class="s">Di 27. · aus der Rücklage gedeckt – nichts zu tun</p></div></a><div class="sep" style="margin-left: 52px"></div>
      <a class="task" href="Review.dc.html"><span class="cb"></span><div style="flex: 1; min-width: 0"><p class="n">Inspektion prüfen und freigeben</p><p class="s">212,40 € · Scan von gestern · Empfänger fehlt</p></div></a><div class="sep" style="margin-left: 52px"></div>
      <a class="task" href="Vertraege.dc.html"><span class="cb"></span><div style="flex: 1; min-width: 0"><p class="n">Deutschlandticket: kündigen oder behalten?</p><p class="s">Frist 10. Nov. · 58 €/Monat</p></div></a>
    </div>
  </div>
  <div class="sec">
    <h2 class="ttl2">Erledigt <span>heute 2</span></h2>
    <div class="card">
      <div class="task"><span class="cb on"></span><div style="flex: 1; min-width: 0"><p class="n" style="color: #637894; text-decoration: line-through">REWE-Bon erfasst</p><p class="s">58,37 € · Lebensmittel</p></div></div><div class="sep" style="margin-left: 52px"></div>
      <div class="task"><span class="cb on"></span><div style="flex: 1; min-width: 0"><p class="n" style="color: #637894; text-decoration: line-through">Kontostand abgeglichen</p><p class="s">2.410,00 € · passt zur Planung</p></div></div>
    </div>
  </div>
'''
    page("V01_Heute.dc.html", "V1 · Heute", body, LOGIC, 'u', CSS_V)

    # ---------------------------------------------------------------- V2 Ampel
    body = f'''  <div class="vh" style="padding-bottom: 18px">
    {nav()}
    <p class="k" style="margin-top: 22px">Dein Stand</p>
    <p class="z" style="font-size: 24px; letter-spacing: -0.4px">Eine Rechnung braucht dich.</p>
  </div>
  <div class="sec" style="padding-top: 14px">
    <div class="amp">
      <a class="tile" href="Rechnungen.dc.html"><span class="dotb" style="background: #E03C31"></span><p class="tl">Rechnungen</p><p class="tv">1</p><p class="ts">überfällig · 3 fällig</p></a>
      <a class="tile" href="Monatsrechnung.dc.html"><span class="dotb" style="background: #2F8F5B"></span><p class="tl">Geld</p><p class="tv">592 €</p><p class="ts">noch frei</p></a>
      <a class="tile" href="Vertraege.dc.html"><span class="dotb" style="background: #E8A33D"></span><p class="tl">Verträge</p><p class="tv">2</p><p class="ts">Fristen bis 15. Nov.</p></a>
    </div>
  </div>
  <div class="sec">
    <h2 class="ttl2">Zuerst</h2>
    <div class="card">{due_row("21", "Okt.", "Stadtwerke Mainstadt", "überfällig seit 4 Tagen", "142,00", True)}</div>
    <div style="display: flex; gap: 10px; margin-top: 10px"><a class="btn pri" href="Rechnung.dc.html" style="flex: 1">Jetzt bezahlen</a><a class="btn sec2" href="Rechnung.dc.html" style="flex: 1">IBAN kopieren</a></div>
  </div>
  <div class="sec">
    <h2 class="ttl2">Bereiche</h2>
    {areas(False)}
  </div>
'''
    page("V02_Ampel.dc.html", "V2 · Ampel", body, LOGIC, 'u', CSS_V)

    # ---------------------------------------------------------------- V3 Eine Zahl (Calm)
    body = f'''  <div class="vh" style="padding-bottom: 40px">
    {nav()}
    <div style="text-align: center; margin-top: 54px">
      <p class="k">Noch frei bis Monatsende</p>
      <p class="big2" style="margin: 10px 0 0">592 €</p>
      <p class="t" style="margin-top: 10px">7 Tage · etwa 85 € pro Tag</p>
    </div>
  </div>
  <div class="sec" style="margin-top: -22px">
    <a class="tile" href="Rechnung.dc.html" style="display: flex; align-items: center; gap: 12px; border-left: 4px solid #E03C31"><div style="flex: 1; min-width: 0"><p class="tl" style="color: #E03C31; font-weight: 600">Eine Rechnung ist überfällig</p><p class="tv" style="font-size: 17px; margin-top: 3px">Stadtwerke · 142,00 €</p></div>{CHEV}</a>
  </div>
  <div class="sec" style="flex: 1"></div>
  <div class="sec" style="padding-bottom: 8px">
    <p class="note" style="text-align: center; margin: 0 0 10px">Sonst ist alles im Plan.</p>
    <div style="display: flex; gap: 10px"><a class="btn sec2" href="Rechnungen.dc.html" style="flex: 1">Fällig</a><a class="btn sec2" href="Wohnen.dc.html" style="flex: 1">Bereiche</a><a class="btn sec2" href="Liquiditaet.dc.html" style="flex: 1">Konto</a></div>
  </div>
'''
    page("V03_Ruhe.dc.html", "V3 · Ruhe", body, LOGIC, 'u', CSS_V)

    # ---------------------------------------------------------------- V4 Zeitstrahl
    dots = lambda cols: ''.join(f'<i style="background: {c}"></i>' for c in cols)
    days = [("Mo", "19", ""), ("Di", "20", ""), ("Mi", "21", dots(["#E03C31"])), ("Do", "22", ""), ("Fr", "23", ""), ("Sa", "24", ""), ("So", "25", "on")]
    week = ''.join(f'<div><p class="d">{d}</p><p class="n {"on" if p == "on" else ""}">{n}</p><div class="p">{p if p != "on" else ""}</div></div>' for d, n, p in days)
    days2 = [("Mo", "26", ""), ("Di", "27", dots([M])), ("Mi", "28", ""), ("Do", "29", dots([H])), ("Fr", "30", dots(["#2F8F5B", M])), ("Sa", "31", ""), ("So", "1", dots([W, M, H]))]
    week2 = ''.join(f'<div><p class="d">{d}</p><p class="n">{n}</p><div class="p">{p}</div></div>' for d, n, p in days2)
    body = f'''  <div class="vh" style="padding-bottom: 16px">
    {nav()}
    <p class="k" style="margin-top: 20px">Kontostand heute · noch frei 592,70 €</p>
    <p class="z" style="font-size: 30px">2.410,00 €</p>
    <div class="card" style="margin-top: 16px; padding: 12px 10px; color: #16243A"><div class="week">{week}</div><div class="week" style="margin-top: 8px">{week2}</div></div>
  </div>
  <div class="sec" style="padding-top: 14px">
    <div class="card">
      {due_row("21", "Okt.", "Stadtwerke Mainstadt", "überfällig · danach 2.268,00", "−142,00", True)}
      {due_row("27", "Okt.", "HUK24 Kfz-Versicherung", "Rücklage · danach 1.780,80", "−487,20", False, "Vertrag.dc.html")}
      {due_row("29", "Okt.", "Netflix", "danach 1.767,81", "−12,99", False, "Vertrag.dc.html")}
      {due_row("30", "Okt.", "Gehalt Muster AG", "danach 5.167,81", "+3.400,00", False, "Einnahmen.dc.html")}
      {due_row("30", "Okt.", "Autohaus Keller", "danach 4.955,41", "−212,40", False, "Review.dc.html")}
      {due_row("1", "Nov.", "7 Fixkosten", "Miete, Leasing, Abschläge · danach 3.365,13", "−1.590,28", False, "Vertraege.dc.html")}
    </div>
    <p class="note">Tiefster Stand 1.767,81 € am 29. Okt. – über dem Puffer.</p>
  </div>
'''
    page("V04_Zeitstrahl.dc.html", "V4 · Zeitstrahl", body, LOGIC, 'l', CSS_V)

    # ---------------------------------------------------------------- V5 Posteingang
    doc = '<svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/></svg>'
    body = f'''  <div class="vh" style="padding-bottom: 18px">
    {nav("Eingang")}
    <p class="z" style="margin-top: 20px; font-size: 28px">3 neue Belege</p>
    <p class="t">1 zu prüfen · 1 überfällig · 592,70 € noch frei</p>
    <div style="display: flex; gap: 8px; margin-top: 14px"><span class="chip on">Eingang 3</span><a class="chip" href="Rechnungen.dc.html">Fällig 4</a><a class="chip" href="Rechnungen.dc.html">Erledigt 13</a></div>
  </div>
  <div class="sec" style="padding-top: 14px">
    <div class="card">
      <a class="inb" href="Review.dc.html"><span class="unread"></span><span class="ic">{CAM}</span><div style="flex: 1; min-width: 0"><p class="n">Autohaus Keller · Inspektion</p><p class="s">Scan gestern · Empfänger prüfen</p></div><p class="v" style="margin: 0; font-weight: 600">212,40</p></a><div class="sep" style="margin-left: 76px"></div>
      <a class="inb" href="Rechnung.dc.html"><span class="unread"></span><span class="ic">{doc}</span><div style="flex: 1; min-width: 0"><p class="n">Telekom Rechnung Oktober</p><p class="s">PDF aus Mail · passt zum Vertrag</p></div><p class="v" style="margin: 0; font-weight: 600">39,99</p></a><div class="sep" style="margin-left: 76px"></div>
      <a class="inb" href="Rechnung.dc.html"><span class="unread"></span><span class="ic">{doc}</span><div style="flex: 1; min-width: 0"><p class="n">REWE</p><p class="s">Bon gestern · Lebensmittel</p></div><p class="v" style="margin: 0; font-weight: 600">58,37</p></a>
    </div>
    <p class="note">Antippen bestätigt den Beleg. Bestätigte Belege wandern nach „Fällig“ oder „Erledigt“.</p>
  </div>
  <div class="sec">
    <h2 class="ttl2">Überfällig <span style="color: #E03C31">1</span></h2>
    <div class="card">{due_row("21", "Okt.", "Stadtwerke Mainstadt", "Nachzahlung · seit 4 Tagen", "142,00", True)}</div>
  </div>
  <div class="sec">
    <a class="btn pri" href="Erfassen.dc.html" style="width: 100%">{CAM} Beleg scannen</a>
  </div>
'''
    page("V05_Eingang.dc.html", "V5 · Eingang", body, LOGIC, 'r', CSS_V)

    # ---------------------------------------------------------------- V6 Bereichskacheln
    def big_tile(href, col, ic, name, val, line, warn=False):
        return f'''<a class="tile" href="{href}" style="display: flex; align-items: center; gap: 14px; padding: 16px"><span class="c" style="background: {col}; width: 48px; height: 48px; border-radius: 16px; display: inline-flex; align-items: center; justify-content: center; color: #fff; flex: none">{ic}</span><div style="flex: 1; min-width: 0"><p class="tl" style="font-size: 16px; font-weight: 700; color: #16243A">{name}</p><p class="ts" style="{"color: #E03C31; font-weight: 600" if warn else ""}">{line}</p></div><p class="tv" style="margin: 0; font-size: 18px">{val}</p></a>'''
    body = f'''  <div class="vh" style="padding-bottom: 18px">
    {nav()}
    <p class="k" style="margin-top: 22px">Noch frei im Oktober</p>
    <p class="z">592,70 €</p>
  </div>
  <div class="sec" style="padding-top: 14px; display: flex; flex-direction: column; gap: 10px">
    {big_tile("Wohnen.dc.html", W, ICON["home"], "Wohnen", "1.368 €", "Strom-Nachzahlung überfällig", True)}
    {big_tile("Akte.dc.html", M, ICON["car"], "Mobilität", "746 €", "Versicherung Di · Inspektion Fr")}
    {big_tile("Haushalt.dc.html", H, ICON["bag"], "Haushalt", "882 €", "Freizeit 30 € über Budget")}
  </div>
  <div class="sec">
    <h2 class="ttl2">Fällig <span>4 Posten</span></h2>
    <div class="card">{DUE4}</div>
  </div>
'''
    page("V06_Bereiche.dc.html", "V6 · Bereiche", body, LOGIC, 'u', CSS_V)

    # ---------------------------------------------------------------- V7 Monatsbrief
    body = f'''  <div class="vh" style="padding-bottom: 26px">
    {nav()}
    <p class="k" style="margin-top: 22px">Dein Oktober, kurz gesagt</p>
    <p class="story" style="margin-top: 12px; color: #FFFFFF">Es kamen <b style="color: #FFFFFF">3.650 €</b> rein. <b style="color: #FFFFFF">1.985 €</b> gehen für Miete, Verträge und Rücklagen weg, <b style="color: #FFFFFF">1.072 €</b> hast du ausgegeben oder eingeplant.</p>
    <p class="story" style="margin-top: 14px; color: #FFFFFF">Bleiben <b style="color: #FFFFFF">592 €</b> – das ist gut.</p>
  </div>
  <div class="sec">
    <a class="tile" href="Rechnung.dc.html" style="border-left: 4px solid #E03C31"><p class="story" style="font-size: 16px">Eine Rechnung wartet seit 4 Tagen: <b>Stadtwerke, 142 €</b>. Zwei Minuten – dann ist der Monat sauber.</p><div style="display: flex; gap: 10px; margin-top: 12px"><span class="btn pri sm" style="flex: 1">Jetzt bezahlen</span><span class="btn sec2 sm" style="flex: 1">Später</span></div></a>
  </div>
  <div class="sec">
    <a class="tile" href="Vertraege.dc.html"><p class="story" style="font-size: 16px">Am Dienstag bucht die <b>HUK24 487 €</b> ab. Dafür hast du 12 Monate gespart – der Monat merkt nichts davon.</p></a>
  </div>
  <div class="sec">
    <a class="tile" href="Budgets.dc.html"><p class="story" style="font-size: 16px">Freizeit liegt <b>30 € über</b> dem Budget. Lebensmittel hat noch 38 € Luft – soll ich umschichten?</p></a>
  </div>
  <div class="sec"><p class="note" style="text-align: center">Zahlen im Detail: Monatsrechnung · Bereiche · Fällig</p></div>
'''
    page("V07_Monatsbrief.dc.html", "V7 · Monatsbrief", body, LOGIC, 'u', CSS_V)

    # ---------------------------------------------------------------- V8 Haushaltsbuch klassisch
    body = f'''  <div class="vh" style="padding-bottom: 16px">
    {nav()}
    <div style="display: flex; justify-content: space-between; margin-top: 20px; gap: 10px">
      <div><p class="k">Einnahmen</p><p class="z" style="font-size: 20px; color: #9BE2B5">3.650,00</p></div>
      <div><p class="k">Ausgaben</p><p class="z" style="font-size: 20px">3.057,30</p></div>
      <div style="text-align: right"><p class="k">Saldo</p><p class="z" style="font-size: 20px">+592,70</p></div>
    </div>
  </div>
  <div class="sec" style="padding-top: 14px">
    <div class="card" style="padding: 4px 10px 6px">
      <table class="tbl">
        <tr><th>Woche</th><th>Ein</th><th>Aus</th><th>Saldo</th></tr>
        <tr><td>1.–4. Okt.</td><td>–</td><td>1.819,64</td><td>−1.819,64</td></tr>
        <tr><td>5.–11. Okt.</td><td>250,00</td><td>335,88</td><td>−85,88</td></tr>
        <tr><td>12.–18. Okt.</td><td>–</td><td>181,90</td><td>−181,90</td></tr>
        <tr><td>19.–25. Okt.</td><td>–</td><td>312,98</td><td>−312,98</td></tr>
        <tr><td>26.–31. Okt. <span style="color: #637894">(geplant)</span></td><td>3.400,00</td><td>406,90</td><td>+2.993,10</td></tr>
        <tr class="sum"><td>Oktober</td><td>3.650,00</td><td>3.057,30</td><td>+592,70</td></tr>
      </table>
    </div>
  </div>
  <div class="sec">
    <h2 class="ttl2">Letzte Buchungen <span>Alle</span></h2>
    <div class="card">
      {due_row("24", "Okt.", "REWE", "Bon · Lebensmittel", "−58,37")}
      {due_row("21", "Okt.", "Stadtwerke Mainstadt", "Rechnung · offen", "−142,00", True)}
      {due_row("21", "Okt.", "Bäckerei Schmitt", "Bon · Lebensmittel", "−12,60")}
      {due_row("18", "Okt.", "Wochenmarkt", "Bon · Lebensmittel", "−41,80")}
      {due_row("16", "Okt.", "EnBW mobility+", "Rechnung · bezahlt", "−64,20")}
    </div>
  </div>
'''
    page("V08_Haushaltsbuch.dc.html", "V8 · Haushaltsbuch", body, LOGIC, 'u', CSS_V)

    # ---------------------------------------------------------------- V9 Fokus-Karte
    body = f'''  <div class="vh" style="padding-bottom: 70px">
    {nav()}
    <p class="k" style="margin-top: 22px">Das Wichtigste zuerst</p>
    <p class="z" style="font-size: 22px; letter-spacing: -0.3px">1 von 4</p>
  </div>
  <div class="sec" style="margin-top: -52px">
    <div class="focus">
      <span class="cap" style="background: #F7D4D1; color: #943333">Überfällig seit 4 Tagen</span>
      <p style="margin: 14px 0 0; font-size: 22px; font-weight: 700; letter-spacing: -0.3px">Stadtwerke Mainstadt</p>
      <p style="margin: 4px 0 0; font-size: 14px; color: #637894">Nachzahlung Strom 2025 · Wohnen</p>
      <p style="margin: 18px 0 0; font-size: 40px; font-weight: 700; letter-spacing: -1px; font-variant-numeric: tabular-nums">142,00 €</p>
      <p style="margin: 6px 0 0; font-size: 13px; color: #637894">IBAN DE12 5001 … 3249 31 · Verwendung SW-2026-0217</p>
      <div style="display: flex; gap: 10px; margin-top: 20px"><a class="btn pri" href="Rechnung.dc.html" style="flex: 1">Als bezahlt markieren</a></div>
      <div style="display: flex; gap: 10px; margin-top: 10px"><a class="btn sec2" href="Rechnung.dc.html" style="flex: 1">IBAN kopieren</a><a class="btn sec2" href="Rechnung.dc.html" style="flex: 1">Morgen erinnern</a></div>
    </div>
    <p class="note" style="text-align: center; margin-top: 14px">Wischen für die nächste: HUK24 · Inspektion · Deutschlandticket</p>
  </div>
  <div class="sec" style="flex: 1"></div>
  <div class="sec">
    <a class="tile" href="Monatsrechnung.dc.html" style="display: flex; align-items: center; justify-content: space-between"><p class="tl" style="font-size: 14px">Noch frei im Oktober</p><p class="tv" style="margin: 0; font-size: 18px">592,70 €</p></a>
  </div>
'''
    page("V09_Fokus.dc.html", "V9 · Fokus", body, LOGIC, 'u', CSS_V)

    # ---------------------------------------------------------------- V10 Cockpit
    bars = ''.join(f'<i style="height: {h}%" class="{"on" if i == 5 else ""}"></i>' for i, h in enumerate([70, 73, 100, 70, 72, 77]))
    body = f'''  <div class="vh" style="padding-bottom: 16px">
    {nav()}
    <div style="display: flex; justify-content: space-between; align-items: flex-end; margin-top: 18px">
      <div><p class="k">Noch frei</p><p class="z" style="font-size: 30px">592,70 €</p></div>
      <div style="text-align: right"><p class="k">Sparquote</p><p class="z" style="font-size: 30px">25 %</p></div>
    </div>
  </div>
  <div class="sec" style="padding-top: 14px">
    <div class="kpi">
      <a class="tile" href="Liquiditaet.dc.html"><p class="tl">Kontostand</p><p class="tv">2.410 €</p><p class="ts">Tief 1.768 € am 29.</p></a>
      <a class="tile" href="Vertraege.dc.html"><p class="tl">Verträge</p><p class="tv">1.713 €/M</p><p class="ts">16 · 2 kündbar</p></a>
      <a class="tile" href="Budgets.dc.html"><p class="tl">Budgets</p><p class="tv">61 € frei</p><p class="ts">Freizeit +30 €</p></a>
      <a class="tile" href="Rechnungen.dc.html"><p class="tl">Offen</p><p class="tv" style="color: #943333">354 €</p><p class="ts">1 überfällig · 1 fällig</p></a>
    </div>
  </div>
  <div class="sec">
    <a class="tile" href="Auswertung.dc.html"><div style="display: flex; justify-content: space-between"><p class="tl">Ausgaben je Monat</p><p class="tl">Ø 3.004 €</p></div><div class="mini" style="margin-top: 8px">{bars}</div><div style="display: flex; justify-content: space-between; font-size: 11px; color: #637894; margin-top: 4px"><span>Mai</span><span>Jun</span><span>Jul</span><span>Aug</span><span>Sep</span><span>Okt</span></div></a>
  </div>
  <div class="sec">
    {areas(True)}
  </div>
  <div class="sec">
    <h2 class="ttl2">Fällig <span>4</span></h2>
    <div class="card">{DUE4}</div>
  </div>
'''
    page("V10_Cockpit.dc.html", "V10 · Cockpit", body, LOGIC, 'u', CSS_V)

    # canvas: neue Reihe
    p = os.path.join(OUT, "canvas.json")
    c = json.load(open(p, encoding="utf-8"))
    names = ["V01_Heute", "V02_Ampel", "V03_Ruhe", "V04_Zeitstrahl", "V05_Eingang", "V06_Bereiche", "V07_Monatsbrief", "V08_Haushaltsbuch", "V09_Fokus", "V10_Cockpit"]
    titles = ["V1 Heute – Aufgaben zuerst", "V2 Ampel – drei Zustände", "V3 Ruhe – eine Zahl", "V4 Zeitstrahl – was kommt", "V5 Eingang – Belege zuerst", "V6 Bereiche – Haus, Auto, Familie", "V7 Monatsbrief – in Sätzen", "V8 Haushaltsbuch – klassisch", "V9 Fokus – eine Sache", "V10 Cockpit – alles auf einmal"]
    Y = 5700
    for i, (n, t) in enumerate(zip(names, titles)):
        f = n + ".dc.html"
        c["boards"][f] = {"x": i * 470, "y": Y, "w": 390, "h": 844, "title": t, "radius": 44, "is_interactive": True}
        if f not in c["order"]: c["order"].append(f)
    c["notes"]["t3"] = {"x": 0, "y": Y - 160, "text": "Startseiten-Varianten 25.10. – zehn Aufbaustrukturen aus Sicht Designer, CEO, Psychologe und Vergleichsprodukte (Begründung: docs/konzept-2.0.0/startseiten-varianten.md). Zur Entscheidung, nicht final.", "kind": "title1", "maxW": 4600}
    json.dump(c, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=2)




# ====================================================================== Kategorien auf der Startseite (V11–V16)
CATS = [  # name, betrag, bereich-farbe, budget (None = fix), kurz
    ("Miete / Hausgeld", 950.00, W, None), ("Lebensmittel", 412.00, H, 450), ("Kfz-Rate / Leasing", 289.00, M, None),
    ("Werkstatt & Reifen", 272.40, M, None), ("Strom", 240.00, W, None), ("Freizeit & Kultur", 209.90, H, 150, 180),
    ("Urlaub & Reisen", 200.00, H, None), ("Gas / Heizung", 112.00, W, None), ("Kraftstoff / Laden", 74.19, M, 300),
    ("ÖPNV / Ticket", 58.00, M, None), ("Kommunikation", 53.96, H, None), ("Kfz-Versicherung", 40.60, M, None),
    ("Internet", 39.99, W, None), ("Rundfunk", 18.36, W, None), ("Kfz-Steuer", 12.00, M, None), ("Hausrat", 7.83, W, None), ("Haftpflicht", 5.67, H, None),
]
CSS_K = """
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.grid3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px}
.kt{background:#FFFFFF;border-radius:16px;box-shadow:0 2px 10px rgba(22,36,58,.06);padding:12px 12px 10px;text-decoration:none;color:inherit;display:block;min-width:0}
.kt .ki{width:30px;height:30px;border-radius:10px;display:inline-flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:13px}
.kt .kn{margin:8px 0 0;font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.kt .kv{margin:2px 0 0;font-size:16px;font-weight:700;font-variant-numeric:tabular-nums;letter-spacing:-0.3px}
.kt .kb{height:4px;border-radius:2px;background:#EEF1F5;margin-top:8px;overflow:hidden}
.kt .kb i{display:block;height:4px;border-radius:2px}
.kt .ks{margin:4px 0 0;font-size:11px;color:#637894;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.kl2{display:flex;align-items:center;gap:10px;padding:9px 16px;text-decoration:none;color:inherit}
.kl2 .nm{flex:1.5;min-width:0;font-size:14px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.kl2 .hb{flex:1;height:8px;border-radius:4px;background:#EEF1F5;overflow:hidden}
.kl2 .hb i{display:block;height:8px;border-radius:4px}
.kl2 .am{width:64px;text-align:right;font-size:14px;font-weight:600;font-variant-numeric:tabular-nums}
.strip{display:flex;gap:8px;overflow-x:auto;scrollbar-width:none;padding:0 20px}
.strip .sc{flex:none;background:#FFFFFF;border-radius:14px;padding:10px 12px;min-width:150px;text-decoration:none;color:inherit;box-shadow:0 2px 10px rgba(22,36,58,.06)}
.strip .sc p{margin:0}
.env{padding:10px 16px;text-decoration:none;color:inherit;display:block}
.env .top{display:flex;justify-content:space-between;align-items:baseline;gap:10px}
.env .nm{font-size:15px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.env .rest{font-size:13px;font-weight:600;white-space:nowrap}
.env .hb{height:8px;border-radius:4px;background:#EEF1F5;overflow:hidden;margin-top:7px}
.env .hb i{display:block;height:8px;border-radius:4px}
.env .sub{margin:5px 0 0;font-size:12px;color:#637894}
"""

def ini(name): return name[0]

def kt(name, amt, col, budget=None, spent=None, href="Kategorie.dc.html", note=None):
    if budget:
        sp = spent if spent is not None else amt
        pct = min(100, round(sp / budget * 100)); over = sp > budget
        bar = f'<div class="kb"><i style="width: {pct}%; background: {"#E03C31" if over else col}"></i></div>'
        sub = f'<p class="ks" style="{"color: #E03C31" if over else ""}">{(eur_py(sp-budget) + " über Budget") if over else ("noch " + eur_py(budget-sp) + " von " + eur_py(budget, 0))}</p>'
    else:
        bar = ''; sub = f'<p class="ks">{note or "fix · Vertrag"}</p>'
    return f'<a class="kt" href="{href}"><span class="ki" style="background: {col}">{ini(name)}</span><p class="kn">{name}</p><p class="kv">{eur_py(amt)}</p>{bar}{sub}</a>'

def eur_py(v, dec=2):
    s = f"{v:,.{dec}f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return s

def build_k():
    tot = sum(c[1] for c in CATS)
    # ------------------------------------------------------------ V11 Kategorie-Raster
    tiles = ''.join(kt(*t) for t in CATS[:8])
    body = f'''  <div class="vh" style="padding-bottom: 18px">
    {nav()}
    <div style="display: flex; justify-content: space-between; align-items: flex-end; margin-top: 18px"><div><p class="k">Noch frei im Oktober</p><p class="z" style="font-size: 30px">592,70 €</p></div><a class="chip" href="Rechnungen.dc.html" style="background: #E03C31; color: #fff">1 überfällig</a></div>
  </div>
  <div class="sec" style="padding-top: 14px">
    <div style="display: flex; gap: 8px; margin-bottom: 12px"><span class="chip lt on">Alle</span><span class="chip lt"><i class="dot" style="background: {W}; margin-right: 6px"></i>Wohnen</span><span class="chip lt"><i class="dot" style="background: {M}; margin-right: 6px"></i>Mobilität</span><span class="chip lt"><i class="dot" style="background: {H}; margin-right: 6px"></i>Haushalt</span></div>
    <div class="grid2">{tiles}</div>
    <p class="note" style="text-align: center">9 weitere Kategorien · Summe 2.995,90 €</p>
  </div>
'''
    page("V11_Raster.dc.html", "V11 · Kategorie-Raster", body, LOGIC, 'u', CSS_V + CSS_K)

    # ------------------------------------------------------------ V12 Kategorienliste mit Balken
    mx = CATS[0][1]
    rows = ''
    for n, a, c, b, *_ in CATS[:10]:
        over = n.startswith('Freizeit')
        rows += f'<a class="kl2" href="Kategorie.dc.html"><span class="dot" style="background: {c}"></span><span class="nm">{n}</span><span class="hb"><i style="width: {round(a/mx*100)}%; background: {"#E03C31" if over else c}"></i></span><span class="am">{eur_py(a, 0)}</span></a><div class="sep" style="margin-left: 38px"></div>'
    body = f'''  <div class="vh" style="padding-bottom: 18px">
    {nav()}
    <p class="k" style="margin-top: 18px">Noch frei im Oktober</p>
    <p class="z" style="font-size: 30px">592,70 €</p>
  </div>
  <div style="margin-top: 14px" class="strip">
    <a class="sc" href="Rechnung.dc.html" style="border-left: 3px solid #E03C31"><p style="font-size: 11px; color: #E03C31; font-weight: 700">ÜBERFÄLLIG</p><p style="font-size: 14px; font-weight: 600; margin-top: 2px">Stadtwerke</p><p style="font-size: 13px; color: #637894">142,00 € · 21. Okt.</p></a>
    <a class="sc" href="Vertrag.dc.html"><p style="font-size: 11px; color: #637894; font-weight: 700">DI 27.</p><p style="font-size: 14px; font-weight: 600; margin-top: 2px">HUK24</p><p style="font-size: 13px; color: #637894">487,20 € · Rücklage</p></a>
    <a class="sc" href="Review.dc.html"><p style="font-size: 11px; color: #637894; font-weight: 700">FR 30.</p><p style="font-size: 14px; font-weight: 600; margin-top: 2px">Inspektion</p><p style="font-size: 13px; color: #637894">212,40 € · prüfen</p></a>
  </div>
  <div class="sec">
    <h2 class="ttl2">Kategorien im Oktober <span>nach Betrag</span></h2>
    <div class="card" style="padding: 4px 0">{rows}</div>
    <p class="note">Balken relativ zur größten Kategorie; rot = Budget überschritten. 7 weitere unter 50 €.</p>
  </div>
'''
    page("V12_Liste.dc.html", "V12 · Kategorienliste", body, LOGIC, 'u', CSS_V + CSS_K)

    # ------------------------------------------------------------ V13 Ring + Top-Kategorien
    import math
    segs = [(1368.18, W), (746.19, M), (881.53, H)]; total = sum(s[0] for s in segs); R = 54; C = 2 * math.pi * R
    ring = ''; off = 0
    for v, col in segs:
        l = v / total * C
        ring += f'<circle cx="70" cy="70" r="{R}" fill="none" stroke="{col}" stroke-width="16" stroke-dasharray="{l:.1f} {C - l:.1f}" stroke-dashoffset="{-off:.1f}" transform="rotate(-90 70 70)"/>'
        off += l
    top = ''.join(f'<a class="kl2" href="Kategorie.dc.html"><span class="dot" style="background: {c}"></span><span class="nm">{n}</span><span class="am" style="width: auto">{eur_py(a)}</span>{CHEV}</a><div class="sep" style="margin-left: 38px"></div>' for n, a, c, b, *_ in CATS[:6])
    body = f'''  <div class="vh" style="padding-bottom: 18px">
    {nav()}
    <div style="display: flex; align-items: center; gap: 18px; margin-top: 18px">
      <svg width="140" height="140" viewBox="0 0 140 140" aria-label="Verteilung"><circle cx="70" cy="70" r="{R}" fill="none" stroke="rgba(255,255,255,.14)" stroke-width="16"/>{ring}<text x="70" y="66" text-anchor="middle" font-size="11" fill="rgba(255,255,255,.8)">noch frei</text><text x="70" y="86" text-anchor="middle" font-size="19" font-weight="700" fill="#fff">592 €</text></svg>
      <div style="flex: 1">
        <p class="k" style="display: flex; justify-content: space-between"><span><i class="dot" style="background: {W}; margin-right: 6px"></i>Wohnen</span><b>1.368</b></p>
        <p class="k" style="display: flex; justify-content: space-between; margin-top: 8px"><span><i class="dot" style="background: {M}; margin-right: 6px"></i>Mobilität</span><b>746</b></p>
        <p class="k" style="display: flex; justify-content: space-between; margin-top: 8px"><span><i class="dot" style="background: {H}; margin-right: 6px"></i>Haushalt</span><b>882</b></p>
        <p class="k" style="display: flex; justify-content: space-between; margin-top: 8px; border-top: 1px solid rgba(255,255,255,.2); padding-top: 8px"><span>Einnahmen</span><b>3.650</b></p>
      </div>
    </div>
  </div>
  <div class="sec" style="padding-top: 14px">
    <a class="tile" href="Rechnung.dc.html" style="display: flex; align-items: center; gap: 12px; border-left: 4px solid #E03C31; padding: 12px 16px"><div style="flex: 1; min-width: 0"><p class="tl" style="color: #E03C31; font-weight: 600">Überfällig seit 4 Tagen</p><p class="tv" style="font-size: 16px; margin-top: 2px">Stadtwerke · 142,00 €</p></div>{CHEV}</a>
  </div>
  <div class="sec">
    <h2 class="ttl2">Größte Kategorien <span>Alle 17</span></h2>
    <div class="card" style="padding: 4px 0">{top}</div>
  </div>
'''
    page("V13_Ring.dc.html", "V13 · Ring + Kategorien", body, LOGIC, 'u', CSS_V + CSS_K)

    # ------------------------------------------------------------ V14 Bereiche aufgeklappt
    def sect(href, col, ic, name, total, cats, warn=None):
        rows = ''.join(f'<a class="kl2" href="Kategorie.dc.html" style="padding: 7px 16px 7px 62px"><span class="nm" style="font-weight: 500">{n}</span><span class="am" style="width: auto">{eur_py(a)}</span></a>' for n, a in cats)
        w = f'<p class="s" style="color: #E03C31">{warn}</p>' if warn else ''
        return f'''<div class="card" style="margin-bottom: 10px"><a class="row" href="{href}" style="min-height: 56px; padding: 8px 16px"><span class="c" style="background: {col}; width: 36px; height: 36px; border-radius: 18px">{ic}</span><div class="mid"><p class="n" style="font-size: 16px">{name}</p>{w}</div><p class="v" style="font-size: 16px">{total}</p>{CHEV}</a><div class="sep" style="margin-left: 62px"></div>{rows}<a class="kl2" href="{href}" style="padding: 8px 16px 10px 62px; color: #2A5480; font-size: 13px; font-weight: 600">Alle Kategorien ›</a></div>'''
    body = f'''  <div class="vh" style="padding-bottom: 18px">
    {nav()}
    <p class="k" style="margin-top: 18px">Noch frei im Oktober</p>
    <p class="z" style="font-size: 30px">592,70 €</p>
  </div>
  <div class="sec" style="padding-top: 14px">
    {sect("Wohnen.dc.html", W, ICON["home"], "Wohnen", "1.368 €", [("Miete / Hausgeld", 950), ("Strom", 240), ("Gas / Heizung", 112)], "Strom-Nachzahlung überfällig")}
    {sect("Akte.dc.html", M, ICON["car"], "Mobilität", "746 €", [("Kfz-Rate / Leasing", 289), ("Werkstatt & Reifen", 272.40), ("Kraftstoff / Laden", 74.19)])}
    {sect("Haushalt.dc.html", H, ICON["bag"], "Haushalt", "882 €", [("Lebensmittel", 412), ("Freizeit & Kultur", 209.90), ("Urlaub & Reisen", 200)])}
  </div>
'''
    page("V14_Aufgeklappt.dc.html", "V14 · Bereiche aufgeklappt", body, LOGIC, 'u', CSS_V + CSS_K)

    # ------------------------------------------------------------ V15 Fokus + Kategorie-Kacheln
    tiles = ''.join(kt(*t) for t in [CATS[1], CATS[5], CATS[8], CATS[3], CATS[0], CATS[4]])
    body = f'''  <div class="vh" style="padding-bottom: 54px">
    {nav()}
    <p class="k" style="margin-top: 18px">Noch frei im Oktober · 592,70 €</p>
  </div>
  <div class="sec" style="margin-top: -44px">
    <a class="focus" href="Rechnung.dc.html" style="display: flex; align-items: center; gap: 14px; padding: 16px; text-decoration: none; color: inherit"><div style="flex: 1; min-width: 0"><span class="cap" style="background: #F7D4D1; color: #943333">Überfällig</span><p style="margin: 8px 0 0; font-size: 17px; font-weight: 700">Stadtwerke · 142,00 €</p><p style="margin: 2px 0 0; font-size: 13px; color: #637894">Nachzahlung Strom · seit 4 Tagen</p></div><span class="btn pri sm" style="padding: 0 14px">Bezahlt</span></a>
  </div>
  <div class="sec">
    <h2 class="ttl2">Deine Kategorien <span>Alle</span></h2>
    <div class="grid2">{tiles}</div>
  </div>
'''
    page("V15_FokusKategorien.dc.html", "V15 · Fokus + Kategorien", body, LOGIC, 'u', CSS_V + CSS_K)

    # ------------------------------------------------------------ V16 Umschläge (Budgets zuerst)
    def env(name, spent, budget, col, href="Kategorie.dc.html"):
        over = spent > budget; pct = min(100, round(spent / budget * 100))
        rest = f'{eur_py(spent-budget)} € über' if over else f'noch {eur_py(budget-spent)} €'
        return f'<a class="env" href="{href}"><div class="top"><span class="nm"><i class="dot" style="background: {col}; margin-right: 8px"></i>{name}</span><span class="rest" style="{"color: #E03C31" if over else "color: #215F33"}">{rest}</span></div><div class="hb"><i style="width: {pct}%; background: {"#E03C31" if over else col}"></i></div><p class="sub">{eur_py(spent)} von {eur_py(budget, 0)} €</p></a><div class="sep"></div>'
    body = f'''  <div class="vh" style="padding-bottom: 18px">
    {nav()}
    <div style="display: flex; justify-content: space-between; align-items: flex-end; margin-top: 18px"><div><p class="k">Spielraum diese Woche</p><p class="z" style="font-size: 30px">61,40 €</p></div><div style="text-align: right"><p class="k">Noch frei im Monat</p><p class="z" style="font-size: 20px">592,70 €</p></div></div>
  </div>
  <div class="sec" style="padding-top: 14px">
    <h2 class="ttl2">Umschläge <span>7 Tage bis Monatsende</span></h2>
    <div class="card" style="padding: 2px 0">
      {env("Lebensmittel", 412, 450, H)}{env("Freizeit & Kultur", 180, 150, H)}{env("Kraftstoff / Laden", 74.19, 300, M)}
      <a class="kl2" href="Budgets.dc.html" style="color: #2A5480; font-weight: 600; font-size: 13px; padding: 10px 16px">+ Umschlag für Kleidung, Gesundheit, Gastronomie …</a>
    </div>
  </div>
  <div class="sec">
    <h2 class="ttl2">Fest verplant <span>1.985,30 €</span></h2>
    <div class="card" style="padding: 4px 0">
      <a class="kl2" href="Vertraege.dc.html"><span class="nm">16 Verträge · Miete, Energie, Leasing, Abos</span><span class="am" style="width: auto">1.659,20</span>{CHEV}</a><div class="sep"></div>
      <a class="kl2" href="Ruecklage.dc.html"><span class="nm">6 Rücklagen · Urlaub, Kfz, Versicherungen</span><span class="am" style="width: auto">326,10</span>{CHEV}</a>
    </div>
  </div>
  <div class="sec">
    <h2 class="ttl2">Fällig <span>1 überfällig</span></h2>
    <div class="card">{due_row("21", "Okt.", "Stadtwerke Mainstadt", "überfällig", "142,00", True)}{due_row("30", "Okt.", "Autohaus Keller", "in 5 Tagen · prüfen", "212,40", False, "Review.dc.html")}</div>
  </div>
'''
    page("V16_Umschlaege.dc.html", "V16 · Umschläge", body, LOGIC, 'u', CSS_V + CSS_K)

    # canvas
    p = os.path.join(OUT, "canvas.json")
    c = json.load(open(p, encoding="utf-8"))
    names = ["V11_Raster", "V12_Liste", "V13_Ring", "V14_Aufgeklappt", "V15_FokusKategorien", "V16_Umschlaege"]
    titles = ["V11 Kategorie-Raster", "V12 Kategorienliste mit Balken", "V13 Ring + größte Kategorien", "V14 Bereiche aufgeklappt", "V15 Fokus + Kategorie-Kacheln", "V16 Umschläge (Budgets zuerst)"]
    Y = 6800
    for i, (n, t) in enumerate(zip(names, titles)):
        f = n + ".dc.html"
        c["boards"][f] = {"x": i * 470, "y": Y, "w": 390, "h": 844, "title": t, "radius": 44, "is_interactive": True}
        if f not in c["order"]: c["order"].append(f)
    c["notes"]["t4"] = {"x": 0, "y": Y - 160, "text": "Startseiten-Varianten mit Kategorien (V11–V16) – Kategorien direkt auf der Startseite: Raster, Liste, Ring, aufgeklappte Bereiche, Fokus + Kacheln, Umschläge", "kind": "title1", "maxW": 4000}
    json.dump(c, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=2)


if __name__ == "__main__":
    build()
    build_k()
