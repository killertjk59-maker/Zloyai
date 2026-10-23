// Санҷиши мантиқи пул ва ledger — node test/logic.test.mjs
import { calculateSplit, postEntries, balanceOf, ledgerInvariant, RULES } from '../src/lib/money.js';

let pass = 0, fail = 0;
const eq = (a, b, m) => { if (a === b) pass++; else { fail++; console.log('FAIL', m, '→', a, '≠', b); } };

// 1. Тақсим: ҳеҷ тийин гум намешавад
for (const gross of [100, 1000, 14900, 24000, 999999, 123457]) {
  for (const rate of [0.05, 0.08, 0.12]) {
    const s = calculateSplit(gross, rate);
    eq(s.sumCheck, gross, `sumCheck gross=${gross} rate=${rate}`);
    eq(s.platformNet + s.managerBonus + s.feeAbsorbed, s.commission, `platform identity gross=${gross}`);
    eq(s.sellerPayout >= 0, true, `sellerPayout>=0 gross=${gross}`);
  }
}

// 2. Ledger: Σ ҳамаи ҳисобҳо = 0
let L = [];
L = postEntries(L, 'buyer:u1:wallet', 'escrow:o1', 14900, 'escrow_in', {});
const s = calculateSplit(14900, 0.08);
L = postEntries(L, 'escrow:o1', 'platform:fees', s.paymentFee, 'payment_fee', {});
if (s.commission > 0) L = postEntries(L, 'escrow:o1', 'platform:revenue', s.commission, 'commission', {});
if (s.managerBonus > 0) L = postEntries(L, 'platform:revenue', 'manager:bonus', s.managerBonus, 'manager_bonus', {});
L = postEntries(L, 'escrow:o1', `seller:s1:payable`, s.sellerPayout, 'seller_payable', {});
eq(ledgerInvariant(L), 0, 'ledger invariant');
eq(balanceOf(L, 'seller:s1:payable'), s.sellerPayout, 'seller payable');
eq(balanceOf(L, 'escrow:o1'), 0, 'escrow emptied');

// 3. Escrow наметавонад манфӣ шавад
let threw = false;
try { postEntries(L, 'escrow:o1', 'x:y', 1, 'test', {}); } catch { threw = true; }
eq(threw, true, 'escrow overdraft blocked');

// 4. Қоидаҳо
eq(RULES.minPayout, 10000, 'minPayout 100 TJS');
eq(RULES.fourEyeThreshold, 200000, 'fourEye 2000 TJS');

console.log(`${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
