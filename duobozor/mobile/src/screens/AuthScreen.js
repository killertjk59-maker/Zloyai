// Воридшавӣ: Telegram · Google · Телефон (формат ҳамеша як аккаунт)
import React, { useState } from 'react';
import { View, Text, TextInput, StyleSheet, Pressable, ScrollView, KeyboardAvoidingView, Platform } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { C, S } from '../theme';
import { Btn, Badge, tap } from '../components/ui';
import { useApp, normalizePhone, maskPhone } from '../store';

export default function AuthScreen() {
  const { t, login, state } = useApp();
  const [mode, setMode] = useState('welcome'); // welcome | phone | otp
  const [phone, setPhone] = useState('');
  const [code, setCode] = useState('');
  const norm = normalizePhone(phone);
  const known = norm ? state.users.find((u) => u.phone === norm) : null;

  const doLogin = async (provider, payload) => {
    const r = await login(provider, payload);
    if (!r.ok) return;
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1, backgroundColor: C.bg }}>
      <ScrollView contentContainerStyle={{ flexGrow: 1 }} showsVerticalScrollIndicator={false}>
        <LinearGradient colors={[C.red, '#FF6A3D', C.orange]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.hero}>
          <View style={styles.heroCircle} />
          <Text style={{ fontSize: 54 }}>🛍️</Text>
          <Text style={styles.logo}>DuoBozor</Text>
          <Text style={styles.logoSub}>{t('welcome_sub')}</Text>
        </LinearGradient>

        <View style={{ padding: 20, marginTop: -18, backgroundColor: C.bg, borderTopLeftRadius: 26, borderTopRightRadius: 26, flex: 1 }}>
          {mode === 'welcome' && (
            <>
              <Text style={styles.h1}>{t('welcome')}</Text>
              <Text style={styles.h2}>{t('welcome_sub')}</Text>

              <View style={{ marginTop: 18 }}>
                <Pressable onPress={() => { tap(); doLogin('telegram'); }} style={styles.provTg}>
                  <View style={styles.provIcon}><Text style={{ fontSize: 16 }}>✈️</Text></View>
                  <Text style={{ color: '#fff', fontWeight: '800', fontSize: 13.5, flex: 1 }}>{t('login_telegram')}</Text>
                  <Badge text={t('demo_badge')} kind="gold" />
                </Pressable>

                <Pressable onPress={() => { tap(); doLogin('google'); }} style={styles.prov}>
                  <View style={[styles.provIcon, { backgroundColor: C.blueSoft }]}>
                    <Ionicons name="logo-google" size={16} color="#4285F4" />
                  </View>
                  <Text style={styles.provText}>{t('login_google')}</Text>
                  <Ionicons name="chevron-forward" size={16} color="#C3CAD8" />
                </Pressable>

                <Pressable onPress={() => { tap(); setMode('phone'); }} style={styles.prov}>
                  <View style={[styles.provIcon, { backgroundColor: C.redSoft }]}>
                    <Ionicons name="phone-portrait-outline" size={16} color={C.red} />
                  </View>
                  <Text style={styles.provText}>{t('login_phone')}</Text>
                  <Ionicons name="chevron-forward" size={16} color="#C3CAD8" />
                </Pressable>
              </View>

              <Text style={styles.legal}>
                Давом дода, шумо Шартҳои истифода ва Сиёсати махфиятро қабул мекунед.
              </Text>
            </>
          )}

          {mode === 'phone' && (
            <>
              <Pressable onPress={() => setMode('welcome')} style={styles.back}><Ionicons name="chevron-back" size={20} color={C.ink} /></Pressable>
              <Text style={styles.h1}>{t('phone_title')}</Text>
              <Text style={styles.h2}>{t('phone_sub')}</Text>

              <View style={[styles.field, norm && { borderColor: C.red }]}>
                <Text style={styles.fieldLabel}>{t('phone_label')}</Text>
                <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                  <Text style={styles.cc}>+992</Text>
                  <TextInput
                    value={phone}
                    onChangeText={setPhone}
                    placeholder="92 123 45 67"
                    placeholderTextColor="#B9C0CE"
                    keyboardType="phone-pad"
                    style={styles.input}
                    maxLength={20}
                  />
                </View>
              </View>

              {norm ? (
                <View style={styles.normBox}>
                  <Text style={styles.normLabel}>✓ {t('normalization')}</Text>
                  <Text style={styles.normVal}>{norm}</Text>
                </View>
              ) : null}

              {norm && known ? (
                <View style={[styles.card, { marginTop: 12, flexDirection: 'row', alignItems: 'center' }]}>
                  <View style={styles.avatar}><Text style={{ color: '#fff', fontWeight: '800' }}>{known.name[0]}</Text></View>
                  <View style={{ flex: 1 }}>
                    <Text style={{ fontSize: 13, fontWeight: '800', color: C.ink }}>{t('account_found')}</Text>
                    <Text style={{ fontSize: 10.5, color: C.muted, marginTop: 2 }}>
                      {known.name} · {maskPhone(known.phone)}
                    </Text>
                  </View>
                  <Ionicons name="checkmark-circle" size={22} color={C.green} />
                </View>
              ) : null}

              <View style={{ marginTop: 18 }}>
                <Btn title={t('continue')} disabled={!norm} onPress={() => setMode('otp')} />
              </View>
            </>
          )}

          {mode === 'otp' && (
            <>
              <Pressable onPress={() => setMode('phone')} style={styles.back}><Ionicons name="chevron-back" size={20} color={C.ink} /></Pressable>
              <Text style={styles.h1}>Коди тасдиқ</Text>
              <Text style={styles.h2}>Ба {maskPhone(norm)} фиристода шуд</Text>

              <View style={{ flexDirection: 'row', justifyContent: 'center', gap: 7, marginTop: 22 }}>
                {[0, 1, 2, 3, 4, 5].map((i) => (
                  <View key={i} style={[styles.otpBox, code.length > i && { borderColor: C.red, backgroundColor: '#FFF7F5' }]}>
                    <Text style={{ fontSize: 19, fontWeight: '800', color: C.ink }}>{code[i] || ''}</Text>
                  </View>
                ))}
              </View>

              <TextInput
                value={code}
                onChangeText={(v) => setCode(v.replace(/\D/g, '').slice(0, 6))}
                keyboardType="number-pad"
                style={{ height: 1, opacity: 0 }}
                autoFocus
              />

              <View style={styles.hintBox}>
                <Text style={{ fontSize: 10.5, color: '#0C7A3C', lineHeight: 15 }}>
                  🛡️ Дар демо код ҳақиқӣ нест — ҳар 6 рақам қабул мешавад.
                </Text>
              </View>

              <View style={{ marginTop: 18 }}>
                <Btn title={t('continue')} disabled={code.length < 4} onPress={() => doLogin('phone', phone)} />
              </View>
            </>
          )}
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  hero: { paddingTop: 64, paddingBottom: 46, paddingHorizontal: 24, alignItems: 'center', borderBottomLeftRadius: 30, borderBottomRightRadius: 30, overflow: 'hidden' },
  heroCircle: { position: 'absolute', width: 220, height: 220, borderRadius: 110, backgroundColor: 'rgba(255,255,255,0.13)', top: -80, right: -70 },
  logo: { fontSize: 24, fontWeight: '800', color: '#fff', marginTop: 8, letterSpacing: -0.6 },
  logoSub: { fontSize: 12, color: 'rgba(255,255,255,0.92)', marginTop: 6, textAlign: 'center', lineHeight: 17 },
  h1: { fontSize: 20, fontWeight: '800', color: C.ink, letterSpacing: -0.4 },
  h2: { fontSize: 12.5, color: C.muted, marginTop: 6, lineHeight: 18 },
  provTg: {
    flexDirection: 'row', alignItems: 'center', backgroundColor: '#2AABEE', borderRadius: 15, padding: 13,
    marginBottom: 10, shadowColor: '#2AABEE', shadowOpacity: 0.35, shadowRadius: 14, shadowOffset: { width: 0, height: 6 }, elevation: 6,
  },
  prov: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 15, padding: 13, marginBottom: 10, ...S.shadow },
  provIcon: { width: 34, height: 34, borderRadius: 11, backgroundColor: 'rgba(255,255,255,0.22)', alignItems: 'center', justifyContent: 'center', marginRight: 10 },
  provText: { flex: 1, fontSize: 13.5, fontWeight: '700', color: C.ink },
  legal: { fontSize: 9.5, color: '#9AA2B4', textAlign: 'center', marginTop: 18, lineHeight: 14 },
  back: { width: 34, height: 34, borderRadius: 11, backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center', marginBottom: 14, ...S.shadow },
  field: { backgroundColor: '#fff', borderRadius: 15, paddingHorizontal: 14, paddingBottom: 10, marginTop: 16, borderWidth: 1.5, borderColor: 'transparent', ...S.shadow },
  fieldLabel: { fontSize: 9.5, fontWeight: '800', color: C.muted, paddingTop: 9 },
  cc: { fontSize: 16, fontWeight: '800', color: C.ink, marginRight: 6 },
  input: { flex: 1, fontSize: 17, fontWeight: '800', color: C.ink, paddingVertical: 6 },
  normBox: { backgroundColor: '#EDFBF3', borderRadius: 12, padding: 10, marginTop: 10, borderWidth: 1, borderColor: '#BFEAD3' },
  normLabel: { fontSize: 9.5, fontWeight: '800', color: '#0C7A3C' },
  normVal: { fontSize: 13, fontWeight: '800', color: '#0C7A3C', marginTop: 2 },
  card: { backgroundColor: '#fff', borderRadius: 16, padding: 14, ...S.shadow },
  avatar: { width: 44, height: 44, borderRadius: 22, backgroundColor: C.red, alignItems: 'center', justifyContent: 'center', marginRight: 12 },
  otpBox: { width: 42, height: 52, borderRadius: 12, backgroundColor: '#fff', borderWidth: 1.5, borderColor: C.line, alignItems: 'center', justifyContent: 'center', ...S.shadow },
  hintBox: { backgroundColor: '#EDFBF3', borderRadius: 13, padding: 11, marginTop: 18 },
});
