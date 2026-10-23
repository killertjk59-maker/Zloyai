// Профил: забон, калидҳои пайвастшуда, панелҳои фурӯшанда/админ, оффлайн
import React from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable, Switch } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { C, S, fmt } from '../theme';
import { Badge, Btn, Card, Divider, Header, tap } from '../components/ui';
import { useApp, maskPhone } from '../store';
import { LANGS } from '../i18n';

export default function ProfileScreen({ go }) {
  const { t, state, setLang, toggleOffline, syncNow, queueCount, logout, showToast } = useApp();
  const u = state.user;

  return (
    <View style={{ flex: 1, backgroundColor: C.bg }}>
      <Header title={t('profile_title')} />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, paddingTop: 0, paddingBottom: 24 }}>
        <Card style={{ flexDirection: 'row', alignItems: 'center' }}>
          <View style={styles.avatar}><Text style={{ color: '#fff', fontSize: 18, fontWeight: '800' }}>{u?.name?.[0]}</Text></View>
          <View style={{ flex: 1 }}>
            <Text style={{ fontSize: 14, fontWeight: '800', color: C.ink }}>{u?.name}</Text>
            <Text style={{ fontSize: 11, color: C.muted, marginTop: 2 }}>
              {u?.phone ? maskPhone(u.phone) : '@bozor_user'}
            </Text>
          </View>
          <Badge text={t('demo_badge')} kind="gold" />
        </Card>

        <Text style={styles.section}>{t('language')}</Text>
        <Card style={{ padding: 8 }}>
          {LANGS.map((l) => (
            <Pressable key={l.code} onPress={() => { tap(); setLang(l.code); }} style={styles.rowItem}>
              <Text style={{ fontSize: 13, fontWeight: '600', color: C.ink }}>{l.label}</Text>
              {state.lang === l.code ? <Ionicons name="checkmark-circle" size={20} color={C.red} /> : <View style={styles.circle} />}
            </Pressable>
          ))}
        </Card>

        <Text style={styles.section}>{t('account_security')}</Text>
        <Card style={{ padding: 14 }}>
          <Text style={{ fontSize: 10.5, color: C.muted, marginBottom: 8 }}>{t('identities')}</Text>
          {(u?.identities || []).map((id, i) => (
            <View key={i} style={{ flexDirection: 'row', alignItems: 'center', paddingVertical: 8 }}>
              <Text style={{ fontSize: 14, marginRight: 8 }}>{id.provider === 'phone' ? '📱' : id.provider === 'telegram' ? '✈️' : '🔵'}</Text>
              <Text style={{ flex: 1, fontSize: 12, fontWeight: '600', color: C.ink }}>{id.hint}</Text>
              <Badge text={t('linked')} kind="green" />
            </View>
          ))}
        </Card>

        <Text style={styles.section}>{t('offline_mode')}</Text>
        <Card>
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <Ionicons name={state.offline ? 'cloud-offline' : 'cloud-done'} size={18} color={state.offline ? C.red : C.green} />
            <Text style={{ flex: 1, fontSize: 12.5, fontWeight: '700', color: C.ink, marginLeft: 8 }}>
              {state.offline ? t('offline') : t('online')}
            </Text>
            <Switch value={state.offline} onValueChange={toggleOffline} trackColor={{ true: C.red }} />
          </View>
          <Divider style={{ marginVertical: 10 }} />
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <Text style={{ flex: 1, fontSize: 11.5, color: C.muted }}>{queueCount} {t('queued')}</Text>
            <Btn title={t('sync_now')} kind="ghost" small style={{ width: 130 }} onPress={async () => { const r = await syncNow(); showToast(`${r.sent} ✓`); }} />
          </View>
        </Card>

        <Text style={styles.section}>{t('seller_panel')} / {t('admin_panel')}</Text>
        <Card style={{ padding: 8 }}>
          <Pressable onPress={() => { tap(); go('seller'); }} style={styles.rowItem}>
            <Ionicons name="storefront-outline" size={18} color={C.ink2} />
            <Text style={{ flex: 1, marginLeft: 10, fontSize: 13, fontWeight: '600', color: C.ink }}>{t('seller_dash')}</Text>
            <Ionicons name="chevron-forward" size={16} color="#C3CAD8" />
          </Pressable>
          <Divider />
          <Pressable onPress={() => { tap(); go('admin'); }} style={styles.rowItem}>
            <Ionicons name="shield-half-outline" size={18} color={C.ink2} />
            <Text style={{ flex: 1, marginLeft: 10, fontSize: 13, fontWeight: '600', color: C.ink }}>{t('admin_dash')}</Text>
            <Ionicons name="chevron-forward" size={16} color="#C3CAD8" />
          </Pressable>
        </Card>

        <View style={{ marginTop: 16 }}>
          <Btn title={t('logout')} kind="danger" onPress={logout} />
        </View>
        <Text style={{ textAlign: 'center', fontSize: 10, color: C.muted, marginTop: 14 }}>DuoBozor v1.0.0 · {t('version')}</Text>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  avatar: { width: 48, height: 48, borderRadius: 24, backgroundColor: C.red, alignItems: 'center', justifyContent: 'center', marginRight: 12 },
  section: { fontSize: 11, fontWeight: '800', color: C.muted, marginTop: 18, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 0.5 },
  rowItem: { flexDirection: 'row', alignItems: 'center', paddingVertical: 12, paddingHorizontal: 6 },
  circle: { width: 20, height: 20, borderRadius: 10, borderWidth: 2, borderColor: '#CBD2E0' },
});
