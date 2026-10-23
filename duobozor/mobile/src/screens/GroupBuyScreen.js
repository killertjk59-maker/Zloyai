// Гурӯҳхаридӣ: давраи прогресс, таймер, даъватнома
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable, Share } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { C, S, fmt } from '../theme';
import { Btn, Badge, Price, EscrowBox, tap } from '../components/ui';
import { useApp } from '../store';

export default function GroupBuyScreen({ id, back, go }) {
  const { t, name, state, inviteToGroup, joinGroupBuy, showToast, addToCart } = useApp();
  const [, setTick] = useState(0);
  const g = state.groupBuys.find((x) => x.id === id);
  const p = g ? state.products.find((x) => x.id === g.productId) : null;

  useEffect(() => {
    const i = setInterval(() => setTick((x) => x + 1), 1000);
    return () => clearInterval(i);
  }, []);

  if (!g || !p) return null;
  const left = Math.max(0, g.required - g.members.length);
  const ms = Math.max(0, g.expiresAt - Date.now());
  const hh = String(Math.floor(ms / 3600000)).padStart(2, '0');
  const mm = String(Math.floor((ms % 3600000) / 60000)).padStart(2, '0');
  const ss = String(Math.floor((ms % 60000) / 1000)).padStart(2, '0');
  const done = g.status === 'success';
  const failed = g.status === 'failed';

  const invite = async () => {
    tap();
    inviteToGroup(g.id);
    try {
      await Share.share({
        message: `DuoBozor: ${name(p)} — ${fmt(g.price)} c. ба ҷои ${fmt(p.price)} c. Ба гурӯҳи ман ҳамроҳ шав! https://t.me/Bozoronline_bot?start=grp_${g.id}`,
      });
    } catch (e) { /* */ }
    showToast(t('group_invite_sent'));
  };

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 20 }}>
        <LinearGradient colors={['#12151C', '#2B3446']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.hero}>
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
            <Pressable onPress={() => { tap(); back(); }} style={styles.iconBtn}><Ionicons name="chevron-back" size={20} color="#fff" /></Pressable>
            <Text style={{ color: '#fff', fontSize: 13, fontWeight: '700' }}>{t('group_my')}</Text>
            <View style={styles.iconBtn}><Ionicons name="ellipsis-horizontal" size={17} color="#fff" /></View>
          </View>

          <View style={styles.ring}>
            <View style={styles.ringIn}>
              <Text style={{ color: '#fff', fontSize: 26, fontWeight: '800', letterSpacing: -1 }}>
                {g.members.length}/{g.required}
              </Text>
              <Text style={{ color: '#98A2B8', fontSize: 10 }}>{t('group_people')}</Text>
            </View>
            <View style={[styles.ringArc, { opacity: 0.9 }]} pointerEvents="none" />
          </View>

          <Text style={{ color: '#fff', fontSize: 15, fontWeight: '800', textAlign: 'center', marginTop: 10 }}>
            {done ? t('group_success') : failed ? t('group_failed') : `${left} ${t('group_left')}`}
          </Text>
          <Text style={{ color: '#98A2B8', fontSize: 10.5, textAlign: 'center', marginTop: 5 }}>
            {t('group_time_left')}: {hh}:{mm}:{ss}
          </Text>

          <View style={{ flexDirection: 'row', justifyContent: 'center', gap: 14, marginTop: 16 }}>
            {g.members.map((m) => (
              <View key={m.userId} style={{ alignItems: 'center', width: 58 }}>
                <View style={[styles.mem, { backgroundColor: m.guest ? '#5FD394' : C.orange }]}>
                  <Text style={{ color: m.guest ? '#0D2A1B' : '#fff', fontWeight: '800', fontSize: 16 }}>{m.name[0]}</Text>
                </View>
                <Text style={{ color: '#C6CEDD', fontSize: 9, marginTop: 5 }} numberOfLines={1}>{m.name.split(' ')[0]}</Text>
              </View>
            ))}
            {Array.from({ length: Math.max(0, g.required - g.members.length) }).map((_, i) => (
              <View key={i} style={{ alignItems: 'center', width: 58 }}>
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
          <Pressable onPress={invite} style={styles.inviteBtn}>
            <Ionicons name="share-social" size={17} color={C.red} />
            <Text style={{ color: C.red, fontWeight: '800', fontSize: 12.5, marginLeft: 8 }}>{t('group_invite')}</Text>
          </Pressable>

          <View style={{ marginTop: 14 }}><EscrowBox t={t} amount={g.price} /></View>

          <Text style={{ fontSize: 13, fontWeight: '800', color: C.ink, marginTop: 18, marginBottom: 10 }}>{t('group_status')}</Text>
          <View style={styles.card}>
            {[
              { title: t('group_created'), sub: new Date(g.createdAt).toLocaleTimeString('ru-RU').slice(0, 5), ok: true },
              ...g.members.slice(1).map((m) => ({ title: `${m.name} — ${t('join_now')}`, sub: new Date(m.joinedAt).toLocaleTimeString('ru-RU').slice(0, 5), ok: true })),
              { title: done ? t('group_success') : t('group_waiting'), sub: done ? '' : t('group_expire_note'), now: !done },
            ].map((it, i, arr) => (
              <View key={i} style={{ flexDirection: 'row', minHeight: 42 }}>
                <View style={{ width: 16, alignItems: 'center' }}>
                  <View style={[styles.dot, { backgroundColor: it.now ? C.red : C.green }]} />
                  {i < arr.length - 1 && <View style={{ width: 2, flex: 1, backgroundColor: '#E7E9F0' }} />}
                </View>
                <View style={{ flex: 1, paddingBottom: 12, paddingLeft: 4 }}>
                  <Text style={{ fontSize: 12.5, fontWeight: '700', color: it.now ? C.red : C.ink }}>{it.title}</Text>
                  {it.sub ? <Text style={{ fontSize: 10.5, color: C.muted, marginTop: 2 }}>{it.sub}</Text> : null}
                </View>
              </View>
            ))}
          </View>
        </View>
      </ScrollView>

      <View style={styles.cta}>
        <Btn title={t('cancel')} kind="ghost" style={{ flex: 0.4 }} onPress={() => { back(); }} />
        <Btn
          title={done ? t('to_pay') : t('group_invite')}
          style={{ flex: 1 }}
          onPress={() => {
            if (done) { addToCart(p.id, 1, g.id); go && go('cart'); }
            else invite();
          }}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  hero: { paddingTop: 50, paddingBottom: 26, paddingHorizontal: 16, borderBottomLeftRadius: 26, borderBottomRightRadius: 26 },
  iconBtn: { width: 34, height: 34, borderRadius: 11, backgroundColor: 'rgba(255,255,255,0.14)', alignItems: 'center', justifyContent: 'center' },
  ring: { width: 132, height: 132, borderRadius: 66, alignSelf: 'center', marginTop: 16, alignItems: 'center', justifyContent: 'center', backgroundColor: '#2A3446' },
  ringArc: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, borderWidth: 7, borderColor: C.orange, borderRadius: 66, borderRightColor: 'transparent', borderBottomColor: 'transparent' },
  ringIn: { width: 112, height: 112, borderRadius: 56, backgroundColor: '#12151C', alignItems: 'center', justifyContent: 'center' },
  mem: { width: 46, height: 46, borderRadius: 23, alignItems: 'center', justifyContent: 'center' },
  memEmpty: { width: 46, height: 46, borderRadius: 23, borderWidth: 1.5, borderColor: '#4A5468', borderStyle: 'dashed', alignItems: 'center', justifyContent: 'center' },
  pricePill: { flexDirection: 'row', alignItems: 'center', gap: 8, alignSelf: 'center', backgroundColor: 'rgba(255,255,255,0.08)', borderRadius: 14, paddingHorizontal: 14, paddingVertical: 9, marginTop: 16 },
  inviteBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff', borderRadius: 14, paddingVertical: 13, ...S.shadow },
  card: { backgroundColor: '#fff', borderRadius: 16, padding: 14, ...S.shadow },
  dot: { width: 11, height: 11, borderRadius: 6, borderWidth: 0, marginTop: 3 },
  cta: { flexDirection: 'row', gap: 9, padding: 12, paddingBottom: 20, backgroundColor: '#fff', borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: C.line },
});
