// Панели фурӯшанда: фурӯш, pending, дастрас, пардохт, интиқол
import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { C, S, G, fmt, fmtDate } from '../theme';
import { Badge, Btn, Card, Empty, Header, Progress, Press, FadeIn } from '../components/ui';
import { useApp } from '../store';
import { RULES } from '../lib/money';

export default function SellerScreen({ back, go }) {
  const { t, name, state, requestPayout, advanceOrder, showToast } = useApp();
  const SELLER_ID = 'u_seller1';
  const shop = state.shops.find((s) => s.sellerId === SELLER_ID) || state.shops[0];
  const w = state.wallets[SELLER_ID] || { balance: 0, pending: 0 };
  const orders = state.orders.filter((o) => o.shopId === shop.id);
  const done = orders.filter((o) => o.status === 'COMPLETED');
  const sales = done.reduce((a, b) => a + b.escrow.amount, 0);
  const payouts = state.payouts.filter((p) => p.sellerId === SELLER_ID);
  const [amount, setAmount] = useState(String(Math.floor((w.balance || 0) / 100)));

  const ask = () => {
    const v = Math.round(Number(amount || 0) * 100);
    if (!v) { showToast(t('error'), 'err'); return; }
    const r = requestPayout(v);
    showToast(r.ok ? t('seller_payout_ok') : r.error, r.ok ? 'ok' : 'err');
  };

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={t('seller_dash')} onBack={back} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 24 }}>
        <FadeIn>
          <LinearGradient colors={G.dark} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.card}>
            <View style={{ flexDirection: 'row', alignItems: 'center' }}>
              <View style={styles.shopIco}><Text style={{ fontSize: 18 }}>🏪</Text></View>
              <View style={{ flex: 1 }}>
                <Text style={{ fontSize: 13.5, fontWeight: '800', color: '#fff' }}>{shop.name}</Text>
                <Text style={{ fontSize: 10, color: '#9DA6BA', marginTop: 2 }}>{shop.region} · ★ {shop.rating}</Text>
              </View>
              <Badge text="KYC ✓" kind="green" />
            </View>
            <Text style={{ fontSize: 9.5, color: '#9DA6BA', marginTop: 18 }}>{t('seller_available')}</Text>
            <Text style={{ fontSize: 27, fontWeight: '800', color: '#fff', letterSpacing: -1 }}>{fmt(w.balance || 0)} c.</Text>
            <View style={{ flexDirection: 'row', gap: 24, marginTop: 14 }}>
              <View>
                <Text style={styles.k}>{t('seller_pending')}</Text>
                <Text style={[styles.v, { color: '#FFC24A' }]}>{fmt(w.pending || 0)}</Text>
              </View>
              <View>
                <Text style={styles.k}>{t('seller_sales')}</Text>
                <Text style={styles.v}>{fmt(sales)}</Text>
              </View>
              <View>
                <Text style={styles.k}>{t('seller_orders')}</Text>
                <Text style={styles.v}>{orders.length}</Text>
              </View>
            </View>
          </LinearGradient>
        </FadeIn>

        <Card style={{ marginTop: 12 }}>
          <Text style={{ fontSize: 12.5, fontWeight: '800', color: C.ink }}>{t('seller_payout')}</Text>
          <Text style={{ fontSize: 10, color: C.muted, marginTop: 3 }}>{t('seller_payout_min')} · 2 тасдиқ барои &gt; {fmt(RULES.fourEyeThreshold)} c.</Text>
          <View style={{ flexDirection: 'row', alignItems: 'center', marginVertical: 12 }}>
            <Text style={{ fontSize: 18, fontWeight: '800', color: C.ink }}>{amount || '0'}</Text>
            <Text style={{ fontSize: 12, color: C.muted, marginLeft: 4 }}>c.</Text>
            <View style={{ flex: 1 }} />
            <Btn title={t('seller_payout')} small style={{ width: 140 }} onPress={ask} />
          </View>
          <Progress value={(w.balance || 0) / Math.max(1, (w.balance || 0) + (w.pending || 0))} color={C.green} height={5} />
        </Card>

        <Text style={styles.section}>{t('seller_orders')}</Text>
        {!orders.length ? <Empty icon="cube-outline" title={t('no_orders')} /> : orders.map((o, i) => (
          <FadeIn key={o.id} delay={i * 40} dy={8}>
            <Press onPress={() => go('order', o.id)} style={{ marginBottom: 8 }}>
              <View style={styles.orderRow}>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 12, fontWeight: '800', color: C.ink }}>#{o.no}</Text>
                  <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{o.items[0] && o.items[0].title} × {o.items[0] && o.items[0].qty}</Text>
                  <Text style={{ fontSize: 9.5, color: o.escrow.state === 'held' ? C.goldText : C.green, marginTop: 2, fontWeight: '700' }}>
                    {o.escrow.state === 'held' ? `🛡 ${fmt(o.escrow.amount)} c. ${t('in_escrow')}` : `✓ ${fmt(o.escrow.amount)} c.`}
                  </Text>
                </View>
                <View style={{ alignItems: 'flex-end', gap: 6 }}>
                  <Badge text={o.status} kind={o.status === 'COMPLETED' ? 'green' : 'gold'} />
                  {['PAID_HELD', 'PACKED'].includes(o.status) ? (
                    <Press onPress={() => { advanceOrder(o.id); showToast(t('success')); }} scaleTo={0.9}>
                      <View style={styles.ship}>
                        <Ionicons name="cube" size={11} color={C.blue} />
                        <Text style={{ fontSize: 9.5, fontWeight: '800', color: C.blue, marginLeft: 4 }}>{t('seller_ship')}</Text>
                      </View>
                    </Press>
                  ) : null}
                </View>
              </View>
            </Press>
          </FadeIn>
        ))}

        <Text style={styles.section}>{t('admin_payouts')}</Text>
        <Card style={{ padding: 6 }}>
          {!payouts.length ? <Text style={{ fontSize: 11, color: C.muted, padding: 10 }}>{t('admin_no_data')}</Text> : payouts.map((p, i) => (
            <View key={p.id} style={[styles.payoutRow, i === payouts.length - 1 && { borderBottomWidth: 0 }]}>
              <Ionicons name={p.status === 'sent' ? 'checkmark-circle' : 'time-outline'} size={16} color={p.status === 'sent' ? C.green : C.gold} />
              <Text style={{ flex: 1, fontSize: 11.5, color: C.ink, marginLeft: 8 }}>{fmtDate(p.createdAt)}</Text>
              <Text style={{ fontSize: 12, fontWeight: '800', color: C.ink }}>{fmt(p.amount)} c.</Text>
            </View>
          ))}
        </Card>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { borderRadius: 20, padding: 16 },
  shopIco: { width: 40, height: 40, borderRadius: 13, backgroundColor: 'rgba(255,255,255,0.14)', alignItems: 'center', justifyContent: 'center', marginRight: 10 },
  k: { fontSize: 9, color: '#9DA6BA' },
  v: { fontSize: 13.5, fontWeight: '800', color: '#fff', marginTop: 2 },
  section: { fontSize: 10.5, fontWeight: '800', color: C.muted, marginTop: 18, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 0.6 },
  orderRow: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 15, padding: 12, ...S.shadow },
  ship: { flexDirection: 'row', alignItems: 'center', backgroundColor: C.blueSoft, borderRadius: 8, paddingHorizontal: 7, paddingVertical: 4 },
  payoutRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10, paddingHorizontal: 8, borderBottomWidth: 1, borderBottomColor: '#F1F3F8' },
});
