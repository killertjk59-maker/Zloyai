// duobozor/mobile/src/data/seed.js — маълумоти ибтидоӣ
export const CATEGORIES = [
  { id: 'c1', slug: 'libos', name_tj: 'Либос ва пойафзол', name_ru: 'Одежда и обувь', icon: '👟', rate: 0.1 },
  { id: 'c2', slug: 'elektronika', name_tj: 'Электроника', name_ru: 'Электроника', icon: '📱', rate: 0.05 },
  { id: 'c3', slug: 'hurok', name_tj: 'Хӯрок ва нӯшокӣ', name_ru: 'Продукты', icon: '🍎', rate: 0.06 },
  { id: 'c4', slug: 'kudakon', name_tj: 'Кӯдакон', name_ru: 'Детям', icon: '🧸', rate: 0.08 },
  { id: 'c5', slug: 'hona', name_tj: 'Хона ва рӯзгор', name_ru: 'Дом и быт', icon: '🏠', rate: 0.08 },
  { id: 'c6', slug: 'kosmetika', name_tj: 'Косметика', name_ru: 'Косметика', icon: '💄', rate: 0.12 },
];

export const SHOPS = [
  { id: 's1', name: 'Bozori Nav', region: 'Хуҷанд', rating: 4.8, official: true, sellerId: 'u_seller1' },
  { id: 's2', name: 'TechnoPlus', region: 'Душанбе', rating: 4.6, official: true, sellerId: 'u_seller1' },
  { id: 's3', name: 'Modniy Dom', region: 'Хуҷанд', rating: 4.5, official: false, sellerId: 'u_seller1' },
];

// price — TJS; дар store ба тийин табдил мешавад
export const PRODUCTS = [
  { id: 'p1', shopId: 's1', catId: 'c1', emoji: '👟', title_tj: 'Пойафзоли варзишӣ, сабук', title_ru: 'Кроссовки спортивные, лёгкие',
    desc_tj: 'Барои ҳар рӯз, андозаҳо 36–45, вазни сабук', desc_ru: 'На каждый день, размеры 36–45',
    price: 240, groupPrice: 149, groupMin: 2, group5: 132, stock: 42, rating: 4.8, rc: 312, sold: 1240, hot: true },
  { id: 'p2', shopId: 's2', catId: 'c2', emoji: '🎧', title_tj: 'Гӯшмонаки бесим, 40 соат', title_ru: 'Наушники беспроводные, 40ч',
    desc_tj: 'Bluetooth 5.3, заряд то 40 соат, микрофон', desc_ru: 'Bluetooth 5.3, до 40 часов',
    price: 135, groupPrice: 89, groupMin: 2, group5: 79, stock: 18, rating: 4.7, rc: 91, sold: 640, hot: true },
  { id: 'p3', shopId: 's3', catId: 'c1', emoji: '🧥', title_tj: 'Куртаи тирамоҳӣ, гарм', title_ru: 'Куртка осенняя, тёплая',
    desc_tj: 'Андозаҳо S–XXL, изолятсияи гарм', desc_ru: 'Размеры S–XXL',
    price: 390, groupPrice: 210, groupMin: 2, group5: 195, stock: 25, rating: 4.6, rc: 148, sold: 320, hot: false },
  { id: 'p4', shopId: 's1', catId: 'c5', emoji: '🫖', title_tj: 'Чойники шишагӣ 1.5л', title_ru: 'Чайник стеклянный 1.5л',
    desc_tj: 'Шишаи тобовар, филтри пӯлодӣ', desc_ru: 'Термостойкое стекло',
    price: 95, groupPrice: 62, groupMin: 2, group5: 55, stock: 60, rating: 4.9, rc: 84, sold: 410, hot: false },
  { id: 'p5', shopId: 's3', catId: 'c6', emoji: '🧴', title_tj: 'Маҷмӯаи нигоҳубини рӯй, 4 адад', title_ru: 'Набор для ухода за лицом, 4 шт',
    desc_tj: 'Тозакунӣ, серум, крем, маска', desc_ru: 'Очищение, сыворотка, крем, маска',
    price: 120, groupPrice: 78, groupMin: 3, group5: 70, stock: 33, rating: 4.8, rc: 312, sold: 890, hot: true },
  { id: 'p6', shopId: 's2', catId: 'c2', emoji: '🔌', title_tj: 'Пуркунандаи тез, 65W', title_ru: 'Зарядка быстрая, 65W',
    desc_tj: 'Type-C, 3 порт, GaN', desc_ru: 'Type-C, 3 порта, GaN',
    price: 180, groupPrice: 119, groupMin: 2, group5: 105, stock: 7, rating: 4.5, rc: 57, sold: 210, hot: false },
  { id: 'p7', shopId: 's1', catId: 'c4', emoji: '🧸', title_tj: 'Маҷмӯаи бозичаҳои таълимӣ', title_ru: 'Набор развивающих игрушек',
    desc_tj: '6 адад, аз 3-сола боло', desc_ru: '6 шт, от 3 лет',
    price: 160, groupPrice: 99, groupMin: 2, group5: 88, stock: 21, rating: 4.9, rc: 203, sold: 530, hot: false },
  { id: 'p8', shopId: 's2', catId: 'c3', emoji: '☕', title_tj: 'Қаҳваи донагӣ 1кг', title_ru: 'Кофе в зёрнах 1кг',
    desc_tj: 'Арабика, бирёнкунии миёна', desc_ru: 'Арабика, средняя обжарка',
    price: 220, groupPrice: 165, groupMin: 3, group5: 150, stock: 40, rating: 4.7, rc: 76, sold: 190, hot: false },
];

export const SELLERS = [
  { id: 'u_seller1', name: 'Bozori Nav (фурӯшанда)', phone: '+992921112233', kyc: 'approved' },
];

export const ADDRESS = {
  id: 'a1',
  label: 'Хона',
  text_tj: 'Хуҷанд, кӯчаи Ленин 42, хон. 15',
  text_ru: 'Худжанд, ул. Ленина 42, кв. 15',
  phone: '+992 92 123 45 67',
};
