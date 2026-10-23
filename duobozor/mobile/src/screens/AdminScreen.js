// Панели админ: escrow, комиссия, баҳсҳо, пардохтҳо, ledger, аудит
import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TextInput, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { C, S, fmt } from '../theme';
import { Badge, Btn, Card, Divider, Empty, Header, Kpi, KV, tap } from '../components/ui';
import { useApp } from '../store';

export default function AdminScreen({ back }) {
  const { t, name, state, adminRelease, adminRefund, approvePayout, approveKyc, broadcast, showToast, platformRevenue, ledgerSum, adminEscrow } = useApp();
  const [msg, setMsg] = useState('');
  const disputed = state.orders.filter((o) => o.status === 'DISPUTED');
  const payoutReq = state.payouts.filter((p) => p.status === 'requested');
  const kycReq = state.users.filter((u) => u.kyc !== 'approved' && u.roles?.includes('seller'));

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={t('admin_dash')} onBack={back} right={<Badge text="ADMIN" kind="red" />} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 28 }}>
        <View style={{ backgroundColor: '#12151C', borderRadius: 18, padding: 14 }}>
          <View style={{ flexDirection: 'row', gap: 8 }}>
            <Kpi label={t('admin_revenue')} value={fmt(platformRevenue)} color="#7CE3A8" icon="trending-up" />
            <Kpi label={t('admin_escrow')} value={fmt(adminEscrow.reduce((a, b) => a + b.escrow.amount, 0))} color="#FFC24A" icon="shield-checkmark" />
          </View>
          <View style={{ flexDirection: 'row', gap: 8, marginTop: 8 }}>
            <Kpi label={t('admin_users')} value={String(state.users.length)} icon="people" />
            <Kpi label={t('admin_disputes')} value={String(disputed.length)} color={disputed.length ? '#FF8C82' : '#fff'} icon="alert-circle" />
          </View>
          <View style={styles.ledgerRow}>
            <View style={[styles.dot, { backgroundColor: Math.abs(ledgerSum) < 1 ? '#5FD394' : '#FF8C82' }]} />
            <Text style={{ fontSize: 9.5, color: '#C6CEDD', fontWeight: '700' }}>
              {t('admin_ledger_ok')}: Σ = {ledgerSum} тийин
            </Text>
            <Text style={{ fontSize: 9, color: '#7E89A1', marginLeft: 'auto' }}>{state.ledger.length} entries</Text>
          </View>
        </View>

        <Text style={styles.section}>{t('admin_escrow')} · {adminEscrow.length}</Text>
        {!adminEscrow.length ? <Empty icon="shield-outline" title={t('admin_no_data')} /> : adminEscrow.map((o) => (
          <Card key={o.id} style={{ marginBottom: 8 }}>
            <View style={{ flexDirection: 'row', alignItems: 'center' }}>
              <View style={{ flex: 1 }}>
                <Text style={{ fontSize: 11.5, fontWeight: '800', color: C.ink }}>#{o.no}</Text>
                <Text style={{ fontSize: 10, color: C.muted, marginTop: 2 }}>{o.items[0]?.title}</Text>
              </View>
              <Text style={{ fontSize: 13, fontWeight: '800', color: C.goldText }}>{fmt(o.escrow.amount)} c.</Text>
            </View>
            <View style={{ flexDirection: 'row', gap: 8, marginTop: 10 }}>
              <Btn title={t('admin_release')} small style={{ flex: 1 }} onPress={() => {
                const r = adminRelease(o.id);
                showToast(r.ok ? `${t('release_done')} ${fmt(r.split.sellerPayout)}` : t('error'), r.ok ? 'ok' : 'err');
              }} />
              <Btn title={t('admin_refund')} kind="danger" small style={{ flex: 1 }} onPress={() => {
                const r = adminRefund(o.id);
                showToast(r.ok ? t('admin_refund') : t('error'), r.ok ? 'ok' : 'err');
              }} />
            </View>
          </Card>
        ))}

        <Text style={styles.section}>{t('admin_payouts')} · {payoutReq.length}</Text>
        <Card style={{ padding: 6 }}>
          {!payoutReq.length ? <Text style={{ fontSize: 11, color: C.muted, padding: 10 }}>{t('admin_no_data')}</Text> : payoutReq.map((p, i) => (
            <View key={p.id} style={styles.row}>
              <View style={{ flex: 1 }}>
                <Text style={{ fontSize: 11.5, fontWeight: '700', color: C.ink }}>{fmt(p.amount)} c.</Text>
                <Text style={{ fontSize: 9.5, color: C.muted, marginTop: 2 }}>
                  {p.sellerId} · {p.fourEye ? t('admin_four_eye') : 'OK'}
                </Text>
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
            placeholderTextColor="#B9C0CE"
            style={{ fontSize: 12.5, color: C.ink, backgroundColor: C.bg, borderRadius: 11, padding: 10, minHeight: 62 }}
            multiline
          />
          <Btn
            title={t('admin_broadcast')}
            small
            style={{ marginTop: 10 }}
            disabled={!msg.trim()}
            onPress={() => { broadcast(msg); setMsg(''); showToast(t('admin_broadcast_sent')); }}
          />
          {state.broadcast ? <Text style={{ fontSize: 9.5, color: C.green, marginTop: 8 }}>✓ Охирин: {state.broadcast.slice(0, 60)}</Text> : null}
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
                {a.amount ? `${fmt(a.amount)}` : new Date(a.at).toLocaleTimeString('ru-RU').slice(0, 5)}
              </Text>
            </View>
          ))}
        </Card>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  section: { fontSize: 11, fontWeight: '800', color: C.muted, marginTop: 18, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 0.5 },
  ledgerRow: { flexDirection: 'row', alignItems: 'center', gap: 6, backgroundColor: '#1B2230', borderRadius: 10, padding: 8, marginTop: 8 },
  dot: { width: 7, height: 7, borderRadius: 4 },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10, paddingHorizontal: 8, borderBottomWidth: 1, borderBottomColor: '#F1F3F8' },
});
