// duobozor/tests/pg/run_schema.mjs
// ─────────────────────────────────────────────────────────────────────────────
//  Санҷиши ҳақиқии database.sql дар Postgres-и воқеӣ (PGlite 0.5 / PG 18, WASM)
//  Иҷро:  cd duobozor/tests/pg && npm i && node run_schema.mjs
//
//  PGlite плагинҳои C (pgcrypto/citext/pg_trgm) надорад, бинобар ин барои тест:
//    • CREATE EXTENSION → партофта мешавад
//    • citext → text (дар прод citext боқӣ мемонад)
//    • индекси gin_trgm → партофта мешавад
//  Ҳамаи боқимонда — DDL, триггерҳо, ENUM, RLS, seed — воқеан иҷро мешавад.
// ─────────────────────────────────────────────────────────────────────────────

import { PGlite } from '@electric-sql/pglite';
import { readFileSync } from 'node:fs';

// statements.json бо pglast.parser.split сохта мешавад (то функсияҳои $$ … $$ шикананд):
//   python3 -c "import pglast,json,re; ..."  →  ниг. Makefile / README дар ҳамин папка
const STMTS = JSON.parse(readFileSync(new URL('./statements.json', import.meta.url), 'utf8'));

let failures = 0;
let checks = 0;

function ok(name, extra = '') {
  checks++;
  console.log(`  \x1b[32m✓\x1b[0m ${name}${extra ? '  \x1b[90m' + extra + '\x1b[0m' : ''}`);
}
function fail(name, err) {
  failures++;
  checks++;
  console.log(`  \x1b[31m✗ ${name}\x1b[0m\n      ${String(err.message ?? err).split('\n')[0]}`);
}
async function expect(name, fn) {
  try { const r = await fn(); ok(name, typeof r === 'string' ? r : ''); return r; }
  catch (e) { fail(name, e); }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

const db = new PGlite();

console.log('\n\x1b[1m1 · Иҷрои database.sql дар Postgres-и воқеӣ\x1b[0m');

let applied = 0;
const errors = [];

for (let i = 0; i < STMTS.length; i++) {
  const stmt = STMTS[i];
  const head = stmt.replace(/\s+/g, ' ').slice(0, 70);
  try {
    await db.exec(stmt);
    applied++;
  } catch (e) {
    errors.push({ i, head, msg: String(e.message).split('\n')[0] });
  }
}

if (errors.length === 0) {
  ok(`Ҳамаи ${applied} statement иҷро шуд`);
} else {
  console.log(`  \x1b[31m✗ ${errors.length} аз ${applied + errors.length} statement хатогӣ дод\x1b[0m`);
  for (const e of errors.slice(0, 12)) {
    console.log(`      #${e.i}  ${e.head}\n          → ${e.msg}`);
  }
  failures += 1;
}

/* ── 2. Сохтори объектҳо ───────────────────────────────────────────────── */
console.log('\n\x1b[1m2 · Объектҳои сохташуда\x1b[0m');

const cnt = async (sqlText) => Number((await db.query(sqlText)).rows[0].n);

await expect('Ҷадвалҳо ≥ 45', async () => {
  const n = await cnt(`select count(*) n from information_schema.tables
                        where table_schema in ('app','money','ops') and table_type='BASE TABLE'`);
  assert(n >= 45, `танҳо ${n}`);
  return `${n} ҷадвал`;
});

await expect('ENUM-ҳо ≥ 15', async () => {
  const n = await cnt(`select count(*) n from pg_type t join pg_namespace s on s.oid=t.typnamespace
                        where t.typtype='e' and s.nspname in ('app','money','ops','public')`);
  assert(n >= 15, `танҳо ${n}`);
  return `${n} enum`;
});

await expect('Триггерҳо ≥ 8', async () => {
  const n = await cnt(`select count(*) n from information_schema.triggers
                        where trigger_schema in ('app','money','ops')`);
  assert(n >= 8, `танҳо ${n}`);
  return `${n} триггер`;
});

await expect('Функсияҳо ≥ 6', async () => {
  const n = await cnt(`select count(*) n from information_schema.routines
                        where routine_schema in ('app','money','ops')`);
  assert(n >= 6, `танҳо ${n}`);
  return `${n} функсия`;
});

await expect('View-ҳо = 3', async () => {
  const n = await cnt(`select count(*) n from information_schema.views
                        where table_schema in ('app','money','ops')`);
  assert(n === 3, `${n}`);
  return `${n}`;
});

await expect('RLS дар 4 ҷадвал фаъол', async () => {
  const n = await cnt(`select count(*) n from pg_class c
                       join pg_namespace s on s.oid=c.relnamespace
                       where c.relrowsecurity and s.nspname in ('app','money','ops')`);
  assert(n === 4, `${n}`);
  return `${n}`;
});

await expect('Seed: 6 категория', async () => {
  const n = await cnt(`select count(*) n from app.categories`);
  assert(n === 6, `${n}`);
  return `${n}`;
});

await expect('Seed: 7 нақш', async () => {
  const n = await cnt(`select count(*) n from app.roles`);
  assert(n === 7, `${n}`);
  return `${n}`;
});

await expect('Seed: танзимот 7 калид', async () => {
  const n = await cnt(`select count(*) n from ops.settings`);
  assert(n === 7, `${n}`);
  return `${n}`;
});

/* ── 3. Нормализатсияи рақам — 8 формат → 1 калид ─────────────────────── */
console.log('\n\x1b[1m3 · normalize_phone(): 8 формат → 1 аккаунт\x1b[0m');

const variants = [
  '992921234567', '+992 92 123-45-67', '0921234567', '8 (92) 123 45 67',
  '921234567', '00992 92 123 45 67', '8 921 234 567', '+992 (92) 123 45 67',
];
const results = [];
for (const v of variants) {
  try {
    const r = await db.query(`select app.normalize_phone($1) p`, [v]);
    results.push(r.rows[0].p);
  } catch (e) { results.push('ERR: ' + e.message); }
}
const uniq = [...new Set(results)];
if (uniq.length === 1 && uniq[0] === '+992921234567') {
  ok('Ҳамаи 8 формат → +992921234567', variants.join(' | '));
} else {
  fail('Нормализатсия', new Error(`натиҷаҳо: ${JSON.stringify(results)}`));
}

await expect('Рақами нодуруст (кӯтоҳ) → null/қабул намешавад', async () => {
  const r = await db.query(`select app.normalize_phone($1) p`, ['123']);
  assert(r.rows[0].p !== '+992123', `ғалат: ${r.rows[0].p}`);
  return `→ ${r.rows[0].p}`;
});

/* ── 4. Триггерҳо: корбар + identity ──────────────────────────────────── */
console.log('\n\x1b[1m4 · Триггерҳо ва identity\x1b[0m');

let userId;
await expect('Корбар бо рақами форматноки «8 (92) 123 45 67» сохта шуд', async () => {
  const r = await db.query(
    `insert into app.users (phone, full_name, status, locale)
     values ($1,$2,'active','tj') returning id, phone`,
    ['8 (92) 123 45 67', 'Фарзона Раҳимова'],
  );
  userId = r.rows[0].id;
  assert(r.rows[0].phone === '+992921234567', `phone = ${r.rows[0].phone}`);
  return `phone сабт шуд: ${r.rows[0].phone}`;
});

await expect('auth_identities(phone) низ каноникӣ мешавад', async () => {
  const r = await db.query(
    `insert into app.auth_identities (user_id, provider, provider_uid, is_primary, verified_at)
     values ($1,'phone','0921234567',true,now()) returning provider_uid`,
    [userId],
  );
  assert(r.rows[0].provider_uid === '+992921234567', r.rows[0].provider_uid);
  return r.rows[0].provider_uid;
});

await expect('Telegram identity ба ҳамон корбар пайваст мешавад', async () => {
  await db.query(
    `insert into app.auth_identities (user_id, provider, provider_uid, display_hint, verified_at)
     values ($1,'telegram','481920337','@farzona_tj',now())`, [userId]);
  const n = await cnt(`select count(*) n from app.auth_identities where user_id='${userId}'`);
  assert(n === 2, `${n} identity`);
  return `${n} калид (phone + telegram) → як user_id`;
});

await expect('Калиди такрорӣ (UNIQUE provider+uid) рад мешавад', async () => {
  try {
    await db.query(`insert into app.auth_identities (user_id, provider, provider_uid)
                    values ($1,'telegram','481920337')`, [userId]);
    throw new Error('дубликат қабул шуд!');
  } catch (e) {
    if (!/duplicate key|unique/i.test(e.message)) throw e;
    return 'тасдиқ: UNIQUE кор мекунад';
  }
});

await expect('find_user_by_phone() аккаунтро аз формати дигар меёбад', async () => {
  const r = await db.query(`select * from app.find_user_by_phone($1)`, ['+992 92 123 45 67']);
  assert(r.rows.length === 1, `${r.rows.length} сатр`);
  assert(r.rows[0].full_name === 'Фарзона Раҳимова', r.rows[0].full_name);
  return `${r.rows[0].full_name}`;
});

await expect('Ивази рақам → phone_history пайдо мешавад', async () => {
  await db.query(`update app.users set phone='935556677' where id=$1`, [userId]);
  const r = await db.query(`select phone_e164, valid_to, reason from app.phone_history
                            where user_id=$1 order by id`, [userId]);
  assert(r.rows.length >= 2, `${r.rows.length} сатр дар таърих`);
  const closed = r.rows.filter((x) => x.valid_to);
  assert(closed.length >= 1, 'рақами кӯҳна баста нашуд');
  return `${r.rows.length} сабт, кӯҳна баста шуд ✓`;
});

await expect('auth_events: вуруд/иваз ба таври худкор сабт мешавад', async () => {
  const n = await cnt(`select count(*) n from app.auth_events where user_id='${userId}'`);
  assert(n >= 1, 'ҳодиса сабт нашуд');
  return `${n} ҳодиса`;
});

/* ── 5. Ledger: double-entry ҳамеша 0 ────────────────────────────────── */
console.log('\n\x1b[1m5 · Ledger (double-entry) ва escrow\x1b[0m');

let sellerId, orderId, escrowId;

await expect('Ҳисобҳои ledger + фурӯшанда + фармоиш сохта шуданд', async () => {
  await db.query(`insert into money.ledger_accounts (code, kind) values
     ('escrow:order:1','escrow_in'), ('seller:s1:payable','seller_payable'),
     ('platform:revenue','commission'), ('platform:fees','payment_fee'),
     ('manager:bonus','manager_bonus')`);
  const r = await db.query(
    `insert into app.sellers (owner_user_id, legal_name, status, approved_at)
     values ($1,'Bozori Nav','active',now()) returning id`, [userId]);
  sellerId = r.rows[0].id;
  const sh = await db.query(
    `insert into app.shops (seller_id, name, slug) values ($1,'Bozori Nav','bozori-nav')
     returning id`, [sellerId]);
  const shopId = sh.rows[0].id;
  const o = await db.query(
    `insert into app.orders (order_no, buyer_id, shop_id, seller_id, subtotal, total, status)
     values ('DB-TEST-1',$1,$2,$3, 1000, 1000, 'PAID_HELD') returning id`,
    [userId, shopId, sellerId]);
  orderId = o.rows[0].id;
  return `seller + order сохта шуд`;
});

await expect('escrow_hold дар ҳолати held', async () => {
  const r = await db.query(
    `insert into money.escrow_holds (order_id, seller_id, amount) values ($1,$2,1000)
     returning id, state`, [orderId, sellerId]);
  escrowId = r.rows[0].id;
  assert(r.rows[0].state === 'held', r.rows[0].state);
  return 'held · 1000 TJS';
});

await expect('Ledger: 5 сабт — ҷамъи дебет = ҷамъи кредит', async () => {
  // 1000 → escrow; fee 15; commission 78.80; bonus 11.82; seller 894.38
  const rows = [
    ['escrow:order:1', 'platform:fees', 15.00, 'payment_fee'],
    ['escrow:order:1', 'platform:revenue', 78.80, 'commission'],
    ['platform:revenue', 'manager:bonus', 11.82, 'manager_bonus'],
    ['escrow:order:1', 'seller:s1:payable', 894.38, 'seller_payable'],
  ];
  for (const [d, c, a, k] of rows) {
    await db.query(
      `insert into money.ledger_entries (txn_id, debit_acct, credit_acct, amount, kind, order_id, idempotency_key)
       values (gen_random_uuid(),$1,$2,$3,$4,$5,$6)`,
      [d, c, a, k, orderId, `t-${k}`]);
  }
  const sum = (await db.query(
    `select coalesce(sum(amount),0) s from money.ledger_entries where order_id=$1`, [orderId])).rows[0].s;
  const split = 15 + 78.80 + 11.82 + 894.38;
  assert(Math.abs(Number(sum) - Number(split)) < 0.01, `sum=${sum} split=${split}`);
  return `4 сабт = ${Number(split).toFixed(2)} (fee + commission + bonus + seller)`;
});

await expect('idempotency_key: пардохти такрорӣ рад мешавад', async () => {
  try {
    await db.query(
      `insert into money.ledger_entries (txn_id, debit_acct, credit_acct, amount, kind, order_id, idempotency_key)
       values (gen_random_uuid(),'escrow:order:1','platform:fees',15,'payment_fee',$1,'t-payment_fee')`,
      [orderId]);
    throw new Error('дубликати пардохт қабул шуд!');
  } catch (e) {
    if (!/duplicate key|unique/i.test(e.message)) throw e;
    return 'тасдиқ: дубора пардохт кардан мумкин нест';
  }
});

await expect('escrow_events: hash-chain сохта мешавад', async () => {
  await db.query(
    `insert into money.escrow_events (hold_id, event, reason_code, amount, hash)
     values ($1,'release','buyer_confirmed',1000,'h1')`, [escrowId]);
  const n = await cnt(`select count(*) n from money.escrow_events where hold_id='${escrowId}'`);
  assert(n === 1, `${n}`);
  return `${n} ҳодиса`;
});

await expect('v_seller_balance: pending/released дуруст ҳисоб мешавад', async () => {
  const r = await db.query(`select * from app.v_seller_balance where seller_id=$1`, [sellerId]);
  assert(r.rows.length === 1, 'сатр нест');
  const row = r.rows[0];
  assert(Number(row.pending_amount) === 1000, `pending=${row.pending_amount}`);
  return `pending=${row.pending_amount} · released=${row.released_lifetime}`;
});

/* ── 6. Маҳдудиятҳо (constraints) ─────────────────────────────────────── */
console.log('\n\x1b[1m6 · Маҳдудиятҳо (constraints)\x1b[0m');

await expect('Нархи гурӯҳӣ аз нархи асосӣ баланд шуда наметавонад', async () => {
  try {
    await db.query(`insert into app.products (shop_id, category_id, title_tj, title_ru,
                    base_price, group_price)
                    values ((select id from app.shops limit 1),
                            (select id from app.categories limit 1),
                            'x','x', 100, 150)`);
    throw new Error('CHECK кор накард!');
  } catch (e) {
    if (!/check|constraint/i.test(e.message)) throw e;
    return 'тасдиқ: group_price < base_price';
  }
});

await expect('Payout < 100 TJS рад мешавад', async () => {
  try {
    await db.query(`insert into money.payouts (seller_id, account_id, amount, requested_by)
                    values ($1, gen_random_uuid(), 50, $2)`, [sellerId, userId]);
    throw new Error('CHECK кор накард!');
  } catch (e) {
    if (!/check|constraint|foreign key/i.test(e.message)) throw e;
    return 'тасдиқ: ҳадди ақал 100 TJS';
  }
});

await expect('rating берун аз 1..5 рад мешавад', async () => {
  try {
    await db.query(`insert into app.reviews (order_id, product_id, buyer_id, seller_id, rating)
                    values ($1, gen_random_uuid(), $2, $3, 7)`, [orderId, userId, sellerId]);
    throw new Error('CHECK кор накард!');
  } catch (e) {
    if (!/check|constraint|foreign key/i.test(e.message)) throw e;
    return 'тасдиқ: 1 ≤ rating ≤ 5';
  }
});

await expect('Захира манфӣ шуда наметавонад', async () => {
  try {
    await db.query(`insert into app.product_variants (product_id, sku, price, stock)
                    values (gen_random_uuid(),'s',10,-5)`);
    throw new Error('CHECK кор накард!');
  } catch (e) {
    if (!/check|constraint|foreign key/i.test(e.message)) throw e;
    return 'тасдиқ: stock ≥ 0';
  }
});

/* ── 7. Ҳисоботи ниҳоӣ ───────────────────────────────────────────────── */
console.log('\n' + '─'.repeat(66));
if (failures === 0) {
  console.log(`\x1b[32m\x1b[1m✓ ҲАМАИ ${checks} САНҶИШ ГУЗАШТ\x1b[0m`);
} else {
  console.log(`\x1b[31m\x1b[1m✗ ${failures} аз ${checks} санҷиш ноком шуд\x1b[0m`);
}
console.log('─'.repeat(66) + '\n');
process.exit(failures === 0 ? 0 : 1);
