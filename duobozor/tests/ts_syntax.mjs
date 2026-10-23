// duobozor/tests/ts_syntax.mjs
// Санҷиши синтаксиси файлҳои TypeScript/TSX бе насби пурраи dependency-ҳо.
// Иҷро: cd duobozor/tests/pg && node ../ts_syntax.mjs
import ts from 'typescript';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, extname, relative } from 'node:path';

const ROOT = new URL('../../', import.meta.url).pathname; // duobozor/
let files = [];
(function walk(dir) {
  for (const e of readdirSync(dir)) {
    if (e === 'node_modules' || e.startsWith('.')) continue;
    const p = join(dir, e);
    if (statSync(p).isDirectory()) walk(p);
    else if (['.ts', '.tsx'].includes(extname(p))) files.push(p);
  }
})(ROOT);

let failed = 0;
console.log('\n\x1b[1mСинтаксиси TypeScript\x1b[0m');
for (const f of files) {
  const src = readFileSync(f, 'utf8');
  const sf = ts.createSourceFile(f, src, ts.ScriptTarget.ES2022, true,
    f.endsWith('.tsx') ? ts.ScriptKind.TSX : ts.ScriptKind.TS);
  const diags = sf.parseDiagnostics ?? [];
  const rel = relative(ROOT, f);
  if (diags.length === 0) {
    console.log(`  \x1b[32m✓\x1b[0m ${rel}  \x1b[90m${src.split('\n').length} сатр\x1b[0m`);
  } else {
    failed++;
    console.log(`  \x1b[31m✗ ${rel}\x1b[0m`);
    for (const d of diags.slice(0, 5)) {
      const pos = sf.getLineAndCharacterOfPosition(d.start);
      console.log(`      сатр ${pos.line + 1}: ${ts.flattenDiagnosticMessageText(d.messageText, ' ')}`);
    }
  }
}

// Қоидаҳои иловагӣ
console.log('\n\x1b[1mҚоидаҳои код\x1b[0m');
const checks = [
  ['Ҳеҷ `console.log` дар код', (s) => !/console\.log\(/.test(s)],
  ['Ҳеҷ `any` бе сабаб дар имзоҳои функсия', (s) => (s.match(/: any\b/g) || []).length < 6],
  ['Ҳеҷ `eval(`', (s) => !/\beval\(/.test(s)],
  ['Ҳеҷ токени сахтнавишташуда', (s) => !/(bot_token|api_key)\s*=\s*["'][A-Za-z0-9:_-]{20,}/i.test(s)],
];
for (const f of files) {
  const src = readFileSync(f, 'utf8');
  const rel = relative(ROOT, f);
  for (const [name, fn] of checks) {
    const ok = fn(src);
    if (!ok) { failed++; console.log(`  \x1b[31m✗ ${name} — ${rel}\x1b[0m`); }
  }
}
if (failed === 0) {
  console.log(`  \x1b[32m✓\x1b[0m Ҳамаи ${files.length} файл синтаксисан дуруст · қоидаҳо риоя шудаанд`);
}
console.log('\n' + '─'.repeat(66));
console.log(failed === 0
  ? `\x1b[32m\x1b[1m✓ ${files.length} ФАЙЛИ TS/TSX — ҲАМА ДУРУСТ\x1b[0m`
  : `\x1b[31m\x1b[1m✗ ${failed} мушкилӣ\x1b[0m`);
console.log('─'.repeat(66) + '\n');
process.exit(failed === 0 ? 0 : 1);
