// Сабад + Checkout (бо escrow ва тафтиши нарх/захира)
import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { C, S, fmt } from '../theme';
import { Btn, Badge, Empty, EscrowBox, Header, KV, Price, tap } from '../components/ui';
import { useApp } from '../store';

export function CartScreen({ go }) {
  const { t, name, state, setQty, cartTotals, clearCart } = useApp();
  const { items, subtotal, delivery, total } = cartTotals();

  if (!items.length) {
    return (
      <View style={{ flex: 1, backgroundColor: C.bg }}>
        <Header title={t('cart_title')} />
        <Empty icon="bag-outline" title={t('cart_empty')} sub={t('for_you')} />
        <View style={{ padding: 20 }}><Btn title={t('go_shopping')} onPress={() => go && go('home')} /></View>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={`${t('cart_title')} (${items.length})`} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 20 }}>
        {items.map((it) => (
          <View key={it.id} style={styles.row}>
            <View style={styles.thumb}><Text style={{ fontSize: 26 }}>{it.product.emoji}</Text></View>
            <View style={{ flex: 1, marginLeft: 11 }}>
              <Text numberOfLines={2} style={{ fontSize: 12.5, fontWeight: '700', color: C.ink }}>{name(it.product)}</Text>
              <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: 6 }}>
                <Price value={it.product.price} size={14} />
                <View style={styles.qty}>
                  <Pressable onPress={() => { tap(); setQty(it.id, it.qty - 1); }} hitSlop={6}><Ionicons name="remove" size={14} color={C.ink} /></Pressable>
                  <Text style={{ fontSize: 12.5, fontWeight: '800', marginHorizontal: 10 }}>{it.qty}</Text>
                  <Pressable onPress={() => { tap(); setQty(it.id, it.qty + 1); }} hitSlop={6}><Ionicons name="add" size={14} color={C.ink} /></Pressable>
                </View>
              </View>
            </View>
          </View>
        ))}

        <View style={[styles.card, { marginTop: 14 }]}>
          <KV k={t('subtotal')} v={`${fmt(subtotal)} c.`} />
          <KV k={t('delivery')} v={delivery ? `${fmt(delivery)} c.` : t('free')} color={delivery ? C.ink : C.green} />
          <View style={{ height: 1, backgroundColor: C.line, marginVertical: 6 }} />
          <KV k={t('total')} v={`${fmt(total)} c.`} bold color={C.red} />
        </View>
      </ScrollView>

      <View style={styles.cta}>
        <View style={{ flex: 1 }}>
          <Text style={{ fontSize: 10, color: C.muted }}>{t('to_pay')}</Text>
          <Price value={total} size={19} />
        </View>
        <Btn title={t('checkout')} style={{ flex: 1.1 }} onPress={() => go && go('checkout')} />
      </View>
    </View>
  );
}

export function CheckoutScreen({ back, go }) {
  const { t, name, state, cartTotals, placeOrder, myWallet, showToast } = useApp();
  const { items, subtotal, delivery, total } = cartTotals();
  const [method, setMethod] = useState('wallet');
  const [busy, setBusy] = useState(false);
  const offline = state.offline;

  const pay = async () => {
    setBusy(true);
    const r = await placeOrder(method);
    setBusy(false);
    if (!r.ok) { showToast(r.error, 'err'); return; }
    showToast(t('order_placed'));
    go && go('orders');
  };

  const opts = [
    { key: 'wallet', title: t('pay_wallet'), sub: `${fmt(myWallet.balance)} c. ${t('pay_wallet_bal')}`, icon: '👛', disabled: false },
    { key: 'cash', title: t('pay_cash'), sub: 'Курер ҳангоми додан мегирад', icon: '💵', disabled: false },
    { key: 'card', title: t('pay_card'), sub: offline ? 'Интернет лозим аст' : 'Alipay / корт', icon: '💳', disabled: offline },
  ];

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={t('checkout_title')} onBack={back} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 20 }}>
        <View style={styles.card}>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 10 }}>
            <Text style={{ fontSize: 10.5, color: C.muted }}>{t('address')}</Text>
            <Text style={{ fontSize: 10.5, color: C.red, fontWeight: '700' }}>{t('change')}</Text>
          </View>
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <View style={[styles.thumb, { width: 34, height: 34, borderRadius: 11 }]}><Text>📍</Text></View>
            <View style={{ marginLeft: 9 }}>
              <Text style={{ fontSize: 12.5, fontWeight: '700', color: C.ink }}>
                {state.lang === 'ru' ? state.address.text_ru : state.address.text_tj}
              </Text>
              <Text style={{ fontSize: 10.5, color: C.muted, marginTop: 2 }}>{state.user?.name} · {state.address.phone}</Text>
            </View>
          </View>
        </View>

        <View style={[styles.card, { marginTop: 10 }]}>
          <Text style={{ fontSize: 10.5, color: C.muted, marginBottom: 10 }}>{t('payment_method')}</Text>
          {opts.map((o) => (
            <Pressable
              key={o.key}
              disabled={o.disabled}
              onPress={() => { tap(); setMethod(o.key); }}
              style={[styles.payOpt, method === o.key && styles.payOptOn, o.disabled && { opacity: 0.45 }]}
            >
              <View style={[styles.radio, method === o.key && { borderColor: C.red }]}>
                {method === o.key ? <View style={{ width: 8, height: 8, borderRadius: 4, backgroundColor: C.red }} /> : null}
              </View>
              <View style={{ flex: 1 }}>
                <Text style={{ fontSize: 12.5, fontWeight: '700', color: C.ink }}>{o.title}</Text>
                <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{o.sub}</Text>
              </View>
              <Text style={{ fontSize: 17 }}>{o.icon}</Text>
            </Pressable>
          ))}
        </View>

        <View style={[styles.card, { marginTop: 10 }]}>
          {items.map((it) => (
            <KV key={it.id} k={`${name(it.product)} × ${it.qty}`} v={`${fmt(it.line)} c.`} />
          ))}
          <KV k={t('delivery')} v={delivery ? `${fmt(delivery)} c.` : t('free')} color={delivery ? C.ink : C.green} />
          <View style={{ height: 1, backgroundColor: C.line, marginVertical: 6 }} />
          <KV k={t('total')} v={`${fmt(total)} c.`} bold color={C.red} />
        </View>

        <View style={{ marginTop: 12 }}><EscrowBox t={t} /></View>
      </ScrollView>

      <View style={styles.cta}>
        <View style={{ flex: 1 }}>
          <Text style={{ fontSize: 10, color: C.muted }}>{t('to_pay')}</Text>
          <Price value={total} size={19} />
        </View>
        <Btn title={busy ? t('loading') : `🔒 ${t('pay_secure')}`} style={{ flex: 1.3 }} onPress={pay} disabled={busy} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', backgroundColor: '#fff', borderRadius: 16, padding: 10, marginBottom: 10, ...S.shadow },
  thumb: { width: 60, height: 60, borderRadius: 13, backgroundColor: '#EEF1F8', alignItems: 'center', justifyContent: 'center' },
  qty: { flexDirection: 'row', alignItems: 'center', marginLeft: 'auto', backgroundColor: C.bg, borderRadius: 10, paddingHorizontal: 9, paddingVertical: 5 },
  card: { backgroundColor: '#fff', borderRadius: 16, padding: 14, ...S.shadow },
  cta: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 12, paddingBottom: 20, backgroundColor: '#fff', borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: C.line },
  payOpt: { flexDirection: 'row', alignItems: 'center', gap: 10, borderWidth: 1.5, borderColor: C.line, borderRadius: 13, padding: 11, marginBottom: 8 },
  payOptOn: { borderColor: C.red, backgroundColor: '#FFF7F5' },
  radio: { width: 17, height: 17, borderRadius: 9, borderWidth: 2, borderColor: '#CBD2E0', alignItems: 'center', justifyContent: 'center' },
});
