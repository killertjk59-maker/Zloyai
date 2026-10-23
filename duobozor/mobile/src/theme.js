// duobozor/mobile/src/theme.js
export const C = {
  red: '#E8402A',
  redDark: '#C22F1C',
  orange: '#FF8A3D',
  gold: '#FFB020',
  green: '#12A150',
  greenSoft: '#E6F7EE',
  blue: '#2F6FED',
  blueSoft: '#EAF1FE',
  ink: '#12151C',
  ink2: '#2A3040',
  muted: '#7A8299',
  line: '#E7E9F0',
  bg: '#F5F6FA',
  white: '#FFFFFF',
  yellowSoft: '#FFF4DC',
  redSoft: '#FDEAE7',
  goldText: '#B47A00',
};

export const S = {
  r: 16,
  rSm: 12,
  rLg: 22,
  pad: 16,
  shadow: {
    shadowColor: '#12151C',
    shadowOpacity: 0.08,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 3 },
    elevation: 3,
  },
};

export const fmt = (tiyn) => {
  const v = Math.abs(Number(tiyn) || 0) / 100;
  const s = v.toLocaleString('ru-RU', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  return (tiyn < 0 ? '−' : '') + s;
};
