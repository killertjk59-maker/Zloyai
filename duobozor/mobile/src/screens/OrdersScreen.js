// Фармоишҳо: рӯйхат + тафсил бо «Гирифтам» (escrow release)
import React from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { C, S, fmt } from '../theme';
import { Btn, Badge, Empty, EscrowBox, Header, KV, Price, Timeline, tap } from '../components/ui';
import { useApp } from '../store';

const STATUS_KEY = {
  PAID_HELD: 'status_paid', PACKED: 'status_packed', SHIPPED: 'status_shipped',
  DELIVERED: 'status_delivered', COMPLETED: 'status_completed',
  CANCELLED: 'status_cancelled', DISPUTED: 'status_disputed', REFUNDED: 'status_cancelled',
};
const STATUS_COLOR = {
  PAID_HELD: 'gold', PACKED: 'blue', SHIPPED: 'blue', DELIVERED: 'green',
  COMPLETED: 'green', DISPUTED: 'red', REFUNDED: 'gray', CANCELLED: 'gray',
};

export function OrdersScreen({ go }) {
  const { t, name, myOrders } = useApp();
  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={t('orders_title')} />
      {!myOrders.length ? (
        <Empty icon="receipt-outline" title={t('no_orders')} />
      ) : (
        <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 20 }}>
          {myOrders.map((o) => (
            <Pressable key={o.id} onPress={() => { tap(); go && go('order', o.id); }} style={styles.card}>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                <Text style={{ fontSize: 11, fontWeight: '800', color: C.ink2 }}>#{o.no}</Text>
                <Badge text={t(STATUS_KEY[o.status])} kind={STATUS_COLOR[o.status]} />
              </View>
              <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: 10 }}>
                <View style={styles.thumb}><Text style={{ fontSize: 22 }}>{o.items[0].emoji}</Text></View>
                <View style={{ flex: 1, marginLeft: 10 }}>
                  <Text numberOfLines={1} style={{ fontSize: 12.5, fontWeight: '700', color: C.ink }}>{o.items[0].title}</Text>
                  <Text style={{ fontSize: 10, color: C.muted, marginTop: 3 }}>
                    {o.items.length} мол · {new Date(o.createdAt).toLocaleDateString('ru-RU')}
                  </Text>
                </View>
                <Price value={o.total} size={15} />
              </View>
              {o.escrow.state === 'held' ? (
                <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: 10, backgroundColor: '#E6F7EE', borderRadius: 10, padding: 8 }}>
                  <Ionicons name="shield-checkmark" size={13} color="#0C7A3C" />
                  <Text style={{ fontSize: 10, color: '#0C7A3C', fontWeight: '700', marginLeft: 6 }}>
                    {fmt(o.escrow.amount)} c. {t('in_escrow')}
                  </Text>
                </View>
              ) : null}
            </Pressable>
          ))}
        </ScrollView>
      )}
    </View>
  );
}

export function OrderDetailScreen({ id, back }) {
  const { t, name, state, confirmReceipt, advanceOrder, openDispute, showToast } = useApp();
  const o = state.orders.find((x) => x.id === id);
  if (!o) return null;

  const canConfirm = ['DELIVERED', 'SHIPPED'].includes(o.status) && o.escrow.state === 'held';
  const steps = [
    { s: 'paid', title: t('status_paid'), at: o.createdAt },
    { s: 'packed', title: t('status_packed') },
    { s: 'shipped', title: t('status_shipped') },
    { s: 'delivered', title: t('status_delivered') },
    { s: 'completed', title: t('status_completed') },
  ];
  const doneSet = new Set(o.timeline.map((x) => x.s));
  const items = steps.map((st) => ({
    ...st,
    now: o.escrow.state === 'held' && !doneSet.has(nextOf(st.s, doneSet)),
  }));
  function nextOf(s, done) {
    const order = ['paid', 'packed', 'shipped', 'delivered', 'completed'];
    const i = order.indexOf(s);
    return done.has(s) ? order[i + 1] : s;
  }

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={`#${o.no}`} onBack={back} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 24 }}>
        <EscrowBox t={t} amount={o.escrow.state === 'held' ? o.escrow.amount : null} />

        <View style={[styles.card, { marginTop: 10 }]}>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 12 }}>
            <Text style={{ fontSize: 12.5, fontWeight: '800', color: C.ink }}>{t('timeline')}</Text>
            <Badge text={t(STATUS_KEY[o.status])} kind={STATUS_COLOR[o.status]} />
          </View>
          {items.map((it, i) => (
            <View key={it.s} style={{ flexDirection: 'row', minHeight: 40 }}>
              <View style={{ width: 16, alignItems: 'center' }}>
                <View style={[styles.dot, { backgroundColor: doneSet.has(it.s) ? C.green : it.now ? C.red : '#D5DBE7' }]} />
                {i < items.length - 1 && <View style={{ width: 2, flex: 1, backgroundColor: '#E7E9F0' }} />}
              </View>
              <View style={{ flex: 1, paddingBottom: 12, paddingLeft: 4 }}>
                <Text style={{ fontSize: 12.5, fontWeight: '700', color: doneSet.has(it.s) ? C.ink : it.now ? C.red : '#A6AEC2' }}>{it.title}</Text>
                {it.at ? <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{new Date(it.at).toLocaleString('ru-RU')}</Text> : null}
              </View>
            </View>
          ))}
        </View>

        <View style={[styles.card, { marginTop: 10 }]}>
          {o.items.map((it, i) => (
            <KV key={i} k={`${it.title} × ${it.qty}`} v={`${fmt(it.line)} c.`} />
          ))}
          <View style={{ height: 1, backgroundColor: C.line, marginVertical: 6 }} />
          <KV k={t('total')} v={`${fmt(o.total)} c.`} bold color={C.red} />
        </View>

        {o.split ? (
          <View style={[styles.card, { marginTop: 10 }]}>
            <Text style={{ fontSize: 11, fontWeight: '800', color: C.green, marginBottom: 8 }}>{t('release_done')}</Text>
            <KV k="Payment fee" v={`${fmt(o.split.paymentFee)} c.`} />
            <KV k="Commission" v={`${fmt(o.split.commission)} c.`} />
            <KV k="Manager bonus" v={`${fmt(o.split.managerBonus)} c.`} />
            <KV k="Seller payout" v={`${fmt(o.split.sellerPayout)} c.`} bold color={C.green} />
          </View>
        ) : null}

        {o.escrow.state === 'held' && (
          <View style={{ marginTop: 10, flexDirection: 'row', gap: 8 }}>
            <Badge text={t('auto_release')} kind="gold" />
          </View>
        )}
      </ScrollView>

      <View style={styles.cta}>
        {o.escrow.state === 'held' && o.status !== 'DISPUTED' ? (
          <>
            <Btn title={t('dispute')} kind="ghost" style={{ flex: 0.45 }} onPress={() => { openDispute(o.id); showToast(t('dispute')); }} />
            <Btn
              title={`✓ ${t('confirm_receipt')}`}
              style={{ flex: 1 }}
              disabled={!canConfirm}
              onPress={() => {
                const r = confirmReceipt(o.id);
                if (r.ok) showToast(`${t('release_done')} · ${fmt(r.split.sellerPayout)} c.`);
                else showToast(r.error || t('error'), 'err');
              }}
            />
          </>
        ) : (
          <Btn title={t('close')} onPress={back} />
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { backgroundColor: '#fff', borderRadius: 16, padding: 14, ...S.shadow },
  thumb: { width: 46, height: 46, borderRadius: 12, backgroundColor: '#EEF1F8', alignItems: 'center', justifyContent: 'center' },
  dot: { width: 11, height: 11, borderRadius: 6, marginTop: 3 },
  cta: { flexDirection: 'row', gap: 9, padding: 12, paddingBottom: 20, backgroundColor: '#fff', borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: C.line },
});
