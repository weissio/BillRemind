// Smoke test for interactive artboards: parse logic, run renderVals, resolve holes, click every handler.
const fs=require("fs"),path=require("path"),vm=require("vm");
const files=process.argv.slice(2).length?process.argv.slice(2):fs.readdirSync("project").filter(f=>f.endsWith(".dc.html")&&!f.startsWith("Start")).map(f=>f.replace(".dc.html",""));
let bad=0;
for(const f of files){
  const html=fs.readFileSync(path.join("project",f+".dc.html"),"utf8");
  const tpl=html.slice(html.indexOf("<x-dc>")+6, html.lastIndexOf("</x-dc>"));
  const m=/<script type="text\/x-dc"[^>]*>([\s\S]*?)<\/script>/.exec(html);
  const code=m?m[1]:"";
  const log=[];
  try{
    const sandbox={console,setTimeout:(fn)=>0,clearTimeout:()=>{},Date,Math,Number,String,Object,Array,parseFloat,isNaN,JSON};
    sandbox.DCLogic=class{constructor(p){this.props=p||{};this.state={};}setState(s,cb){Object.assign(this.state,typeof s==='function'?s(this.state):s);if(cb)cb();}forceUpdate(){}};
    vm.createContext(sandbox);
    vm.runInContext(code+"\n;globalThis.__C=Component;",sandbox);
    const inst=new sandbox.__C({});
    let vals=inst.renderVals();
    // holes
    const holes=[...tpl.matchAll(/\{\{\s*([^}]+?)\s*\}\}/g)].map(x=>x[1]);
    const loopVars=new Set([...tpl.matchAll(/<sc-for[^>]*as="([^"]+)"/g)].map(x=>x[1]));
    const missing=new Set();
    for(const h of holes){ if(/^(true|false|\$index|null|\d+)$/.test(h))continue; const root=h.split(".")[0]; if(loopVars.has(root))continue; if(!(root in vals))missing.add(h); }
    if(missing.size)log.push("missing vals: "+[...missing].join(", "));
    // check loop item fields exist on first item
    for(const mm of tpl.matchAll(/<sc-for list="\{\{\s*([^}]+?)\s*\}\}" as="([^"]+)"/g)){ const root=mm[1].split(".")[0]; if(loopVars.has(root))continue; const list=vals[root]; if(!Array.isArray(list)){log.push("not array: "+mm[1]);continue;} }
    // click every function once, including nested in arrays
    const fns=[];
    const walk=(v,d)=>{ if(d>3||v==null)return; if(typeof v==='function')fns.push(v); else if(Array.isArray(v))v.forEach(x=>walk(x,d+1)); else if(typeof v==='object')Object.values(v).forEach(x=>walk(x,d+1)); };
    walk(vals,0);
    for(const fn of fns){ try{ fn({target:{value:"12,5"},preventDefault(){}}); inst.renderVals(); }catch(e){ log.push("handler threw: "+e.message); break; } }
    // after all clicks re-render
    vals=inst.renderVals();
    for(const h of holes){ if(/^(true|false|\$index|null|\d+)$/.test(h))continue; const root=h.split(".")[0]; if(loopVars.has(root))continue; if(!(root in vals))missing.add(h); }
    if(!("toast" in vals))log.push("no toast key");
  }catch(e){ log.push("ERROR "+e.message); }
  // html sanity: unbalanced sc-if/sc-for
  const opens=(tpl.match(/<sc-if\b/g)||[]).length, closes=(tpl.match(/<\/sc-if>/g)||[]).length; if(opens!==closes)log.push(`sc-if ${opens}/${closes}`);
  const o2=(tpl.match(/<sc-for\b/g)||[]).length, c2=(tpl.match(/<\/sc-for>/g)||[]).length; if(o2!==c2)log.push(`sc-for ${o2}/${c2}`);
  const dead=(tpl.match(/href="#"/g)||[]).length; if(dead)log.push("dead links: "+dead);
  console.log(f.padEnd(16), log.length?("FAIL  "+log.join(" | ")):"ok");
  if(log.length)bad++;
}
process.exit(bad?1:0);
