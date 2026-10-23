// Панели фурӯшанда: фурӯш, pending, дастрас, пардохт, интиқол
import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { C, S, fmt } from '../theme';
import { Badge, Btn, Card, Divider, Empty, Header, KV, Progress, tap } from '../components/ui';
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
        <LinearGradient colors={['#12151C', '#2E394C']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.card}>
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
          <View style={{ flexDirection: 'row', gap: 26, marginTop: 14 }}>
            <View>
              <Text style={{ fontSize: 9, color: '#9DA6BA' }}>{t('seller_pending')}</Text>
              <Text style={{ fontSize: 13.5, fontWeight: '800', color: '#FFC24A', marginTop: 2 }}>{fmt(w.pending || 0)}</Text>
            </View>
            <View>
              <Text style={{ fontSize: 9, color: '#9DA6BA' }}>{t('seller_sales')}</Text>
              <Text style={{ fontSize: 13.5, fontWeight: '800', color: '#fff', marginTop: 2 }}>{fmt(sales)}</Text>
            </View>
            <View>
              <Text style={{ fontSize: 9, color: '#9DA6BA' }}>{t('seller_orders')}</Text>
              <Text style={{ fontSize: 13.5, fontWeight: '800', color: '#fff', marginTop: 2 }}>{orders.length}</Text>
            </View>
          </View>
        </LinearGradient>

        <Card style={{ marginTop: 12 }}>
          <Text style={{ fontSize: 12.5, fontWeight: '800', color: C.ink }}>{t('seller_payout')}</Text>
          <Text style={{ fontSize: 10, color: C.muted, marginTop: 3 }}>
            {t('seller_payout_min')} · 2 тасдиқ барои &gt; {fmt(RULES.fourEyeThreshold)} c.
          </Text>
          <View style={styles.amtRow}>
            <Text style={{ fontSize: 17, fontWeight: '800', color: C.ink }}>{amount || '0'}</Text>
            <Text style={{ fontSize: 12, color: C.muted, marginLeft: 4 }}>c.</Text>
            <View style={{ flex: 1 }} />
            <Btn title={t('seller_payout')} small style={{ width: 140 }} onPress={ask} />
          </View>
          <Progress value={w.balance / Math.max(1, (w.balance || 0) + (w.pending || 0))} color={C.green} height={5} />
        </Card>

        <Text style={styles.section}>{t('seller_orders')}</Text>
        {!orders.length ? <Empty icon="cube-outline" title={t('no_orders')} /> : orders.map((o) => (
          <Pressable key={o.id} onPress={() => { tap(); go && go('order', o.id); }} style={styles.orderRow}>
            <View style={{ flex: 1 }}>
              <Text style={{ fontSize: 12, fontWeight: '800', color: C.ink }}>#{o.no}</Text>
              <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{o.items[0]?.title} × {o.items[0]?.qty}</Text>
              <Text style={{ fontSize: 9.5, color: C.muted, marginTop: 2 }}>
                {o.escrow.state === 'held' ? `🛡 ${fmt(o.escrow.amount)} c. ${t('in_escrow')}` : `✓ ${fmt(o.escrow.amount)} c.`}
              </Text>
            </View>
            <View style={{ alignItems: 'flex-end', gap: 6 }}>
              <Badge text={o.status} kind={o.status === 'COMPLETED' ? 'green' : 'gold'} />
              {['PAID_HELD', 'PACKED'].includes(o.status) ? (
                <Pressable onPress={() => { tap(); advanceOrder(o.id); showToast(t('success')); }} style={styles.ship}>
                  <Ionicons name="cube" size={11} color={C.blue} />
                  <Text style={{ fontSize: 9.5, fontWeight: '800', color: C.blue, marginLeft: 4 }}>{t('seller_ship')}</Text>
                </Pressable>
              ) : null}
            </View>
          </Pressable>
        ))}

        <Text style={styles.section}>{t('admin_payouts')}</Text>
        <Card style={{ padding: 6 }}>
          {!payouts.length ? <Text style={{ fontSize: 11, color: C.muted, padding: 10 }}>{t('admin_no_data')}</Text> : payouts.map((p, i) => (
            <View key={p.id} style={[styles.payoutRow, i === payouts.length - 1 && { borderBottomWidth: 0 }]}>
              <Ionicons name={p.status === 'sent' ? 'checkmark-circle' : 'time-outline'} size={16} color={p.status === 'sent' ? C.green : C.gold} />
              <Text style={{ flex: 1, fontSize: 11.5, color: C.ink, marginLeft: 8 }}>{new Date(p.createdAt).toLocaleDateString('ru-RU')}</Text>
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
  amtRow: { flexDirection: 'row', alignItems: 'center', marginVertical: 12 },
  section: { fontSize: 11, fontWeight: '800', color: C.muted, marginTop: 18, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 0.5 },
  orderRow: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 14, padding: 12, marginBottom: 8, ...S.shadow },
  ship: { flexDirection: 'row', alignItems: 'center', backgroundColor: C.blueSoft, borderRadius: 8, paddingHorizontal: 7, paddingVertical: 4 },
  payoutRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10, paddingHorizontal: 8, borderBottomWidth: 1, borderBottomColor: '#F1F3F8' },
});
