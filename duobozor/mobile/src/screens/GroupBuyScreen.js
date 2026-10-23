// Гурӯҳхаридӣ: ҳалқаи прогресс, таймер, даъватнома
import React, { useEffect, useState, useRef } from 'react';
import { View, Text, StyleSheet, ScrollView, Share, Animated, Easing } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { C, S, G, fmt, fmtCountdown, fmtTime } from '../theme';
import { Btn, Badge, Price, EscrowBox, Ring, Press, FadeIn } from '../components/ui';
import { useApp } from '../store';

export default function GroupBuyScreen({ id, back, go }) {
  const { t, name, state, inviteToGroup, showToast, addToCart } = useApp();
  const [, setTick] = useState(0);
  const g = state.groupBuys.find((x) => x.id === id);
  const p = g ? state.products.find((x) => x.id === g.productId) : null;
  const pulse = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    const i = setInterval(() => setTick((x) => x + 1), 1000);
    const loop = Animated.loop(Animated.sequence([
      Animated.timing(pulse, { toValue: 1, duration: 900, easing: Easing.inOut(Easing.quad), useNativeDriver: true }),
      Animated.timing(pulse, { toValue: 0, duration: 900, easing: Easing.inOut(Easing.quad), useNativeDriver: true }),
    ]));
    loop.start();
    return () => { clearInterval(i); loop.stop(); };
  }, []);

  if (!g || !p) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: C.bg }}>
        <Text style={{ fontSize: 13, color: C.muted }}>Гурӯҳ ёфт нашуд</Text>
        <Btn title="Бозгашт" kind="ghost" style={{ marginTop: 12, width: 160 }} onPress={back} />
      </View>
    );
  }

  const left = Math.max(0, g.required - g.members.length);
  const ms = Math.max(0, g.expiresAt - Date.now());
  const done = g.status === 'success';
  const failed = g.status === 'failed';
  const ratio = g.members.length / g.required;

  const invite = async () => {
    inviteToGroup(g.id);
    try {
      await Share.share({
        message: `DuoBozor: ${name(p)} — ${fmt(g.price)} c. ба ҷои ${fmt(p.price)} c. Ба гурӯҳи ман ҳамроҳ шав! https://t.me/Bozoronline_bot?start=grp_${g.id}`,
      });
    } catch (e) { /* корбар бекор кард */ }
    showToast(t('group_invite_sent'));
  };

  const steps = [
    { title: t('group_created'), sub: fmtTime(g.createdAt), ok: true },
    ...g.members.slice(1).map((m) => ({ title: `${m.name} — ${t('join_now')}`, sub: fmtTime(m.joinedAt), ok: true })),
    { title: done ? t('group_success') : failed ? t('group_failed') : t('group_waiting'), sub: done ? '' : t('group_expire_note'), now: !done && !failed },
  ];

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 16 }}>
        <LinearGradient colors={['#101420', '#2A3446']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.hero}>
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
            <Press testID="btn-back" onPress={back} hitSlop={8}><View style={styles.iconBtn}><Ionicons name="chevron-back" size={20} color="#fff" /></View></Press>
            <Text style={{ color: '#fff', fontSize: 13, fontWeight: '800' }}>{t('group_my')}</Text>
            <Press onPress={() => showToast(`#${g.id.slice(-5)}`)} hitSlop={8}>
              <View style={styles.iconBtn}><Ionicons name="ellipsis-horizontal" size={17} color="#fff" /></View>
            </Press>
          </View>

          <FadeIn delay={40} style={{ alignItems: 'center', marginTop: 18 }}>
            <Ring value={ratio} size={132} stroke={8} color={done ? C.green : C.orange}>
              <View style={styles.ringIn}>
                <Text style={{ color: '#fff', fontSize: 27, fontWeight: '800', letterSpacing: -1 }}>{g.members.length}/{g.required}</Text>
                <Text style={{ color: '#98A2B8', fontSize: 9.5 }}>{t('group_people')}</Text>
              </View>
            </Ring>

            <Text style={{ color: '#fff', fontSize: 15.5, fontWeight: '800', textAlign: 'center', marginTop: 14 }}>
              {done ? t('group_success') : failed ? t('group_failed') : `${left} ${t('group_left')}`}
            </Text>
            <Animated.View style={{ opacity: done || failed ? 1 : pulse.interpolate({ inputRange: [0, 1], outputRange: [0.55, 1] }) }}>
              <Text style={{ color: '#98A2B8', fontSize: 10.5, textAlign: 'center', marginTop: 5 }}>
                {t('group_time_left')}: {fmtCountdown(ms)}
              </Text>
            </Animated.View>
          </FadeIn>

          <View style={{ flexDirection: 'row', justifyContent: 'center', gap: 12, marginTop: 18 }}>
            {g.members.map((m) => (
              <FadeIn key={m.userId} style={{ alignItems: 'center', width: 56 }}>
                <View style={[styles.mem, { backgroundColor: m.guest ? '#5FD394' : C.orange }]}>
                  <Text style={{ color: m.guest ? '#0D2A1B' : '#fff', fontWeight: '800', fontSize: 16 }}>{(m.name || '?')[0]}</Text>
                </View>
                <Text style={{ color: '#C6CEDD', fontSize: 9, marginTop: 5 }} numberOfLines={1}>{(m.name || '').split(' ')[0]}</Text>
              </FadeIn>
            ))}
            {Array.from({ length: Math.max(0, g.required - g.members.length) }).map((_, i) => (
              <View key={'e' + i} style={{ alignItems: 'center', width: 56 }}>
                <View style={styles.memEmpty}><Text style={{ color: '#5D6880', fontSize: 18 }}>+</Text></View>
                <Text style={{ color: '#7E89A1', fontSize: 9, marginTop: 5 }}>{t('join_now')}</Text>
              </View>
            ))}
          </View>

          <View style={styles.pricePill}>
            <Text style={{ color: '#C6CEDD', fontSize: 10 }}>{t('product_group_price')}:</Text>
            <Price value={g.price} size={15} color="#FFC24A" />
            <Text style={{ color: '#8B93A6', fontSize: 10, textDecorationLine: 'line-through' }}>{fmt(p.price)}</Text>
          </View>
        </LinearGradient>

        <View style={{ padding: 16 }}>
          <Btn title={t('group_invite')} icon="share-social" kind="ghost" onPress={invite} />
          <View style={{ marginTop: 12 }}><EscrowBox t={t} amount={g.price} /></View>

          <Text style={styles.section}>{t('group_status')}</Text>
          <View style={styles.card}>
            {steps.map((it, i) => (
              <View key={i} style={{ flexDirection: 'row', minHeight: 40 }}>
                <View style={{ width: 16, alignItems: 'center' }}>
                  <View style={[styles.dot, { backgroundColor: it.now ? C.red : C.green }]} />
                  {i < steps.length - 1 && <View style={{ width: 2, flex: 1, backgroundColor: '#E7E9F0' }} />}
                </View>
                <View style={{ flex: 1, paddingBottom: 12, paddingLeft: 4 }}>
                  <Text style={{ fontSize: 12.5, fontWeight: '700', color: it.now ? C.red : C.ink }}>{it.title}</Text>
                  {it.sub ? <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{it.sub}</Text> : null}
                </View>
              </View>
            ))}
          </View>
        </View>
      </ScrollView>

      <View style={styles.cta}>
        <Btn title={t('cancel')} kind="ghost" style={{ flex: 0.4 }} onPress={back} />
        <Btn
          title={done ? t('to_pay') : t('group_invite')}
          style={{ flex: 1 }}
          onPress={() => {
            if (done) { addToCart(p.id, 1, g.id); go('cart'); } else invite();
          }}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  hero: { paddingTop: 14, paddingBottom: 24, paddingHorizontal: 16, borderBottomLeftRadius: 26, borderBottomRightRadius: 26 },
  iconBtn: { width: 34, height: 34, borderRadius: 11, backgroundColor: 'rgba(255,255,255,0.14)', alignItems: 'center', justifyContent: 'center' },
  ringIn: { width: 110, height: 110, borderRadius: 55, backgroundColor: '#12161F', alignItems: 'center', justifyContent: 'center' },
  mem: { width: 46, height: 46, borderRadius: 23, alignItems: 'center', justifyContent: 'center' },
  memEmpty: { width: 46, height: 46, borderRadius: 23, borderWidth: 1.5, borderColor: '#4A5468', borderStyle: 'dashed', alignItems: 'center', justifyContent: 'center' },
  pricePill: { flexDirection: 'row', alignItems: 'center', gap: 8, alignSelf: 'center', backgroundColor: 'rgba(255,255,255,0.08)', borderRadius: 14, paddingHorizontal: 14, paddingVertical: 9, marginTop: 16 },
  section: { fontSize: 12.5, fontWeight: '800', color: C.ink, marginTop: 18, marginBottom: 10 },
  card: { backgroundColor: '#fff', borderRadius: 16, padding: 14, ...S.shadow },
  dot: { width: 11, height: 11, borderRadius: 6, marginTop: 3 },
  cta: { flexDirection: 'row', gap: 9, padding: 12, paddingBottom: 18, backgroundColor: '#fff', borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: C.line },
});
