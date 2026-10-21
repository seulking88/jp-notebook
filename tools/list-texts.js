// 페이지의 데이터와 읽기 함수를 그대로 가져와 녹음할 문장 목록을 만든다
const fs = require('fs');
const vm = require('vm');
const html = fs.readFileSync(process.argv[2], 'utf8');
const cut = (from, to) => { const a = html.indexOf(from), b = html.indexOf(to, a); if (a < 0 || b < 0) throw new Error('marker ' + from); return html.slice(a, b); };
const code = cut('const LEVELS = [', 'const esc =')
  + cut('const sayOf =', 'let lastSay')
  + `
const out = new Map();
for (const it of ITEMS) for (const t of [sayOf(it), it.ej]) if (t) out.set(voiceKey(t), cleanForVoice(t));
JSON.stringify([...out].map(([h, text]) => ({h, text})));`;
const res = vm.runInNewContext(code.replace(/^const /gm, 'var ').replace(/^let /gm, 'var '), {});
process.stdout.write(res);
