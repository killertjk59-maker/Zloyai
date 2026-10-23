// Маҳсулот: нархи зинавӣ, escrow-кафолат, «Гурӯҳ соз» / «Ҳамроҳ шав»
import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { C, S, fmt } from '../theme';
import { Btn, Badge, Price, EscrowBox, Header, tap } from '../components/ui';
import { useApp } from '../store';

export default function ProductScreen({ id, back, go }) {
  const { t, name, state, addToCart, createGroupBuy } = useApp();
  const p = state.products.find((x) => x.id === id);
  const [tier, setTier] = useState(2);
  if (!p) return null;

  const shop = state.shops.find((s) => s.id === p.shopId);
  const off = Math.round((1 - p.groupPrice / p.price) * 100);
  const price = tier === 1 ? p.price : tier === 2 ? p.groupPrice : p.group5;

  const start = () => {
    if (tier === 1) {
      addToCart(p.id, 1);
      go && go('cart');
    } else {
      const g = createGroupBuy(p.id, tier);
      go && go('group', g.id);
    }
  };

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 20 }}>
        <View style={styles.hero}>
          <Text style={{ fontSize: 82 }}>{p.emoji}</Text>
          <Pressable onPress={() => { tap(); back(); }} style={styles.back}><Ionicons name="chevron-back" size={20} color={C.ink} /></Pressable>
          <View style={{ position: 'absolute', top: 14, right: 16 }}><Badge text={`−${off}%`} /></View>
        </View>

        <View style={styles.sheet}>
          <View style={{ flexDirection: 'row', alignItems: 'baseline' }}>
            <Price value={price} size={27} old={tier === 1 ? null : p.price} />
            <View style={{ marginLeft: 'auto' }}><Badge text={t('product_group_price')} kind="green" /></View>
          </View>

          <Text style={styles.title}>{name(p)}</Text>
          <Text style={{ fontSize: 12, color: C.muted, marginTop: 6, lineHeight: 18 }}>{state.lang === 'ru' ? p.desc_ru : p.desc_tj}</Text>

          <View style={{ flexDirection: 'row', gap: 8, marginTop: 10, alignItems: 'center' }}>
            <Badge text={`★ ${p.rating}`} kind="gold" />
            <Text style={{ fontSize: 10.5, color: C.muted }}>{p.rc} {t('reviews')} · {p.sold} {t('sold')}</Text>
            <Text style={{ fontSize: 10.5, color: p.stock > 0 ? C.green : C.red, marginLeft: 'auto', fontWeight: '700' }}>
              {p.stock > 0 ? `${p.stock} ${t('stock')}` : t('out_of_stock')}
            </Text>
          </View>

          <Text style={{ fontSize: 11.5, fontWeight: '800', color: C.ink, marginTop: 16, marginBottom: 8 }}>{t('product_tier')}</Text>
          <View style={{ flexDirection: 'row', gap: 8 }}>
            {[
              { n: 1, label: t('alone'), val: p.price },
              { n: 2, label: t('pair'), val: p.groupPrice },
              { n: 5, label: t('group'), val: p.group5 },
            ].map((o) => (
              <Pressable
                key={o.n}
                onPress={() => { tap(); setTier(o.n); }}
                style={[styles.tier, tier === o.n && styles.tierOn]}
              >
                <Text style={[styles.tierN, tier === o.n && { color: C.red }]}>{o.n}</Text>
                <Text style={styles.tierL}>{o.label}</Text>
                <Text style={[styles.tierP, tier === o.n && { color: C.red }]}>{fmt(o.val)}</Text>
              </Pressable>
            ))}
          </View>

          <View style={{ marginTop: 14 }}><EscrowBox t={t} /></View>

          <View style={[styles.card, { marginTop: 12, flexDirection: 'row', alignItems: 'center' }]}>
            <View style={styles.shopIco}><Text style={{ fontSize: 16 }}>🏪</Text></View>
            <View style={{ flex: 1 }}>
              <Text style={{ fontSize: 12, fontWeight: '800', color: C.ink }}>{shop?.name || 'DuoBozor'}</Text>
              <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{shop?.region} · ✓ KYC {shop?.official ? 'verified' : ''}</Text>
            </View>
            <Badge text={`★ ${shop?.rating ?? 4.5}`} kind="blue" />
          </View>

          {tier > 1 && (
            <View style={styles.hintCard}>
              <Text style={{ fontSize: 12, fontWeight: '800', color: '#8A5B00' }}>🎁 {t('create_group')} — {tier} {t('group_people')}</Text>
              <Text style={{ fontSize: 10.5, color: '#A98C4D', marginTop: 3 }}>
                {t('group_hint')} — {fmt(p.price - price)} c.
              </Text>
            </View>
          )}
        </View>
      </ScrollView>

      <View style={styles.cta}>
        <Btn
          title={tier === 1 ? t('cart_title') : t('create_group')}
          kind="ghost"
          style={{ flex: 0.42 }}
          onPress={() => { addToCart(p.id, 1); }}
        />
        <Btn title={t('join_group')} style={{ flex: 1 }} onPress={start} disabled={p.stock === 0} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  hero: { height: 250, backgroundColor: '#EEF1F8', alignItems: 'center', justifyContent: 'center' },
  back: { position: 'absolute', top: 14, left: 16, width: 34, height: 34, borderRadius: 11, backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center', ...S.shadow },
  sheet: { marginTop: -18, backgroundColor: '#fff', borderTopLeftRadius: 22, borderTopRightRadius: 22, padding: 16 },
  title: { fontSize: 14.5, fontWeight: '700', color: C.ink, marginTop: 10, lineHeight: 21 },
  tier: { flex: 1, borderWidth: 1.5, borderColor: C.line, borderRadius: 13, paddingVertical: 9, alignItems: 'center' },
  tierOn: { borderColor: C.red, backgroundColor: '#FFF7F5' },
  tierN: { fontSize: 15, fontWeight: '800', color: C.ink },
  tierL: { fontSize: 9.5, color: C.muted, marginTop: 1 },
  tierP: { fontSize: 11, fontWeight: '800', color: C.ink2, marginTop: 3 },
  card: { backgroundColor: '#fff', borderRadius: 16, padding: 14, ...S.shadow },
  shopIco: { width: 38, height: 38, borderRadius: 12, backgroundColor: '#EEF1F8', alignItems: 'center', justifyContent: 'center', marginRight: 10 },
  hintCard: { backgroundColor: '#FFF9EF', borderRadius: 14, padding: 12, marginTop: 12, borderWidth: 1, borderColor: '#F0DDB8', borderStyle: 'dashed' },
  cta: { flexDirection: 'row', gap: 9, padding: 12, paddingBottom: 20, backgroundColor: '#fff', borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: C.line },
});
