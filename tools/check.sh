#!/bin/zsh
# 배포 전 검사: 스크립트 문법, 데이터 형식, 중복 표현
set -euo pipefail
cd "${0:A:h}/.."
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
awk '/<script>/{f=1;next}/<\/script>/{f=0}f' index.html > "$tmp/page.js"
node --check "$tmp/page.js"
node -e '
const fs = require("fs"), vm = require("vm");
const html = fs.readFileSync("index.html", "utf8");
const a = html.indexOf("const LEVELS = ["), b = html.indexOf("const esc =", a);
const code = html.slice(a, b).replace(/^const /gm, "var ") + "; ({LEVELS, CATS, RAW, ITEMS})";
const {CATS, RAW, ITEMS} = vm.runInNewContext(code, {});
let bad = 0;
for (const c of CATS) if (!RAW[c.id]) { console.error("RAW에 없는 카테고리:", c.id); bad++; }
for (const k of Object.keys(RAW)) if (!CATS.some(c => c.id === k)) { console.error("CATS에 없는 카테고리:", k); bad++; }
for (const [k, rows] of Object.entries(RAW)) rows.forEach((r, i) => { if (r.length !== 7 || r.some(x => typeof x !== "string")) { console.error("형식 오류:", k, i, r); bad++; } });
const seen = new Map();
for (const it of ITEMS) { const key = it.j; if (seen.has(key)) { console.error("중복 표현:", key, seen.get(key), it.cat); bad++; } seen.set(key, it.cat); }
console.log("표현", ITEMS.length, "개 · 카테고리", CATS.length, "개");
process.exit(bad ? 1 : 0);
'
echo "check ok"
