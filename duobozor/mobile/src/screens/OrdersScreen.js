// Фармоишҳо + тафсил бо «Гирифтам» (escrow release)
import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { C, S, fmt, fmtDate, fmtTime, fmtDateTime } from '../theme';
import { Btn, Badge, Empty, EscrowBox, Header, KV, Price, Press, FadeIn } from '../components/ui';
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
      <Header title={t('orders_title')} right={<Badge text={`${myOrders.length}`} kind="gray" />} />
      {!myOrders.length ? (
        <Empty icon="receipt-outline" title={t('no_orders')} />
      ) : (
        <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 18 }}>
          {myOrders.map((o, i) => (
            <FadeIn key={o.id} delay={i * 45} dy={10}>
              <Press testID={'order-' + o.id} onPress={() => go('order', o.id)} style={{ marginBottom: 10 }}>
                <View style={styles.card}>
                  <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Text style={{ fontSize: 11, fontWeight: '800', color: C.ink2 }}>#{o.no}</Text>
                    <Badge text={t(STATUS_KEY[o.status])} kind={STATUS_COLOR[o.status]} />
                  </View>
                  <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: 10 }}>
                    <View style={styles.thumb}><Text style={{ fontSize: 22 }}>{o.items[0].emoji}</Text></View>
                    <View style={{ flex: 1, marginLeft: 10 }}>
                      <Text numberOfLines={1} style={{ fontSize: 12.5, fontWeight: '700', color: C.ink }}>{o.items[0].title}</Text>
                      <Text style={{ fontSize: 10, color: C.muted, marginTop: 3 }}>{o.items.length} мол · {fmtDate(o.createdAt)}</Text>
                    </View>
                    <Price value={o.total} size={15} />
                  </View>
                  {o.escrow.state === 'held' ? (
                    <View style={styles.escrowRow}>
                      <Ionicons name="shield-checkmark" size={13} color={C.green} />
                      <Text style={{ fontSize: 10, color: C.green, fontWeight: '800', marginLeft: 6 }}>{fmt(o.escrow.amount)} c. {t('in_escrow')}</Text>
                      <Ionicons name="chevron-forward" size={13} color={C.green} style={{ marginLeft: 'auto' }} />
                    </View>
                  ) : null}
                </View>
              </Press>
            </FadeIn>
          ))}
        </ScrollView>
      )}
    </View>
  );
}

export function OrderDetailScreen({ id, back }) {
  const { t, state, confirmReceipt, advanceOrder, openDispute, showToast } = useApp();
  const o = state.orders.find((x) => x.id === id);
  if (!o) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: C.bg }}>
        <Text style={{ fontSize: 13, color: C.muted }}>Фармоиш ёфт нашуд</Text>
        <Btn title={t('close')} kind="ghost" style={{ marginTop: 12, width: 160 }} onPress={back} />
      </View>
    );
  }

  const canConfirm = ['DELIVERED', 'SHIPPED'].includes(o.status) && o.escrow.state === 'held';
  const order = ['paid', 'packed', 'shipped', 'delivered', 'completed'];
  const doneSet = new Set((o.timeline || []).map((x) => x.s));
  const stepDefs = [
    { s: 'paid', title: t('status_paid') },
    { s: 'packed', title: t('status_packed') },
    { s: 'shipped', title: t('status_shipped') },
    { s: 'delivered', title: t('status_delivered') },
    { s: 'completed', title: t('status_completed') },
  ];
  const at = {};
  (o.timeline || []).forEach((x) => { at[x.s] = x.at; });
  const firstOpen = stepDefs.find((s) => !doneSet.has(s.s));

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={`#${o.no}`} onBack={back} sub={fmtDateTime(o.createdAt)} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 20 }}>
        <EscrowBox t={t} amount={o.escrow.state === 'held' ? o.escrow.amount : null} />

        <View style={[styles.card, { marginTop: 10 }]}>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 12 }}>
            <Text style={{ fontSize: 12.5, fontWeight: '800', color: C.ink }}>{t('timeline')}</Text>
            <Badge text={t(STATUS_KEY[o.status])} kind={STATUS_COLOR[o.status]} />
          </View>
          {stepDefs.map((it, i) => {
            const done = doneSet.has(it.s);
            const now = !done && firstOpen && firstOpen.s === it.s;
            return (
              <View key={it.s} style={{ flexDirection: 'row', minHeight: 38 }}>
                <View style={{ width: 16, alignItems: 'center' }}>
                  <View style={[styles.dot, { backgroundColor: done ? C.green : now ? C.red : '#D5DBE7' }]} />
                  {i < stepDefs.length - 1 && <View style={{ width: 2, flex: 1, backgroundColor: '#E7E9F0' }} />}
                </View>
                <View style={{ flex: 1, paddingBottom: 12, paddingLeft: 4 }}>
                  <Text style={{ fontSize: 12.5, fontWeight: '700', color: done ? C.ink : now ? C.red : '#A6AEC2' }}>{it.title}</Text>
                  {at[it.s] ? <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{fmtDateTime(at[it.s])}</Text> : null}
                </View>
              </View>
            );
          })}
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
            <Text style={{ fontSize: 11, fontWeight: '800', color: C.green, marginBottom: 8 }}>✓ {t('release_done')}</Text>
            <KV k="Payment fee 1.5%" v={`${fmt(o.split.paymentFee)} c.`} />
            <KV k="Commission" v={`${fmt(o.split.commission)} c.`} />
            <KV k="Manager bonus" v={`${fmt(o.split.managerBonus)} c.`} />
            <KV k="Seller payout" v={`${fmt(o.split.sellerPayout)} c.`} bold color={C.green} />
          </View>
        ) : null}

        {o.escrow.state === 'held' ? <View style={{ marginTop: 10 }}><Badge text={t('auto_release')} kind="gold" icon="time-outline" /></View> : null}
        {['PAID_HELD', 'PACKED', 'SHIPPED'].includes(o.status) ? (
          <Press onPress={() => { advanceOrder(o.id); showToast(t('success')); }} style={{ marginTop: 12 }}>
            <View style={styles.demoRow}>
              <Ionicons name="cube-outline" size={15} color={C.blue} />
              <Text style={{ fontSize: 11, color: C.blue, fontWeight: '800', marginLeft: 7 }}>Демо: қадами навбатии фармоиш</Text>
            </View>
          </Press>
        ) : null}
      </ScrollView>

      <View style={styles.cta}>
        {o.escrow.state === 'held' && o.status !== 'DISPUTED' ? (
          <>
            <Btn title={t('dispute')} kind="ghost" style={{ flex: 0.42 }} onPress={() => { openDispute(o.id); showToast(t('dispute')); }} />
            <Btn
              testID="btn-confirm"
              title={t('confirm_receipt')}
              style={{ flex: 1 }}
              disabled={!canConfirm}
              onPress={() => {
                const r = confirmReceipt(o.id);
                if (r && r.ok) showToast(`${t('release_done')} · ${fmt(r.split.sellerPayout)} c.`);
                else showToast((r && r.error) || t('error'), 'err');
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
  card: { backgroundColor: '#fff', borderRadius: 17, padding: 14, ...S.shadow },
  thumb: { width: 46, height: 46, borderRadius: 13, backgroundColor: '#F0F3FA', alignItems: 'center', justifyContent: 'center' },
  escrowRow: { flexDirection: 'row', alignItems: 'center', marginTop: 10, backgroundColor: C.greenSoft, borderRadius: 11, padding: 8 },
  dot: { width: 11, height: 11, borderRadius: 6, marginTop: 3 },
  demoRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', backgroundColor: C.blueSoft, borderRadius: 12, padding: 11 },
  cta: { flexDirection: 'row', gap: 9, padding: 12, paddingBottom: 18, backgroundColor: '#fff', borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: C.line },
});
