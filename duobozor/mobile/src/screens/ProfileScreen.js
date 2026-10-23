// Профил: забон, калидҳо, оффлайн, панелҳо (вобаста ба нақш)
import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Switch } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { C, S, G, fmt } from '../theme';
import { Badge, Btn, Card, Divider, Header, Press, FadeIn } from '../components/ui';
import { useApp, maskPhone } from '../store';
import { LANGS } from '../i18n';

export default function ProfileScreen({ go }) {
  const { t, state, setLang, toggleOffline, syncNow, queueCount, logout, showToast } = useApp();
  const u = state.user || {};
  const roles = u.roles || ['buyer'];
  const isAdmin = roles.includes('admin');
  const isSeller = roles.includes('seller');
  const [editing, setEditing] = useState(false);

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={t('profile_title')} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 24 }}>
        <FadeIn>
          <LinearGradient colors={isAdmin ? ['#1B2130', '#3A2A12'] : G.dark} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.head}>
            <View style={styles.avatar}><Text style={{ color: C.red, fontSize: 20, fontWeight: '800' }}>{(u.name || 'U')[0]}</Text></View>
            <View style={{ flex: 1 }}>
              <Text style={styles.name} numberOfLines={1}>{u.name || t('guest')}</Text>
              <Text style={styles.meta}>{u.phone ? maskPhone(u.phone) : (u.identities || [])[0]?.hint || '—'}</Text>
              <View style={{ flexDirection: 'row', gap: 5, marginTop: 7 }}>
                {isAdmin ? <Badge text={t('admin_badge')} kind="gold" /> : null}
                {isSeller ? <Badge text={t('seller_badge')} kind="blue" /> : <Badge text="BUYER" kind="gray" />}
                {u.age ? <Badge text={`${u.age} ${t('age_label').toLowerCase()}`} kind="gray" /> : null}
              </View>
            </View>
          </LinearGradient>
        </FadeIn>

        <View style={{ flexDirection: 'row', gap: 8, marginTop: 12 }}>
          <Press onPress={() => go('wallet')} containerStyle={{ flex: 1 }}>
            <Card style={{ alignItems: 'center', paddingVertical: 13 }}>
              <Ionicons name="wallet-outline" size={19} color={C.red} />
              <Text style={styles.quickV}>{fmt(state.wallets[u.id]?.balance || 0)}</Text>
              <Text style={styles.quickL}>{t('wallet_title')}</Text>
            </Card>
          </Press>
          <Press onPress={() => go('orders')} containerStyle={{ flex: 1 }}>
            <Card style={{ alignItems: 'center', paddingVertical: 13 }}>
              <Ionicons name="receipt-outline" size={19} color={C.blue} />
              <Text style={styles.quickV}>{state.orders.filter((o) => o.buyerId === u.id).length}</Text>
              <Text style={styles.quickL}>{t('orders_title')}</Text>
            </Card>
          </Press>
          <Press onPress={() => go('notifications')} containerStyle={{ flex: 1 }}>
            <Card style={{ alignItems: 'center', paddingVertical: 13 }}>
              <Ionicons name="notifications-outline" size={19} color={C.goldText} />
              <Text style={styles.quickV}>{state.audit.length}</Text>
              <Text style={styles.quickL}>{t('notifications')}</Text>
            </Card>
          </Press>
        </View>

        {isAdmin || isSeller ? (
          <>
            <Text style={styles.section}>{isAdmin ? t('admin_panel') : t('seller_panel')}</Text>
            <Card style={{ padding: 8 }}>
              {isSeller ? (
                <>
                  <Press onPress={() => go('seller')}>
                    <View style={styles.rowItem}>
                      <View style={styles.rowIco}><Ionicons name="storefront-outline" size={17} color={C.blue} /></View>
                      <Text style={styles.rowTxt}>{t('seller_dash')}</Text>
                      <Ionicons name="chevron-forward" size={16} color="#C3CAD8" />
                    </View>
                  </Press>
                  <Divider />
                </>
              ) : null}
              {isAdmin ? (
                <Press onPress={() => go('admin')}>
                  <View style={styles.rowItem}>
                    <View style={[styles.rowIco, { backgroundColor: C.yellowSoft }]}><Ionicons name="shield-half-outline" size={17} color={C.goldText} /></View>
                    <Text style={styles.rowTxt}>{t('admin_dash')}</Text>
                    <Ionicons name="chevron-forward" size={16} color="#C3CAD8" />
                  </View>
                </Press>
              ) : null}
            </Card>
          </>
        ) : (
          <View style={{ marginTop: 14 }}>
            <Card style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
              <Ionicons name="shield-half" size={18} color={C.goldText} />
              <Text style={{ flex: 1, fontSize: 11, color: C.muted, lineHeight: 16 }}>Панелҳои фурӯшанда ва админ танҳо барои ҳисобҳои вобаста дастрас аст.</Text>
              <Press onPress={logout}><Badge text="→" kind="gold" /></Press>
            </Card>
          </View>
        )}

        <Text style={styles.section}>{t('account_security')}</Text>
        <Card style={{ padding: 14 }}>
          <Text style={{ fontSize: 10, color: C.muted, marginBottom: 6, fontWeight: '700' }}>{t('identities')}</Text>
          {(u.identities || []).map((id, i) => (
            <View key={i} style={{ flexDirection: 'row', alignItems: 'center', paddingVertical: 8 }}>
              <Text style={{ fontSize: 14, marginRight: 8 }}>{id.provider === 'phone' ? '📱' : id.provider === 'telegram' ? '✈️' : '🔵'}</Text>
              <Text style={{ flex: 1, fontSize: 12, fontWeight: '600', color: C.ink }}>{id.hint}</Text>
              <Badge text={t('linked')} kind="green" />
            </View>
          ))}
        </Card>

        <Text style={styles.section}>{t('language')}</Text>
        <Card style={{ padding: 6 }}>
          {LANGS.map((l) => (
            <Press key={l.code} onPress={() => setLang(l.code)}>
              <View style={styles.rowItem}>
                <Text style={{ flex: 1, fontSize: 13, fontWeight: '700', color: C.ink }}>{l.label}</Text>
                {state.lang === l.code
                  ? <Ionicons name="checkmark-circle" size={20} color={C.red} />
                  : <View style={styles.circle} />}
              </View>
            </Press>
          ))}
        </Card>

        <Text style={styles.section}>{t('offline_mode')}</Text>
        <Card>
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <Ionicons name={state.offline ? 'cloud-offline' : 'cloud-done'} size={18} color={state.offline ? C.red : C.green} />
            <Text style={{ flex: 1, fontSize: 12.5, fontWeight: '700', color: C.ink, marginLeft: 8 }}>
              {state.offline ? t('offline') : t('online')}
            </Text>
            <Switch value={!!state.offline} onValueChange={toggleOffline} trackColor={{ true: C.red, false: '#D7DCE6' }} thumbColor="#fff" />
          </View>
          <Divider style={{ marginVertical: 10 }} />
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <Text style={{ flex: 1, fontSize: 11.5, color: C.muted }}>{queueCount} {t('queued')}</Text>
            <Btn title={t('sync_now')} kind="ghost" small style={{ width: 130 }} onPress={async () => { const r = await syncNow(); showToast(`${r.sent} ✓`); }} />
          </View>
        </Card>

        <View style={{ marginTop: 18 }}>
          <Btn title={t('logout')} kind="danger" icon="log-out-outline" onPress={logout} />
        </View>
        <Text style={{ textAlign: 'center', fontSize: 10, color: C.muted, marginTop: 14 }}>DuoBozor v1.1.0 · {t('version')}</Text>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  head: { flexDirection: 'row', alignItems: 'center', borderRadius: 20, padding: 16 },
  avatar: { width: 52, height: 52, borderRadius: 26, backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center', marginRight: 13 },
  name: { fontSize: 15, fontWeight: '800', color: '#fff' },
  meta: { fontSize: 11, color: '#9DA6BA', marginTop: 2 },
  quickV: { fontSize: 14, fontWeight: '800', color: C.ink, marginTop: 6 },
  quickL: { fontSize: 9, color: C.muted, marginTop: 2 },
  section: { fontSize: 10.5, fontWeight: '800', color: C.muted, marginTop: 18, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 0.6 },
  rowItem: { flexDirection: 'row', alignItems: 'center', paddingVertical: 11, paddingHorizontal: 6, gap: 10 },
  rowIco: { width: 32, height: 32, borderRadius: 10, backgroundColor: C.blueSoft, alignItems: 'center', justifyContent: 'center' },
  rowTxt: { flex: 1, fontSize: 12.5, fontWeight: '700', color: C.ink },
  circle: { width: 20, height: 20, borderRadius: 10, borderWidth: 2, borderColor: '#CBD2E0' },
});
