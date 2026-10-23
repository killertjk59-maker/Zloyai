// Сабад + Checkout
import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { C, S, G, fmt } from '../theme';
import { Btn, Badge, Empty, EscrowBox, Header, KV, Price, Press, FadeIn } from '../components/ui';
import { useApp } from '../store';

export function CartScreen({ go }) {
  const { t, name, state, setQty, cartTotals } = useApp();
  const { items, subtotal, delivery, total } = cartTotals();

  if (!items.length) {
    return (
      <View style={{ flex: 1, backgroundColor: C.bg }}>
        <Header title={t('cart_title')} />
        <Empty icon="bag-outline" title={t('cart_empty')} sub={t('for_you')} />
        <View style={{ padding: 20 }}><Btn title={t('go_shopping')} onPress={() => go('home')} /></View>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={`${t('cart_title')} · ${items.length}`} right={<Badge text={`${items.reduce((a, b) => a + b.qty, 0)} мол`} kind="gray" />} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 18 }}>
        {items.map((it, i) => (
          <FadeIn key={it.id} delay={i * 45} dy={10}>
            <View style={styles.row}>
              <View style={styles.thumb}><Text style={{ fontSize: 27 }}>{it.product.emoji}</Text></View>
              <View style={{ flex: 1, marginLeft: 11 }}>
                <Text numberOfLines={2} style={{ fontSize: 12.5, fontWeight: '700', color: C.ink }}>{name(it.product)}</Text>
                <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: 6 }}>
                  <Price value={it.product.price} size={14} />
                  <View style={styles.qty}>
                    <Press onPress={() => setQty(it.id, it.qty - 1)} scaleTo={0.8} hitSlop={10}>
                      <Ionicons name={it.qty <= 1 ? 'trash-outline' : 'remove'} size={14} color={it.qty <= 1 ? C.red : C.ink} />
                    </Press>
                    <Text style={{ fontSize: 12.5, fontWeight: '800', marginHorizontal: 12 }}>{it.qty}</Text>
                    <Press onPress={() => setQty(it.id, it.qty + 1)} scaleTo={0.8} hitSlop={10}>
                      <Ionicons name="add" size={14} color={C.ink} />
                    </Press>
                  </View>
                </View>
              </View>
            </View>
          </FadeIn>
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
        <Btn testID="btn-goto-checkout" title={t('checkout')} style={{ flex: 1.1 }} icon="arrow-forward" onPress={() => go('checkout')} />
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
    if (!r || !r.ok) { showToast((r && r.error) || t('error'), 'err'); return; }
    showToast(t('order_placed'));
    go('orders');
  };

  const opts = [
    { key: 'wallet', title: t('pay_wallet'), sub: `${fmt(myWallet.balance)} c. ${t('pay_wallet_bal')}`, icon: '👛', disabled: false },
    { key: 'cash', title: t('pay_cash'), sub: 'Курер ҳангоми додан мегирад', icon: '💵', disabled: false },
    { key: 'card', title: t('pay_card'), sub: offline ? t('offline_banner') : 'Alipay / корти бонкӣ', icon: '💳', disabled: offline },
  ];

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={t('checkout_title')} onBack={back} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 18 }}>
        <View style={styles.card}>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 10 }}>
            <Text style={{ fontSize: 10.5, color: C.muted, fontWeight: '700' }}>{t('address')}</Text>
            <Text style={{ fontSize: 10.5, color: C.red, fontWeight: '800' }}>{t('change')}</Text>
          </View>
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <View style={[styles.thumb, { width: 36, height: 36 }]}><Text style={{ fontSize: 15 }}>📍</Text></View>
            <View style={{ marginLeft: 9, flex: 1 }}>
              <Text style={{ fontSize: 12.5, fontWeight: '700', color: C.ink }}>{state.lang === 'ru' ? state.address.text_ru : state.address.text_tj}</Text>
              <Text style={{ fontSize: 10.5, color: C.muted, marginTop: 2 }}>{state.user?.name} · {state.address.phone}</Text>
            </View>
          </View>
        </View>

        <View style={[styles.card, { marginTop: 10 }]}>
          <Text style={{ fontSize: 10.5, color: C.muted, marginBottom: 10, fontWeight: '700' }}>{t('payment_method')}</Text>
          {opts.map((o) => (
            <Press key={o.key} onPress={() => setMethod(o.key)} disabled={o.disabled} containerStyle={{ marginBottom: 8 }}>
              <View style={[styles.payOpt, method === o.key && styles.payOptOn, o.disabled && { opacity: 0.45 }]}>
                <View style={[styles.radio, method === o.key && { borderColor: C.red }]}>
                  {method === o.key ? <View style={{ width: 8, height: 8, borderRadius: 4, backgroundColor: C.red }} /> : null}
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 12.5, fontWeight: '700', color: C.ink }}>{o.title}</Text>
                  <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{o.sub}</Text>
                </View>
                <Text style={{ fontSize: 17 }}>{o.icon}</Text>
              </View>
            </Press>
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
        <Btn testID="btn-pay" title={busy ? t('loading') : t('pay_secure')} style={{ flex: 1.3 }} onPress={pay} loading={busy} icon="lock-closed" />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', backgroundColor: '#fff', borderRadius: 17, padding: 10, marginBottom: 10, ...S.shadow },
  thumb: { width: 62, height: 62, borderRadius: 14, backgroundColor: '#F0F3FA', alignItems: 'center', justifyContent: 'center' },
  qty: { flexDirection: 'row', alignItems: 'center', marginLeft: 'auto', backgroundColor: C.bg, borderRadius: 11, paddingHorizontal: 10, paddingVertical: 6 },
  card: { backgroundColor: '#fff', borderRadius: 17, padding: 14, ...S.shadow },
  cta: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 12, paddingBottom: 18, backgroundColor: '#fff', borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: C.line },
  payOpt: { flexDirection: 'row', alignItems: 'center', gap: 10, borderWidth: 1.5, borderColor: C.line, borderRadius: 14, padding: 11 },
  payOptOn: { borderColor: C.red, backgroundColor: '#FFF7F5' },
  radio: { width: 17, height: 17, borderRadius: 9, borderWidth: 2, borderColor: '#CBD2E0', alignItems: 'center', justifyContent: 'center' },
});
