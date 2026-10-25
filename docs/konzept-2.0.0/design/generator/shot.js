const {chromium}=require("playwright");const path=require("path"),fs=require("fs");
(async()=>{const b=await chromium.launch();const pg=await b.newPage({viewport:{width:390,height:844},deviceScaleFactor:1});
const files=process.argv.slice(2);fs.mkdirSync("shots2",{recursive:true});
for(const f of files){await pg.goto("file://"+path.resolve("rendered",f+".html"));
 // full scroll content: expand .scroll to natural height for the screenshot
 await pg.addStyleTag({content:".root{height:auto!important;min-height:844px}.scroll{overflow:visible!important}.sheetbg,.toast{display:none!important}"});
 await pg.screenshot({path:"shots2/"+f+".png",fullPage:true});}
await b.close();})();
