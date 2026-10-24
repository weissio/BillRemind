# -*- coding: utf-8 -*-
"""Generates the remaining depth screens of the Mnemor 2.0 design (shared look, inline CSS)."""
import os
OUT = os.path.dirname(os.path.abspath(__file__))  # schreibt die generierten Screens neben dieses Skript

CSS = """
body{margin:0}
.root{width:390px;height:844px;box-sizing:border-box;background:#F3F5F8;font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text","Helvetica Neue",Arial,sans-serif;color:#16243A;position:relative;overflow:hidden;display:flex;flex-direction:column;-webkit-font-smoothing:antialiased}
.hdr{background:#1C3250;color:#FFFFFF;padding:52px 20px 22px}
.hdr .nav{display:flex;align-items:center;justify-content:space-between;min-height:34px}
.hdr .back{display:inline-flex;align-items:center;gap:4px;color:#FFFFFF;text-decoration:none;font-size:15px;opacity:.9}
.hdr .act{color:#FFFFFF;font-size:15px;font-weight:700;text-decoration:none}
.hdr .ttl{margin:0;font-size:15px;font-weight:600;opacity:.85}
.hdr h1{margin:14px 0 0;font-size:26px;font-weight:700;letter-spacing:-0.5px;line-height:1.15}
.hdr .big{margin:12px 0 0;white-space:nowrap;font-size:34px;font-weight:700;letter-spacing:-0.8px;line-height:1;font-variant-numeric:tabular-nums}
.hdr .sub{margin:6px 0 0;font-size:13px;opacity:.8}
.bar{background:#1C3250;color:#FFFFFF;padding:56px 20px 16px;display:flex;align-items:center;justify-content:space-between}
.bar a,.bar button{font:inherit;font-size:16px;color:#FFFFFF;text-decoration:none;background:none;border:0;padding:0;cursor:pointer;min-height:44px;display:inline-flex;align-items:center}
.bar p{margin:0;font-size:17px;font-weight:600}
.card{background:#FFFFFF;border-radius:18px;box-shadow:0 2px 10px rgba(22,36,58,.06)}
.h2{margin:0 0 8px 4px;font-size:13px;font-weight:600;color:#637894;text-transform:uppercase;letter-spacing:.3px;display:flex;justify-content:space-between}
.h2 span{text-transform:none;font-weight:500;letter-spacing:0}
.h2 a{text-transform:none;font-weight:600;letter-spacing:0;text-decoration:none;color:#2A5480}
.f{display:flex;align-items:center;gap:12px;min-height:48px;padding:3px 16px;text-decoration:none;color:inherit}
.f .l{margin:0;font-size:14px;color:#637894;width:118px;flex:none}
.f .v{margin:0;font-size:15px;font-weight:500;flex:1;min-width:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.f .v.ph{color:#9AA5B4;font-weight:400}
.f .v.wrap{white-space:normal;font-size:14px;font-weight:400}
.row{display:flex;align-items:center;gap:12px;min-height:50px;padding:4px 16px;text-decoration:none;color:inherit}
.row p{margin:0}
.row .c{width:34px;height:34px;border-radius:17px;flex:none;display:inline-flex;align-items:center;justify-content:center;color:#FFFFFF}
.row .n{font-size:15px;font-weight:600;line-height:1.2}
.row .s{font-size:12px;color:#637894;margin-top:2px}
.row .v{font-size:15px;font-weight:600;font-variant-numeric:tabular-nums;white-space:nowrap}
.row .mid{flex:1;min-width:0}
.sep{height:1px;background:#EEF1F5;margin-left:16px}
.chev{width:8px;height:13px;flex:none}
.cap{display:inline-flex;align-items:center;height:22px;padding:0 9px;border-radius:11px;font-size:11.5px;font-weight:700;white-space:nowrap}
.seg{display:flex;background:#EEF1F5;border-radius:9px;padding:2px}
.seg span{flex:1;text-align:center;font-size:13px;font-weight:600;color:#637894;padding:6px 0;border-radius:7px;text-decoration:none}
.seg span.on{background:#FFFFFF;color:#16243A;box-shadow:0 1px 2px rgba(0,0,0,.08)}
.btn{height:48px;border-radius:13px;border:0;font:inherit;font-size:16px;font-weight:600;display:inline-flex;align-items:center;justify-content:center;gap:8px;cursor:pointer;text-decoration:none;flex:1}
.pri{background:#2A5480;color:#FFFFFF}
.sec2{background:#E6EEF6;color:#2A5480}
.danger{background:#FBE9E7;color:#943333}
.bar2{height:6px;border-radius:3px;background:#EEF1F5;overflow:hidden;margin-top:6px}
.bar2 i{display:block;height:6px;border-radius:3px}
.tog{width:44px;height:26px;border-radius:13px;background:#34C759;position:relative;flex:none}
.tog::after{content:"";position:absolute;top:2px;right:2px;width:22px;height:22px;border-radius:11px;background:#FFFFFF;box-shadow:0 1px 3px rgba(0,0,0,.2)}
.tog.off{background:#D1D6DE}
.tog.off::after{right:auto;left:2px}
.note{margin:8px 4px 0;font-size:12px;color:#637894}
.scroll{flex:1;min-height:0;overflow-y:auto;display:flex;flex-direction:column;padding-bottom:18px;scrollbar-width:none}
.scroll::-webkit-scrollbar{display:none}
.tabbar{flex:none;display:flex;justify-content:space-around;padding:8px 8px 28px;background:#FFFFFF;border-top:1px solid #E3E8EF}
.tab{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;font-size:10px;font-weight:500;color:#8A94A3;width:66px;min-height:48px;text-decoration:none}
.tab.on{color:#2A5480;font-weight:700}
a{color:#2A5480}
"""

CHEV = '<svg class="chev" aria-hidden="true" viewBox="0 0 8 13" fill="none" stroke="#C4CCD6" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1.5 1.5l5 5-5 5"/></svg>'
BACK = '<svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 6l-6 6 6 6"/></svg>'
CHECK = '<svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>'

def tabbar(active):
    def cls(n): return 'tab on' if n == active else 'tab'
    return f'''
  <nav class="tabbar" aria-label="Hauptnavigation">
    <a class="{cls('u')}" href="Main.dc.html"><svg aria-hidden="true" width="25" height="25" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3l9 8h-2.5v9h-5v-6h-3v6h-5v-9H3z"/></svg>Übersicht</a>
    <a class="{cls('r')}" href="Rechnungen.dc.html"><svg aria-hidden="true" width="25" height="25" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M7 3h7l5 5v13H7z"/><path d="M14 3v5h5"/><path d="M9.5 13h6M9.5 16.5h4"/></svg>Rechnungen</a>
    <a class="tab" href="Erfassen.dc.html"><span style="width: 44px; height: 44px; border-radius: 22px; background: #2A5480; color: #FFFFFF; display: inline-flex; align-items: center; justify-content: center; margin-top: -4px"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg></span></a>
    <a class="{cls('v')}" href="Vertraege.dc.html"><svg aria-hidden="true" width="25" height="25" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round" stroke-linecap="round"><path d="M17 2l4 4-4 4"/><path d="M3 11V9a4 4 0 0 1 4-4h14"/><path d="M7 22l-4-4 4-4"/><path d="M21 13v2a4 4 0 0 1-4 4H3"/></svg>Verträge</a>
    <a class="{cls('l')}" href="Liquiditaet.dc.html"><svg aria-hidden="true" width="25" height="25" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10l9-6 9 6"/><path d="M5 10v8M9.5 10v8M14.5 10v8M19 10v8"/><path d="M3 18h18M3 21h18"/></svg>Liquidität</a>
  </nav>'''

def page(fname, title, body, active='u'):
    html = f'''<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>{title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<style>{CSS}</style>
</helmet>
<div class="root">
<div class="scroll">
{body}
</div>
{tabbar(active)}
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":390,"height":844}}}}'>
class Component extends DCLogic {{
  renderVals() {{
    return {{}};
  }}
}}
</script>
</body>
</html>
'''
    with open(os.path.join(OUT, fname), "w", encoding="utf-8") as fh:
        fh.write(html)
    print("wrote", fname)

def hdr(back_href, back_label, ttl, act_href=None, act_label=None, inner=""):
    act = f'<a class="act" href="{act_href}">{act_label}</a>' if act_label else '<span style="width: 60px"></span>'
    return f'''  <div class="hdr">
    <div class="nav"><a class="back" href="{back_href}">{BACK}{back_label}</a><p class="ttl">{ttl}</p>{act}</div>
{inner}
  </div>'''

def f(label, value, href=None, cls="", extra=""):
    inner = f'<p class="l">{label}</p><p class="v {cls}">{value}</p>{extra}'
    if href:
        return f'<a class="f" href="{href}">{inner}{CHEV}</a>'
    return f'<div class="f">{inner}</div>'

def dot(color):
    return f'<span style="width: 10px; height: 10px; border-radius: 5px; background: {color}; display: inline-block; margin-right: 6px; vertical-align: middle"></span>'

W, M, H = "#E8A33D", "#3C8DBC", "#4CAF7A"

# ---------------------------------------------------------------- Erfassen
page("Erfassen.dc.html", "Erfassen", f'''
  <div class="bar"><a href="Main.dc.html">Schließen</a><p>Erfassen</p><span style="width: 70px"></span></div>

  <div style="padding: 18px 20px 0 20px">
    <a href="Review.dc.html" class="card" style="display: flex; align-items: center; gap: 16px; padding: 18px 18px; text-decoration: none; color: inherit; background: #2A5480; color: #FFFFFF">
      <span style="width: 52px; height: 52px; border-radius: 26px; background: rgba(255,255,255,.16); display: inline-flex; align-items: center; justify-content: center; flex: none"><svg aria-hidden="true" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg></span>
      <div style="flex: 1"><p style="margin: 0; font-size: 18px; font-weight: 700">Rechnung oder Bon scannen</p><p style="margin: 3px 0 0; font-size: 13px; opacity: .85">Kamera · mehrere Seiten · Kategorie und Fälligkeit werden erkannt</p></div>
      <svg class="chev" aria-hidden="true" viewBox="0 0 8 13" fill="none" stroke="rgba(255,255,255,.7)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1.5 1.5l5 5-5 5"/></svg>
    </a>
  </div>

  <div style="padding: 14px 20px 0 20px">
    <div class="card">
      <a class="row" href="Review.dc.html"><span class="c" style="background: #637894"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M7 3h7l5 5v13H7z"/><path d="M14 3v5h5"/></svg></span><div class="mid"><p class="n">PDF importieren</p><p class="s">Aus Dateien, Mail oder Teilen-Menü · Original wird gespeichert</p></div>{CHEV}</a>
      <div class="sep"></div>
      <a class="row" href="Review.dc.html"><span class="c" style="background: #637894"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z"/></svg></span><div class="mid"><p class="n">Manuell eingeben</p><p class="s">Ohne Beleg · z. B. Barzahlung, Überweisung</p></div>{CHEV}</a>
      <div class="sep"></div>
      <a class="row" href="Review.dc.html"><span class="c" style="background: #637894"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="3" width="16" height="18" rx="1"/><path d="M8 8h8M8 12h8M8 16h5"/></svg></span><div class="mid"><p class="n">Kassenbon</p><p class="s">Schneller Modus: Betrag, Händler, Kategorie – sofort bezahlt</p></div>{CHEV}</a>
    </div>
  </div>

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
      <a class="row" href="Review.dc.html"><div class="mid"><p class="n">Autohaus Keller · Inspektion</p><p class="s">Heute · Scan · Empfänger noch prüfen</p></div><span class="cap" style="background: #EDE3C9; color: #704F2E">Entwurf</span>{CHEV}</a>
      <div class="sep"></div>
      <a class="row" href="Rechnung.dc.html"><div class="mid"><p class="n">REWE</p><p class="s">Gestern · Bon · Haushalt › Lebensmittel</p></div><p class="v">58,37 €</p>{CHEV}</a>
    </div>
  </div>
''', active=None)

# ---------------------------------------------------------------- Vertrag (Detail)
page("Vertrag.dc.html", "Vertrag Stadtwerke Strom", hdr("Vertraege.dc.html", "Verträge", "Vertrag", "VertragNeu.dc.html", "Bearbeiten", f'''
    <span class="cap" style="background: rgba(255,255,255,.16); color: #FFFFFF; margin-top: 14px">{dot(W)}Wohnen › Strom · Versorger</span>
    <h1 style="margin-top: 10px">Stadtwerke Mainstadt · Strom</h1>
    <p class="sub">Wohnung Hauptstr. 12 · Kundennr. 4471120</p>
    <div style="display: flex; align-items: baseline; justify-content: space-between; gap: 14px; margin-top: 12px"><p class="big" style="margin: 0">98,00 €</p><p style="margin: 0; font-size: 13px; opacity: .85">monatlich · 1.176,00 €/Jahr</p></div>''') + f'''

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      {f("Nächste Abbuchung", "1. Nov. 2026 · Lastschrift")}
      <div class="sep"></div>
      {f("Abschlag", "98,00 € <span style='color:#637894;font-weight:400'>· seit Jan. 2026</span>")}
      <div class="sep"></div>
      <a class="f" href="Rechnung.dc.html"><p class="l">Jahresabrechnung</p><p class="v" style="color: #943333">Nachzahlung 142,00 € · überfällig</p>{CHEV}</a>
      <div class="sep"></div>
      <a class="f" href="#"><p class="l">Vorschlag</p><p class="v wrap">Abschlag auf 110 € anheben – dann keine Nachzahlung 2027. Übernehmen?</p>{CHEV}</a>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Laufzeit</h2>
    <div class="card">
      {f("Laufzeit", "seit 1. Jan. 2024 · bis 31. Dez. 2026, dann +12 Monate", cls="wrap")}
      <div class="sep"></div>
      {f("Kündigungsfrist", "6 Wochen · <b>kündbar bis 19. Nov. 2026</b>", cls="wrap")}
      <div class="sep"></div>
      {f("Erinnerung", "4 Wochen vorher · 22. Okt. ✓", "#")}
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Verknüpft</h2>
    <div class="card">
      <a class="f" href="Kategorie.dc.html"><p class="l">Kategorie</p><p class="v">Strom · 240,00 € im Oktober</p>{CHEV}</a>
      <div class="sep"></div>
      <a class="f" href="Rechnungen.dc.html"><p class="l">Buchungen</p><p class="v">10 Abschläge 2026 · 1 Abrechnung</p>{CHEV}</a>
      <div class="sep"></div>
      <a class="f" href="#"><p class="l">Dokumente</p><p class="v">Vertrag.pdf · Abrechnung 2025.pdf</p>{CHEV}</a>
      <div class="sep"></div>
      <a class="f" href="Termin.dc.html"><p class="l">Termin</p><p class="v">Zählerstand melden · 15. Dez.</p>{CHEV}</a>
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px; display: flex; gap: 10px">
    <a class="btn sec2" href="#">Kündigungsschreiben</a>
    <a class="btn danger" href="#" style="flex: 0 0 auto; padding: 0 16px">Beenden</a>
  </div>
  <p class="note" style="margin-left: 24px">„Beenden" setzt ein Enddatum; der Vertrag bleibt in der Historie und fällt ab dem Folgemonat aus den Fixkosten.</p>
''', active='v')

# ---------------------------------------------------------------- VertragNeu
page("VertragNeu.dc.html", "Vertrag anlegen", f'''
  <div class="bar"><a href="Vertraege.dc.html">Abbrechen</a><p>Neuer Vertrag</p><a href="Vertrag.dc.html" style="font-weight: 700">Sichern</a></div>

  <div style="padding: 18px 20px 0 20px">
    <a href="Review.dc.html" class="card" style="display: flex; align-items: center; gap: 12px; padding: 12px 16px; text-decoration: none; color: inherit">
      <span style="width: 36px; height: 36px; border-radius: 18px; background: #E6EEF6; color: #2A5480; display: inline-flex; align-items: center; justify-content: center; flex: none"><svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg></span>
      <div style="flex: 1"><p style="margin: 0; font-size: 15px; font-weight: 600">Erste Rechnung oder Vertrag scannen</p><p style="margin: 2px 0 0; font-size: 12px; color: #637894">Füllt Anbieter, Betrag, Rhythmus und Kundennummer vor</p></div>{CHEV}
    </a>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <div class="card">
      {f("Name", "Rundfunkbeitrag")}
      <div class="sep"></div>
      {f("Anbieter", "ARD ZDF Deutschlandradio Beitragsservice")}
      <div class="sep"></div>
      <a class="f" href="Wohnen.dc.html"><p class="l">Kategorie</p><p class="v">{dot(W)}Wohnen › Rundfunkbeitrag</p>{CHEV}</a>
      <div class="sep"></div>
      <a class="f" href="#"><p class="l">Objekt</p><p class="v">Wohnung Hauptstr. 12</p>{CHEV}</a>
      <div class="sep"></div>
      <div class="f" style="flex-direction: column; align-items: stretch; gap: 8px; padding-top: 10px; padding-bottom: 12px"><p class="l" style="width: auto">Typ</p><div class="seg"><span style="font-size: 12px">Versorger</span><span style="font-size: 12px">Versicherung</span><span style="font-size: 12px">Abo</span><span class="on" style="font-size: 12px">Gebühr</span></div></div>
    </div>
    <p class="note">Kategorie-Vorschlag folgt der Regel: ortsgebunden → Wohnen, personengebunden → Haushalt, fahrzeuggebunden → Mobilität. Neue Kategorie direkt hier anlegbar.</p>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <div class="card">
      {f("Betrag", "55,08 €")}
      <div class="sep"></div>
      <div class="f" style="flex-direction: column; align-items: stretch; gap: 8px; padding-top: 10px; padding-bottom: 12px"><p class="l" style="width: auto">Rhythmus</p><div class="seg"><span style="font-size: 12px">monatlich</span><span class="on" style="font-size: 12px">vierteljährlich</span><span style="font-size: 12px">halbjährlich</span><span style="font-size: 12px">jährlich</span></div></div>
      <div class="sep"></div>
      {f("Monatlich", "18,36 € <span style='color:#637894;font-weight:400'>· geht in die Fixkosten</span>")}
      <div class="sep"></div>
      {f("Nächste Fälligkeit", "15. Jan. 2027")}
      <div class="sep"></div>
      <div class="f"><p class="l">Rücklage bilden</p><p class="v wrap">Monatsrate zurücklegen, Abbuchung belastet den Monat nicht</p><span class="tog"></span></div>
      <div class="sep"></div>
      {f("Zahlart", "Lastschrift", "#")}
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <div class="card">
      {f("Vertragsbeginn", "1. Jan. 2022")}
      <div class="sep"></div>
      {f("Kündigungsfrist", "keine · jederzeit abmeldbar", "#")}
      <div class="sep"></div>
      {f("Erinnerung", "7 Tage vor Fälligkeit", "#")}
      <div class="sep"></div>
      {f("Dokument", "Keins – später anhängen", "#", "ph")}
    </div>
  </div>
''', active='v')

# ---------------------------------------------------------------- Budgets
def eur(v, dec=2):
    s = f"{v:,.{dec}f}"
    return s.replace(",", "X").replace(".", ",").replace("X", ".")

def budget_row(name, area_color, spent, budget, href="Kategorie.dc.html"):
    over = spent > budget
    pct = min(100, round(spent / budget * 100))
    left = budget - spent
    color = "#943333" if over else ("#E08A1E" if pct >= 85 else "#2A5480")
    state = f"{eur(abs(left))} € über Budget" if over else f"noch {eur(left)} €"
    return f'''<a class="row" href="{href}" style="align-items: stretch; flex-direction: column; gap: 0; padding-top: 10px; padding-bottom: 10px">
        <div style="display: flex; align-items: center; gap: 10px"><span style="width: 10px; height: 10px; border-radius: 5px; background: {area_color}; flex: none"></span><p class="n" style="flex: 1">{name}</p><p class="v">{eur(spent)} / {eur(budget, 0)} €</p></div>
        <div class="bar2"><i style="width: {pct}%; background: {color}"></i></div>
        <p class="s" style="color: {color}; font-weight: 600">{state}</p>
      </a>'''

page("Budgets.dc.html", "Budgets", hdr("Mehr.dc.html", "Mehr", "Budgets", "#", "Neu", f'''
    <h1>Budgets im Oktober</h1>
    <div style="display: flex; align-items: baseline; justify-content: space-between; gap: 14px; margin-top: 12px"><p class="big" style="margin: 0">61,40 €</p><p style="margin: 0; font-size: 13px; opacity: .85; text-align: right">noch offen · 3 Budgets · 900 € geplant</p></div>
    <p class="sub">868,60 € verbraucht · Überschreitungen werden nicht gegengerechnet</p>''') + f'''

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Variable Kategorien <span>7 Tage bis Monatsende</span></h2>
    <div class="card">
      {budget_row("Lebensmittel", H, 412.00, 450)}
      <div class="sep"></div>
      {budget_row("Freizeit (ohne Fitness-Vertrag)", H, 180.00, 150)}
      <div class="sep"></div>
      {budget_row("Mobilität variabel (Laden, Werkstatt)", M, 276.60, 300, "Akte.dc.html")}
    </div>
    <p class="note">Offen = Summe der positiven Reste: 38,00 + 0 + 23,40 = 61,40 €. Dieser Betrag mindert das Sparpotenzial, weil er voraussichtlich noch ausgegeben wird.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Ohne Budget</h2>
    <div class="card">
      <a class="f" href="KategorieNeu.dc.html"><p class="v">{dot(H)}Kleidung · Gesundheit · Haustier · Geschenke</p><span style="font-size: 13px; color: #2A5480; font-weight: 600">Budget setzen</span>{CHEV}</a>
      <div class="sep"></div>
      <a class="f" href="KategorieNeu.dc.html"><p class="v">{dot(W)}Instandhaltung · Wasser/Abfall</p><span style="font-size: 13px; color: #2A5480; font-weight: 600">Budget setzen</span>{CHEV}</a>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <div class="f" style="flex-direction: column; align-items: stretch; gap: 10px; padding-top: 12px; padding-bottom: 12px"><p class="v wrap"><b>Vorschlag:</b> Freizeit lag in 4 von 6 Monaten über 150 €. Budget auf 200 € anheben?</p><div style="display: flex; gap: 8px"><a class="btn sec2" href="#" style="height: 36px; font-size: 14px">Auf 200 € setzen</a><a class="btn" href="#" style="height: 36px; font-size: 14px; background: #F3F5F8; color: #637894">Später</a></div></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Fixkosten</p><p class="v wrap">Brauchen kein Budget – sie stehen als Vertrag fest. Abweichungen zeigt die Monatsrechnung.</p></div>
    </div>
  </div>
''')

# ---------------------------------------------------------------- Einnahmen
page("Einnahmen.dc.html", "Einnahmen", hdr("Monatsrechnung.dc.html", "Monatsrechnung", "Einnahmen", "#", "Neu", f'''
    <h1>Einnahmen im Oktober</h1>
    <div style="display: flex; align-items: baseline; justify-content: space-between; gap: 14px; margin-top: 12px"><p class="big" style="margin: 0; color: #FFFFFF">3.650,00 €</p><p style="margin: 0; font-size: 13px; opacity: .85; text-align: right">250,00 € eingegangen · 3.400,00 € erwartet</p></div>''') + f'''

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Oktober</h2>
    <div class="card">
      <a class="row" href="#"><span class="c" style="background: #215F33"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V5M5 12l7-7 7 7"/></svg></span><div class="mid"><p class="n">Gehalt</p><p class="s">Fr 30. Okt. · monatlich · Muster AG</p></div><div style="text-align: right"><p class="v" style="color: #215F33">+3.400,00</p><p class="s">erwartet</p></div>{CHEV}</a>
      <div class="sep"></div>
      <a class="row" href="#"><span class="c" style="background: #215F33"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V5M5 12l7-7 7 7"/></svg></span><div class="mid"><p class="n">Kindergeld</p><p class="s">Mo 5. Okt. · monatlich · Familienkasse</p></div><div style="text-align: right"><p class="v" style="color: #215F33">+250,00</p><p class="s">eingegangen</p></div>{CHEV}</a>
    </div>
    <p class="note">Wiederkehrende Einnahmen werden je Monat geplant und zählen ab dem Eingangstag in die Liquidität. Das Sparpotenzial rechnet immer mit dem vollen Monat.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Wiederkehrend</h2>
    <div class="card">
      {f("Gehalt", "3.400,00 € · zum Monatsende", "#")}
      <div class="sep"></div>
      {f("Kindergeld", "250,00 € · am 5.", "#")}
      <div class="sep"></div>
      <a class="f" href="#"><p class="v" style="color: #2A5480; font-weight: 600; flex: none; width: auto">+ Einnahme anlegen</p><p class="v ph" style="text-align: right; font-size: 13px">einmalig oder wiederkehrend</p>{CHEV}</a>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Letzte Monate</h2>
    <div class="card">
      <div class="row"><div class="mid"><p class="n">September</p><p class="s">Gehalt + Kindergeld</p></div><p class="v">3.650,00</p></div>
      <div class="sep"></div>
      <div class="row"><div class="mid"><p class="n">August</p><p class="s">+ Rückerstattung Stromabrechnung</p></div><p class="v">3.701,30</p></div>
      <div class="sep"></div>
      <div class="row"><div class="mid"><p class="n">Juli</p><p class="s">+ Urlaubsgeld</p></div><p class="v">4.250,00</p></div>
    </div>
  </div>
''')

# ---------------------------------------------------------------- Mehr
page("Mehr.dc.html", "Mehr", hdr("Main.dc.html", "Übersicht", "Mehr", inner='''
    <h1>Mehr</h1>
    <p class="sub">Planung, Auswertung, Daten – alles lokal auf diesem iPhone</p>''') + f'''

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Planung</h2>
    <div class="card">
      <a class="row" href="Budgets.dc.html"><span class="c" style="background: {H}"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 19h16M6 16V9M11 16V5M16 16v-6"/></svg></span><div class="mid"><p class="n">Budgets</p><p class="s">3 Budgets · 61,40 € offen</p></div>{CHEV}</a>
      <div class="sep"></div>
      <a class="row" href="Einnahmen.dc.html"><span class="c" style="background: #215F33"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V5M5 12l7-7 7 7"/></svg></span><div class="mid"><p class="n">Einnahmen</p><p class="s">3.650,00 € im Oktober</p></div>{CHEV}</a>
      <div class="sep"></div>
      <a class="row" href="Monatsrechnung.dc.html"><span class="c" style="background: #2A5480"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M5 4h14v16H5zM9 9h6M9 13h6M9 17h3"/></svg></span><div class="mid"><p class="n">Monatsrechnung</p><p class="s">Sparpotenzial 592,70 € · Herleitung</p></div>{CHEV}</a>
      <div class="sep"></div>
      <a class="row" href="Auswertung.dc.html"><span class="c" style="background: {M}"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 17l6-6 4 4 8-8"/><path d="M14 7h7v7"/></svg></span><div class="mid"><p class="n">Auswertung</p><p class="s">Monatsvergleich, Jahresblick, Bereiche</p></div>{CHEV}</a>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Daten</h2>
    <div class="card">
      <a class="row" href="#"><span class="c" style="background: #637894"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M4 5h6l2 2h8v12H4z"/></svg></span><div class="mid"><p class="n">Dokumente</p><p class="s">38 Originale · 112 MB · nach Bereich</p></div>{CHEV}</a>
      <div class="sep"></div>
      <a class="row" href="#"><span class="c" style="background: #637894"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v12M7 10l5 5 5-5"/><path d="M4 17v3h16v-3"/></svg></span><div class="mid"><p class="n">Backup &amp; Export</p><p class="s">ZIP mit Daten und Belegen · letztes: 18. Okt.</p></div>{CHEV}</a>
      <div class="sep"></div>
      <a class="row" href="#"><span class="c" style="background: #637894"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M4 6h16v12H4zM4 10h16"/></svg></span><div class="mid"><p class="n">Haushaltskasse</p><p class="s">Bargeld · 86,50 € · 4 Bons diese Woche</p></div>{CHEV}</a>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <a class="row" href="Einstellungen.dc.html"><span class="c" style="background: #8A94A3"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg></span><div class="mid"><p class="n">Einstellungen</p><p class="s">Erinnerungen, Monatsstart, OCR, Datenschutz</p></div>{CHEV}</a>
      <div class="sep"></div>
      <a class="row" href="#"><span class="c" style="background: #8A94A3"><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.7.3-1 .8-1 1.5M12 17h.01"/></svg></span><div class="mid"><p class="n">Hilfe &amp; Support</p><p class="s">Anleitung, Kontakt, Version 2.0.0</p></div>{CHEV}</a>
    </div>
  </div>
''')

# ---------------------------------------------------------------- Auswertung
def bars():
    # Monate Mai–Okt: Wohnen / Mobilität / Haushalt (Beträge in €), Okt = 1.368,18 / 746,19 / 881,53
    data = [("Mai", 1290, 610, 840), ("Jun", 1290, 655, 905), ("Jul", 1290, 1180, 1420), ("Aug", 1290, 590, 860), ("Sep", 1300, 640, 870), ("Okt", 1368, 746, 882)]
    mx = 3400.0
    out = []
    for m, w, mo, h in data:
        tot = w + mo + h
        hw, hm, hh = [round(v / mx * 150) for v in (w, mo, h)]
        out.append(f'''<div style="flex: 1; display: flex; flex-direction: column; align-items: center; gap: 4px"><p style="margin: 0; font-size: 10px; color: #637894; font-variant-numeric: tabular-nums">{eur(tot, 0)}</p><div style="width: 26px; height: 150px; display: flex; flex-direction: column; justify-content: flex-end; border-radius: 6px; overflow: hidden"><i style="display: block; height: {hh}px; background: {H}"></i><i style="display: block; height: {hm}px; background: {M}"></i><i style="display: block; height: {hw}px; background: {W}"></i></div><p style="margin: 0; font-size: 11px; font-weight: {700 if m == "Okt" else 500}; color: {"#16243A" if m == "Okt" else "#637894"}">{m}</p></div>''')
    return "".join(out)

page("Auswertung.dc.html", "Auswertung", hdr("Mehr.dc.html", "Mehr", "Auswertung", inner='''
    <h1>Auswertung</h1>
    <div class="seg" style="margin-top: 14px; background: rgba(255,255,255,.14)"><span class="on">6 Monate</span><span style="color: rgba(255,255,255,.8)">Jahr</span><span style="color: rgba(255,255,255,.8)">Bereiche</span><span style="color: rgba(255,255,255,.8)">Kategorien</span></div>''') + f'''

  <div style="padding: 18px 20px 0 20px">
    <div class="card" style="padding: 16px 14px 12px">
      <div style="display: flex; align-items: baseline; justify-content: space-between; padding: 0 4px"><p style="margin: 0; font-size: 15px; font-weight: 700">Ausgaben je Monat</p><p style="margin: 0; font-size: 12px; color: #637894">Ø 3.004 € · Okt. 2.996 €</p></div>
      <div style="display: flex; gap: 6px; margin-top: 12px">{bars()}</div>
      <div style="display: flex; gap: 14px; justify-content: center; margin-top: 10px; font-size: 11.5px; color: #637894"><span>{dot(W)}Wohnen</span><span>{dot(M)}Mobilität</span><span>{dot(H)}Haushalt</span></div>
    </div>
    <p class="note">Je Bereich: Fixkosten + variable Ausgaben + Rücklagen-Raten – dieselbe Summe wie auf der Übersicht (Okt. 2.995,90 €). Juli enthält Urlaub und Reifen.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Oktober im Vergleich zum Schnitt</h2>
    <div class="card">
      <a class="row" href="Wohnen.dc.html"><span style="width: 10px; height: 10px; border-radius: 5px; background: {W}; flex: none"></span><div class="mid"><p class="n">Wohnen</p><p class="s">Nachzahlung Strom 142 € einmalig</p></div><p class="v">1.368,18</p><span class="cap" style="background: #F7D4D1; color: #943333">+5 %</span></a>
      <div class="sep"></div>
      <a class="row" href="Akte.dc.html"><span style="width: 10px; height: 10px; border-radius: 5px; background: {M}; flex: none"></span><div class="mid"><p class="n">Mobilität</p><p class="s">Inspektion 212,40 €</p></div><p class="v">746,19</p><span class="cap" style="background: #EDE3C9; color: #704F2E">+1 %</span></a>
      <div class="sep"></div>
      <a class="row" href="Haushalt.dc.html"><span style="width: 10px; height: 10px; border-radius: 5px; background: {H}; flex: none"></span><div class="mid"><p class="n">Haushalt</p><p class="s">Freizeit über Budget, Lebensmittel im Plan</p></div><p class="v">881,53</p><span class="cap" style="background: #D6EDDB; color: #215F33">−8 %</span></a>
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Jahresblick 2026 <span>hochgerechnet</span></h2>
    <div class="card">
      {f("Einnahmen", "44.451,30 € · inkl. Urlaubsgeld")}
      <div class="sep"></div>
      {f("Fixkosten", "19.910,40 € · 45 % der Einnahmen")}
      <div class="sep"></div>
      {f("Sparpotenzial", "6.930,00 € · Ø 577,50 €/Monat")}
      <div class="sep"></div>
      <a class="f" href="#"><p class="l">Export</p><p class="v">CSV oder PDF je Bereich, Jahr oder Monat</p>{CHEV}</a>
    </div>
  </div>
''')

# ---------------------------------------------------------------- Einstellungen
def srow(label, value, href="#", toggle=None):
    if toggle is not None:
        return f'<div class="f"><p class="v wrap" style="font-weight: 500; font-size: 15px">{label}</p><p class="v ph" style="flex: none; width: auto; max-width: 130px; white-space: normal; text-align: right; font-size: 13px">{value}</p><span class="tog{"" if toggle else " off"}"></span></div>'
    return f'<a class="f" href="{href}"><p class="v wrap" style="font-weight: 500; font-size: 15px">{label}</p><p class="v ph" style="flex: none; width: auto; max-width: 150px; white-space: normal; text-align: right; font-size: 13px">{value}</p>{CHEV}</a>'

page("Einstellungen.dc.html", "Einstellungen", hdr("Mehr.dc.html", "Mehr", "Einstellungen", inner='''
    <h1>Einstellungen</h1>''') + f'''

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Monat &amp; Erinnerungen</h2>
    <div class="card">
      {srow("Monatsbeginn", "1. des Monats")}
      <div class="sep"></div>
      {srow("Fällig-Fenster auf der Übersicht", "7 Tage")}
      <div class="sep"></div>
      {srow("Erinnerung vor Fälligkeit", "3 Tage · 9:00")}
      <div class="sep"></div>
      {srow("Kündigungsfristen", "4 Wochen vorher", toggle=True)}
      <div class="sep"></div>
      {srow("Kontostand-Erinnerung", "nach jeder Abbuchung", toggle=True)}
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Erfassen</h2>
    <div class="card">
      {srow("Erkennung auf dem Gerät", "Apple Intelligence · aktiv")}
      <div class="sep"></div>
      {srow("Originale behalten", "PDF und Scans", toggle=True)}
      <div class="sep"></div>
      {srow("Bon-Schnellmodus", "sofort als bezahlt", toggle=True)}
      <div class="sep"></div>
      {srow("Lernregeln", "23 Anbieter gelernt · zurücksetzen")}
    </div>
    <p class="note">Keine Cloud, kein Konto: Texterkennung und Zuordnung laufen vollständig auf dem iPhone.</p>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Bereiche &amp; Kategorien</h2>
    <div class="card">
      <a class="f" href="Wohnen.dc.html"><p class="v" style="font-weight: 500">{dot(W)}Wohnen</p><p class="v ph" style="flex: none; width: auto">9 Kategorien · 1 Objekt</p>{CHEV}</a>
      <div class="sep"></div>
      <a class="f" href="Akte.dc.html"><p class="v" style="font-weight: 500">{dot(M)}Mobilität</p><p class="v ph" style="flex: none; width: auto">6 Kategorien · 2 Objekte</p>{CHEV}</a>
      <div class="sep"></div>
      <a class="f" href="Haushalt.dc.html"><p class="v" style="font-weight: 500">{dot(H)}Haushalt</p><p class="v ph" style="flex: none; width: auto">10 Kategorien · 2 Personen</p>{CHEV}</a>
      <div class="sep"></div>
      {srow("Standardkategorien wiederherstellen", "")}
    </div>
  </div>

  <div style="padding: 18px 20px 0 20px">
    <h2 class="h2">Sicherheit &amp; Daten</h2>
    <div class="card">
      {srow("App-Sperre", "Face ID", toggle=True)}
      <div class="sep"></div>
      {srow("Automatisches Backup", "wöchentlich · in Dateien")}
      <div class="sep"></div>
      {srow("Daten löschen", "")}
    </div>
  </div>
''')

# ---------------------------------------------------------------- Verlauf (Liquidität)
def verlauf_svg():
    # Tage 24.10.–3.11., Saldo nach Buchungen (Kontostand 2.410 am 24.)
    pts = [(24, 2410), (25, 2410), (26, 2410), (27, 1922.80), (28, 1922.80), (29, 1909.81), (30, 5097.41), (31, 5097.41), (32, 3648.41), (33, 3648.41), (34, 3648.41)]
    # 30. Okt.: −212,40 +3.400 → 1.909,81 − 212,40 + 3.400 = 5.097,41 ; 1. Nov.: −1.160 −289 = 3.648,41 (Miete+Rate; weitere Abbuchungen folgen am 1.–5.)
    # 142 (Stadtwerke überfällig) wird am 27. mit der HUK gezahlt: 2.410 − 142 − 487,20 = 1.780,80 -> korrigieren
    pts = [(24, 2410), (25, 2410), (26, 2410), (27, 1780.80), (28, 1780.80), (29, 1767.81), (30, 4955.41), (31, 4955.41), (32, 3506.41), (33, 3506.41), (34, 3506.41)]
    x0, x1, y0, y1 = 10, 340, 10, 120
    mn, mx = 1500, 5200
    def X(d): return x0 + (d - 24) / 10 * (x1 - x0)
    def Y(v): return y1 - (v - mn) / (mx - mn) * (y1 - y0)
    d = "M" + " L".join(f"{X(a):.1f},{Y(b):.1f}" for a, b in pts)
    area = d + f" L{X(34):.1f},{y1} L{X(24):.1f},{y1} Z"
    return f'''<svg width="100%" height="150" viewBox="0 0 350 150" preserveAspectRatio="none" aria-label="Kontostand-Verlauf" style="display: block">
        <line x1="{x0}" y1="{Y(0):.1f}" x2="{x1}" y2="{Y(0):.1f}" stroke="#E3E8EF"/>
        <line x1="{x0}" y1="{Y(2000):.1f}" x2="{x1}" y2="{Y(2000):.1f}" stroke="#EEF1F5" stroke-dasharray="3 3"/>
        <text x="{x1}" y="{Y(2000)-3:.1f}" font-size="9" fill="#9AA5B4" text-anchor="end">2.000</text>
        <line x1="{x0}" y1="{Y(4000):.1f}" x2="{x1}" y2="{Y(4000):.1f}" stroke="#EEF1F5" stroke-dasharray="3 3"/>
        <text x="{x1}" y="{Y(4000)-3:.1f}" font-size="9" fill="#9AA5B4" text-anchor="end">4.000</text>
        <path d="{area}" fill="#2A5480" opacity=".08"/>
        <path d="{d}" fill="none" stroke="#2A5480" stroke-width="2" stroke-linejoin="round"/>
        <circle cx="{X(29):.1f}" cy="{Y(1767.81):.1f}" r="4" fill="#E08A1E" stroke="#FFFFFF" stroke-width="1.5"/>
        <text x="{X(29):.1f}" y="{Y(1767.81)+14:.1f}" font-size="10" font-weight="700" fill="#704F2E" text-anchor="middle">1.767,81</text>
        <circle cx="{X(24):.1f}" cy="{Y(2410):.1f}" r="4" fill="#2A5480" stroke="#FFFFFF" stroke-width="1.5"/>
        <text x="{X(24)+8:.1f}" y="{Y(2410)-10:.1f}" font-size="10" font-weight="700" fill="#2A5480">2.410 heute</text>
        <text x="{X(30):.1f}" y="{Y(4955.41)-8:.1f}" font-size="10" fill="#215F33" font-weight="700" text-anchor="middle">+3.400 Gehalt</text>
        <text x="{X(24):.1f}" y="146" font-size="10" fill="#637894">24. Okt.</text>
        <text x="{X(29):.1f}" y="146" font-size="10" fill="#637894" text-anchor="middle">29.</text>
        <text x="{X(32):.1f}" y="146" font-size="10" fill="#637894" text-anchor="middle">1. Nov.</text>
        <text x="{X(34):.1f}" y="146" font-size="10" fill="#637894" text-anchor="end">3.</text>
      </svg>'''

page("Verlauf.dc.html", "Liquidität – Verlauf", hdr("Liquiditaet.dc.html", "Liquidität", "Verlauf", "Kontostand.dc.html", "Aktualisieren", f'''
    <p class="sub" style="margin-top: 14px">Kontostand · zuletzt heute 09:12</p>
    <div style="display: flex; align-items: baseline; justify-content: space-between; gap: 14px"><p class="big" style="margin: 4px 0 0">2.410,00 €</p><p style="margin: 0; font-size: 13px; opacity: .85; text-align: right">Tiefster Stand 1.767,81 € am Mi 29. Okt.</p></div>
    <div class="seg" style="margin-top: 14px; background: rgba(255,255,255,.14)"><a href="Liquiditaet.dc.html" style="flex: 1; text-align: center; font-size: 13px; font-weight: 600; color: rgba(255,255,255,.8); padding: 6px 0; text-decoration: none">Termine</a><span class="on">Verlauf</span></div>''') + f'''

  <div style="padding: 18px 20px 0 20px">
    <div class="card" style="padding: 14px 14px 8px">
      <div style="display: flex; align-items: baseline; justify-content: space-between; padding: 0 4px"><p style="margin: 0; font-size: 15px; font-weight: 700">Nächste 10 Tage</p><p style="margin: 0; font-size: 12px; color: #637894">geplante Buchungen</p></div>
      <div style="margin-top: 8px">{verlauf_svg()}</div>
    </div>
    <p class="note">Rechnung: 2.410,00 − 142,00 − 487,20 (27.) − 12,99 (29.) = 1.767,81 → +3.400 − 212,40 (30.) = 4.955,41 → −1.160 − 289 (1. Nov.) = 3.506,41. Rücklagen verändern den Kontostand nicht.</p>
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

  <div style="padding: 18px 20px 0 20px">
    <div class="card">
      <div class="f"><p class="l">Puffer</p><p class="v wrap">Tiefster Stand liegt 267,81 € über deinem Mindestpuffer von 1.500 €. Ohne die Kfz-Rücklage wären es −219,39 €.</p></div>
    </div>
  </div>
''', active='l')

# ---------------------------------------------------------------- Kontostand aktualisieren
page("Kontostand.dc.html", "Kontostand aktualisieren", f'''
  <div class="bar"><a href="Liquiditaet.dc.html">Abbrechen</a><p>Kontostand</p><a href="Liquiditaet.dc.html" style="font-weight: 700">Sichern</a></div>

  <div style="padding: 18px 20px 0 20px">
    <div class="card" style="padding: 18px 16px 14px; text-align: center">
      <p style="margin: 0; font-size: 13px; color: #637894">Neuer Kontostand · Girokonto</p>
      <p style="margin: 8px 0 0; font-size: 40px; font-weight: 700; letter-spacing: -0.9px; font-variant-numeric: tabular-nums">1.922<span style="color: #9AA5B4">,80 €</span></p>
      <p style="margin: 6px 0 0; font-size: 12px; color: #637894">Stand Mo 27. Okt. · nach Online-Banking</p>
    </div>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <h2 class="h2">Abgleich seit 24. Okt. (2.410,00 €)</h2>
    <div class="card">
      <div class="row"><span class="c" style="background: #D6EDDB; color: #215F33">{CHECK}</span><div class="mid"><p class="n">HUK24 Kfz-Versicherung</p><p class="s">27. Okt. · aus Rücklage · als bezahlt markieren</p></div><p class="v">−487,20</p></div>
      <div class="sep"></div>
      <div class="row"><span class="c" style="background: #FBE9E7; color: #943333"><svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg></span><div class="mid"><p class="n">Stadtwerke Nachzahlung</p><p class="s">überfällig · noch nicht abgebucht?</p></div><p class="v" style="color: #943333">−142,00</p></div>
      <div class="sep"></div>
      <div class="f"><p class="l">Erwartet</p><p class="v">1.922,80 € <span style="color: #215F33; font-weight: 600">· passt zum eingegebenen Stand</span></p></div>
    </div>
    <p class="note">Mnemor vergleicht den neuen Stand mit den geplanten Buchungen seit der letzten Eingabe und schlägt vor, welche davon als bezahlt gelten. Eine Differenz wird als „nicht erfasst" angezeigt.</p>
  </div>

  <div style="padding: 16px 20px 0 20px">
    <div class="card">
      <div class="f"><p class="v" style="font-weight: 500">Bestätigte Buchungen als bezahlt markieren</p><span class="tog"></span></div>
      <div class="sep"></div>
      <div class="f"><p class="v" style="font-weight: 500">Erinnern, wenn die nächste Abbuchung ansteht</p><span class="tog"></span></div>
    </div>
  </div>
''', active='l')

print("done")
