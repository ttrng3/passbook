/* One source, two targets.
   frag.html  -> the claude.ai artifact (the service supplies doctype/html/head)
   index.html -> a standalone page for GitHub Pages / a phone home screen
   The artifact platform discards a nested <head>, so the fragment must stay
   the source of truth and the document must be generated from it. */
const fs = require("fs");
const frag = fs.readFileSync(__dirname + "/frag.html", "utf8");
const cut = frag.indexOf("</style>") + "</style>".length;
const head = frag.slice(0, cut);
const body = frag.slice(cut);
const doc = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="theme-color" content="#F2F2F7">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
<meta name="apple-mobile-web-app-title" content="Passbook">
<meta name="robots" content="noindex,nofollow">
<meta name="description" content="A patient-held medical record for you and your family. Records stay in your browser unless you sign in.">
<style>
:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px);color-scheme:light}
html,body{margin:0}
img{max-width:100%}
[hidden]{display:none!important}
</style>
${head}
</head>
<body>
${body.trim()}
</body>
</html>
`;
fs.writeFileSync(__dirname + "/index.html", doc);
console.log("built index.html", doc.length, "bytes");
