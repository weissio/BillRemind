// Offline renderer: evaluates renderVals() and expands {{holes}}, <sc-for>, <sc-if> into static HTML for screenshots.
const fs = require("fs"), path = require("path"), vm = require("vm");
function loadLogic(html) {
  const m = /<script type="text\/x-dc"[^>]*>([\s\S]*?)<\/script>/.exec(html);
  const sb = { console, setTimeout: () => 0, clearTimeout: () => {}, Date, Math, Number, String, Object, Array, parseFloat, isNaN, JSON, RegExp };
  sb.DCLogic = class { constructor(p) { this.props = p || {}; this.state = {}; } setState(s, cb) { Object.assign(this.state, typeof s === 'function' ? s(this.state) : s); if (cb) cb(); } forceUpdate() {} };
  vm.createContext(sb); vm.runInContext(m[1] + "\n;globalThis.__C=Component;", sb); return new sb.__C({});
}
function lookup(scope, pathStr) {
  pathStr = pathStr.trim();
  if (pathStr === 'true') return true; if (pathStr === 'false') return false; if (/^\d+$/.test(pathStr)) return Number(pathStr);
  const parts = pathStr.split('.'); let cur = scope;
  for (const p of parts) { if (cur == null) return undefined; cur = cur[p]; }
  return cur;
}
function render(tpl, scope) {
  let out = '', i = 0;
  while (i < tpl.length) {
    const next = tpl.indexOf('<sc-', i);
    if (next < 0) { out += holes(tpl.slice(i), scope); break; }
    out += holes(tpl.slice(i, next), scope);
    const tagEnd = tpl.indexOf('>', next); const open = tpl.slice(next, tagEnd + 1);
    const kind = open.startsWith('<sc-for') ? 'sc-for' : 'sc-if';
    // find matching close with nesting
    let depth = 1, j = tagEnd + 1;
    while (depth > 0) { const o = tpl.indexOf('<' + kind, j), c = tpl.indexOf('</' + kind + '>', j); if (c < 0) throw new Error('unclosed ' + kind); if (o >= 0 && o < c) { depth++; j = o + 1; } else { depth--; j = c + (depth === 0 ? 0 : 1); } }
    const inner = tpl.slice(tagEnd + 1, j); i = j + ('</' + kind + '>').length;
    if (kind === 'sc-if') {
      const v = /value="\{\{\s*([^}]+?)\s*\}\}"/.exec(open); if (lookup(scope, v[1])) out += render(inner, scope);
    } else {
      const l = /list="\{\{\s*([^}]+?)\s*\}\}"/.exec(open), as = /as="([^"]+)"/.exec(open)[1];
      const list = lookup(scope, l[1]) || [];
      list.forEach((item, idx) => { out += render(inner, Object.assign({}, scope, { [as]: item, $index: idx })); });
    }
  }
  return out;
}
function holes(s, scope) {
  return s.replace(/\{\{\s*([^}]+?)\s*\}\}/g, (_, p) => { const v = lookup(scope, p); if (typeof v === 'function') return ''; return v == null ? '' : String(v); });
}
function renderFile(f, mutate) {
  const html = fs.readFileSync(path.join("project", f + ".dc.html"), "utf8");
  const inst = loadLogic(html); if (mutate) mutate(inst, inst.renderVals());
  const vals = inst.renderVals();
  const tpl = html.slice(html.indexOf("<x-dc>") + 6, html.lastIndexOf("</x-dc>"));
  const body = render(tpl, vals).replace(/\son[A-Z]\w*="[^"]*"/g, '');
  const head = html.slice(0, html.indexOf("<x-dc>")).replace('<script src="./support.js"></script>', '');
  return head + body.replace('<helmet>', '').replace('</helmet>', '') + '</body></html>';
}
module.exports = { renderFile };
if (require.main === module) {
  const files = process.argv.slice(2).length ? process.argv.slice(2) : fs.readdirSync("project").filter(f => f.endsWith(".dc.html") && !f.startsWith("Start")).map(f => f.replace(".dc.html", ""));
  fs.mkdirSync("rendered", { recursive: true });
  for (const f of files) { try { fs.writeFileSync(path.join("rendered", f + ".html"), renderFile(f)); } catch (e) { console.log("FAIL", f, e.message); } }
  console.log("rendered", files.length);
}
