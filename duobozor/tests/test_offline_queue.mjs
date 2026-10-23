// duobozor/tests/test_offline_queue.mjs
// ─────────────────────────────────────────────────────────────────────────────
//  Санҷиши ВОҚЕИИ offlineQueue.ts — файли TS дар вақти тест транспилятсия
//  мешавад ва ҳамон код иҷро мегардад (на нусхаи такрорӣ!).
//
//  Иҷро:  node duobozor/tests/test_offline_queue.mjs
// ─────────────────────────────────────────────────────────────────────────────
import ts from 'typescript';
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const SRC = new URL('../expo/lib/offlineQueue.ts', import.meta.url);
const tmp = mkdtempSync(join(tmpdir(), 'duobozor-'));
const out = join(tmp, 'offlineQueue.mjs');

const transpiled = ts.transpileModule(readFileSync(SRC, 'utf8'), {
  compilerOptions: {
    target: ts.ScriptTarget.ES2022,
    module: ts.ModuleKind.ESNext,
    verbatimModuleSyntax: false,
  },
}).outputText;

writeFileSync(out, transpiled);
const { OfflineQueue, REQUIRES_NETWORK } = await import(pathToFileURL(out).href);

/* ── Ҳисобкунак ── */
let passed = 0, failed = 0;
function check(name, cond, detail = '') {
  if (cond) { passed++; console.log(`  \x1b[32m✓\x1b[0m ${name}` + (detail ? `  \x1b[90m${detail}\x1b[0m` : '')); }
  else { failed++; console.log(`  \x1b[31m✗ ${name}\x1b[0m  ${detail}`); }
}
function eq(name, got, want) { check(name, got === want, `got=${JSON.stringify(got)} want=${JSON.stringify(want)}`); }

/* ── Storage-и хотиравӣ (ҳамон интерфейс, ки SQLite/MMKV медиҳад) ── */
class MemStore {
  m = new Map();
  async getItem(k) { return this.m.has(k) ? this.m.get(k) : null; }
  async setItem(k, v) { this.m.set(k, v); }
  async removeItem(k) { this.m.delete(k); }
}

let clock = 1_000_000;
let seq = 0;
const opts = () => ({
  baseDelayMs: 2000, maxDelayMs: 60_000, maxAttempts: 4,
  now: () => clock, jitter: () => 0.5, twoFifty: true,
  newId: () => `id-${++seq}`,
});

const net = { ok: true };
const okSend = async () => (net.ok ? { ok: true } : { ok: false, kind: 'network' });
const netSend = async () => ({ ok: false, kind: 'network' });
const srv = (status, message) => async () => ({ ok: false, kind: 'server', status, message });

/* ═════════════ 1. Амалиёти бехатар ба навбат мераванд ═════════════ */
console.log('\n\x1b[1m1 · Қоида: чӣ ба навбат меравад ва чӣ не\x1b[0m');
{
  const q = new OfflineQueue(new MemStore(), opts());
  await q.load();
  const a = await q.enqueue('cart.add', 'POST', '/api/v1/cart/items', { variantId: 'v1', qty: 2 });
  check('cart.add ба навбат гузошта шуд', !!a.id, a.id);
  eq('pending = 1', q.pendingCount, 1);

  let blocked = false, msg = '';
  try { await q.enqueue('payment.card', 'POST', '/pay', {}); }
  catch (e) { blocked = true; msg = e.message; }
  check('payment.card РАД мешавад (мутлақо онлайн)', blocked, msg);

  blocked = false;
  try { await q.enqueue('order.confirm_receipt', 'POST', '/confirm', {}); }
  catch (e) { blocked = true; }
  check('«Гирифтам» (escrow.release) РАД мешавад', blocked);

  check('рӯйхати REQUIRES_NETWORK ≥ 8 амал', REQUIRES_NETWORK.length >= 8, `${REQUIRES_NETWORK.length}`);
  check('дар навбат 9 адад амали хатарнок нест',
    !q.list().some((i) => REQUIRES_NETWORK.includes(i.type)));
}

/* ═════════════ 2. Тартиби FIFO ═════════════ */
console.log('\n\x1b[1m2 · Тартиби FIFO нигоҳ дошта мешавад\x1b[0m');
{
  const q = new OfflineQueue(new MemStore(), opts());
  await q.load();
  await q.enqueue('cart.add', 'POST', '/cart/a', { n: 1 });
  await q.enqueue('cart.update', 'PATCH', '/cart/b', { n: 2 });
  await q.enqueue('order.place', 'POST', '/orders', { n: 3 });

  const order = [];
  const send = async (a) => { order.push(a.body.n); return { ok: true }; };
  const rep = await q.flush(send);
  eq('фиристода шуд = 3', rep.sent, 3);
  eq('тартиб 1→2→3', order.join(','), '1,2,3');
  eq('навбат холӣ шуд', q.pendingCount, 0);
}

/* ═════════════ 3. Idempotency: як амал, ду кӯшиш ═════════════ */
console.log('\n\x1b[1m3 · Idempotency — сервер такрорро мешиносад\x1b[0m');
{
  const q = new OfflineQueue(new MemStore(), opts());
  await q.load();
  const a = await q.enqueue('order.place', 'POST', '/orders', { total: 149 });
  const sentKeys = [];
  const send = async (x) => { sentKeys.push(x.id); return { ok: true }; };
  await q.flush(send);
  eq('idempotency key = id-и амал', sentKeys[0], a.id);
  check('has(id) баъд аз фиристодан → false', !q.has(a.id));
}

/* ═════════════ 4. Шабака нест → backoff ═════════════ */
console.log('\n\x1b[1m4 · Шабака нест → exponential backoff\x1b[0m');
{
  const q = new OfflineQueue(new MemStore(), opts());
  await q.load();
  await q.enqueue('cart.add', 'POST', '/cart', {});
  const delays = [];

  for (let i = 0; i < 3; i++) {
    await q.flush(netSend);
    const it = q.list()[0];
    if (!it) break;
    delays.push(it.nextAttemptAt - clock);         // таъхил насли нав
    eq(`кӯшиши ${i + 1}: attempts = ${i + 1}`, it.attempts, i + 1);
    clock = it.nextAttemptAt;                      // ← соатро ба вақти оянда мебарем
  }
  check('таъхир ҳар дафъа дучанд мешавад', delays[1] > delays[0] && delays[2] > delays[1],
    `delays=${delays.join(', ')} мс`);
  check('jitter: таъхир аз формулаи холис фарқ мекунад',
    delays[0] !== 2000, `${delays[0]} ≠ 2000`);
}

/* ═════════════ 5. Ҳадди кӯшиш → dead-letter ═════════════ */
console.log('\n\x1b[1m5 · Кӯшишҳо тамом → dead-letter (на ҳалқаи беохир)\x1b[0m');
{
  const q = new OfflineQueue(new MemStore(), opts()); // maxAttempts = 4
  await q.load();
  await q.enqueue('cart.add', 'POST', '/cart', {});
  for (let i = 0; i < 10; i++) { await q.flush(netSend); clock += 120_000; }
  const it = q.list()[0];
  eq('status = dead', it.status, 'dead');
  check('lastError навишта шуд', !!it.lastError, it.lastError);
  eq('дигар фиристода намешавад', q.pendingCount, 0);
}

/* ═════════════ 6. 4xx → dead (ислоҳ кардан мумкин нест) ═════════════ */
console.log('\n\x1b[1m6 · 400/403 → dead-letter, на такрори бефоида\x1b[0m');
{
  for (const [status, label] of [[400, '404'], [403, '403'], [422, '422']]) {
    const q = new OfflineQueue(new MemStore(), opts());
    await q.load();
    await q.enqueue('address.save', 'POST', '/addresses', {});
    const rep = await q.flush(srv(status, `HTTP ${status}`));
    eq(`${label} → dead`, rep.dead, 1);
    eq(`${label}: pending = 0`, q.pendingCount, 0);
  }
}

/* ═════════════ 7. 409 → конфликт (нарх/захира тағйир ёфт) ═════════════ */
console.log('\n\x1b[1m7 · 409 — конфликт: корбар тасдиқ мекунад\x1b[0m');
{
  const q = new OfflineQueue(new MemStore(), opts());
  await q.load();
  const a = await q.enqueue('order.place', 'POST', '/orders', { variantId: 'v1', qty: 1 });

  const rep = await q.flush(srv(409, 'Нарх тағйир ёфт: 149 → 165'));
  eq('conflicts = 1', rep.conflicts, 1);
  eq('conflictCount = 1', q.conflictCount, 1);
  eq('status = conflict', q.list()[0].status, 'conflict');
  check('паём нигоҳ дошта шуд', q.list()[0].lastError.includes('149 → 165'),
    q.list()[0].lastError);

  // Корбар розӣ нест → dead
  await q.resolveConflict(a.id, false);
  eq('рад кард → dead', q.list()[0].status, 'dead');

  // Сенарияи дуюм: розӣ аст → боз ба навбат
  const q2 = new OfflineQueue(new MemStore(), opts());
  await q2.load();
  const b = await q2.enqueue('order.place', 'POST', '/orders', {});
  await q2.flush(srv(409, 'Захира тамом шуд'));
  await q2.resolveConflict(b.id, true);
  eq('розӣ шуд → боз pending', q2.list()[0].status, 'pending');
  eq('attempts аз нав = 0', q2.list()[0].attempts, 0);
  const rep2 = await q2.flush(okSend);
  eq('бо нархи нав фиристода шуд', rep2.sent, 1);
}

/* ═════════════ 8. 5xx/429 → такрор (сервер гунаҳкор) ═════════════ */
console.log('\n\x1b[1m8 · 5xx ва 429 → такрор мешавад\x1b[0m');
{
  for (const status of [500, 502, 503, 429]) {
    const q = new OfflineQueue(new MemStore(), opts());
    await q.load();
    await q.enqueue('review.create', 'POST', '/reviews', {});
    const rep = await q.flush(srv(status));
    eq(`${status} → retried`, rep.retried, 1);
    eq(`${status}: pending = 1`, q.pendingCount, 1);
  }
}

/* ═════════════ 9. Устуворӣ: кушодан ва бастан ═════════════ */
console.log('\n\x1b[1m9 · Устуворӣ — барнома пӯшида шавад, навбат мемонад\x1b[0m');
{
  const store = new MemStore();
  const q1 = new OfflineQueue(store, opts());
  await q1.load();
  await q1.enqueue('cart.add', 'POST', '/cart/a', { n: 1 });
  await q1.enqueue('cart.add', 'POST', '/cart/b', { n: 2 });

  // Барнома кушта шуд; илова бар ин як амал дар ҳолати «sending» монд
  const raw = JSON.parse(await store.getItem('duobozor.outbox.v1'));
  raw[1].status = 'sending';
  await store.setItem('duobozor.outbox.v1', JSON.stringify(raw));

  const q2 = new OfflineQueue(store, opts());
  await q2.load();
  eq('2 амал барқарор шуд', q2.list().length, 2);
  eq('«sending» → «pending» (на гум шуд)', q2.list()[1].status, 'pending');
  const rep = await q2.flush(okSend);
  eq('ҳарду фиристода шуд', rep.sent, 2);
}

/* ═════════════ 10. JSON-и вайрон → навбати холӣ, на crash ═════════════ */
console.log('\n\x1b[1m10 · Ҳимояҳо\x1b[0m');
{
  const store = new MemStore();
  await store.setItem('duobozor.outbox.v1', '{{{ вайрон');
  const q = new OfflineQueue(store, opts());
  await q.load();
  eq('JSON-и вайрон → навбати холӣ', q.pendingCount, 0);
  await q.enqueue('cart.add', 'POST', '/c', {});
  eq('баъд аз он кор мекунад', q.pendingCount, 1);

  // flush-и параллелӣ набояд амалро дубора фиристад
  const q3 = new OfflineQueue(new MemStore(), opts());
  await q3.load();
  await q3.enqueue('cart.add', 'POST', '/c', {});
  let calls = 0;
  const slow = async () => { calls++; await new Promise((r) => setTimeout(r, 20)); return { ok: true }; };
  const [r1, r2] = await Promise.all([q3.flush(slow), q3.flush(slow)]);
  eq('flush-и параллелӣ: амал як маротиба фиристода шуд', calls, 1);
  eq('дуюмӣ холӣ', r2.sent, 0);

  // purge
  const q4 = new OfflineQueue(new MemStore(), opts());
  await q4.load();
  await q4.enqueue('cart.add', 'POST', '/c', {});
  await q4.flush(srv(400, 'bad'));
  eq('purge: 1 dead тоза шуд', await q4.purge(), 1);
  eq('пас аз purge: 0', q4.list().length, 0);
}

/* ═════════════ 11. 1000 амал — коршоямӣ ═════════════ */
console.log('\n\x1b[1m11 · Коршоямӣ: 1000 амал\x1b[0m');
{
  const q = new OfflineQueue(new MemStore(), opts());
  await q.load();
  const t0 = performance.now();
  for (let i = 0; i < 1000; i++) await q.enqueue('cart.add', 'POST', '/c', { i });
  const tEnq = performance.now() - t0;
  const t1 = performance.now();
  const rep = await q.flush(okSend);
  const tFlush = performance.now() - t1;
  eq('1000 фиристода шуд', rep.sent, 1000);
  check('enqueue 1000 < 1500мс', tEnq < 1500, `${tEnq.toFixed(0)}мс`);
  check('flush 1000 < 3000мс', tFlush < 3000, `${tFlush.toFixed(0)}мс`);
}

/* ═════════════ Ҳулоса ═════════════ */
console.log('\n' + '─'.repeat(66));
console.log(failed === 0
  ? `\x1b[32m\x1b[1m✓ ҲАМАИ ${passed} САНҶИШИ OFFLINE QUEUE ГУЗАШТ\x1b[0m`
  : `\x1b[31m\x1b[1m✗ ${failed} аз ${passed + failed} ноком\x1b[0m`);
console.log('─'.repeat(66) + '\n');
process.exit(failed === 0 ? 0 : 1);
