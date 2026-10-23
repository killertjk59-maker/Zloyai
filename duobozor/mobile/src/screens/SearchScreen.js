// Ҷустуҷӯ: матн + категория + ҷобаҷогузорӣ
import React, { useMemo, useState, useEffect } from 'react';
import { View, Text, StyleSheet, TextInput, ScrollView, Dimensions } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { C, S, G, fmtInt } from '../theme';
import { Badge, Empty, Price, FadeIn, Press } from '../components/ui';
import { useApp } from '../store';

const W = Dimensions.get('window').width;
const CARD_W = (W - 30) / 2;

const SORTS = [
  { key: 'hot', label: '🔥', name: 'машҳур' },
  { key: 'cheap', label: '↑', name: 'арзон' },
  { key: 'expensive', label: '↓', name: 'қиммат' },
];

export default function SearchScreen({ go, initialCat }) {
  const { t, name, state, addToCart, showToast } = useApp();
  const [q, setQ] = useState('');
  const [cat, setCat] = useState(initialCat || null);
  const [sort, setSort] = useState('hot');

  useEffect(() => { setCat(initialCat || null); }, [initialCat]);

  const res = useMemo(() => {
    let list = state.products.slice();
    if (q.trim()) {
      const s = q.trim().toLowerCase();
      list = list.filter((p) => `${p.title_tj} ${p.title_ru}`.toLowerCase().includes(s));
    }
    if (cat) list = list.filter((p) => p.catId === cat);
    if (sort === 'cheap') list.sort((a, b) => a.groupPrice - b.groupPrice);
    else if (sort === 'expensive') list.sort((a, b) => b.groupPrice - a.groupPrice);
    else list.sort((a, b) => b.sold - a.sold);
    return list;
  }, [q, cat, sort, state.products]);

  const activeCat = state.categories.find((c) => c.id === cat);

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <View style={styles.top}>
        <Text style={styles.title}>{t('tab_search')}</Text>
        <View style={styles.field}>
          <Ionicons name="search" size={15} color="#9AA1B4" />
          <TextInput
            value={q}
            onChangeText={setQ}
            placeholder={t('search_ph')}
            placeholderTextColor="#9AA1B4"
            style={{ flex: 1, fontSize: 13, color: C.ink, marginLeft: 8, paddingVertical: 0 }}
          />
          {q ? <Press onPress={() => setQ('')}><Ionicons name="close-circle" size={17} color="#C3CAD8" /></Press> : null}
        </View>
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: 16, gap: 8, paddingBottom: 10 }}>
        <Press onPress={() => setCat(null)}>
          <View style={[styles.chip, !cat && styles.chipOn]}>
            <Text style={[styles.chipTxt, !cat && { color: '#fff' }]}>Ҳама</Text>
          </View>
        </Press>
        {state.categories.map((c) => (
          <Press key={c.id} onPress={() => setCat(c.id === cat ? null : c.id)}>
            <View style={[styles.chip, cat === c.id && styles.chipOn]}>
              <Text style={[styles.chipTxt, cat === c.id && { color: '#fff' }]}>
                {c.icon} {state.lang === 'ru' ? c.name_ru : c.name_tj}
              </Text>
            </View>
          </Press>
        ))}
      </ScrollView>

      <View style={{ flexDirection: 'row', gap: 7, paddingHorizontal: 16, paddingBottom: 10, alignItems: 'center' }}>
        {SORTS.map((s) => (
          <Press key={s.key} onPress={() => setSort(s.key)}>
            <View style={[styles.sort, sort === s.key && { borderColor: C.red, backgroundColor: '#FFF7F5' }]}>
              <Text style={{ fontSize: 10, fontWeight: '700', color: sort === s.key ? C.red : C.muted }}>{s.label} {s.name}</Text>
            </View>
          </Press>
        ))}
        <Text style={{ marginLeft: 'auto', fontSize: 10.5, color: C.muted }}>{fmtInt(res.length)} мол</Text>
      </View>

      {activeCat ? (
        <View style={{ paddingHorizontal: 16, paddingBottom: 8 }}>
          <Badge text={`${activeCat.icon} ${state.lang === 'ru' ? activeCat.name_ru : activeCat.name_tj} · комиссия ${Math.round(activeCat.rate * 100)}%`} kind="blue" />
        </View>
      ) : null}

      {!res.length ? (
        <Empty icon="search-outline" title={t('no_results')} sub={t('search_ph')} />
      ) : (
        <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: 10, paddingBottom: 22 }}>
          <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 10 }}>
            {res.map((p, i) => {
              const off = Math.round((1 - p.groupPrice / p.price) * 100);
              return (
                <FadeIn key={p.id} delay={Math.min(i, 8) * 35} dy={12}>
                  <Press onPress={() => go('product', p.id)}>
                    <View style={styles.card}>
                      <View style={styles.img}>
                        <Text style={{ fontSize: 34 }}>{p.emoji}</Text>
                        <View style={{ position: 'absolute', top: 6, left: 6 }}><Badge text={`−${off}%`} /></View>
                      </View>
                      <Text numberOfLines={2} style={{ fontSize: 11.5, fontWeight: '700', color: C.ink, marginTop: 8, height: 32, lineHeight: 16 }}>{name(p)}</Text>
                      <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 5 }}>
                        <Price value={p.groupPrice} size={13.5} />
                        <Press onPress={() => { addToCart(p.id); showToast(t('add_cart_ok')); }} scaleTo={0.85} hitSlop={8}>
                          <LinearGradient colors={G.brand} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.add}>
                            <Ionicons name="add" size={15} color="#fff" />
                          </LinearGradient>
                        </Press>
                      </View>
                    </View>
                  </Press>
                </FadeIn>
              );
            })}
          </View>
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  top: { paddingHorizontal: 16, paddingTop: 10, paddingBottom: 12 },
  title: { fontSize: 20, fontWeight: '800', color: C.ink, letterSpacing: -0.4, marginBottom: 10 },
  field: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 14, paddingHorizontal: 13, paddingVertical: 11, ...S.shadow },
  chip: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 99, backgroundColor: '#fff', ...S.shadow },
  chipOn: { backgroundColor: C.ink },
  chipTxt: { fontSize: 11, fontWeight: '700', color: C.ink2 },
  sort: { paddingHorizontal: 11, paddingVertical: 6, borderRadius: 99, borderWidth: 1.5, borderColor: C.line, backgroundColor: '#fff' },
  card: { width: CARD_W, backgroundColor: '#fff', borderRadius: 17, padding: 10, ...S.shadow },
  img: { height: 100, borderRadius: 13, backgroundColor: '#F0F3FA', alignItems: 'center', justifyContent: 'center' },
  add: { width: 26, height: 26, borderRadius: 9, alignItems: 'center', justifyContent: 'center' },
});
