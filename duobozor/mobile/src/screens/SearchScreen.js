// Ҷустуҷӯ: филтр аз рӯи матн, категория ва нарх
import React, { useMemo, useState } from 'react';
import { View, Text, StyleSheet, TextInput, ScrollView, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { C, S, fmt } from '../theme';
import { Badge, Empty, Price, tap } from '../components/ui';
import { useApp } from '../store';

export default function SearchScreen({ go }) {
  const { t, name, state, addToCart } = useApp();
  const [q, setQ] = useState('');
  const [cat, setCat] = useState(null);
  const [sort, setSort] = useState('hot');

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

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <View style={styles.top}>
        <View style={styles.field}>
          <Ionicons name="search" size={15} color="#9AA1B4" />
          <TextInput
            value={q}
            onChangeText={setQ}
            placeholder={t('search_ph')}
            placeholderTextColor="#9AA1B4"
            style={{ flex: 1, fontSize: 13, color: C.ink, marginLeft: 8, paddingVertical: 0 }}
          />
          {q ? <Pressable onPress={() => setQ('')} hitSlop={8}><Ionicons name="close-circle" size={16} color="#C3CAD8" /></Pressable> : null}
        </View>
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: 16, gap: 7, paddingBottom: 8 }}>
        <Pressable onPress={() => { tap(); setCat(null); }} style={[styles.chip, !cat && styles.chipOn]}>
          <Text style={[styles.chipTxt, !cat && { color: '#fff' }]}>{t('see_all')}</Text>
        </Pressable>
        {state.categories.map((c) => (
          <Pressable key={c.id} onPress={() => { tap(); setCat(c.id === cat ? null : c.id); }} style={[styles.chip, cat === c.id && styles.chipOn]}>
            <Text style={[styles.chipTxt, cat === c.id && { color: '#fff' }]}>{c.icon} {state.lang === 'ru' ? c.name_ru : c.name_tj}</Text>
          </Pressable>
        ))}
      </ScrollView>

      <View style={{ flexDirection: 'row', gap: 7, paddingHorizontal: 16, paddingVertical: 8 }}>
        {[['hot', '🔥'], ['cheap', '↑'], ['expensive', '↓']].map(([k, ic]) => (
          <Pressable key={k} onPress={() => setSort(k)} style={[styles.sort, sort === k && { borderColor: C.red, backgroundColor: '#FFF7F5' }]}>
            <Text style={{ fontSize: 10, fontWeight: '700', color: sort === k ? C.red : C.muted }}>{ic} {k === 'hot' ? t('sold') : k === 'cheap' ? 'арзон' : 'қиммат'}</Text>
          </Pressable>
        ))}
        <Text style={{ marginLeft: 'auto', fontSize: 10.5, color: C.muted, alignSelf: 'center' }}>{res.length} мол</Text>
      </View>

      {!res.length ? <Empty icon="search-outline" title={t('no_results')} sub={t('search_ph')} /> : (
        <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: 10, paddingBottom: 20 }}>
          <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 10 }}>
            {res.map((p) => (
              <Pressable key={p.id} onPress={() => { tap(); go('product', p.id); }} style={styles.card}>
                <View style={styles.img}><Text style={{ fontSize: 32 }}>{p.emoji}</Text></View>
                <Text numberOfLines={2} style={{ fontSize: 12, fontWeight: '600', color: C.ink, marginTop: 8, height: 33 }}>{name(p)}</Text>
                <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 6 }}>
                  <Price value={p.groupPrice} size={14} />
                  <Pressable onPress={() => { tap(); addToCart(p.id); }} hitSlop={8} style={styles.add}>
                    <Ionicons name="add" size={14} color="#fff" />
                  </Pressable>
                </View>
              </Pressable>
            ))}
          </View>
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  top: { paddingHorizontal: 16, paddingTop: 12, paddingBottom: 10 },
  field: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 14, paddingHorizontal: 13, paddingVertical: 11, ...S.shadow },
  chip: { paddingHorizontal: 12, paddingVertical: 7, borderRadius: 99, backgroundColor: '#fff', ...S.shadow },
  chipOn: { backgroundColor: C.ink },
  chipTxt: { fontSize: 11, fontWeight: '600', color: C.ink2 },
  sort: { paddingHorizontal: 11, paddingVertical: 6, borderRadius: 99, borderWidth: 1.5, borderColor: C.line, backgroundColor: '#fff' },
  card: { width: '30.5%', minWidth: 100, flexGrow: 1, backgroundColor: '#fff', borderRadius: 15, padding: 9, ...S.shadow },
  img: { height: 92, borderRadius: 11, backgroundColor: '#F0F3FA', alignItems: 'center', justifyContent: 'center' },
  add: { width: 25, height: 25, borderRadius: 9, backgroundColor: C.red, alignItems: 'center', justifyContent: 'center' },
});
