// Огоҳиномаҳо: аз аудит-логи ҳолат сохта мешаванд
import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { C, S, fmt, fmtTime, fmtDate } from '../theme';
import { Empty, Header, FadeIn, Badge } from '../components/ui';
import { useApp } from '../store';

const ICONS = {
  'order.place': ['bag-check', C.blue, C.blueSoft],
  'escrow.release': ['shield-checkmark', C.green, C.greenSoft],
  'escrow.refund': ['return-down-back', C.red, C.redSoft],
  'payout.request': ['cash', C.goldText, C.yellowSoft],
  'payout.approve': ['checkmark-done', C.green, C.greenSoft],
  'admin.broadcast': ['megaphone', C.goldText, C.yellowSoft],
  'auth.admin': ['shield-half', C.goldText, C.yellowSoft],
  'seller.kyc.approve': ['ribbon', C.blue, C.blueSoft],
};

export default function NotificationsScreen({ back }) {
  const { t, state } = useApp();
  const items = state.audit.slice().reverse();
  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={t('notifications')} onBack={back} right={<Badge text={`${items.length}`} kind="gray" />} />
      {!items.length ? <Empty icon="notifications-off-outline" title={t('no_notifications')} /> : (
        <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 24 }}>
          {state.broadcast ? (
            <FadeIn>
              <View style={styles.broadcast}>
                <Ionicons name="megaphone" size={16} color={C.goldText} />
                <Text style={{ flex: 1, fontSize: 11.5, color: '#7A5500', fontWeight: '700', marginLeft: 8 }}>{state.broadcast}</Text>
              </View>
            </FadeIn>
          ) : null}
          {items.map((a, i) => {
            const [ic, color, bg] = ICONS[a.action] || ['information-circle', C.muted, '#F1F3F8'];
            return (
              <FadeIn key={a.id} delay={Math.min(i, 8) * 35} dy={8}>
                <View style={styles.row}>
                  <View style={[styles.ico, { backgroundColor: bg }]}><Ionicons name={ic} size={16} color={color} /></View>
                  <View style={{ flex: 1 }}>
                    <Text style={{ fontSize: 12, fontWeight: '800', color: C.ink }}>{a.action}</Text>
                    <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{a.actor} · {a.ref || '—'}</Text>
                  </View>
                  <View style={{ alignItems: 'flex-end' }}>
                    {a.amount ? <Text style={{ fontSize: 11.5, fontWeight: '800', color: C.ink }}>{fmt(a.amount)}</Text> : null}
                    <Text style={{ fontSize: 9, color: '#A6AEC2', marginTop: 2 }}>{fmtDate(a.at)} {fmtTime(a.at)}</Text>
                  </View>
                </View>
              </FadeIn>
            );
          })}
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: 10, backgroundColor: '#fff', borderRadius: 15, padding: 12, marginBottom: 8, ...S.shadow },
  ico: { width: 34, height: 34, borderRadius: 11, alignItems: 'center', justifyContent: 'center' },
  broadcast: { flexDirection: 'row', alignItems: 'center', backgroundColor: C.yellowSoft, borderRadius: 14, padding: 12, marginBottom: 10, borderWidth: 1, borderColor: '#F3E0B4' },
});
