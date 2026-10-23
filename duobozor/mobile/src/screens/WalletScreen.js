// Ҳамён: бақия, escrow, кэшбэк, ҳаракатҳо
import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { C, S, fmt } from '../theme';
import { Btn, Empty, Header, Badge } from '../components/ui';
import { useApp } from '../store';

export default function WalletScreen() {
  const { t, state, myWallet, escrowTotal, myOrders } = useApp();
  const txn = myOrders.slice(0, 8).map((o) => ({
    id: o.id,
    title: `#${o.no}`,
    sub: new Date(o.createdAt).toLocaleDateString('ru-RU'),
    amount: o.escrow.state === 'held' ? -o.escrow.amount : 0,
    kind: o.escrow.state === 'held' ? 'escrow' : 'done',
    cashback: o.split ? Math.round(o.escrow.amount * 0.01) : 0,
  }));

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={t('wallet_title')} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 24 }}>
        <LinearGradient colors={['#12151C', '#333D52']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.card}>
          <Text style={{ fontSize: 10.5, color: '#9DA6BA' }}>{t('available')}</Text>
          <Text style={styles.bal}>{fmt(myWallet.balance)} c.</Text>
          <View style={{ flexDirection: 'row', gap: 24, marginTop: 16 }}>
            <View>
              <Text style={{ fontSize: 9.5, color: '#9DA6BA' }}>{t('escrow')}</Text>
              <Text style={{ fontSize: 14, fontWeight: '800', color: '#FFC24A', marginTop: 2 }}>{fmt(escrowTotal)}</Text>
            </View>
            <View>
              <Text style={{ fontSize: 9.5, color: '#9DA6BA' }}>{t('cashback')}</Text>
              <Text style={{ fontSize: 14, fontWeight: '800', color: '#7CE3A8', marginTop: 2 }}>{fmt(myWallet.cashback || 0)}</Text>
            </View>
            <View>
              <Text style={{ fontSize: 9.5, color: '#9DA6BA' }}>{t('orders_title')}</Text>
              <Text style={{ fontSize: 14, fontWeight: '800', color: '#fff', marginTop: 2 }}>{myOrders.length}</Text>
            </View>
          </View>
        </LinearGradient>

        <View style={{ flexDirection: 'row', gap: 8, marginTop: 14 }}>
          <Btn title={t('topup')} kind="ghost" small style={{ flex: 1 }} onPress={() => {}} />
          <Btn title={t('withdraw')} kind="ghost" small style={{ flex: 1 }} onPress={() => {}} />
        </View>

        <Text style={{ fontSize: 13, fontWeight: '800', color: C.ink, marginTop: 20, marginBottom: 10 }}>{t('transactions')}</Text>
        {!txn.length ? <Empty icon="wallet-outline" title={t('no_txn')} /> : (
          <View style={styles.listCard}>
            {txn.map((x, i) => (
              <View key={x.id} style={[styles.txn, i === txn.length - 1 && { borderBottomWidth: 0 }]}>
                <View style={[styles.txnIco, { backgroundColor: x.kind === 'escrow' ? C.greenSoft : C.blueSoft }]}>
                  <Ionicons name={x.kind === 'escrow' ? 'shield-checkmark' : 'checkmark-done'} size={15} color={x.kind === 'escrow' ? C.green : C.blue} />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 12, fontWeight: '700', color: C.ink }}>{x.title}</Text>
                  <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{x.sub}</Text>
                </View>
                <View style={{ alignItems: 'flex-end' }}>
                  <Text style={{ fontSize: 12.5, fontWeight: '800', color: x.amount < 0 ? C.ink : C.green }}>
                    {x.amount < 0 ? `−${fmt(-x.amount)}` : `+${fmt(x.amount)}`}
                  </Text>
                  {x.cashback ? <Text style={{ fontSize: 9, color: C.goldText }}>+{fmt(x.cashback)} кэшбэк</Text> : null}
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
  card: { borderRadius: 20, padding: 18, overflow: 'hidden' },
  bal: { fontSize: 30, fontWeight: '800', color: '#fff', letterSpacing: -1.2, marginTop: 2 },
  listCard: { backgroundColor: '#fff', borderRadius: 16, paddingHorizontal: 14, ...S.shadow },
  txn: { flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 11, borderBottomWidth: 1, borderBottomColor: '#F1F3F8' },
  txnIco: { width: 34, height: 34, borderRadius: 11, alignItems: 'center', justifyContent: 'center' },
});
