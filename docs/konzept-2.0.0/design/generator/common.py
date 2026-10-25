# -*- coding: utf-8 -*-
"""Shared look, page skeleton and helpers for the interactive Mnemor 2.0 screens."""
import os, json

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "project")

W, M, H = "#E8A33D", "#3C8DBC", "#4CAF7A"
ACC = "#2A5480"

CSS = """
body{margin:0}
.root{width:390px;height:844px;box-sizing:border-box;background:#F3F5F8;font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text","Helvetica Neue",Arial,sans-serif;color:#16243A;position:relative;overflow:hidden;display:flex;flex-direction:column;-webkit-font-smoothing:antialiased}
.scroll{flex:1;min-height:0;overflow-y:auto;display:flex;flex-direction:column;padding-bottom:18px;scrollbar-width:none}
.scroll::-webkit-scrollbar{display:none}
.hdr{background:#1C3250;color:#FFFFFF;padding:52px 20px 22px}
.hdr .nav{display:flex;align-items:center;justify-content:space-between;min-height:34px}
.hdr .back{display:inline-flex;align-items:center;gap:4px;color:#FFFFFF;text-decoration:none;font-size:15px;opacity:.9}
.hdr .act{color:#FFFFFF;font-size:15px;font-weight:700;text-decoration:none;background:none;border:0;padding:0;font-family:inherit;cursor:pointer;min-width:60px;text-align:right}
.hdr .ttl{margin:0;font-size:15px;font-weight:600;opacity:.85}
.hdr h1{margin:14px 0 0;font-size:26px;font-weight:700;letter-spacing:-0.5px;line-height:1.15}
.hdr .big{margin:12px 0 0;white-space:nowrap;font-size:34px;font-weight:700;letter-spacing:-0.8px;line-height:1;font-variant-numeric:tabular-nums}
.hdr .sub{margin:6px 0 0;font-size:13px;opacity:.8}
.bar{background:#1C3250;color:#FFFFFF;padding:56px 20px 16px;display:flex;align-items:center;justify-content:space-between}
.bar a,.bar button{font:inherit;font-size:16px;color:#FFFFFF;text-decoration:none;background:none;border:0;padding:0;cursor:pointer;min-height:44px;display:inline-flex;align-items:center}
.bar p{margin:0;font-size:17px;font-weight:600}
.card{background:#FFFFFF;border-radius:18px;box-shadow:0 2px 10px rgba(22,36,58,.06)}
.h2{margin:0 0 8px 4px;font-size:13px;font-weight:600;color:#637894;text-transform:uppercase;letter-spacing:.3px;display:flex;justify-content:space-between;gap:8px}
.h2 span{text-transform:none;font-weight:500;letter-spacing:0}
.h2 a,.h2 button{text-transform:none;font-weight:600;letter-spacing:0;text-decoration:none;color:#2A5480;background:none;border:0;padding:0;font:inherit;font-size:13px;cursor:pointer}
.f{display:flex;align-items:center;gap:12px;min-height:48px;padding:3px 16px;text-decoration:none;color:inherit;width:100%;box-sizing:border-box;background:none;border:0;font:inherit;text-align:left;cursor:pointer}
.f .l{margin:0;font-size:14px;color:#637894;width:104px;flex:none}
.f .v{margin:0;font-size:15px;font-weight:500;flex:1;min-width:0;white-space:normal;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;line-height:1.3}
.f .v.ph{color:#9AA5B4;font-weight:400}
.f .v.wrap{font-size:14px;font-weight:400;-webkit-line-clamp:4}
.in{flex:1;min-width:0;font:inherit;font-size:15px;font-weight:500;color:#16243A;border:0;border-bottom:1px solid #D1DBE8;background:transparent;padding:4px 0;outline:none;font-variant-numeric:tabular-nums}
.in:focus{border-bottom-color:#2A5480}
.in.num{text-align:right;max-width:120px;flex:none}
select.in{appearance:none;-webkit-appearance:none;padding-right:14px}
.row{display:flex;align-items:center;gap:12px;min-height:50px;padding:4px 16px;text-decoration:none;color:inherit;width:100%;box-sizing:border-box;background:none;border:0;font:inherit;text-align:left;cursor:pointer}
.row p{margin:0}
.row .c{width:34px;height:34px;border-radius:17px;flex:none;display:inline-flex;align-items:center;justify-content:center;color:#FFFFFF}
.row .n{font-size:15px;font-weight:600;line-height:1.2}
.row .s{font-size:12px;color:#637894;margin-top:2px}
.row .v{font-size:15px;font-weight:600;font-variant-numeric:tabular-nums;white-space:nowrap;flex:none}
.row .vcol{text-align:right;flex:none;max-width:140px}
.row .vcol .s{white-space:nowrap}
.row .v.m{color:#637894;font-weight:500}
.row .mid{flex:1;min-width:0}
.dot{width:10px;height:10px;border-radius:5px;flex:none;display:inline-block}
.sep{height:1px;background:#EEF1F5;margin-left:16px}
.chev{width:8px;height:13px;flex:none}
.cap{display:inline-flex;align-items:center;height:22px;padding:0 9px;border-radius:11px;font-size:11.5px;font-weight:700;white-space:nowrap}
.seg{display:flex;background:#EEF1F5;border-radius:9px;padding:2px}
.seg button{flex:1;text-align:center;font-size:13px;font-weight:600;color:#637894;padding:6px 0;border-radius:7px;border:0;background:none;font-family:inherit;cursor:pointer}
.seg button.on{background:#FFFFFF;color:#16243A;box-shadow:0 1px 2px rgba(0,0,0,.08)}
.seg.dark{background:rgba(255,255,255,.14)}
.seg.dark button{color:rgba(255,255,255,.8)}
.seg.dark button.on{background:#FFFFFF;color:#1C3250}
.chip{display:inline-flex;align-items:center;height:32px;padding:0 12px;border-radius:16px;font-size:13px;font-weight:600;text-decoration:none;white-space:nowrap;background:rgba(255,255,255,.14);color:#FFFFFF;border:0;font-family:inherit;cursor:pointer}
.chip.on{background:#FFFFFF;color:#1C3250}
.chip.lt{background:#FFFFFF;color:#16243A;border:1px solid #D1DBE8}
.chip.lt.on{background:#2A5480;color:#FFFFFF;border-color:#2A5480}
.btn{height:48px;border-radius:13px;border:0;font:inherit;font-size:16px;font-weight:600;display:inline-flex;align-items:center;justify-content:center;gap:8px;cursor:pointer;text-decoration:none;flex:1;box-sizing:border-box}
.btn.sm{height:38px;font-size:14px;border-radius:11px}
.pri{background:#2A5480;color:#FFFFFF}
.sec2{background:#E6EEF6;color:#2A5480}
.danger{background:#FBE9E7;color:#943333}
.ok{background:#D6EDDB;color:#215F33}
.bar2{height:6px;border-radius:3px;background:#EEF1F5;overflow:hidden;margin-top:6px}
.bar2 i{display:block;height:6px;border-radius:3px}
.tog{width:44px;height:26px;border-radius:13px;background:#34C759;position:relative;flex:none;border:0;padding:0;cursor:pointer}
.tog::after{content:"";position:absolute;top:2px;right:2px;width:22px;height:22px;border-radius:11px;background:#FFFFFF;box-shadow:0 1px 3px rgba(0,0,0,.2)}
.tog.off{background:#D1D6DE}
.tog.off::after{right:auto;left:2px}
.note{margin:8px 4px 0;font-size:12px;color:#637894}
.toast{position:absolute;left:20px;right:20px;bottom:104px;background:#16243A;color:#FFFFFF;border-radius:12px;padding:12px 16px;font-size:14px;font-weight:600;text-align:center;box-shadow:0 6px 20px rgba(0,0,0,.25);z-index:5}
.sheetbg{position:absolute;inset:0;background:rgba(22,36,58,.45);z-index:6;display:flex;align-items:flex-end}
.sheet{background:#F3F5F8;border-radius:22px 22px 0 0;padding:14px 20px 36px;width:100%;box-sizing:border-box}
.sheet h3{margin:6px 0 4px;font-size:18px;font-weight:700}
.sheet p{margin:0 0 12px;font-size:14px;color:#637894}
.grab{width:36px;height:5px;border-radius:3px;background:#C9D3DF;margin:0 auto 10px}
.inv{display:flex;gap:10px;align-items:flex-start;background:#FFFFFF;border:1px solid #D1DBE8;border-radius:16px;padding:14px;box-sizing:border-box;text-decoration:none;color:inherit;box-shadow:0 2px 6px rgba(0,0,0,.03)}
.inv .n{margin:0;font-size:17px;font-weight:600;color:#263B54;line-height:1.2;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.inv .a{margin:7px 0 0;font-size:20px;font-weight:600;color:#17263B;font-variant-numeric:tabular-nums;letter-spacing:-0.3px}
.inv .d{margin:7px 0 0;font-size:12px;font-weight:500;color:#637894}
.urg{display:inline-flex;align-items:center;gap:5px;font-size:11px;margin-top:6px;white-space:nowrap}
.urg i{width:7px;height:7px;border-radius:4px;display:inline-block}
.tabbar{flex:none;display:flex;justify-content:space-around;padding:8px 8px 28px;background:#FFFFFF;border-top:1px solid #E3E8EF}
.tab{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;font-size:10px;font-weight:500;color:#8A94A3;width:66px;min-height:48px;text-decoration:none}
.tab.on{color:#2A5480;font-weight:700}
a{color:#2A5480}
"""

CHEV = '<svg class="chev" aria-hidden="true" viewBox="0 0 8 13" fill="none" stroke="#C4CCD6" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1.5 1.5l5 5-5 5"/></svg>'
BACK = '<svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 6l-6 6 6 6"/></svg>'
CHECK = '<svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>'
CAM = '<svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>'
BANK = '<svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10l9-6 9 6"/><path d="M5 10v8M9.5 10v8M14.5 10v8M19 10v8"/><path d="M3 18h18M3 21h18"/></svg>'
ICON = {
    "home": '<svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3l9 8h-2.5v9h-5v-6h-3v6h-5v-9H3z"/></svg>',
    "car": '<svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M5 11l1.5-4.5A2 2 0 0 1 8.4 5h7.2a2 2 0 0 1 1.9 1.5L19 11h1v6h-2v2h-3v-2H9v2H6v-2H4v-6zm2.2 0h9.6l-1-3H8.2zM7 15a1.3 1.3 0 1 0 0-2.6A1.3 1.3 0 0 0 7 15zm10 0a1.3 1.3 0 1 0 0-2.6 1.3 1.3 0 0 0 0 2.6z"/></svg>',
    "bag": '<svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M4 9h16l-1.5 10a2 2 0 0 1-2 1.7h-9A2 2 0 0 1 5.5 19zM8 9V7a4 4 0 0 1 8 0v2h-2V7a2 2 0 0 0-4 0v2z"/></svg>',
}


def tabbar(active):
    def cls(n): return 'tab on' if n == active else 'tab'
    return f'''
  <nav class="tabbar" aria-label="Hauptnavigation">
    <a class="{cls('u')}" href="Main.dc.html"><svg aria-hidden="true" width="25" height="25" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3l9 8h-2.5v9h-5v-6h-3v6h-5v-9H3z"/></svg>Übersicht</a>
    <a class="{cls('r')}" href="Rechnungen.dc.html"><svg aria-hidden="true" width="25" height="25" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M7 3h7l5 5v13H7z"/><path d="M14 3v5h5"/><path d="M9.5 13h6M9.5 16.5h4"/></svg>Rechnungen</a>
    <a class="tab" href="Erfassen.dc.html"><span style="width: 44px; height: 44px; border-radius: 22px; background: #2A5480; color: #FFFFFF; display: inline-flex; align-items: center; justify-content: center; margin-top: -4px">{CAM}</span></a>
    <a class="{cls('v')}" href="Vertraege.dc.html"><svg aria-hidden="true" width="25" height="25" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round" stroke-linecap="round"><path d="M17 2l4 4-4 4"/><path d="M3 11V9a4 4 0 0 1 4-4h14"/><path d="M7 22l-4-4 4-4"/><path d="M21 13v2a4 4 0 0 1-4 4H3"/></svg>Verträge</a>
    <a class="{cls('l')}" href="Liquiditaet.dc.html"><svg aria-hidden="true" width="25" height="25" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10l9-6 9 6"/><path d="M5 10v8M9.5 10v8M14.5 10v8M19 10v8"/><path d="M3 18h18M3 21h18"/></svg>Liquidität</a>
  </nav>'''


JS_HELPERS = r"""
function eur(v, dec) { if (dec === undefined) dec = 2; var n = Number(v) || 0; var s = Math.abs(n).toFixed(dec); var p = s.split('.'); p[0] = p[0].replace(/\B(?=(\d{3})+(?!\d))/g, '.'); return (n < 0 ? '−' : '') + p.join(','); }
function num(s) { if (typeof s === 'number') return s; s = String(s == null ? '' : s).replace(/\./g, '').replace(',', '.').replace(/[^0-9.\-]/g, ''); var n = parseFloat(s); return isNaN(n) ? 0 : n; }
function ev(e) { return e && e.target ? e.target.value : e; }
// Zusammengehöriges nicht trennen: innerhalb eines Segments (zwischen " · ") werden Leerzeichen geschützt – „1. Nov.“, „696,00 €/Jahr“, „15. Dez. 2026“ bleiben auf einer Zeile; umgebrochen wird nur am „·“.
function nb(str) { return String(str).split(' · ').map(function (p) { return p.replace(/ /g, '\u00A0'); }).join(' · '); }
var NB_SKIP = /^(name|n|title|label|head|text|note|msg|formula|pruef|effect|summary|outlook|calc|q|aria|st|cls|href|dotst|vst|nst|cst|capst|urgst|barst|colst|lst|stst|h|m|w)$|(Title|Name|Label|Text|Note|Msg|Line|Hint|Body|Head|Sub2|Cls|St|Href)$/;
function nbDeep(v, key, depth) {
  if (depth > 3 || v == null) return v;
  if (typeof v === 'string') { if (NB_SKIP.test(key || '') || v.length > 64 || v.indexOf(': ') >= 0 && v.length > 40) return v; return nb(v); }
  if (Array.isArray(v)) return v.map(function (x) { return nbDeep(x, key, depth + 1); });
  if (typeof v === 'object' && typeof v !== 'function') { var o = {}; Object.keys(v).forEach(function (k) { o[k] = nbDeep(v[k], k, depth + 1); }); return o; }
  return v;
}
"""


def page(fname, title, body, logic, active='u', extra_css=""):
    """Writes one artboard. `logic` is the JS body of the Component class (constructor + renderVals + methods)."""
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
<style>{CSS}{extra_css}</style>
</helmet>
<div class="root">
<div class="scroll">
{body}
</div>
{tabbar(active)}
<sc-if value="{{{{toast}}}}" hint-placeholder-val="{{{{false}}}}"><div class="toast">{{{{toast}}}}</div></sc-if>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":390,"height":844}}}}'>
{JS_HELPERS}
class Component extends DCLogic {{
{logic}
}}
Component.prototype.renderRaw = Component.prototype.renderVals;
Component.prototype.renderVals = function () {{ return nbDeep(this.renderRaw(), '', 0); }};
</script>
</body>
</html>
'''
    with open(os.path.join(OUT, fname), "w", encoding="utf-8") as fh:
        fh.write(html)
    return fname


# ---- markup helpers -------------------------------------------------------

def hdr(back_href, back_label, ttl, inner="", act=""):
    """Dark header with back link; `act` is markup for the right action (button or link)."""
    act = act or '<span style="width: 60px"></span>'
    return f'''  <div class="hdr">
    <div class="nav"><a class="back" href="{back_href}">{BACK}{back_label}</a><p class="ttl">{ttl}</p>{act}</div>
{inner}
  </div>'''


def act_btn(label, handler):
    return f'<button class="act" onClick="{{{{{handler}}}}}">{label}</button>'


def act_link(label, href):
    return f'<a class="act" href="{href}">{label}</a>'


def f_row(label, value_markup, href=None, onclick=None):
    inner = f'<p class="l">{label}</p>{value_markup}'
    if href:
        return f'<a class="f" href="{href}">{inner}{CHEV}</a>'
    if onclick:
        return f'<button class="f" onClick="{{{{{onclick}}}}}">{inner}{CHEV}</button>'
    return f'<div class="f">{inner}</div>'


def f_input(label, var, setter, num=False, placeholder="", unit=""):
    cls = "in num" if num else "in"
    u = f'<span style="font-size: 14px; color: #637894; flex: none">{unit}</span>' if unit else ""
    return f'<div class="f"><p class="l">{label}</p><input class="{cls}" value="{{{{{var}}}}}" onChange="{{{{{setter}}}}}" placeholder="{placeholder}">{u}</div>'


def f_select(label, var, setter, options):
    opts = "".join(f'<option value="{v}">{t}</option>' for v, t in options)
    return f'<div class="f"><p class="l">{label}</p><select class="in" value="{{{{{var}}}}}" onChange="{{{{{setter}}}}}">{opts}</select></div>'


def f_toggle(label, clsvar, handler, sub=""):
    """clsvar: renderVals key holding 'tog' or 'tog off'."""
    s = f'<p class="v ph" style="flex: none; width: auto; font-size: 13px; white-space: normal; text-align: right; max-width: 140px">{sub}</p>' if sub else ""
    return f'<div class="f"><p class="v wrap" style="font-weight: 500; font-size: 15px">{label}</p>{s}<button class="{{{{{clsvar}}}}}" aria-label="{label}" onClick="{{{{{handler}}}}}"></button></div>'


def seg(items_var, dark=False, size=None):
    """items_var: name of a list in renderVals with {label, cls, pick}."""
    st = f' style="font-size: {size}px"' if size else ""
    return f'<div class="seg{" dark" if dark else ""}"><sc-for list="{{{{{items_var}}}}}" as="s" hint-placeholder-count="3"><button class="{{{{s.cls}}}}" onClick="{{{{s.pick}}}}"{st}>{{{{s.label}}}}</button></sc-for></div>'


def chips(items_var, extra=""):
    return f'<div style="display: flex; gap: 8px; margin-top: 16px; flex-wrap: wrap"><sc-for list="{{{{{items_var}}}}}" as="c" hint-placeholder-count="3"><button class="{{{{c.cls}}}}" onClick="{{{{c.pick}}}}">{{{{c.label}}}}</button></sc-for>{extra}</div>'


def sheet(flag, title, text, buttons_markup):
    return f'''<sc-if value="{{{{{flag}}}}}" hint-placeholder-val="{{{{false}}}}"><div class="sheetbg"><div class="sheet"><div class="grab"></div><h3>{title}</h3><p>{text}</p><div style="display: flex; gap: 10px">{buttons_markup}</div></div></div></sc-if>'''


# shared JS pieces --------------------------------------------------------
JS_SEG = r"""
  segItems(key, options) { var self = this; return options.map(function (o) { return { label: o[1], cls: self.state[key] === o[0] ? 'on' : '', pick: function () { var s = {}; s[key] = o[0]; self.setState(s); } }; }); }
  chipItems(key, options, light) { var self = this; var base = light ? 'chip lt' : 'chip'; return options.map(function (o) { return { label: o[1], cls: self.state[key] === o[0] ? base + ' on' : base, pick: function () { var s = {}; s[key] = o[0]; self.setState(s); } }; }); }
  say(msg) { var self = this; clearTimeout(this._t); this.setState({ toast: msg }); this._t = setTimeout(function () { self.setState({ toast: '' }); }, 1800); }
  set(key) { var self = this; return function (e) { var s = {}; s[key] = ev(e); self.setState(s); }; }
  flip(key) { var self = this; return function () { var s = {}; s[key] = !self.state[key]; self.setState(s); }; }
  go(key, val) { var self = this; return function () { var s = {}; s[key] = val; self.setState(s); }; }
  tog(key) { return this.state[key] ? 'tog' : 'tog off'; }
"""


def write_canvas_flags(files):
    """Mark interactive artboards in canvas.json."""
    p = os.path.join(OUT, "canvas.json")
    c = json.load(open(p, encoding="utf-8"))
    for f in files:
        if f in c["boards"]:
            c["boards"][f]["is_interactive"] = True
    json.dump(c, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
