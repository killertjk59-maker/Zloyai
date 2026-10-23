// duobozor/mobile/src/components/ui.js — компонентҳои умумӣ (бе haptics, бе Intl)
import React, { useEffect, useRef, useState } from 'react';
import {
  View, Text, Pressable, StyleSheet, ActivityIndicator, ScrollView,
  Animated, Easing, TextInput,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { C, S, G, fmt } from '../theme';

/* ───────────────────────── аниматсияҳои бехатар ───────────────────────── */
const useMountAnim = (delay = 0, dy = 14) => {
  const t = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    Animated.timing(t, {
      toValue: 1, delay, duration: 380, easing: Easing.out(Easing.cubic), useNativeDriver: true,
    }).start();
  }, []);
  return {
    opacity: t,
    transform: [{ translateY: t.interpolate({ inputRange: [0, 1], outputRange: [dy, 0] }) }],
  };
};

/** Fade+slide барои ҳар блок — native driver, ҳеҷ layout animation нест */
export function FadeIn({ children, delay = 0, dy = 14, style }) {
  const a = useMountAnim(delay, dy);
  return <Animated.View style={[style, a]}>{children}</Animated.View>;
}

/** Тез кардани элемент ҳангоми пахш (скайл) — ҳамеша ҳис мешавад */
export function Press({ children, onPress, style, containerStyle, disabled, scaleTo = 0.965, onPressIn, hitSlop, testID }) {
  const s = useRef(new Animated.Value(1)).current;
  const to = (v) => Animated.spring(s, { toValue: v, useNativeDriver: true, damping: 14, stiffness: 260, mass: 0.6 }).start();
  return (
    <Pressable
      disabled={disabled}
      hitSlop={hitSlop}
      testID={testID}
      style={containerStyle}
      onPressIn={(e) => { to(scaleTo); onPressIn && onPressIn(e); }}
      onPressOut={() => to(1)}
      onPress={onPress}
    >
      <Animated.View style={[{ transform: [{ scale: s }] }, style]}>{children}</Animated.View>
    </Pressable>
  );
}

/* ───────────────────────── тугмаҳо ───────────────────────── */
export function Btn({ title, onPress, kind = 'primary', disabled, icon, style, small, loading, testID }) {
  const txt = {
    primary: '#fff', ghost: C.ink, dark: '#fff', danger: C.red, gold: '#3A2A00',
  };
  const bg = { ghost: C.white, dark: C.ink, danger: C.redSoft, gold: C.yellowSoft };
  const content = (
    <View style={[styles.btnInner, small && { paddingVertical: 9 }]}>
      {loading ? (
        <ActivityIndicator size="small" color={txt[kind]} />
      ) : (
        <>
          {icon ? <Ionicons name={icon} size={small ? 14 : 17} color={txt[kind]} style={{ marginRight: 6 }} /> : null}
          <Text style={[styles.btnText, { color: txt[kind], fontSize: small ? 11.5 : 14 }]} numberOfLines={1}>{title}</Text>
        </>
      )}
    </View>
  );
  return (
    <Press
      onPress={onPress}
      disabled={disabled}
      testID={testID}
      style={[styles.btn, style, disabled && { opacity: 0.45 }]}
    >
      {kind === 'primary' ? (
        <LinearGradient colors={G.brand} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.btnRadius}>
          {content}
        </LinearGradient>
      ) : (
        <View style={[styles.btnRadius, { backgroundColor: bg[kind] }]}>{content}</View>
      )}
    </Press>
  );
}

/* ───────────────────────── кортҳо ───────────────────────── */
export function Card({ children, style, onPress }) {
  if (onPress) return <Press onPress={onPress} style={style}><View style={styles.card}>{children}</View></Press>;
  return <View style={[styles.card, style]}>{children}</View>;
}

export function Badge({ text, kind = 'red', icon }) {
  const map = {
    red: [C.redSoft, C.red], green: [C.greenSoft, C.green], blue: [C.blueSoft, C.blue],
    gold: [C.yellowSoft, C.goldText], gray: ['#F1F3F8', '#5D6577'], dark: ['#20263400', '#fff'],
  };
  const [bg, fg] = map[kind] || map.red;
  return (
    <View style={[styles.badge, { backgroundColor: bg }]}>
      {icon ? <Ionicons name={icon} size={10} color={fg} style={{ marginRight: 3 }} /> : null}
      <Text style={[styles.badgeText, { color: fg }]}>{text}</Text>
    </View>
  );
}

export function Price({ value, size = 16, color = C.red, old, prefix = '' }) {
  return (
    <View style={{ flexDirection: 'row', alignItems: 'baseline' }}>
      <Text style={{ fontSize: size, fontWeight: '800', color, letterSpacing: -0.5 }}>{prefix}{fmt(value)}</Text>
      <Text style={{ fontSize: size * 0.58, fontWeight: '700', color, marginLeft: 2 }}>c.</Text>
      {old ? <Text style={{ fontSize: size * 0.58, color: C.muted, textDecorationLine: 'line-through', marginLeft: 6 }}>{fmt(old)}</Text> : null}
    </View>
  );
}

export function Header({ title, onBack, right, sub }) {
  return (
    <View style={styles.header}>
      {onBack ? (
        <Press testID="btn-back" onPress={onBack} hitSlop={10} style={styles.backBtn}>
          <Ionicons name="chevron-back" size={20} color={C.ink} />
        </Press>
      ) : null}
      <View style={{ flex: 1, marginLeft: onBack ? 10 : 0 }}>
        <Text style={styles.headerTitle} numberOfLines={1}>{title}</Text>
        {sub ? <Text style={styles.headerSub} numberOfLines={1}>{sub}</Text> : null}
      </View>
      {right}
    </View>
  );
}

export function EscrowBox({ t, amount, compact }) {
  return (
    <View style={[styles.escrow, compact && { padding: 11 }]}>
      <LinearGradient colors={['#0FA958', '#0C8B4A']} style={styles.escrowIco}>
        <Ionicons name="shield-checkmark" size={compact ? 13 : 16} color="#fff" />
      </LinearGradient>
      <View style={{ flex: 1 }}>
        <Text style={styles.escrowTitle}>{t('escrow_title')}</Text>
        {amount != null
          ? <Text style={styles.escrowAmt}>{fmt(amount)} c. · {t('in_escrow')}</Text>
          : <Text style={styles.escrowBody}>{t('escrow_body')}</Text>}
      </View>
    </View>
  );
}

export function Progress({ value, color = C.red, height = 6, track = '#F0F2F7' }) {
  const v = Math.max(0, Math.min(1, Number(value) || 0));
  return (
    <View style={{ height, backgroundColor: track, borderRadius: 99, overflow: 'hidden' }}>
      <View style={{ width: `${v * 100}%`, height: '100%', backgroundColor: color, borderRadius: 99 }} />
    </View>
  );
}

export const Divider = ({ style }) => <View style={[{ height: 1, backgroundColor: C.line }, style]} />;

export function KV({ k, v, bold, color }) {
  return (
    <View style={{ flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 6 }}>
      <Text style={{ fontSize: 12.5, color: bold ? C.ink : C.muted, fontWeight: bold ? '800' : '400', flex: 1 }} numberOfLines={1}>{k}</Text>
      <Text style={{ fontSize: bold ? 14 : 12.5, fontWeight: bold ? '800' : '600', color: color || C.ink, marginLeft: 10 }}>{v}</Text>
    </View>
  );
}

export function Empty({ icon = 'sad-outline', title, sub }) {
  return (
    <FadeIn style={{ alignItems: 'center', paddingVertical: 56 }}>
      <View style={styles.emptyCircle}><Ionicons name={icon} size={32} color="#C3CAD9" /></View>
      <Text style={{ marginTop: 14, fontSize: 14, fontWeight: '800', color: C.ink2 }}>{title}</Text>
      {sub ? <Text style={{ marginTop: 5, fontSize: 11.5, color: C.muted, textAlign: 'center', paddingHorizontal: 40 }}>{sub}</Text> : null}
    </FadeIn>
  );
}

export const Loader = () => (
  <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: C.bg }}>
    <ActivityIndicator color={C.red} size="large" />
  </View>
);

export function Toast({ toast }) {
  const a = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    if (!toast) return;
    a.setValue(0);
    Animated.spring(a, { toValue: 1, useNativeDriver: true, damping: 16, stiffness: 220 }).start();
  }, [toast && toast.id]);
  if (!toast) return null;
  const err = toast.kind === 'err';
  return (
    <Animated.View
      pointerEvents="none"
      style={[styles.toast, {
        backgroundColor: err ? '#2A1B1D' : '#0E2418',
        opacity: a,
        transform: [{ translateY: a.interpolate({ inputRange: [0, 1], outputRange: [26, 0] }) }],
      }]}
    >
      <Ionicons name={err ? 'alert-circle' : 'checkmark-circle'} size={17} color={err ? '#FF8C82' : '#5FD394'} />
      <Text style={{ color: err ? '#FFD9D5' : '#CFF3E0', fontSize: 12, fontWeight: '700', marginLeft: 8, flex: 1 }} numberOfLines={2}>
        {toast.msg}
      </Text>
    </Animated.View>
  );
}

export function Kpi({ label, value, color, sub, icon }) {
  return (
    <View style={styles.kpi}>
      <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
        <Text style={styles.kpiLabel} numberOfLines={1}>{label}</Text>
        {icon ? <Ionicons name={icon} size={12} color="#7E89A1" /> : null}
      </View>
      <Text style={[styles.kpiValue, color ? { color } : null]} numberOfLines={1}>{value}</Text>
      {sub ? <Text style={{ fontSize: 9.5, color: '#7E89A1', marginTop: 3 }}>{sub}</Text> : null}
    </View>
  );
}

export const Scroll = ({ children, ...rest }) => (
  <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 30 }} {...rest}>
    {children}
  </ScrollView>
);

/** Майдони вуруд бо label + хато */
export function Field({ label, value, onChangeText, placeholder, keyboard, secure, error, max, style, prefix }) {
  const [focus, setFocus] = useState(false);
  return (
    <View style={style}>
      {label ? <Text style={styles.fieldLabel}>{label}</Text> : null}
      <View style={[styles.field, focus && { borderColor: C.red, backgroundColor: '#FFFCFB' }, error && { borderColor: C.red }]}>
        {prefix ? <Text style={styles.fieldPrefix}>{prefix}</Text> : null}
        <TextInput
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor="#B6BDCC"
          keyboardType={keyboard || 'default'}
          secureTextEntry={!!secure}
          maxLength={max}
          onFocus={() => setFocus(true)}
          onBlur={() => setFocus(false)}
          style={styles.fieldInput}
          autoCapitalize="none"
        />
      </View>
      {error ? <Text style={styles.fieldErr}>{error}</Text> : null}
    </View>
  );
}

/** Ҳалқаи прогресс барои гурӯҳ — статикӣ (бе хатар) */
export function Ring({ value = 0, size = 132, stroke = 8, color = C.orange, children }) {
  const p = Math.max(0, Math.min(1, value));
  return (
    <View style={{ width: size, height: size, alignItems: 'center', justifyContent: 'center' }}>
      <View style={{
        position: 'absolute', width: size, height: size, borderRadius: size / 2,
        borderWidth: stroke, borderColor: '#2A3446',
      }} />
      <View style={{
        position: 'absolute', width: size, height: size, borderRadius: size / 2,
        borderWidth: stroke, borderColor: color,
        borderRightColor: p > 0.25 ? color : 'transparent',
        borderBottomColor: p > 0.5 ? color : 'transparent',
        borderLeftColor: p > 0.75 ? color : 'transparent',
        borderTopColor: color,
        opacity: p > 0 ? 1 : 0,
        transform: [{ rotate: '-45deg' }],
      }} />
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  btn: { borderRadius: 16, overflow: 'hidden', ...S.shadowLg },
  btnRadius: { borderRadius: 16, overflow: 'hidden' },
  btnInner: { paddingVertical: 14, paddingHorizontal: 14, alignItems: 'center', justifyContent: 'center', flexDirection: 'row' },
  btnText: { fontWeight: '800', letterSpacing: -0.2 },
  card: { backgroundColor: C.card, borderRadius: S.r, padding: 14, ...S.shadow },
  badge: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 8, paddingVertical: 3.5, borderRadius: 99, alignSelf: 'flex-start' },
  badgeText: { fontSize: 9.5, fontWeight: '800', letterSpacing: 0.2 },
  header: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, paddingTop: 10, paddingBottom: 12 },
  backBtn: { width: 36, height: 36, borderRadius: 12, backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center', ...S.shadow },
  headerTitle: { fontSize: 17, fontWeight: '800', color: C.ink, letterSpacing: -0.3 },
  headerSub: { fontSize: 10.5, color: C.muted, marginTop: 1 },
  escrow: { flexDirection: 'row', alignItems: 'center', gap: 11, backgroundColor: '#0E2418', borderRadius: 16, padding: 13 },
  escrowIco: { width: 30, height: 30, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
  escrowTitle: { fontSize: 11.5, fontWeight: '800', color: '#7CE3A8' },
  escrowBody: { fontSize: 10.5, color: '#9FB8AA', lineHeight: 15, marginTop: 3 },
  escrowAmt: { fontSize: 12.5, fontWeight: '800', color: '#fff', marginTop: 2 },
  emptyCircle: { width: 74, height: 74, borderRadius: 37, backgroundColor: '#F0F2F8', alignItems: 'center', justifyContent: 'center' },
  toast: { position: 'absolute', left: 16, right: 16, bottom: 96, borderRadius: 15, padding: 13, flexDirection: 'row', alignItems: 'center', elevation: 20, ...S.shadow },
  kpi: { flex: 1, backgroundColor: C.dark2, borderRadius: 14, padding: 11, borderWidth: 1, borderColor: '#28313F' },
  kpiLabel: { fontSize: 9, color: '#7E89A1', textTransform: 'uppercase', letterSpacing: 0.4, flex: 1 },
  kpiValue: { fontSize: 16, fontWeight: '800', color: '#fff', marginTop: 4, letterSpacing: -0.5 },
  fieldLabel: { fontSize: 9.5, fontWeight: '800', color: C.muted, letterSpacing: 0.6, marginBottom: 6 },
  field: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 15, paddingHorizontal: 14, borderWidth: 1.5, borderColor: 'transparent', ...S.shadow },
  fieldPrefix: { fontSize: 15, fontWeight: '800', color: C.ink, marginRight: 6 },
  fieldInput: { flex: 1, fontSize: 15, fontWeight: '700', color: C.ink, paddingVertical: 13 },
  fieldErr: { fontSize: 10, color: C.red, marginTop: 5, fontWeight: '700' },
});
