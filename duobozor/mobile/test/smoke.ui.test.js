// Санҷиши воқеии render + пахш: барнома намеафтад, ҳамаи ҷараёнҳо кор мекунанд
import React from 'react';
import { Text, TextInput } from 'react-native';
import renderer, { act } from 'react-test-renderer';
import App from '../App';

jest.setTimeout(120000);
const flush = async (ms = 220) => { await act(async () => { await new Promise((r) => setTimeout(r, ms)); }); };

const textUnder = (inst) => {
  try {
    return inst.findAllByType(Text)
      .map((t) => (Array.isArray(t.props.children) ? t.props.children.filter((x) => typeof x === 'string').join('') : (typeof t.props.children === 'string' ? t.props.children : '')))
      .join(' | ');
  } catch (e) { return ''; }
};

let tree;
const root = () => tree.root;
const screenText = () => textUnder(root());

const tapId = async (id) => {
  const n = root().findByProps({ testID: id });
  await act(async () => { n.props.onPress({ nativeEvent: { locationX: 8, locationY: 8 } }); });
  await flush();
};

const pressText = async (needle) => {
  const all = root().findAll((n) => n.props && typeof n.props.onPress === 'function');
  const hit = all.find((n) => textUnder(n).includes(needle));
  if (!hit) throw new Error(`"${needle}" ёфт нашуд. Экрани ҳозира: ${screenText().slice(0, 300)}`);
  await act(async () => { hit.props.onPress({ nativeEvent: { locationX: 8, locationY: 8 } }); });
  await flush();
};

beforeAll(async () => {
  await act(async () => { tree = renderer.create(<App />); });
  await flush(80);
});
afterAll(async () => { await act(async () => { tree.unmount(); }); });

test('1. экрани воридшавӣ', () => {
  expect(screenText()).toContain('DuoBozor');
  expect(screenText()).toContain('Воридшавӣ ҳамчун админ');
});

test('2. сабти ном: Telegram → ном, насаб, синну сол, телефон', async () => {
  await pressText('Идома бо Telegram');
  expect(screenText()).toContain('Telegram кушода мешавад');
  await pressText('идома');

  const inputs = root().findAllByType(TextInput);
  expect(inputs.length).toBeGreaterThanOrEqual(4);
  await act(async () => { inputs[0].props.onChangeText('Фарзона'); });
  await act(async () => { inputs[1].props.onChangeText('Раҳимова'); });
  await act(async () => { inputs[2].props.onChangeText('24'); });
  await act(async () => { inputs[3].props.onChangeText('Хуҷанд'); });
  const phone = root().findAllByType(TextInput)[4];
  await act(async () => { phone.props.onChangeText('921234567'); });
  await flush(120);

  await pressText('Оянда');
  await flush(200);
  expect(screenText()).toContain('Салом');
  expect(screenText()).toContain('Фарзона');
});

test('3. категория → ҷустуҷӯ (крэш намекунад)', async () => {
  await pressText('Электроника');
  expect(screenText()).toContain('Ҷустуҷӯ');
  expect(screenText()).toContain('Гӯшмонак');
});

test('4. мол → ба сабад → сабад', async () => {
  await pressText('Гӯшмонак');
  expect(screenText()).toContain('Нархи гурӯҳӣ');
  await tapId('btn-add-cart');
  await tapId('btn-back');
  await tapId('tab-cart');
  expect(screenText()).toContain('Расонидан');
});

test('5. checkout → фармоиш дар escrow', async () => {
  await tapId('btn-goto-checkout');
  expect(screenText()).toContain('Усули пардохт');
  await tapId('btn-pay');
  await flush(200);
  expect(screenText()).toContain('Фармоишҳои ман');
  expect(screenText()).toContain('дар ҳифз');
});

test('6. тафсил → се қадам → «Гирифтам» → релизи escrow', async () => {
  await pressText('DB-');
  expect(screenText()).toContain('Пайгирӣ');
  await pressText('қадами навбатии фармоиш');
  await pressText('қадами навбатии фармоиш');
  await pressText('қадами навбатии фармоиш');
  await tapId('btn-confirm');
  await flush(240);
  expect(screenText()).toContain('Маблағ ба фурӯшанда дода шуд');
});

test('7. ҳамён + профил', async () => {
  await tapId('btn-back');
  await tapId('tab-profile');
  expect(screenText()).toContain('Профил');
  await pressText('Ҳамён');
  expect(screenText()).toContain('Бақияи дастрас');
});

test('8. админ: баромад → рақам + рамз → панел', async () => {
  await tapId('btn-back');
  await tapId('tab-profile');
  await pressText('Баромадан');
  await flush(200);
  expect(screenText()).toContain('Воридшавӣ ҳамчун админ');

  await pressText('Воридшавӣ ҳамчун админ');
  expect(screenText()).toContain('Панели идоракунӣ');

  const inputs = root().findAllByType(TextInput);
  await act(async () => { inputs[0].props.onChangeText('921112233'); });
  await act(async () => { inputs[1].props.onChangeText('admin2026'); });
  await flush(80);
  await pressText('Воридшавӣ ҳамчун админ');
  await flush(240);

  expect(screenText()).toContain('Абдулло Назаров');
  expect(screenText()).toContain('АДМИН');
  await pressText('Панели идоракунӣ');
  expect(screenText()).toContain('Ledger');
});
