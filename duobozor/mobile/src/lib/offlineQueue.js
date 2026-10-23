// duobozor/mobile/src/lib/offlineQueue.js
// Outbox-и оффлайн — порти JS аз expo/lib/offlineQueue.ts (53 санҷиш гузашта).
const KEY = 'duobozor.outbox.v1';

export const REQUIRES_NETWORK = [
  'payment.card',
  'payment.otp',
  'auth.otp.request',
  'auth.otp.verify',
  'escrow.release',
  'escrow.dispute',
  'payout.request',
  'order.confirm_receipt',
  'groupbuy.join',
];

export class OfflineQueue {
  constructor(storage, opts = {}) {
    this.storage = storage;
    this.items = [];
    this.loaded = false;
    this.flushing = false;
    this.maxAttempts = opts.maxAttempts ?? 6;
    this.baseDelayMs = opts.baseDelayMs ?? 2000;
    this.maxDelayMs = opts.maxDelayMs ?? 5 * 60 * 1000;
    this.now = opts.now ?? (() => Date.now());
  }

  async load() {
    const raw = await this.storage.getItem(KEY);
    if (raw) {
      try {
        const parsed = JSON.parse(raw);
        this.items = Array.isArray(parsed) ? parsed : [];
      } catch { this.items = []; }
    }
    for (const it of this.items) if (it.status === 'sending') it.status = 'pending';
    this.loaded = true;
  }

  async persist() { await this.storage.setItem(KEY, JSON.stringify(this.items)); }

  async enqueue(type, method, path, body) {
    if (REQUIRES_NETWORK.includes(type)) {
      throw new Error(`«${type}» бе интернет иҷро намешавад`);
    }
    if (!this.loaded) await this.load();
    const action = {
      id: `${type}_${this.now()}_${Math.random().toString(36).slice(2, 8)}`,
      type, method, path, body,
      createdAt: this.now(), attempts: 0, nextAttemptAt: this.now(), status: 'pending',
    };
    this.items.push(action);
    await this.persist();
    return action;
  }

  get pendingCount() { return this.items.filter((i) => i.status === 'pending').length; }
  get conflictCount() { return this.items.filter((i) => i.status === 'conflict').length; }
  list() { return this.items; }

  scheduleRetry(a) {
    a.attempts++;
    if (a.attempts >= this.maxAttempts) {
      a.status = 'dead';
      a.lastError = a.lastError || 'кӯшишҳо тамом шуданд';
      return;
    }
    const exp = Math.min(this.maxDelayMs, this.baseDelayMs * 2 ** (a.attempts - 1));
    a.status = 'pending';
    a.nextAttemptAt = this.now() + Math.round(exp * (0.7 + 0.3 * Math.random()));
  }

  async flush(send) {
    if (this.flushing) return { sent: 0, retried: 0, dead: 0, conflicts: 0 };
    if (!this.loaded) await this.load();
    this.flushing = true;
    const rep = { sent: 0, retried: 0, dead: 0, conflicts: 0 };
    try {
      for (const action of [...this.items]) {
        if (action.status !== 'pending' || action.nextAttemptAt > this.now()) continue;
        action.status = 'sending';
        let res;
        try { res = await send(action); } catch { res = { ok: false, kind: 'network' }; }

        if (res.ok) {
          this.items = this.items.filter((i) => i.id !== action.id);
          rep.sent++;
        } else if (res.kind === 'network') {
          this.scheduleRetry(action); rep.retried++;
        } else if (res.status === 409) {
          action.status = 'conflict';
          action.lastError = res.message || 'маълумот тағйир ёфт';
          rep.conflicts++;
        } else if (res.status >= 500 || res.status === 429) {
          this.scheduleRetry(action); rep.retried++;
        } else {
          action.status = 'dead';
          action.lastError = res.message || `HTTP ${res.status}`;
          rep.dead++;
        }
        await this.persist();
      }
    } finally { this.flushing = false; }
    return rep;
  }

  async resolveConflict(id, accept) {
    const a = this.items.find((i) => i.id === id);
    if (!a || a.status !== 'conflict') return;
    if (accept) { a.status = 'pending'; a.attempts = 0; a.nextAttemptAt = this.now(); }
    else { a.status = 'dead'; a.lastError = 'корбар рад кард'; }
    await this.persist();
  }

  async purge() {
    const before = this.items.length;
    this.items = this.items.filter((i) => i.status === 'pending');
    await this.persist();
    return before - this.items.length;
  }
}
