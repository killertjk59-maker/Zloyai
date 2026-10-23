// Маҳсулот: нархи зинавӣ, escrow, аниматсияи илова ба сабад
import React, { useRef, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Animated, Easing } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { C, S, G, fmt, fmtInt } from '../theme';
import { Btn, Badge, Price, EscrowBox, FadeIn, Press } from '../components/ui';
import { useApp } from '../store';

export default function ProductScreen({ id, back, go }) {
  const { t, name, state, addToCart, createGroupBuy, showToast } = useApp();
  const p = state.products.find((x) => x.id === id);
  const [tier, setTier] = useState(2);
  const fly = useRef(new Animated.Value(0)).current;
  const heart = useRef(new Animated.Value(0)).current;
  const [liked, setLiked] = useState(false);

  if (!p) {
    return (
      <View style={{ flex: 1, backgroundColor: C.bg, alignItems: 'center', justifyContent: 'center' }}>
        <Text style={{ fontSize: 13, color: C.muted }}>Мол ёфт нашуд</Text>
        <Btn title="Бозгашт" kind="ghost" style={{ marginTop: 12, width: 160 }} onPress={back} />
      </View>
    );
  }

  const shop = state.shops.find((s) => s.id === p.shopId);
  const off = Math.round((1 - p.groupPrice / p.price) * 100);
  const price = tier === 1 ? p.price : tier === 2 ? p.groupPrice : p.group5;

  const doAdd = () => {
    addToCart(p.id, 1);
    Animated.sequence([
      Animated.timing(fly, { toValue: 1, duration: 260, easing: Easing.out(Easing.cubic), useNativeDriver: true }),
      Animated.timing(fly, { toValue: 0, duration: 180, useNativeDriver: true }),
    ]).start();
    showToast(t('add_cart_ok'));
  };

  const like = () => {
    setLiked((v) => !v);
    heart.setValue(0);
    Animated.spring(heart, { toValue: 1, useNativeDriver: true, damping: 8, stiffness: 260 }).start();
  };

  const start = () => {
    if (tier === 1) { doAdd(); go('cart'); return; }
    const g = createGroupBuy(p.id, tier);
    if (!g) { showToast(t('error'), 'err'); return; }
    go('group', g.id);
  };

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 16 }}>
        <LinearGradient colors={['#F2F4FA', '#E9EDF6']} style={styles.hero}>
          <Text style={{ fontSize: 100 }}>{p.emoji}</Text>
          <Press testID="btn-back" onPress={back} style={styles.back} hitSlop={8}>
            <View style={styles.iconBtn}><Ionicons name="chevron-back" size={20} color={C.ink} /></View>
          </Press>
          <Press onPress={like} style={styles.like} hitSlop={8}>
            <Animated.View style={[styles.iconBtn, { transform: [{ scale: heart.interpolate({ inputRange: [0, 0.5, 1], outputRange: [1, 1.3, 1] }) }] }]}>
              <Ionicons name={liked ? 'heart' : 'heart-outline'} size={19} color={liked ? C.red : C.ink} />
            </Animated.View>
          </Press>
          <View style={{ position: 'absolute', bottom: 14, left: 16 }}><Badge text={`−${off}% ${t('product_group_price')}`} /></View>
        </LinearGradient>

        <FadeIn style={styles.sheet}>
          <View style={{ flexDirection: 'row', alignItems: 'flex-end' }}>
            <Price value={price} size={28} old={tier === 1 ? null : p.price} />
            <View style={{ marginLeft: 'auto', alignItems: 'flex-end' }}>
              <Text style={{ fontSize: 9.5, color: C.muted }}>{t('stock')}</Text>
              <Text style={{ fontSize: 12, fontWeight: '800', color: p.stock > 0 ? C.green : C.red }}>
                {p.stock > 0 ? `${fmtInt(p.stock)}` : t('out_of_stock')}
              </Text>
            </View>
          </View>

          <Text style={styles.title}>{name(p)}</Text>
          <Text style={styles.desc}>{state.lang === 'ru' ? p.desc_ru : p.desc_tj}</Text>

          <View style={{ flexDirection: 'row', gap: 8, marginTop: 10, alignItems: 'center' }}>
            <Badge text={`★ ${p.rating}`} kind="gold" />
            <Text style={{ fontSize: 10.5, color: C.muted }}>{fmtInt(p.rc)} {t('reviews')} · {fmtInt(p.sold)} {t('sold')}</Text>
          </View>

          <Text style={styles.section}>{t('product_tier')}</Text>
          <View style={{ flexDirection: 'row', gap: 8 }}>
            {[
              { n: 1, label: t('alone'), val: p.price },
              { n: 2, label: t('pair'), val: p.groupPrice },
              { n: 5, label: t('group'), val: p.group5 },
            ].map((o) => (
              <Press key={o.n} onPress={() => setTier(o.n)} containerStyle={{ flex: 1 }}>
                <View style={[styles.tier, tier === o.n && styles.tierOn]}>
                  <Text style={[styles.tierN, tier === o.n && { color: C.red }]}>{o.n}</Text>
                  <Text style={styles.tierL}>{o.label}</Text>
                  <Text style={[styles.tierP, tier === o.n && { color: C.red }]}>{fmt(o.val)}</Text>
                </View>
              </Press>
            ))}
          </View>

          <View style={{ marginTop: 14 }}><EscrowBox t={t} /></View>

          <View style={[styles.card, { marginTop: 12 }]}>
            <View style={{ flexDirection: 'row', alignItems: 'center' }}>
              <View style={styles.shopIco}><Text style={{ fontSize: 17 }}>🏪</Text></View>
              <View style={{ flex: 1 }}>
                <Text style={{ fontSize: 12, fontWeight: '800', color: C.ink }}>{shop ? shop.name : 'DuoBozor'}</Text>
                <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{shop ? shop.region : 'Хуҷанд'} · KYC ✓</Text>
              </View>
              <Badge text={`★ ${shop ? shop.rating : 4.5}`} kind="blue" />
            </View>
          </View>

          {tier > 1 ? (
            <View style={styles.hint}>
              <Text style={{ fontSize: 12, fontWeight: '800', color: '#8A5B00' }}>🎁 {t('create_group')} — {tier} {t('group_people')}</Text>
              <Text style={{ fontSize: 10.5, color: '#A98C4D', marginTop: 3 }}>{t('group_hint')} · −{fmt(p.price - price)} c.</Text>
            </View>
          ) : null}
        </FadeIn>
      </ScrollView>

      <Animated.View pointerEvents="none" style={[styles.flyDot, {
        opacity: fly,
        transform: [{ translateY: fly.interpolate({ inputRange: [0, 1], outputRange: [0, -90] }) }, { scale: fly.interpolate({ inputRange: [0, 1], outputRange: [1, 0.4] }) }],
      }]}>
        <Ionicons name="bag" size={22} color={C.red} />
      </Animated.View>

      <View style={styles.cta}>
        <Btn testID="btn-add-cart" title={t('add_cart_ok')} kind="ghost" style={{ flex: 0.44 }} onPress={doAdd} icon="bag-add-outline" />
        <Btn testID="btn-product-cta" title={tier === 1 ? t('checkout') : t('create_group')} style={{ flex: 1 }} onPress={start} disabled={p.stock === 0} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  hero: { height: 260, alignItems: 'center', justifyContent: 'center' },
  back: { position: 'absolute', top: 14, left: 16 },
  like: { position: 'absolute', top: 14, right: 16 },
  iconBtn: { width: 36, height: 36, borderRadius: 12, backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center', ...S.shadow },
  sheet: { marginTop: -20, backgroundColor: '#fff', borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: 16 },
  title: { fontSize: 14.5, fontWeight: '700', color: C.ink, marginTop: 10, lineHeight: 21 },
  desc: { fontSize: 11.5, color: C.muted, marginTop: 6, lineHeight: 18 },
  section: { fontSize: 11.5, fontWeight: '800', color: C.ink, marginTop: 16, marginBottom: 8 },
  tier: { borderWidth: 1.5, borderColor: C.line, borderRadius: 14, paddingVertical: 10, alignItems: 'center' },
  tierOn: { borderColor: C.red, backgroundColor: '#FFF7F5' },
  tierN: { fontSize: 16, fontWeight: '800', color: C.ink },
  tierL: { fontSize: 9.5, color: C.muted, marginTop: 1 },
  tierP: { fontSize: 11, fontWeight: '800', color: C.ink2, marginTop: 3 },
  card: { backgroundColor: '#fff', borderRadius: 16, padding: 13, borderWidth: 1, borderColor: C.line },
  shopIco: { width: 38, height: 38, borderRadius: 12, backgroundColor: '#F0F3FA', alignItems: 'center', justifyContent: 'center', marginRight: 10 },
  hint: { backgroundColor: '#FFF9EF', borderRadius: 14, padding: 12, marginTop: 12, borderWidth: 1, borderColor: '#F0DDB8', borderStyle: 'dashed' },
  flyDot: { position: 'absolute', bottom: 96, right: 30, backgroundColor: '#fff', borderRadius: 22, padding: 10, ...S.shadow },
  cta: { flexDirection: 'row', gap: 9, padding: 12, paddingBottom: 18, backgroundColor: '#fff', borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: C.line },
});
