// Панели админ: escrow, комиссия, баҳсҳо, пардохтҳо, ledger, аудит
import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TextInput } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { C, S, fmt, fmtTime } from '../theme';
import { Badge, Btn, Card, Empty, Header, Kpi, Press, FadeIn } from '../components/ui';
import { useApp } from '../store';

export default function AdminScreen({ back }) {
  const { t, state, adminRelease, adminRefund, approvePayout, broadcast, showToast, platformRevenue, ledgerSum, adminEscrow } = useApp();
  const [msg, setMsg] = useState('');
  const disputed = state.orders.filter((o) => o.status === 'DISPUTED');
  const payoutReq = state.payouts.filter((p) => p.status === 'requested');
  const escrowSum = adminEscrow.reduce((a, b) => a + b.escrow.amount, 0);

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={t('admin_dash')} onBack={back} right={<Badge text="ADMIN" kind="gold" />} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 28 }}>
        <FadeIn>
          <View style={styles.darkCard}>
            <View style={{ flexDirection: 'row', gap: 8 }}>
              <Kpi label={t('admin_revenue')} value={fmt(platformRevenue)} color="#7CE3A8" icon="trending-up" />
              <Kpi label={t('admin_escrow')} value={fmt(escrowSum)} color="#FFC24A" icon="shield-checkmark" />
            </View>
            <View style={{ flexDirection: 'row', gap: 8, marginTop: 8 }}>
              <Kpi label={t('admin_users')} value={String(state.users.length)} icon="people" />
              <Kpi label={t('admin_disputes')} value={String(disputed.length)} color={disputed.length ? '#FF8C82' : '#fff'} icon="alert-circle" />
            </View>
            <View style={styles.ledgerRow}>
              <View style={[styles.dot, { backgroundColor: Math.abs(ledgerSum) < 1 ? '#5FD394' : '#FF8C82' }]} />
              <Text style={{ fontSize: 9.5, color: '#C6CEDD', fontWeight: '800' }}>{t('admin_ledger_ok')}: Σ = {ledgerSum}</Text>
              <Text style={{ fontSize: 9, color: '#7E89A1', marginLeft: 'auto' }}>{state.ledger.length} entries</Text>
            </View>
          </View>
        </FadeIn>

        <Text style={styles.section}>{t('admin_escrow')} · {adminEscrow.length}</Text>
        {!adminEscrow.length ? <Empty icon="shield-outline" title={t('admin_no_data')} /> : adminEscrow.map((o, i) => (
          <FadeIn key={o.id} delay={i * 40} dy={8}>
            <Card style={{ marginBottom: 8 }}>
              <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 11.5, fontWeight: '800', color: C.ink }}>#{o.no}</Text>
                  <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{o.items[0] && o.items[0].title}</Text>
                </View>
                <Text style={{ fontSize: 13, fontWeight: '800', color: C.goldText }}>{fmt(o.escrow.amount)} c.</Text>
              </View>
              <View style={{ flexDirection: 'row', gap: 8, marginTop: 10 }}>
                <Btn
                  title={t('admin_release')} small style={{ flex: 1 }}
                  onPress={() => {
                    const r = adminRelease(o.id);
                    showToast(r && r.ok ? `${t('release_done')} ${fmt(r.split.sellerPayout)}` : t('error'), r && r.ok ? 'ok' : 'err');
                  }}
                />
                <Btn
                  title={t('admin_refund')} kind="danger" small style={{ flex: 1 }}
                  onPress={() => {
                    const r = adminRefund(o.id);
                    showToast(r && r.ok ? t('admin_refund') : t('error'), r && r.ok ? 'ok' : 'err');
                  }}
                />
              </View>
            </Card>
          </FadeIn>
        ))}

        <Text style={styles.section}>{t('admin_payouts')} · {payoutReq.length}</Text>
        <Card style={{ padding: 6 }}>
          {!payoutReq.length ? <Text style={{ fontSize: 11, color: C.muted, padding: 10 }}>{t('admin_no_data')}</Text> : payoutReq.map((p, i) => (
            <View key={p.id} style={[styles.row, i === payoutReq.length - 1 && { borderBottomWidth: 0 }]}>
              <View style={{ flex: 1 }}>
                <Text style={{ fontSize: 11.5, fontWeight: '700', color: C.ink }}>{fmt(p.amount)} c.</Text>
                <Text style={{ fontSize: 9.5, color: C.muted, marginTop: 2 }}>{p.sellerId} · {p.fourEye ? t('admin_four_eye') : 'OK'}</Text>
              </View>
              <Btn title={t('admin_approve')} small kind="ghost" style={{ width: 96 }} onPress={() => { approvePayout(p.id); showToast(t('success')); }} />
            </View>
          ))}
        </Card>

        <Text style={styles.section}>{t('admin_broadcast')}</Text>
        <Card>
          <TextInput
            value={msg}
            onChangeText={setMsg}
            placeholder="Матни паём ба ҳамаи корбарон…"
            placeholderTextColor="#B6BDCC"
            style={{ fontSize: 12.5, color: C.ink, backgroundColor: C.bg, borderRadius: 12, padding: 11, minHeight: 64 }}
            multiline
          />
          <Btn title={t('admin_broadcast')} small style={{ marginTop: 10 }} disabled={!msg.trim()} onPress={() => { broadcast(msg); setMsg(''); showToast(t('admin_broadcast_sent')); }} />
          {state.broadcast ? <Text style={{ fontSize: 9.5, color: C.green, marginTop: 8 }}>✓ {String(state.broadcast).slice(0, 60)}</Text> : null}
        </Card>

        <Text style={styles.section}>{t('admin_audit')}</Text>
        <Card style={{ padding: 6 }}>
          {!state.audit.length ? <Text style={{ fontSize: 11, color: C.muted, padding: 10 }}>{t('admin_no_data')}</Text> : state.audit.slice().reverse().slice(0, 12).map((a, i, arr) => (
            <View key={a.id} style={[styles.row, i === arr.length - 1 && { borderBottomWidth: 0 }]}>
              <Ionicons name="pulse" size={14} color={C.muted} />
              <View style={{ flex: 1, marginLeft: 8 }}>
                <Text style={{ fontSize: 11, fontWeight: '700', color: C.ink }}>{a.action}</Text>
                <Text style={{ fontSize: 9.5, color: C.muted, marginTop: 1 }}>{a.actor} · {a.ref || ''}</Text>
              </View>
              <Text style={{ fontSize: 11, fontWeight: '800', color: a.amount ? C.green : C.muted }}>
                {a.amount ? fmt(a.amount) : fmtTime(a.at)}
              </Text>
            </View>
          ))}
        </Card>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  darkCard: { backgroundColor: C.dark, borderRadius: 20, padding: 14 },
  ledgerRow: { flexDirection: 'row', alignItems: 'center', gap: 6, backgroundColor: '#1B2230', borderRadius: 11, padding: 9, marginTop: 8 },
  dot: { width: 7, height: 7, borderRadius: 4 },
  section: { fontSize: 10.5, fontWeight: '800', color: C.muted, marginTop: 18, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 0.6 },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10, paddingHorizontal: 8, borderBottomWidth: 1, borderBottomColor: '#F1F3F8' },
});
