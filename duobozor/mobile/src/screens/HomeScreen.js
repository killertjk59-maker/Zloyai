// Home: категорияҳои пахшшаванда, гурӯҳҳои фаъол, оҳанрабоҳо
import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TextInput, Dimensions } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { C, S, G, fmt, fmtCountdown, fmtInt } from '../theme';
import { Badge, Price, Progress, EscrowBox, FadeIn, Press } from '../components/ui';
import { useApp } from '../store';

const W = Dimensions.get('window').width;
function timeLeft(ms) { return fmtCountdown(ms); }

export default function HomeScreen({ go }) {
  const { t, name, state, myGroupBuys, escrowTotal, addToCart, showToast } = useApp();
  const lang = state.lang;
  const open = myGroupBuys.filter((g) => g.status === 'open');
  const hot = state.products.filter((p) => p.hot);
  const rest = state.products.filter((p) => !p.hot);
  const [q, setQ] = useState('');

  return (
    <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 26 }}>
      <LinearGradient colors={G.brand} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.hero}>
        <View style={styles.circle} />
        <FadeIn dy={8}>
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <View style={{ flex: 1 }}>
              <Text style={styles.greet}>{t('home_greet')}</Text>
              <Text style={styles.uname} numberOfLines={1}>{state.user?.name || t('guest')}</Text>
            </View>
            <Press onPress={() => go('notifications')} style={{ marginRight: 8 }}>
              <View style={styles.iconBtn}><Ionicons name="notifications-outline" size={17} color="#fff" /></View>
            </Press>
            <Press onPress={() => go('profile')}>
              <View style={styles.avatar}><Text style={{ color: C.red, fontWeight: '800', fontSize: 15 }}>{(state.user?.name || 'U')[0]}</Text></View>
            </Press>
          </View>

          <View style={styles.search}>
            <Ionicons name="search" size={15} color="#9AA1B4" />
            <TextInput
              value={q}
              onChangeText={setQ}
              placeholder={t('search_ph')}
              placeholderTextColor="#9AA1B4"
              style={{ flex: 1, fontSize: 12.5, color: C.ink, marginLeft: 8, paddingVertical: 0 }}
              onSubmitEditing={() => go('search')}
              returnKeyType="search"
            />
            {q ? <Press onPress={() => { setQ(''); go('search'); }}><Ionicons name="arrow-forward-circle" size={19} color={C.red} /></Press> : null}
          </View>

          <View style={styles.statsRow}>
            <View style={styles.stat}><Text style={styles.statV}>{open.length}</Text><Text style={styles.statL}>{t('home_active_groups')}</Text></View>
            <View style={styles.statSep} />
            <View style={styles.stat}><Text style={styles.statV}>{fmt(escrowTotal)}</Text><Text style={styles.statL}>{t('escrow')} · c.</Text></View>
            <View style={styles.statSep} />
            <View style={styles.stat}><Text style={styles.statV}>{fmtInt(state.products.length)}</Text><Text style={styles.statL}>мол</Text></View>
          </View>
        </FadeIn>
      </LinearGradient>

      {/* Категорияҳо — ҳама пахшшаванда */}
      <FadeIn delay={60} dy={10}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 14, gap: 8 }}>
          <Press onPress={() => go('search')}>
            <View style={[styles.chip, { backgroundColor: C.ink }]}>
              <Text style={{ fontSize: 11.5, fontWeight: '800', color: '#fff' }}>🔥 {t('see_all')}</Text>
            </View>
          </Press>
          {state.categories.map((c) => (
            <Press key={c.id} onPress={() => go('search', c.id)}>
              <View style={styles.chip}>
                <Text style={{ fontSize: 11.5, fontWeight: '700', color: C.ink2 }}>
                  {c.icon} {lang === 'ru' ? c.name_ru : c.name_tj}
                </Text>
              </View>
            </Press>
          ))}
        </ScrollView>
      </FadeIn>

      {escrowTotal > 0 ? (
        <FadeIn delay={100} style={{ paddingHorizontal: 16, marginTop: 14 }}>
          <EscrowBox t={t} amount={escrowTotal} compact />
        </FadeIn>
      ) : null}

      {open.length > 0 ? (
        <>
          <SectionHead title={t('group_my')} />
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: 16, gap: 10 }}>
            {open.map((g, i) => {
              const p = state.products.find((x) => x.id === g.productId);
              if (!p) return null;
              const left = g.required - g.members.length;
              return (
                <FadeIn key={g.id} delay={60 * i} dy={12}>
                  <Press onPress={() => go('group', g.id)}>
                    <View style={[styles.card, { width: 240 }]}>
                      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
                        <View style={styles.thumb}><Text style={{ fontSize: 25 }}>{p.emoji}</Text></View>
                        <View style={{ flex: 1 }}>
                          <Text numberOfLines={2} style={{ fontSize: 11.5, fontWeight: '700', color: C.ink }}>{name(p)}</Text>
                          <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: 4 }}>
                            <Ionicons name="time-outline" size={11} color={C.red} />
                            <Text style={{ fontSize: 9.5, color: C.red, fontWeight: '800', marginLeft: 3 }}>{timeLeft(g.expiresAt - Date.now())}</Text>
                          </View>
                        </View>
                      </View>
                      <View style={{ marginTop: 10 }}>
                        <Progress value={g.members.length / g.required} />
                        <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginTop: 5 }}>
                          <Text style={{ fontSize: 9.5, color: C.muted }}>{g.members.length}/{g.required} · {left > 0 ? `${left} ${t('group_left')}` : t('group_success')}</Text>
                          <Text style={{ fontSize: 9.5, fontWeight: '800', color: C.red }}>{fmt(g.price)} c.</Text>
                        </View>
                      </View>
                    </View>
                  </Press>
                </FadeIn>
              );
            })}
          </ScrollView>
        </>
      ) : null}

      <SectionHead title={t('hot_deals')} action={t('see_all')} onAction={() => go('search')} />
      <View style={styles.grid}>
        {hot.map((p, i) => (
          <FadeIn key={p.id} delay={40 * i} dy={14}>
            <ProductCard p={p} t={t} name={name} onPress={() => go('product', p.id)} onAdd={() => { addToCart(p.id); }} />
          </FadeIn>
        ))}
      </View>

      <SectionHead title={t('for_you')} />
      <View style={styles.grid}>
        {rest.map((p, i) => (
          <FadeIn key={p.id} delay={30 * i} dy={14}>
            <ProductCard p={p} t={t} name={name} onPress={() => go('product', p.id)} onAdd={() => addToCart(p.id)} />
          </FadeIn>
        ))}
      </View>
    </ScrollView>
  );
}

function SectionHead({ title, action, onAction }) {
  return (
    <View style={{ flexDirection: 'row', alignItems: 'baseline', justifyContent: 'space-between', paddingHorizontal: 16, paddingTop: 20, paddingBottom: 10 }}>
      <Text style={{ fontSize: 15.5, fontWeight: '800', color: C.ink, letterSpacing: -0.2 }}>{title}</Text>
      {action ? (
        <Press onPress={onAction}><Text style={{ fontSize: 11.5, color: C.red, fontWeight: '800' }}>{action}</Text></Press>
      ) : null}
    </View>
  );
}

function ProductCard({ p, t, name, onPress, onAdd }) {
  const off = Math.round((1 - p.groupPrice / p.price) * 100);
  return (
    <Press onPress={onPress}>
      <View style={styles.pCard}>
        <View style={styles.pImg}>
          <Text style={{ fontSize: 36 }}>{p.emoji}</Text>
          <View style={{ position: 'absolute', top: 7, left: 7 }}><Badge text={`−${off}%`} /></View>
          <View style={styles.soldPill}>
            <Text style={{ color: '#fff', fontSize: 8.5, fontWeight: '800' }}>🔥 {fmtInt(p.sold)}</Text>
          </View>
        </View>
        <Text numberOfLines={2} style={{ fontSize: 11.5, fontWeight: '700', color: C.ink, marginTop: 8, height: 32, lineHeight: 16 }}>{name(p)}</Text>
        <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 5 }}>
          <Price value={p.groupPrice} old={p.price} size={14} />
          <Press onPress={onAdd} hitSlop={10} scaleTo={0.85}>
            <LinearGradient colors={G.brand} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.addBtn}>
              <Ionicons name="add" size={16} color="#fff" />
            </LinearGradient>
          </Press>
        </View>
        <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: 5 }}>
          <Ionicons name="star" size={9} color={C.gold} />
          <Text style={{ fontSize: 9, color: C.muted, marginLeft: 2 }}>{p.rating} · {p.rc} {t('reviews')}</Text>
        </View>
      </View>
    </Press>
  );
}

const styles = StyleSheet.create({
  hero: { paddingTop: 14, paddingHorizontal: 16, paddingBottom: 20, borderBottomLeftRadius: 26, borderBottomRightRadius: 26, overflow: 'hidden' },
  circle: { position: 'absolute', width: 200, height: 200, borderRadius: 100, backgroundColor: 'rgba(255,255,255,0.13)', right: -60, top: -80 },
  greet: { fontSize: 11, color: 'rgba(255,255,255,0.88)', fontWeight: '600' },
  uname: { fontSize: 19, fontWeight: '800', color: '#fff', letterSpacing: -0.5, marginTop: 2 },
  iconBtn: { width: 36, height: 36, borderRadius: 12, backgroundColor: 'rgba(255,255,255,0.2)', alignItems: 'center', justifyContent: 'center' },
  avatar: { width: 36, height: 36, borderRadius: 18, backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center' },
  search: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'rgba(255,255,255,0.98)', borderRadius: 14, paddingHorizontal: 13, paddingVertical: 11, marginTop: 14 },
  statsRow: { flexDirection: 'row', alignItems: 'center', marginTop: 14, backgroundColor: 'rgba(0,0,0,0.14)', borderRadius: 15, paddingVertical: 9 },
  stat: { flex: 1, alignItems: 'center' },
  statV: { fontSize: 13.5, fontWeight: '800', color: '#fff' },
  statL: { fontSize: 8.5, color: 'rgba(255,255,255,0.8)', marginTop: 2 },
  statSep: { width: 1, height: 22, backgroundColor: 'rgba(255,255,255,0.22)' },
  chip: { paddingHorizontal: 13, paddingVertical: 8, borderRadius: 99, backgroundColor: '#fff', ...S.shadow },
  card: { backgroundColor: '#fff', borderRadius: 16, padding: 11, ...S.shadow },
  thumb: { width: 46, height: 46, borderRadius: 13, backgroundColor: '#F0F3FA', alignItems: 'center', justifyContent: 'center' },
  grid: { flexDirection: 'row', flexWrap: 'wrap', paddingHorizontal: 10, gap: 10 },
  pCard: { width: (W - 30) / 2, backgroundColor: '#fff', borderRadius: 17, padding: 10, ...S.shadow },
  pImg: { height: 106, borderRadius: 13, backgroundColor: '#F0F3FA', alignItems: 'center', justifyContent: 'center' },
  soldPill: { position: 'absolute', bottom: 6, right: 6, backgroundColor: 'rgba(15,18,25,0.8)', borderRadius: 8, paddingHorizontal: 6, paddingVertical: 3 },
  addBtn: { width: 28, height: 28, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
});
