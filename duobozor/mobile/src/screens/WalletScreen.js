// Ҳамён: бақия, escrow, кэшбэк, ҳаракатҳо
import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { C, S, G, fmt, fmtDate } from '../theme';
import { Btn, Empty, Header, Badge, FadeIn, Press } from '../components/ui';
import { useApp } from '../store';

export default function WalletScreen({ back }) {
  const { t, state, myWallet, escrowTotal, myOrders, showToast } = useApp();
  const txn = myOrders.slice(0, 10).map((o) => ({
    id: o.id,
    title: `#${o.no}`,
    sub: fmtDate(o.createdAt),
    amount: o.escrow.state === 'held' ? -o.escrow.amount : -o.escrow.amount,
    kind: o.escrow.state === 'held' ? 'escrow' : 'done',
    cashback: o.split ? Math.round(o.escrow.amount * 0.01) : 0,
  }));

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={t('wallet_title')} onBack={back} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 24 }}>
        <FadeIn>
          <LinearGradient colors={G.dark} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.card}>
            <View style={styles.circle} />
            <View style={{ flexDirection: 'row', alignItems: 'center' }}>
              <Text style={{ fontSize: 10.5, color: '#9DA6BA' }}>{t('available')}</Text>
              <View style={{ marginLeft: 'auto' }}><Badge text="TJS" kind="gray" /></View>
            </View>
            <Text style={styles.bal}>{fmt(myWallet.balance)}</Text>
            <View style={{ flexDirection: 'row', gap: 22, marginTop: 16 }}>
              <View>
                <Text style={styles.k}>{t('escrow')}</Text>
                <Text style={[styles.v, { color: '#FFC24A' }]}>{fmt(escrowTotal)}</Text>
              </View>
              <View>
                <Text style={styles.k}>{t('cashback')}</Text>
                <Text style={[styles.v, { color: '#7CE3A8' }]}>{fmt(myWallet.cashback || 0)}</Text>
              </View>
              <View>
                <Text style={styles.k}>{t('orders_title')}</Text>
                <Text style={styles.v}>{myOrders.length}</Text>
              </View>
            </View>
          </LinearGradient>
        </FadeIn>

        <View style={{ flexDirection: 'row', gap: 8, marginTop: 14 }}>
          <Btn title={t('topup')} kind="ghost" small style={{ flex: 1 }} icon="add-circle-outline" onPress={() => showToast('Демо: пуркунӣ дастрас нест', 'err')} />
          <Btn title={t('withdraw')} kind="ghost" small style={{ flex: 1 }} icon="arrow-up-circle-outline" onPress={() => showToast('Демо: баровардан дастрас нест', 'err')} />
        </View>

        <Text style={styles.section}>{t('transactions')}</Text>
        {!txn.length ? <Empty icon="wallet-outline" title={t('no_txn')} /> : (
          <View style={styles.listCard}>
            {txn.map((x, i) => (
              <View key={x.id} style={[styles.txn, i === txn.length - 1 && { borderBottomWidth: 0 }]}>
                <View style={[styles.txnIco, { backgroundColor: x.kind === 'escrow' ? C.greenSoft : C.blueSoft }]}>
                  <Ionicons name={x.kind === 'escrow' ? 'shield-checkmark' : 'checkmark-done'} size={15} color={x.kind === 'escrow' ? C.green : C.blue} />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 12, fontWeight: '700', color: C.ink }}>{x.title}</Text>
                  <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{x.sub} · {x.kind === 'escrow' ? t('in_escrow') : t('status_completed')}</Text>
                </View>
                <View style={{ alignItems: 'flex-end' }}>
                  <Text style={{ fontSize: 12.5, fontWeight: '800', color: C.ink }}>−{fmt(-x.amount)}</Text>
                  {x.cashback ? <Text style={{ fontSize: 9, color: C.goldText }}>+{fmt(x.cashback)} {t('cashback')}</Text> : null}
                </View>
              </View>
            ))}
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { borderRadius: 22, padding: 18, overflow: 'hidden' },
  circle: { position: 'absolute', width: 180, height: 180, borderRadius: 90, backgroundColor: 'rgba(255,255,255,0.05)', top: -70, right: -50 },
  bal: { fontSize: 31, fontWeight: '800', color: '#fff', letterSpacing: -1.4, marginTop: 3 },
  k: { fontSize: 9.5, color: '#9DA6BA' },
  v: { fontSize: 14, fontWeight: '800', color: '#fff', marginTop: 2 },
  section: { fontSize: 13, fontWeight: '800', color: C.ink, marginTop: 20, marginBottom: 10 },
  listCard: { backgroundColor: '#fff', borderRadius: 17, paddingHorizontal: 14, ...S.shadow },
  txn: { flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 11, borderBottomWidth: 1, borderBottomColor: '#F1F3F8' },
  txnIco: { width: 34, height: 34, borderRadius: 11, alignItems: 'center', justifyContent: 'center' },
});
