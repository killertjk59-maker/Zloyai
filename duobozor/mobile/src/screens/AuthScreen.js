// Воридшавӣ / Сабти ном: Telegram · Google · Телефон · Админ (рақам + рамз)
import React, { useState, useRef, useEffect } from 'react';
import {
  View, Text, StyleSheet, Pressable, ScrollView, KeyboardAvoidingView, Platform,
  Animated, Easing, Linking, Dimensions,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { C, S, G } from '../theme';
import { Btn, Badge, Field, FadeIn, Press } from '../components/ui';
import { useApp, normalizePhone, maskPhone } from '../store';

const { height: H } = Dimensions.get('window');

function Steps({ n }) {
  return (
    <View style={{ flexDirection: 'row', gap: 6, marginBottom: 18 }}>
      {[0, 1].map((i) => (
        <View key={i} style={{ height: 4, flex: 1, borderRadius: 2, backgroundColor: i <= n ? C.red : '#E4E8F0' }} />
      ))}
    </View>
  );
}

export default function AuthScreen() {
  const { t, register, adminLogin, showToast, state } = useApp();
  const [step, setStep] = useState('welcome'); // welcome | provider | form | admin | telegram
  const [provider, setProvider] = useState('phone');
  const [form, setForm] = useState({ name: '', surname: '', age: '', phone: '', city: 'Хуҷанд' });
  const [errors, setErrors] = useState({});
  const [admin, setAdmin] = useState({ phone: '', password: '' });
  const [adminErr, setAdminErr] = useState('');
  const fade = useRef(new Animated.Value(1)).current;

  const goStep = (s) => {
    Animated.timing(fade, { toValue: 0, duration: 120, useNativeDriver: true }).start(() => {
      setStep(s);
      Animated.timing(fade, { toValue: 1, duration: 220, easing: Easing.out(Easing.cubic), useNativeDriver: true }).start();
    });
  };

  const set = (k) => (v) => {
    setForm((f) => ({ ...f, [k]: v }));
    if (errors[k]) setErrors((e) => ({ ...e, [k]: null }));
  };

  const submit = () => {
    const errs = {};
    if (String(form.name).trim().length < 2) errs.name = t('name_invalid');
    const age = parseInt(form.age, 10);
    if (!(age >= 12 && age <= 100)) errs.age = t('age_invalid');
    if (provider === 'phone' && !normalizePhone(form.phone)) errs.phone = t('phone_invalid');
    setErrors(errs);
    if (Object.keys(errs).length) return;
    const r = register({ ...form, provider });
    if (!r.ok) showToast(r.error, 'err');
  };

  const submitAdmin = () => {
    setAdminErr('');
    const r = adminLogin(admin.phone, admin.password);
    if (!r.ok) { setAdminErr(r.error); return; }
  };

  const openBot = async () => {
    const url = 'https://t.me/Bozoronline_bot?start=app';
    try {
      const ok = await Linking.canOpenURL(url);
      await Linking.openURL(url);
      if (!ok) showToast('t.me/Bozoronline_bot', 'ok');
    } catch (e) {
      showToast('t.me/Bozoronline_bot', 'ok');
    }
  };

  const PROVIDERS = {
    telegram: { title: t('login_telegram'), sub: t('telegram_sub'), icon: '✈️', color: '#2AABEE' },
    google: { title: t('login_google'), sub: t('google_sub'), icon: null, color: '#4285F4' },
    phone: { title: t('login_phone'), sub: t('phone_sub'), icon: '📱', color: C.red },
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1, backgroundColor: C.bg }}>
      <ScrollView contentContainerStyle={{ flexGrow: 1 }} showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled">
        <LinearGradient colors={G.brand} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.hero}>
          <View style={styles.c1} />
          <View style={styles.c2} />
          <FadeIn delay={40}>
            <View style={styles.logoBox}><Text style={{ fontSize: 30 }}>🛍️</Text></View>
            <Text style={styles.logo}>DuoBozor</Text>
            <Text style={styles.tagline}>Гурӯҳ соз → нархи паст → пул дар escrow</Text>
          </FadeIn>
        </LinearGradient>

        <Animated.View style={[styles.sheet, { opacity: fade }]}>
          {/* ── 1. Хуш омадед ── */}
          {step === 'welcome' && (
            <FadeIn>
              <Text style={styles.h1}>{t('welcome')}</Text>
              <Text style={styles.h2}>{t('welcome_sub')}</Text>

              <View style={{ marginTop: 18, gap: 10 }}>
                <Press onPress={() => { setProvider('telegram'); goStep('telegram'); }}>
                  <View style={[styles.prov, { backgroundColor: '#2AABEE', borderWidth: 0 }]}>
                    <View style={[styles.provIcon, { backgroundColor: 'rgba(255,255,255,0.22)' }]}>
                      <Ionicons name="paper-plane" size={16} color="#fff" />
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text style={[styles.provTitle, { color: '#fff' }]}>{t('login_telegram')}</Text>
                      <Text style={[styles.provSub, { color: 'rgba(255,255,255,0.85)' }]}>{t('telegram_sub')}</Text>
                    </View>
                    <Ionicons name="chevron-forward" size={16} color="rgba(255,255,255,0.9)" />
                  </View>
                </Press>

                <Press onPress={() => { setProvider('google'); goStep('form'); }}>
                  <View style={styles.prov}>
                    <View style={[styles.provIcon, { backgroundColor: C.blueSoft }]}>
                      <Ionicons name="logo-google" size={16} color="#4285F4" />
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text style={styles.provTitle}>{t('login_google')}</Text>
                      <Text style={styles.provSub}>{t('google_sub')}</Text>
                    </View>
                    <Ionicons name="chevron-forward" size={16} color="#C3CAD8" />
                  </View>
                </Press>

                <Press onPress={() => { setProvider('phone'); goStep('form'); }}>
                  <View style={styles.prov}>
                    <View style={[styles.provIcon, { backgroundColor: C.redSoft }]}>
                      <Ionicons name="call" size={16} color={C.red} />
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text style={styles.provTitle}>{t('login_phone')}</Text>
                      <Text style={styles.provSub}>92 123 45 67 · 0921234567 · +992…</Text>
                    </View>
                    <Ionicons name="chevron-forward" size={16} color="#C3CAD8" />
                  </View>
                </Press>
              </View>

              <View style={styles.orRow}>
                <View style={styles.orLine} /><Text style={styles.orTxt}>ё</Text><View style={styles.orLine} />
              </View>

              <Press onPress={() => goStep('admin')}>
                <View style={styles.adminBtn}>
                  <Ionicons name="shield-half" size={17} color={C.goldText} />
                  <Text style={styles.adminTxt}>{t('admin_login')}</Text>
                  <Badge text="ADMIN" kind="gold" />
                </View>
              </Press>

              <Text style={styles.legal}>
                Давом дода, шумо Шартҳои истифода ва Сиёсати махфиятро қабул мекунед.
              </Text>
              <Text style={styles.version}>DuoBozor v1.1.0 · {state.user ? '' : 'demo'}</Text>
            </FadeIn>
          )}

          {/* ── 2. Telegram ── */}
          {step === 'telegram' && (
            <FadeIn>
              <Press onPress={() => goStep('welcome')} style={styles.back}><Ionicons name="chevron-back" size={20} color={C.ink} /></Press>
              <Text style={styles.h1}>{t('telegram_open')}</Text>
              <Text style={styles.h2}>{t('telegram_sub')}</Text>

              <View style={styles.tgCard}>
                <View style={styles.tgAvatar}><Ionicons name="paper-plane" size={22} color="#fff" /></View>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 13, fontWeight: '800', color: C.ink }}>@Bozoronline_bot</Text>
                  <Text style={{ fontSize: 10.5, color: C.muted, marginTop: 2 }}>DuoBozor расмӣ</Text>
                </View>
                <Badge text="✓ online" kind="green" />
              </View>

              <View style={{ gap: 10, marginTop: 16 }}>
                <Btn title={t('open_bot')} icon="paper-plane-outline" onPress={openBot} />
                <Btn title={t('telegram_continue')} kind="dark" onPress={() => { setProvider('telegram'); goStep('form'); }} />
              </View>
              <Text style={styles.legal}>Дар демо баъд аз /start ном ва синну солатонро мепурсем.</Text>
            </FadeIn>
          )}

          {/* ── 3. Сабти ном ── */}
          {step === 'form' && (
            <FadeIn>
              <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 14 }}>
                <Press onPress={() => goStep('welcome')} style={styles.back}>
                  <Ionicons name="chevron-back" size={20} color={C.ink} />
                </Press>
                <View style={{ flex: 1 }} />
                <Badge text={PROVIDERS[provider].title} kind={provider === 'telegram' ? 'blue' : 'red'} />
              </View>

              <Steps n={0} />
              <Text style={styles.h1}>{t('register_title')}</Text>
              <Text style={styles.h2}>{t('register_sub')}</Text>

              <View style={{ marginTop: 16, gap: 12 }}>
                <Field label={t('name_label')} value={form.name} onChangeText={set('name')} placeholder={t('name_ph')} error={errors.name} max={40} />
                <Field label={t('surname_label')} value={form.surname} onChangeText={set('surname')} placeholder={t('surname_ph')} max={40} />
                <View style={{ flexDirection: 'row', gap: 10 }}>
                  <Field label={t('age_label')} value={form.age} onChangeText={(v) => set('age')(v.replace(/\D/g, ''))} placeholder={t('age_ph')} keyboard="number-pad" max={3} error={errors.age} style={{ flex: 1 }} />
                  <Field label={t('city_label')} value={form.city} onChangeText={set('city')} placeholder={t('city_ph')} max={30} style={{ flex: 1.4 }} />
                </View>
                {provider !== 'google' && (
                  <Field
                    label={t('phone_label')}
                    value={form.phone}
                    onChangeText={(v) => set('phone')(v.replace(/[^\d+ ]/g, ''))}
                    placeholder="92 123 45 67"
                    keyboard="phone-pad"
                    prefix="+992"
                    error={errors.phone}
                    max={20}
                  />
                )}
                {form.phone && normalizePhone(form.phone) ? (
                  <View style={styles.normBox}>
                    <Ionicons name="checkmark-circle" size={14} color={C.green} />
                    <Text style={styles.normTxt}>{t('normalization')}: {maskPhone(normalizePhone(form.phone))}</Text>
                  </View>
                ) : null}
              </View>

              <View style={{ marginTop: 18 }}>
                <Btn title={t('next')} icon="arrow-forward" onPress={submit} />
              </View>
              <Text style={styles.legal}>{t('phone_is_key')}</Text>
            </FadeIn>
          )}

          {/* ── 4. Админ: рақам + рамз ── */}
          {step === 'admin' && (
            <FadeIn>
              <Press onPress={() => goStep('welcome')} style={styles.back}><Ionicons name="chevron-back" size={20} color={C.ink} /></Press>
              <View style={styles.adminHead}>
                <LinearGradient colors={['#FFB020', '#FF8A3D']} style={styles.adminIco}>
                  <Ionicons name="shield-half" size={20} color="#fff" />
                </LinearGradient>
                <View style={{ flex: 1 }}>
                  <Text style={styles.h1}>{t('admin_login_title')}</Text>
                  <Text style={styles.h2}>{t('admin_login_sub')}</Text>
                </View>
              </View>

              <View style={{ marginTop: 18, gap: 12 }}>
                <Field
                  label={t('phone_label')}
                  value={admin.phone}
                  onChangeText={(v) => { setAdmin((a) => ({ ...a, phone: v.replace(/[^\d+ ]/g, '') })); setAdminErr(''); }}
                  placeholder="92 111 22 33"
                  keyboard="phone-pad"
                  prefix="+992"
                  max={20}
                />
                <Field
                  label={t('password_label')}
                  value={admin.password}
                  onChangeText={(v) => { setAdmin((a) => ({ ...a, password: v })); setAdminErr(''); }}
                  placeholder={t('password_ph')}
                  secure
                  max={32}
                  error={adminErr}
                />
              </View>

              <View style={{ marginTop: 18 }}>
                <Btn title={t('admin_login')} icon="log-in-outline" onPress={submitAdmin} />
              </View>
              <View style={styles.hintBox}>
                <Ionicons name="information-circle" size={14} color="#8A5B00" />
                <Text style={styles.hintTxt}>{t('admin_hint')}</Text>
              </View>
            </FadeIn>
          )}
        </Animated.View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  hero: {
    paddingTop: 46, paddingBottom: 38, paddingHorizontal: 24, alignItems: 'center',
    borderBottomLeftRadius: 30, borderBottomRightRadius: 30, overflow: 'hidden', minHeight: H * 0.3, justifyContent: 'center',
  },
  c1: { position: 'absolute', width: 230, height: 230, borderRadius: 115, backgroundColor: 'rgba(255,255,255,0.12)', top: -90, right: -70 },
  c2: { position: 'absolute', width: 150, height: 150, borderRadius: 75, backgroundColor: 'rgba(255,255,255,0.09)', bottom: -60, left: -40 },
  logoBox: {
    width: 66, height: 66, borderRadius: 22, backgroundColor: 'rgba(255,255,255,0.2)', alignItems: 'center',
    justifyContent: 'center', alignSelf: 'center', borderWidth: 1, borderColor: 'rgba(255,255,255,0.3)',
  },
  logo: { fontSize: 26, fontWeight: '800', color: '#fff', marginTop: 12, letterSpacing: -0.8, textAlign: 'center' },
  tagline: { fontSize: 11.5, color: 'rgba(255,255,255,0.92)', marginTop: 6, textAlign: 'center' },
  sheet: {
    flex: 1, marginTop: -20, backgroundColor: C.bg, borderTopLeftRadius: 28, borderTopRightRadius: 28,
    padding: 20, paddingTop: 24, minHeight: H * 0.62,
  },
  h1: { fontSize: 20, fontWeight: '800', color: C.ink, letterSpacing: -0.4 },
  h2: { fontSize: 12, color: C.muted, marginTop: 5, lineHeight: 18 },
  prov: {
    flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 16, padding: 13,
    borderWidth: 1, borderColor: '#EEF0F6', ...S.shadow,
  },
  provIcon: { width: 36, height: 36, borderRadius: 12, alignItems: 'center', justifyContent: 'center', marginRight: 11 },
  provTitle: { fontSize: 13, fontWeight: '800', color: C.ink },
  provSub: { fontSize: 9.5, color: C.muted, marginTop: 2 },
  orRow: { flexDirection: 'row', alignItems: 'center', marginVertical: 16, gap: 10 },
  orLine: { flex: 1, height: 1, backgroundColor: C.line },
  orTxt: { fontSize: 10, color: C.muted, fontWeight: '700' },
  adminBtn: { flexDirection: 'row', alignItems: 'center', gap: 9, backgroundColor: C.yellowSoft, borderRadius: 15, padding: 13, borderWidth: 1, borderColor: '#F3E0B4', borderStyle: 'dashed' },
  adminTxt: { flex: 1, fontSize: 12.5, fontWeight: '800', color: C.goldText },
  legal: { fontSize: 9.5, color: '#9AA2B4', textAlign: 'center', marginTop: 16, lineHeight: 14 },
  version: { fontSize: 9, color: '#C0C6D2', textAlign: 'center', marginTop: 10 },
  back: { width: 36, height: 36, borderRadius: 12, backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center', ...S.shadow },
  tgCard: { flexDirection: 'row', alignItems: 'center', gap: 11, backgroundColor: '#fff', borderRadius: 16, padding: 13, marginTop: 18, ...S.shadow },
  tgAvatar: { width: 42, height: 42, borderRadius: 21, backgroundColor: '#2AABEE', alignItems: 'center', justifyContent: 'center' },
  normBox: { flexDirection: 'row', alignItems: 'center', gap: 6, backgroundColor: C.greenSoft, borderRadius: 12, padding: 10 },
  normTxt: { fontSize: 10.5, fontWeight: '800', color: C.green },
  adminHead: { flexDirection: 'row', alignItems: 'center', gap: 12, marginTop: 8 },
  adminIco: { width: 44, height: 44, borderRadius: 14, alignItems: 'center', justifyContent: 'center' },
  hintBox: { flexDirection: 'row', alignItems: 'center', gap: 7, backgroundColor: C.yellowSoft, borderRadius: 12, padding: 11, marginTop: 14 },
  hintTxt: { flex: 1, fontSize: 10, color: '#8A5B00', fontWeight: '700', lineHeight: 15 },
});
