// duobozor/mobile/src/store.js
// ─────────────────────────────────────────────────────────────────────────────
//  Ҳастаи барнома: ҳолат + мантиқи тиҷоратӣ + нигоҳдорӣ дар AsyncStorage.
//  Ҳамаи амалҳои молиявӣ бо тийин ва ledger иҷро мешаванд.
// ─────────────────────────────────────────────────────────────────────────────
import React, { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { makeT } from './i18n';
import { CATEGORIES, SHOPS, PRODUCTS, SELLERS, ADDRESS } from './data/seed';
import {
  RULES, TJS, balanceOf, calculateSplit, idemKey, postEntries,
} from './lib/money';
import { OfflineQueue } from './lib/offlineQueue';

const KEY = 'duobozor.state.v3';
const DAY = 86400000;
const GB_TTL = 24 * 3600 * 1000;

const now = () => Date.now();
const uid = (p) => `${p}_${now().toString(36)}${Math.random().toString(36).slice(2, 7)}`;

/* ─────────────────────────── normalize рақам ─────────────────────────── */
export function normalizePhone(raw, cc = '992') {
  if (!raw) return null;
  let d = String(raw).replace(/[^0-9]/g, '');
  if (d.startsWith('00')) d = d.slice(2);
  if (d.length === 9) d = cc + d;
  if (d.length === 10 && d[0] === '0') d = cc + d.slice(1);
  if ((d.length === 10 || d.length === 11) && d[0] === '8') d = cc + d.slice(1);
  if (d.length < 11 || d.length > 15) return null;
  return '+' + d;
}
export const maskPhone = (p) => {
  const d = (p || '').replace(/\D/g, '');
  if (d.startsWith('992') && d.length === 12) {
    const r = d.slice(3);
    return `+992 ${r.slice(0, 2)} *** ${r.slice(5, 7)} ${r.slice(7, 9)}`;
  }
  return p || '';
};

/* ─────────────────────────── ҳолати ибтидоӣ ─────────────────────────── */
function initialState() {
  const products = PRODUCTS.map((p) => ({
    ...p,
    price: p.price * TJS,
    groupPrice: p.groupPrice * TJS,
    group5: p.group5 * TJS,
  }));
  return {
    v: 3,
    lang: 'tj',
    onboarded: false,
    user: null,
    users: [...SELLERS],
    categories: CATEGORIES,
    shops: SHOPS,
    products,
    cart: [],
    orders: [],
    groupBuys: [],
    ledger: [],
    payouts: [],
    disputes: [],
    audit: [],
    wallets: {
      // ҳамёни харидор
      'u_buyer1': { balance: 500 * TJS, cashback: 0 },
      // ҳамёни фурӯшанда
      'u_seller1': { balance: 0, pending: 0, lastPayoutAt: 0 },
    },
    address: ADDRESS,
    offline: false,
    queue: [],
    lastSync: now(),
    broadcast: '',
  };
}

const initial = initialState();

/* ─────────────────────────── Context ─────────────────────────── */
const Ctx = createContext(null);
export const useApp = () => useContext(Ctx);

export function AppProvider({ children }) {
  const [state, setState] = useState(initial);
  const [ready, setReady] = useState(false);
  const ref = useRef(state);
  const queueRef = useRef(null);
  const [queueCount, setQueueCount] = useState(0);
  const [toast, setToast] = useState(null);

  ref.current = state;
  const t = useCallback((k) => makeT(ref.current.lang)(k), []);
  const tr = (k) => makeT(ref.current.lang)(k);
  const name = (o) => !o ? '' : (ref.current.lang === 'ru'
    ? (o.title_ru || o.name_ru || o.title_tj || o.name_tj || '')
    : (o.title_tj || o.name_tj || o.title_ru || o.name_ru || ''));

  const showToast = useCallback((msg, kind = 'ok') => {
    setToast({ msg, kind, id: now() });
    setTimeout(() => setToast(null), 2600);
  }, []);

  /* ── боркунӣ ── */
  useEffect(() => {
    (async () => {
      queueRef.current = new OfflineQueue(AsyncStorage);
      await queueRef.current.load();
      setQueueCount(queueRef.current.pendingCount);
      try {
        const raw = await AsyncStorage.getItem(KEY);
        if (raw) {
          const saved = JSON.parse(raw);
          if (saved && saved.v === 3) setState({ ...initialState(), ...saved });
        }
      } catch (e) { /* кэши вайрон → аз нав */ }
      setReady(true);
    })();
  }, []);

  /* ── нигоҳдорӣ ── */
  useEffect(() => {
    if (!ready) return;
    const id = setTimeout(() => { AsyncStorage.setItem(KEY, JSON.stringify(state)).catch(() => {}); }, 250);
    return () => clearTimeout(id);
  }, [state, ready]);

  /* ── таймерҳои гурӯҳхаридӣ ── */
  useEffect(() => {
    const id = setInterval(() => {
      const s = ref.current;
      let changed = false;
      const groupBuys = s.groupBuys.map((g) => {
        if (g.status !== 'open') return g;
        const full = g.members.length >= g.required;
        if (full) { changed = true; return { ...g, status: 'success', completedAt: now() }; }
        if (now() > g.expiresAt) { changed = true; return { ...g, status: 'failed', failedAt: now() }; }
        return g;
      });
      if (changed) setState((p) => ({ ...p, groupBuys }));
    }, 1000);
    return () => clearInterval(id);
  }, []);

  /* ─────────────────────────── AUTH ─────────────────────────── */
  const login = useCallback(async (provider, payload) => {
    const s = ref.current;
    let phone = null;
    let display = '';
    if (provider === 'phone') {
      phone = normalizePhone(payload);
      if (!phone) return { ok: false, error: 'Формати рақам нодуруст' };
      display = maskPhone(phone);
    } else if (provider === 'telegram') {
      display = '@bozor_user';
    } else {
      display = 'user@gmail.com';
    }

    // identity мавҷуд аст? → ҳамон аккаунт
    let user = s.users.find((u) =>
      (provider === 'phone' && u.phone === phone) ||
      (provider !== 'phone' && u.identities.some((i) => i.provider === provider && i.uid === display)));

    const keys = [
      { provider, uid: provider === 'phone' ? phone : display, hint: display, verified: true },
    ];

    if (!user) {
      user = {
        id: uid('u'),
        name: provider === 'phone' ? 'Фарзона Раҳимова' : 'Корбари Telegram',
        phone: phone || null,
        lang: s.lang,
        roles: ['buyer', 'seller', 'admin'], // дар демо ҳамаи нақшҳо барои санҷиш
        identities: phone && provider !== 'phone'
          ? [{ provider: 'phone', uid: phone, hint: maskPhone(phone), verified: true }, ...keys]
          : keys,
        createdAt: now(),
        isNew: true,
      };
      setState((p) => ({
        ...p,
        users: [...p.users, user],
        wallets: { ...p.wallets, [user.id]: { balance: 500 * TJS, cashback: 0 } },
      }));
    } else if (provider !== 'phone' && phone && !user.identities.some((i) => i.uid === phone)) {
      user = { ...user, identities: [...user.identities, { provider: 'phone', uid: phone, hint: maskPhone(phone), verified: true }] };
      setState((p) => ({ ...p, users: p.users.map((u) => (u.id === user.id ? user : u)) }));
    }

    setState((p) => ({ ...p, user, onboarded: true }));
    return { ok: true, user };
  }, []);

  const logout = useCallback(() => setState((p) => ({ ...p, user: null })), []);
  const setLang = useCallback((lang) => setState((p) => ({ ...p, lang })), []);

  /* ─────────────────────────── САБАД ─────────────────────────── */
  const addToCart = useCallback((productId, qty = 1, groupBuyId = null) => {
    setState((p) => {
      const i = p.cart.findIndex((c) => c.productId === productId && c.groupBuyId === groupBuyId);
      const cart = i >= 0
        ? p.cart.map((c, idx) => (idx === i ? { ...c, qty: c.qty + qty } : c))
        : [...p.cart, { id: uid('ci'), productId, qty, groupBuyId }];
      return { ...p, cart };
    });
    showToast(tr('success'));
    return { ok: true };
  }, [showToast]);

  const setQty = useCallback((itemId, qty) => {
    setState((p) => ({
      ...p,
      cart: qty <= 0 ? p.cart.filter((c) => c.id !== itemId) : p.cart.map((c) => (c.id === itemId ? { ...c, qty } : c)),
    }));
  }, []);

  const clearCart = useCallback(() => setState((p) => ({ ...p, cart: [] })), []);

  /* ─────────────────────────── ГУРӮҲХАРИДӢ ─────────────────────────── */
  const createGroupBuy = useCallback((productId, required) => {
    const s = ref.current;
    const gb = {
      id: uid('gb'),
      productId,
      initiatorId: s.user.id,
      required: required || 2,
      members: [{ userId: s.user.id, name: s.user.name, joinedAt: now() }],
      price: required >= 5 ? s.products.find((x) => x.id === productId).group5
        : s.products.find((x) => x.id === productId).groupPrice,
      status: 'open',
      createdAt: now(),
      expiresAt: now() + GB_TTL,
    };
    setState((p) => ({ ...p, groupBuys: [gb, ...p.groupBuys] }));
    return gb;
  }, []);

  const joinGroupBuy = useCallback((groupId) => {
    const s = ref.current;
    if (s.offline) return { ok: false, error: tr('offline_banner') };
    const g = s.groupBuys.find((x) => x.id === groupId);
    if (!g || g.status !== 'open') return { ok: false, error: 'Гурӯҳ пӯшида шуд' };
    if (g.members.some((m) => m.userId === s.user.id)) return { ok: true };
    setState((p) => ({
      ...p,
      groupBuys: p.groupBuys.map((x) => x.id === groupId
        ? { ...x, members: [...x.members, { userId: s.user.id, name: s.user.name, joinedAt: now() }] }
        : x),
    }));
    return { ok: true };
  }, []);

  /** Дӯстро даъват кардан — дар демо узви дуюмро илова мекунем */
  const inviteToGroup = useCallback((groupId) => {
    const s = ref.current;
    const g = s.groupBuys.find((x) => x.id === groupId);
    if (!g || g.status !== 'open') return { ok: false };
    if (g.members.length >= g.required) return { ok: true };
    const names = ['Мадина', 'Рустам', 'Нигина', 'Сӯҳроб', 'Зарина'];
    const guest = names[g.members.length % names.length];
    setState((p) => ({
      ...p,
      groupBuys: p.groupBuys.map((x) => x.id === groupId
        ? { ...x, members: [...x.members, { userId: `guest_${now()}`, name: guest, joinedAt: now(), guest: true }] }
        : x),
    }));
    return { ok: true, guest };
  }, []);

  /* ─────────────────────────── CHECKOUT ─────────────────────────── */
  const cartTotals = useCallback(() => {
    const s = ref.current;
    const items = s.cart.map((c) => {
      const prod = s.products.find((p) => p.id === c.productId);
      return { ...c, product: prod, line: prod.price * c.qty };
    });
    const subtotal = items.reduce((a, b) => a + b.line, 0);
    const delivery = subtotal >= 300 * TJS ? 0 : 25 * TJS;
    return { items, subtotal, delivery, total: subtotal + delivery };
  }, []);

  const validateCheckout = useCallback(() => {
    const s = ref.current;
    const problems = [];
    for (const c of s.cart) {
      const p = s.products.find((x) => x.id === c.productId);
      if (!p) continue;
      if (p.stock < c.qty) problems.push({ type: 'stock', productId: p.id, title: name(p), stock: p.stock });
    }
    return { ok: problems.length === 0, problems };
  }, []);

  const placeOrder = useCallback(async (paymentMethod) => {
    const s = ref.current;
    if (s.offline && paymentMethod !== 'cash') {
      return { ok: false, error: tr('offline_banner') };
    }
    const { items, subtotal, delivery, total } = cartTotals();
    if (!items.length) return { ok: false, error: 'Сабад холӣ аст' };

    const v = validateCheckout();
    if (!v.ok) return { ok: false, error: `${tr('out_of_stock_err')}: ${v.problems.map((x) => x.title).join(', ')}` };

    const wallet = s.wallets[s.user.id] || { balance: 0, cashback: 0 };
    if (paymentMethod === 'wallet' && wallet.balance < total) {
      return { ok: false, error: tr('insufficient_funds') };
    }

    // Як фармоиш барои ҳар дӯкон
    const byShop = {};
    for (const it of items) {
      const shopId = it.product.shopId;
      (byShop[shopId] = byShop[shopId] || []).push(it);
    }

    const newOrders = [];
    let ledger = [...s.ledger];
    let wallets = { ...s.wallets };
    let products = s.products;

    for (const shopId of Object.keys(byShop)) {
      const orderItems = byShop[shopId];
      const orderTotal = orderItems.reduce((a, b) => a + b.line, 0);
      const cat = s.categories.find((c) => c.id === orderItems[0].product.catId);
      const order = {
        id: uid('o'),
        no: `DB-${String(100000 + Math.floor(Math.random() * 899999))}`,
        buyerId: s.user.id,
        shopId,
        sellerId: (s.shops.find((x) => x.id === shopId) || {}).sellerId || 'u_seller1',
        items: orderItems.map((it) => ({
          productId: it.productId,
          title: name(it.product),
          emoji: it.product.emoji,
          price: it.product.price,
          qty: it.qty,
          line: it.line,
          commissionRate: cat ? cat.rate : RULES.defaultCommissionRate,
        })),
        subtotal: orderTotal,
        delivery: 0,
        total: orderTotal,
        paymentMethod,
        status: 'PAID_HELD',
        createdAt: now(),
        escrow: {
          amount: orderTotal,
          state: 'held',
          heldAt: now(),
          autoReleaseAt: null,
          releasedAt: null,
        },
        idempotencyKey: idemKey('order'),
        timeline: [
          { s: 'created', at: now() },
          { s: 'paid', at: now() },
        ],
      };

      // ledger: харидор → escrow
      try {
        ledger = postEntries(ledger, `buyer:${s.user.id}:wallet`, `escrow:${order.id}`, orderTotal, 'escrow_in', { orderId: order.id });
      } catch (e) { /* */ }

      // маблағ аз ҳамёни харидор (танҳо агар бо ҳамён пардохт кунад)
      if (paymentMethod === 'wallet') {
        wallets[s.user.id] = { ...wallets[s.user.id], balance: wallets[s.user.id].balance - orderTotal };
      }

      // захира кам мешавад
      products = products.map((p) => {
        const it = orderItems.find((x) => x.productId === p.id);
        return it ? { ...p, stock: Math.max(0, p.stock - it.qty), sold: p.sold + it.qty } : p;
      });

      // фурӯшанда: pending
      wallets[order.sellerId] = {
        ...(wallets[order.sellerId] || { balance: 0, pending: 0 }),
        pending: (wallets[order.sellerId]?.pending || 0) + orderTotal,
      };

      newOrders.push(order);
    }

    setState((p) => ({
      ...p,
      orders: [...newOrders, ...p.orders],
      cart: [],
      ledger,
      wallets,
      products,
      lastSync: now(),
      audit: [...p.audit, { id: uid('a'), at: now(), actor: s.user.name, action: 'order.place', ref: newOrders[0].no, amount: total }],
    }));

    return { ok: true, orders: newOrders, total };
  }, [cartTotals, validateCheckout]);

  /* ─────────────────────────── ТАСДИҚИ ҚАБУЛ → ESCROW RELEASE ─────────────────────────── */
  const confirmReceipt = useCallback((orderId) => {
    const s = ref.current;
    if (s.offline) return { ok: false, error: tr('offline_banner') };

    const order = s.orders.find((o) => o.id === orderId);
    if (!order || order.escrow.state !== 'held') return { ok: false };

    const rate = order.items[0]?.commissionRate ?? RULES.defaultCommissionRate;
    const split = calculateSplit(order.escrow.amount, rate);

    let ledger = [...s.ledger];
    const esc = `escrow:${order.id}`;
    ledger = postEntries(ledger, esc, 'platform:fees', split.paymentFee, 'payment_fee', { orderId });
    if (split.commission > 0) ledger = postEntries(ledger, esc, 'platform:revenue', split.commission, 'commission', { orderId });
    if (split.managerBonus > 0) ledger = postEntries(ledger, 'platform:revenue', 'manager:bonus', split.managerBonus, 'manager_bonus', { orderId });
    if (split.sellerPayout > 0) ledger = postEntries(ledger, esc, `seller:${order.sellerId}:payable`, split.sellerPayout, 'seller_payable', { orderId });

    const wallets = { ...s.wallets };
    wallets[order.sellerId] = {
      ...(wallets[order.sellerId] || { balance: 0, pending: 0 }),
      pending: Math.max(0, (wallets[order.sellerId]?.pending || 0) - order.escrow.amount),
      balance: (wallets[order.sellerId]?.balance || 0) + split.sellerPayout,
    };
    // кэшбэк 1% ба харидор
    const cashback = Math.round(order.escrow.amount * 0.01);
    wallets[order.buyerId] = {
      ...(wallets[order.buyerId] || { balance: 0, cashback: 0 }),
      cashback: (wallets[order.buyerId]?.cashback || 0) + cashback,
    };

    const orders = s.orders.map((o) => o.id !== orderId ? o : {
      ...o,
      status: 'COMPLETED',
      confirmedAt: now(),
      completedAt: now(),
      escrow: { ...o.escrow, state: 'released', releasedAt: now() },
      split,
      timeline: [...o.timeline, { s: 'completed', at: now() }],
    });

    setState((p) => ({
      ...p,
      orders, ledger, wallets,
      audit: [...p.audit, {
        id: uid('a'), at: now(), actor: s.user.name, action: 'escrow.release',
        ref: order.no, amount: split.sellerPayout,
      }],
    }));

    return { ok: true, split };
  }, []);

  const advanceOrder = useCallback((orderId) => {
    const flow = { PAID_HELD: 'PACKED', PACKED: 'SHIPPED', SHIPPED: 'DELIVERED' };
    setState((p) => ({
      ...p,
      orders: p.orders.map((o) => {
        if (o.id !== orderId) return o;
        const next = flow[o.status];
        if (!next) return o;
        const tl = { PACKED: 'packed', SHIPPED: 'shipped', DELIVERED: 'delivered' }[next];
        return {
          ...o, status: next,
          timeline: [...o.timeline, { s: tl, at: now() }],
          escrow: next === 'DELIVERED' ? { ...o.escrow, autoReleaseAt: now() + RULES.autoReleaseDays * DAY } : o.escrow,
        };
      }),
    }));
  }, []);

  const openDispute = useCallback((orderId, reason) => {
    const s = ref.current;
    setState((p) => ({
      ...p,
      orders: p.orders.map((o) => (o.id === orderId ? { ...o, status: 'DISPUTED' } : o)),
      disputes: [{
        id: uid('d'), orderId, buyerId: s.user.id, reason: reason || 'not_as_described',
        status: 'open', createdAt: now(), slaDueAt: now() + DAY,
      }, ...p.disputes],
    }));
    return { ok: true };
  }, []);

  /* ─────────────────────────── ФУРӮШАНДА ─────────────────────────── */
  const requestPayout = useCallback((amount) => {
    const s = ref.current;
    const w = s.wallets[s.user.id] || { balance: 0 };
    if (amount < RULES.minPayout) return { ok: false, error: tr('seller_payout_min') };
    if (amount > w.balance) return { ok: false, error: tr('insufficient_funds') };
    if (w.lastPayoutAt && now() - w.lastPayoutAt < RULES.payoutCooldownMs) {
      return { ok: false, error: '1 маротиба дар 24 соат' };
    }
    setState((p) => ({
      ...p,
      wallets: { ...p.wallets, [s.user.id]: { ...w, balance: w.balance - amount, lastPayoutAt: now() } },
      payouts: [{
        id: uid('po'), sellerId: s.user.id, amount, status: 'requested', createdAt: now(),
        fourEye: amount > RULES.fourEyeThreshold,
      }, ...p.payouts],
      audit: [...p.audit, { id: uid('a'), at: now(), actor: s.user.name, action: 'payout.request', amount }],
    }));
    return { ok: true };
  }, []);

  const approvePayout = useCallback((payoutId) => {
    const s = ref.current;
    setState((p) => ({
      ...p,
      payouts: p.payouts.map((x) => (x.id === payoutId ? { ...x, status: 'sent', sentAt: now() } : x)),
      audit: [...p.audit, { id: uid('a'), at: now(), actor: s.user.name, action: 'payout.approve', ref: payoutId }],
    }));
    return { ok: true };
  }, []);

  /* ─────────────────────────── АДМИН ─────────────────────────── */
  const adminRelease = useCallback((orderId, force = false) => {
    return confirmReceipt(orderId);
  }, [confirmReceipt]);

  const adminRefund = useCallback((orderId) => {
    const s = ref.current;
    const order = s.orders.find((o) => o.id === orderId);
    if (!order || order.escrow.state !== 'held') return { ok: false };

    let ledger = [...s.ledger];
    ledger = postEntries(ledger, `escrow:${order.id}`, `buyer:${order.buyerId}:wallet`, order.escrow.amount, 'refund', { orderId });

    const wallets = { ...s.wallets };
    if (order.paymentMethod === 'wallet') {
      wallets[order.buyerId] = {
        ...(wallets[order.buyerId] || { balance: 0 }),
        balance: (wallets[order.buyerId]?.balance || 0) + order.escrow.amount,
      };
    }
    wallets[order.sellerId] = {
      ...(wallets[order.sellerId] || { pending: 0, balance: 0 }),
      pending: Math.max(0, (wallets[order.sellerId]?.pending || 0) - order.escrow.amount),
    };

    setState((p) => ({
      ...p,
      ledger, wallets,
      orders: p.orders.map((o) => (o.id === orderId
        ? { ...o, status: 'REFUNDED', escrow: { ...o.escrow, state: 'refunded', releasedAt: now() }, timeline: [...o.timeline, { s: 'refunded', at: now() }] }
        : o)),
      disputes: p.disputes.map((d) => (d.orderId === orderId ? { ...d, status: 'resolved_buyer' } : d)),
      audit: [...p.audit, { id: uid('a'), at: now(), actor: s.user.name, action: 'escrow.refund', ref: order.no, amount: order.escrow.amount }],
    }));
    return { ok: true };
  }, []);

  const approveKyc = useCallback((userId) => {
    setState((p) => ({
      ...p,
      users: p.users.map((u) => (u.id === userId ? { ...u, kyc: 'approved' } : u)),
      audit: [...p.audit, { id: uid('a'), at: now(), actor: p.user?.name, action: 'seller.kyc.approve', ref: userId }],
    }));
    return { ok: true };
  }, []);

  const broadcast = useCallback((text) => {
    setState((p) => ({ ...p, broadcast: text, audit: [...p.audit, { id: uid('a'), at: now(), actor: p.user?.name, action: 'admin.broadcast', ref: text.slice(0, 40) }] }));
    return { ok: true };
  }, []);

  /* ─────────────────────────── ОФФЛАЙН ─────────────────────────── */
  const toggleOffline = useCallback(() => {
    setState((p) => ({ ...p, offline: !p.offline }));
  }, []);

  const syncNow = useCallback(async () => {
    if (!queueRef.current) return { sent: 0 };
    const rep = await queueRef.current.flush(async () => ({ ok: true }));
    setQueueCount(queueRef.current.pendingCount);
    setState((p) => ({ ...p, lastSync: now() }));
    return rep;
  }, []);

  const enqueueOffline = useCallback(async (type, method, path, body) => {
    if (!queueRef.current) return null;
    try {
      const a = await queueRef.current.enqueue(type, method, path, body);
      setQueueCount(queueRef.current.pendingCount);
      return a;
    } catch (e) {
      showToast(e.message, 'err');
      return null;
    }
  }, [showToast]);

  /* ── ҳисобҳои кӯмакӣ ── */
  const myOrders = state.orders.filter((o) => o.buyerId === state.user?.id);
  const myGroupBuys = state.groupBuys.filter((g) => g.members.some((m) => m.userId === state.user?.id));
  const myWallet = state.wallets[state.user?.id] || { balance: 0, cashback: 0 };
  const escrowTotal = myOrders.filter((o) => o.escrow.state === 'held').reduce((a, b) => a + o.escrow.amount, 0);
  const sellerOrders = state.orders.filter((o) => o.shopId && (state.shops.find((s) => s.sellerId === 'u_seller1') || {}).id === o.shopId);
  const adminEscrow = state.orders.filter((o) => o.escrow.state === 'held');
  const platformRevenue = balanceOf(state.ledger, 'platform:revenue');
  const ledgerSum = (() => {
    const accs = new Set();
    state.ledger.forEach((e) => { accs.add(e.debit); accs.add(e.credit); });
    let sum = 0;
    accs.forEach((a) => { sum += balanceOf(state.ledger, a); });
    return sum;
  })();

  const value = {
    state, ready, t: tr, name,
    toast, showToast,
    // auth
    login, logout, setLang,
    // cart / order
    addToCart, setQty, clearCart, cartTotals, validateCheckout, placeOrder,
    confirmReceipt, advanceOrder, openDispute,
    // group
    createGroupBuy, joinGroupBuy, inviteToGroup,
    // seller
    requestPayout, approvePayout,
    // admin
    adminRelease, adminRefund, approveKyc, broadcast,
    // offline
    toggleOffline, syncNow, enqueueOffline, queueCount,
    // derived
    myOrders, myGroupBuys, myWallet, escrowTotal, sellerOrders, adminEscrow,
    platformRevenue, ledgerSum,
  };

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}
