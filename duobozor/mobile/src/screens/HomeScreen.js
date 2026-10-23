// Home feed: категорияҳо, оҳанрабоҳо, гурӯҳҳои фаъол
import React, { useMemo } from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable, TextInput } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { C, S, fmt } from '../theme';
import { Badge, Price, Progress, Card, EscrowBox, tap } from '../components/ui';
import { useApp } from '../store';

function timeLeft(ms) {
  if (ms <= 0) return '00:00:00';
  const s = Math.floor(ms / 1000);
  const h = String(Math.floor(s / 3600)).padStart(2, '0');
  const m = String(Math.floor((s % 3600) / 60)).padStart(2, '0');
  const sec = String(s % 60).padStart(2, '0');
  return `${h}:${m}:${sec}`;
}

export default function HomeScreen({ go }) {
  const { t, name, state, myGroupBuys, escrowTotal, addToCart } = useApp();
  const lang = state.lang;
  const open = myGroupBuys.filter((g) => g.status === 'open');
  const hot = state.products.filter((p) => p.hot);
  const rest = state.products.filter((p) => !p.hot);

  return (
    <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 24 }}>
      <LinearGradient colors={[C.red, '#FF6A3D', C.orange]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.hero}>
        <View style={styles.circle} />
        <View style={{ flexDirection: 'row', alignItems: 'center' }}>
          <View style={{ flex: 1 }}>
            <Text style={styles.greet}>{t('home_greet')} {state.user?.name?.split(' ')[0]}</Text>
            <Text style={styles.city}>{open.length} {t('home_active_groups')}</Text>
          </View>
          <View style={{ width: 36, height: 36, borderRadius: 12, backgroundColor: 'rgba(255,255,255,0.2)', alignItems: 'center', justifyContent: 'center', marginRight: 8 }}>
            <Ionicons name="notifications-outline" size={17} color="#fff" />
          </View>
          <View style={styles.avatar}><Text style={{ color: C.red, fontWeight: '800' }}>{state.user?.name?.[0] || 'U'}</Text></View>
        </View>

        <Pressable onPress={() => go && go('search')} style={styles.search}>
          <Ionicons name="search" size={15} color="#9AA1B4" />
          <Text style={{ color: '#9AA1B4', fontSize: 13, marginLeft: 8 }}>{t('search_ph')}</Text>
        </Pressable>
      </LinearGradient>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, gap: 7 }}>
        {state.categories.map((c, i) => (
          <View key={c.id} style={[styles.chip, i === 0 && { backgroundColor: C.ink }]}>
            <Text style={{ fontSize: 11.5, fontWeight: '600', color: i === 0 ? '#fff' : C.ink2 }}>{c.icon} {lang === 'ru' ? c.name_ru : c.name_tj}</Text>
          </View>
        ))}
      </ScrollView>

      {escrowTotal > 0 && (
        <View style={{ paddingHorizontal: 16, marginTop: 12 }}>
          <EscrowBox t={t} amount={escrowTotal} compact />
        </View>
      )}

      {open.length > 0 && (
        <>
          <SectionHead title={t('group_my')} />
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: 16, gap: 10 }}>
            {open.map((g) => {
              const p = state.products.find((x) => x.id === g.productId);
              if (!p) return null;
              const left = g.required - g.members.length;
              return (
                <Pressable key={g.id} onPress={() => { tap(); go && go('group', g.id); }} style={[styles.card, { width: 230 }]}>
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
                    <View style={styles.thumb}><Text style={{ fontSize: 24 }}>{p.emoji}</Text></View>
                    <View style={{ flex: 1 }}>
                      <Text numberOfLines={2} style={{ fontSize: 11.5, fontWeight: '700', color: C.ink }}>{name(p)}</Text>
                      <Text style={{ fontSize: 9.5, color: C.red, fontWeight: '800', marginTop: 3 }}>⏱ {timeLeft(g.expiresAt - Date.now())}</Text>
                    </View>
                  </View>
                  <View style={{ marginTop: 9 }}>
                    <Progress value={g.members.length / g.required} />
                    <Text style={{ fontSize: 9.5, color: C.muted, marginTop: 5 }}>
                      {g.members.length}/{g.required} · {left > 0 ? `${left} ${t('group_left')}` : t('group_success')}
                    </Text>
                  </View>
                </Pressable>
              );
            })}
          </ScrollView>
        </>
      )}

      <SectionHead title={t('hot_deals')} action={t('see_all')} />
      <View style={styles.grid}>
        {hot.map((p) => <ProductCard key={p.id} p={p} onPress={() => go && go('product', p.id)} t={t} name={name} onAdd={() => addToCart(p.id)} />)}
      </View>

      <SectionHead title={t('for_you')} />
      <View style={styles.grid}>
        {rest.map((p) => <ProductCard key={p.id} p={p} onPress={() => go && go('product', p.id)} t={t} name={name} onAdd={() => addToCart(p.id)} />)}
      </View>
    </ScrollView>
  );
}

const SectionHead = ({ title, action }) => (
  <View style={{ flexDirection: 'row', alignItems: 'baseline', justifyContent: 'space-between', paddingHorizontal: 16, paddingTop: 18, paddingBottom: 10 }}>
    <Text style={{ fontSize: 15.5, fontWeight: '800', color: C.ink, letterSpacing: -0.2 }}>{title}</Text>
    {action ? <Text style={{ fontSize: 11.5, color: C.red, fontWeight: '700' }}>{action}</Text> : null}
  </View>
);

function ProductCard({ p, onPress, t, name, onAdd }) {
  const off = Math.round((1 - p.groupPrice / p.price) * 100);
  return (
    <Pressable onPress={() => { tap(); onPress(); }} style={styles.card}>
      <View style={styles.pImg}>
        <Text style={{ fontSize: 34 }}>{p.emoji}</Text>
        <View style={{ position: 'absolute', top: 6, left: 6 }}><Badge text={`−${off}%`} /></View>
        <View style={{ position: 'absolute', bottom: 6, right: 6, backgroundColor: 'rgba(18,21,28,0.82)', borderRadius: 8, paddingHorizontal: 6, paddingVertical: 3 }}>
          <Text style={{ color: '#fff', fontSize: 9, fontWeight: '800' }}>🔥 {p.sold}</Text>
        </View>
      </View>
      <Text numberOfLines={2} style={{ fontSize: 12, fontWeight: '600', color: C.ink, marginTop: 8, height: 33 }}>{name(p)}</Text>
      <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 6 }}>
        <Price value={p.groupPrice} old={p.price} size={15} />
        <Pressable onPress={() => { tap(); onAdd(); }} hitSlop={8} style={styles.addBtn}>
          <Ionicons name="add" size={15} color="#fff" />
        </Pressable>
      </View>
      <Text style={{ fontSize: 9, color: C.muted, marginTop: 5 }}>★ {p.rating} · {p.rc} {t('reviews')}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  hero: { paddingTop: 12, paddingHorizontal: 16, paddingBottom: 22, borderBottomLeftRadius: 26, borderBottomRightRadius: 26, overflow: 'hidden' },
  circle: { position: 'absolute', width: 190, height: 190, borderRadius: 95, backgroundColor: 'rgba(255,255,255,0.13)', right: -60, top: -70 },
  greet: { fontSize: 11.5, color: 'rgba(255,255,255,0.9)' },
  city: { fontSize: 18, fontWeight: '800', color: '#fff', letterSpacing: -0.4, marginTop: 2 },
  avatar: { width: 36, height: 36, borderRadius: 18, backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center' },
  search: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'rgba(255,255,255,0.97)', borderRadius: 13, paddingHorizontal: 13, paddingVertical: 11, marginTop: 14 },
  chip: { paddingHorizontal: 13, paddingVertical: 7, borderRadius: 99, backgroundColor: '#fff', ...S.shadow },
  card: { backgroundColor: '#fff', borderRadius: 16, padding: 10, ...S.shadow },
  thumb: { width: 46, height: 46, borderRadius: 12, backgroundColor: '#EEF1F8', alignItems: 'center', justifyContent: 'center' },
  grid: { flexDirection: 'row', flexWrap: 'wrap', paddingHorizontal: 10, gap: 10 },
  pImg: { height: 104, borderRadius: 12, backgroundColor: '#F0F3FA', alignItems: 'center', justifyContent: 'center' },
  addBtn: { width: 27, height: 27, borderRadius: 10, backgroundColor: C.red, alignItems: 'center', justifyContent: 'center' },
});
