// duobozor/mobile/src/theme.js — рангҳо, андозаҳо, форматкунӣ (бе Intl/Hermes-хатар)
export const C = {
  red: '#E8402A',
  redDeep: '#C22F1C',
  orange: '#FF8A3D',
  gold: '#FFB020',
  green: '#0FA958',
  greenSoft: '#E7F8EF',
  blue: '#2F6FED',
  blueSoft: '#EAF1FE',
  ink: '#0F1219',
  ink2: '#242A38',
  muted: '#78819A',
  line: '#E8EAF1',
  bg: '#F6F7FB',
  white: '#FFFFFF',
  yellowSoft: '#FFF4DC',
  redSoft: '#FDECE9',
  goldText: '#A96F00',
  card: '#FFFFFF',
  dark: '#101420',
  dark2: '#1B2130',
};

export const G = {
  brand: [C.red, '#FF6A3D', C.orange],
  dark: ['#101420', '#2A3446'],
  green: ['#0FA958', '#5FD394'],
  gold: ['#FFB020', '#FFD87A'],
};

export const S = {
  r: 18,
  rSm: 13,
  rLg: 26,
  pad: 16,
  shadow: {
    shadowColor: '#0F1219',
    shadowOpacity: 0.07,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  shadowLg: {
    shadowColor: '#E8402A',
    shadowOpacity: 0.28,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 8 },
    elevation: 8,
  },
};

const pad2 = (n) => (n < 10 ? '0' + n : String(n));

/** 125000 tiyn → "1 250.00" (бе Intl — Hermes баъзан мешиканад) */
export const fmt = (tiyn) => {
  const v = Math.abs(Number(tiyn) || 0) / 100;
  const [i, d] = v.toFixed(2).split('.');
  const grouped = i.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  return (tiyn < 0 ? '−' : '') + grouped + '.' + d;
};

/** 1250.5 → "1 250" */
export const fmtInt = (n) => String(Math.round(Number(n) || 0)).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');

/** 1719000000000 → "23.10.2026" */
export const fmtDate = (ts) => {
  const d = new Date(ts || 0);
  return `${pad2(d.getDate())}.${pad2(d.getMonth() + 1)}.${d.getFullYear()}`;
};

/** → "14:35" */
export const fmtTime = (ts) => {
  const d = new Date(ts || 0);
  return `${pad2(d.getHours())}:${pad2(d.getMinutes())}`;
};

/** → "14:35 · 23.10" */
export const fmtDateTime = (ts) => `${fmtTime(ts)} · ${pad2(new Date(ts || 0).getDate())}.${pad2(new Date(ts || 0).getMonth() + 1)}`;

/** 3725000 ms → "01:02:05" */
export const fmtCountdown = (ms) => {
  const s = Math.max(0, Math.floor((ms || 0) / 1000));
  return `${pad2(Math.floor(s / 3600))}:${pad2(Math.floor((s % 3600) / 60))}:${pad2(s % 60)}`;
};
