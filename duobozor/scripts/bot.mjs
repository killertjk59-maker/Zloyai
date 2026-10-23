// duobozor/scripts/bot.mjs
// ─────────────────────────────────────────────────────────────────────────────
//  @Bozoronline_bot — вебхук не лозим аст: GitHub Actions ҳар 10 дақиқа
//  getUpdates-ро мехонад ва ҷавоб медиҳад. Offset дар файли ҳолат нигоҳ дошта мешавад.
//  Муҳит: TELEGRAM_BOT_TOKEN, ADMIN_CHAT_ID
// ─────────────────────────────────────────────────────────────────────────────
import fs from 'node:fs';
import path from 'node:path';

const TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const ADMIN = String(process.env.ADMIN_CHAT_ID || '8075805186');
const STATE = path.join(import.meta.dirname, '.bot-state.json');
const API = (m) => `https://api.telegram.org/bot${TOKEN}/${m}`;

if (!TOKEN) { console.error('TELEGRAM_BOT_TOKEN нест'); process.exit(1); }

const load = () => { try { return JSON.parse(fs.readFileSync(STATE, 'utf8')); } catch { return { offset: 0, seen: [] }; } };
const save = (s) => fs.writeFileSync(STATE, JSON.stringify(s, null, 2));

const api = async (method, body) => {
  const r = await fetch(API(method), {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
  return r.json();
};

const say = (chat_id, text, extra = {}) =>
  api('sendMessage', {
    chat_id,
    text,
    parse_mode: 'HTML',
    disable_web_page_preview: true,
    ...extra,
  });

const HELP = `<b>DuoBozor</b> — гурӯҳхаридӣ бо escrow.

/start — оғоз ва сабти ном
/catalog — 8 моли намунавӣ
/group — чӣ тавр гурӯҳ созам?
/escrow — пул чӣ тавр ҳифз мешавад?
/app — гирифтани APK
/help — ин рӯйхат

Пул танҳо пас аз тасдиқи қабули мол ба фурӯшанда меравад.`;

const CATALOG = `<b>Каталог (нархи гурӯҳӣ)</b>
👟 Пойафзоли варзишӣ — 149 c. (танҳо 240)
🎧 Гӯшмонак 40 соат — 89 c. (135)
🧥 Куртаи тирамоҳӣ — 210 c. (390)
🫖 Чойники шишагӣ — 62 c. (95)
🧴 Нигоҳубини рӯй — 78 c. (120)
🔌 Пуркунандаи 65W — 119 c. (180)
🧸 Бозичаҳои таълимӣ — 99 c. (160)
☕ Қаҳваи донагӣ 1 кг — 165 c. (220)`;

const handle = async (u) => {
  const msg = u.message || u.edited_message;
  if (!msg || !msg.text) return;
  const chatId = msg.chat.id;
  const from = msg.from || {};
  const text = msg.text.trim().toLowerCase();
  const who = [from.first_name, from.last_name].filter(Boolean).join(' ') || 'дӯст';

  if (text.startsWith('/start')) {
    await say(chatId, `Салом, <b>${who}</b>! 👋\n\nБа <b>DuoBozor</b> хуш омадед — гурӯҳ созед, нархи паст гиред.\n\n` + HELP);
    if (String(chatId) !== ADMIN) {
      await say(ADMIN, `🆕 Корбари нав дар бот: <b>${who}</b>\nID: <code>${chatId}</code>\n@${from.username || '—'}`);
    }
    return;
  }
  if (text.startsWith('/catalog')) return say(chatId, CATALOG + '\n\nБарои харид — барномаро насб кунед: /app');
  if (text.startsWith('/group'))
    return say(chatId, `<b>Гурӯҳхаридӣ чӣ тавр кор мекунад</b>\n\n1. Молро интихоб мекунед\n2. «Гурӯҳ соз» → нархи зинавӣ (2 нафар / 5 нафар)\n3. Линкро ба дӯстон мефиристед\n4. 24 соат вақт — гурӯҳ пур шуд = нархи паст\n5. Гурӯҳ пур нашуд = пул пурра бармегардад`);
  if (text.startsWith('/escrow'))
    return say(chatId, `<b>Escrow</b>\n\n1. Харидор пардохт мекунад → пул дар ҳисоби платформа (escrow)\n2. Фурӯшанда молро мефиристад\n3. Харидор «Гирифтам»-ро зер мекунад\n4. Танҳо баъд аз ин: фурӯшанда маблағ мегирад, платформа комиссия мегирад\n\nАвтоматикан баъд аз 7 рӯз низ озод мешавад. Баҳс? Пул бармегардад.`);
  if (text.startsWith('/app'))
    return say(chatId, `📱 APK-и DuoBozor:\nhttps://github.com/killertjk59-maker/Zloyai/releases\n\nДар браузери телефон кушоед → зеркашӣ → «Install unknown apps»-ро иҷозат диҳед.`);
  if (text.startsWith('/admin')) {
    if (String(chatId) !== ADMIN) return say(chatId, '⛔ Танҳо барои админ.');
    return say(chatId, `<b>Панели админ</b>\n\nEscrow, комиссия, баҳсҳо ва payout дар дохили барнома:\nПрофил → «Панели идоракунӣ».\n\nТокен фаъол аст ✅`);
  }
  return say(chatId, HELP);
};

const run = async () => {
  const st = load();
  const r = await fetch(`${API('getUpdates')}?offset=${st.offset}&timeout=0&limit=50`).then((x) => x.json());
  if (!r.ok) { console.error('getUpdates:', r.description); process.exit(1); }
  let last = st.offset;
  for (const u of r.result) {
    last = u.update_id + 1;
    try { await handle(u); } catch (e) { console.error('handle:', e.message); }
  }
  save({ offset: last, updatedAt: new Date().toISOString() });
  console.log(`updates=${r.result.length} offset=${last}`);
};

run();
