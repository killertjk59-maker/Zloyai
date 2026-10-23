// duobozor/mobile/src/lib/money.js
// ─────────────────────────────────────────────────────────────────────────────
//  Ҳамаи ҳисобҳо бо ТИЙИН (1 TJS = 100 tiyn), ададҳои бутун.
//  Ҳеҷ гоҳ float барои пул — вагарна 0.1 + 0.2 = 0.30000000000000004.
//  Мантиқ аз tests/test_ledger.py (43 санҷиш гузашта) порт шудааст.
// ─────────────────────────────────────────────────────────────────────────────

export const TJS = 100; // tiyn дар як сомонӣ

/** Гирд кардан то тийин (ROUND_HALF_UP) */
export const round = (x) => Math.round(x);

/** rate: 0.08 = 8% */
export const pct = (amount, rate) => round(amount * rate);

export const RULES = {
  paymentFeeRate: 0.015,      // 1.5% PSP
  defaultCommissionRate: 0.08, // 8%
  managerBonusRate: 0.15,      // 15% аз комиссия
  minPayout: 100 * TJS,
  fourEyeThreshold: 2000 * TJS,
  autoReleaseDays: 7,
  payoutCooldownMs: 24 * 3600 * 1000,
};

/**
 * Тақсими маблағ ҳангоми релизи escrow.
 * @param grossTiyn   маблағи харидор пардохткарда
 * @param commissionRate 0.08
 * @param refundedTiyn баргардонии қисмӣ
 */
export function calculateSplit(grossTiyn, commissionRate = RULES.defaultCommissionRate, refundedTiyn = 0) {
  const net = grossTiyn - refundedTiyn;
  if (net < 0) throw new Error('refund > gross');

  const paymentFee = pct(grossTiyn, RULES.paymentFeeRate);

  // fee ҳеҷ гоҳ аз фурӯшанда зиёдтар не — боқимондаро платформа мебардорад
  const feeFromSeller = Math.min(paymentFee, net);
  const feeAbsorbed = paymentFee - feeFromSeller;

  const base = net - feeFromSeller;
  const commission = base > 0 ? pct(base, commissionRate) : 0;
  const managerBonus = pct(commission, RULES.managerBonusRate);
  const platformNet = commission - managerBonus - feeAbsorbed;
  const sellerPayout = Math.max(0, base - commission);

  return {
    gross: net,
    paymentFee,
    feeFromSeller,
    feeAbsorbed,
    commission,
    managerBonus,
    platformNet,
    sellerPayout,
    sumCheck: refundedTiyn + feeFromSeller + commission + sellerPayout,
  };
}

/**
 * Ledger: ҳар амалиёт = дебет + кредит. Ҳисобҳои escrow наметавонанд манфӣ шаванд.
 * @returns рӯйхати нав
 */
export function postEntries(entries, debit, credit, amount, kind, ref = {}) {
  if (amount <= 0) throw new Error('amount <= 0');
  if (debit.startsWith('escrow:')) {
    const bal = balanceOf(entries, debit);
    if (bal - amount < 0) throw new Error(`overdraft ${debit}: ${bal} < ${amount}`);
  }
  return [
    ...entries,
    {
      id: `le_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      debit, credit, amount, kind, ts: Date.now(), ...ref,
    },
  ];
}

export function balanceOf(entries, account) {
  let b = 0;
  for (const e of entries) {
    if (e.debit === account) b -= e.amount;
    if (e.credit === account) b += e.amount;
  }
  return b;
}

/** Ҳамаи ҳисобҳо бояд 0 диҳанд */
export function ledgerInvariant(entries) {
  const accounts = new Set();
  for (const e of entries) { accounts.add(e.debit); accounts.add(e.credit); }
  let sum = 0;
  for (const a of accounts) sum += balanceOf(entries, a);
  return sum;
}

/** Idempotency — калиди якдафъаин барои ҳар амал */
export const idemKey = (prefix = 'op') =>
  `${prefix}_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 10)}`;
