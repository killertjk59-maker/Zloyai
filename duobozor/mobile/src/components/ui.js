// duobozor/mobile/src/components/ui.js — компонентҳои умумӣ
import React from 'react';
import { View, Text, Pressable, StyleSheet, ActivityIndicator, ScrollView } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { C, S, fmt } from '../theme';

export const tap = () => { try { Haptics.selectionAsync(); } catch {} };

export function Btn({ title, onPress, kind = 'primary', disabled, icon, style, small }) {
  const flat = kind === 'ghost' || kind === 'dark' || kind === 'danger';
  const bg = {
    primary: null, ghost: C.white, dark: C.ink, danger: C.redSoft, disabled: '#E4E8F0',
  };
  const txt = { primary: '#fff', ghost: C.ink, dark: '#fff', danger: C.red, disabled: '#A9B1C2' };
  const inner = (
    <View style={[styles.btnInner, small && { paddingVertical: 10 }]}>
      {icon ? <Ionicons name={icon} size={small ? 15 : 18} color={txt[disabled ? 'disabled' : kind]} style={{ marginRight: 6 }} /> : null}
      <Text style={[styles.btnText, { color: txt[disabled ? 'disabled' : kind], fontSize: small ? 12 : 14 }]} numberOfLines={1}>
        {title}
      </Text>
    </View>
  );
  return (
    <Pressable
      onPress={() => { if (disabled) return; tap(); onPress && onPress(); }}
      disabled={disabled}
      style={({ pressed }) => [
        styles.btn, style, disabled && { backgroundColor: bg.disabled, shadowOpacity: 0 },
        !disabled && !flat && { backgroundColor: null },
        pressed && !disabled && { transform: [{ scale: 0.985 }] },
      ]}
    >
      {!disabled && kind === 'primary' ? (
        <LinearGradient colors={[C.red, C.orange]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={{ borderRadius: 15 }}>
          {inner}
        </LinearGradient>
      ) : (
        <View style={{ backgroundColor: bg[kind], borderRadius: 15 }}>{inner}</View>
      )}
    </Pressable>
  );
}

export function Card({ children, style, onPress }) {
  const Wrap = onPress ? Pressable : View;
  return <Wrap onPress={onPress} style={[styles.card, style]}>{children}</Wrap>;
}

export function Badge({ text, kind = 'red', icon }) {
  const map = {
    red: [C.redSoft, C.red], green: [C.greenSoft, C.green], blue: [C.blueSoft, C.blue],
    gold: [C.yellowSoft, C.goldText], gray: ['#F2F4F8', '#5A6478'],
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
      <Text style={{ fontSize: size, fontWeight: '800', color, letterSpacing: -0.4 }}>
        {prefix}{fmt(value)}
      </Text>
      <Text style={{ fontSize: size * 0.6, fontWeight: '700', color, marginLeft: 2 }}>c.</Text>
      {old ? (
        <Text style={{ fontSize: size * 0.6, color: C.muted, textDecorationLine: 'line-through', marginLeft: 6 }}>
          {fmt(old)}
        </Text>
      ) : null}
    </View>
  );
}

export function Header({ title, onBack, right, sub }) {
  return (
    <View style={styles.header}>
      {onBack ? (
        <Pressable onPress={() => { tap(); onBack(); }} style={styles.backBtn} hitSlop={8}>
          <Ionicons name="chevron-back" size={20} color={C.ink} />
        </Pressable>
      ) : null}
      <View style={{ flex: 1 }}>
        <Text style={styles.headerTitle} numberOfLines={1}>{title}</Text>
        {sub ? <Text style={styles.headerSub}>{sub}</Text> : null}
      </View>
      {right}
    </View>
  );
}

export function EscrowBox({ t, amount, compact }) {
  return (
    <View style={[styles.escrow, compact && { padding: 10 }]}>
      <Text style={{ fontSize: compact ? 16 : 20 }}>🛡️</Text>
      <View style={{ flex: 1 }}>
        <Text style={styles.escrowTitle}>{t('escrow_title')}</Text>
        {amount != null ? (
          <Text style={styles.escrowAmt}>{fmt(amount)} c. · {t('in_escrow')}</Text>
        ) : (
          <Text style={styles.escrowBody}>{t('escrow_body')}</Text>
        )}
      </View>
    </View>
  );
}

export function Progress({ value, color = C.red, height = 6 }) {
  return (
    <View style={{ height, backgroundColor: '#F0F2F7', borderRadius: 99, overflow: 'hidden' }}>
      <View style={{ width: `${Math.max(0, Math.min(1, value)) * 100}%`, height: '100%', backgroundColor: color, borderRadius: 99 }} />
    </View>
  );
}

export function Divider({ style }) {
  return <View style={[{ height: 1, backgroundColor: C.line }, style]} />;
}

export function KV({ k, v, bold, color }) {
  return (
    <View style={{ flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 6 }}>
      <Text style={{ fontSize: 12.5, color: bold ? C.ink : C.muted, fontWeight: bold ? '800' : '400' }}>{k}</Text>
      <Text style={{ fontSize: bold ? 14 : 12.5, fontWeight: bold ? '800' : '600', color: color || C.ink }}>{v}</Text>
    </View>
  );
}

export function Empty({ icon = 'sad-outline', title, sub }) {
  return (
    <View style={{ alignItems: 'center', paddingVertical: 48 }}>
      <Ionicons name={icon} size={44} color="#C9D0DE" />
      <Text style={{ marginTop: 12, fontSize: 14, fontWeight: '700', color: C.ink2 }}>{title}</Text>
      {sub ? <Text style={{ marginTop: 4, fontSize: 12, color: C.muted }}>{sub}</Text> : null}
    </View>
  );
}

export function Loader() {
  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: C.bg }}>
      <ActivityIndicator color={C.red} size="large" />
    </View>
  );
}

export function Toast({ toast }) {
  if (!toast) return null;
  const err = toast.kind === 'err';
  return (
    <View style={[styles.toast, { backgroundColor: err ? '#2A1B1D' : '#12301F' }]}>
      <Ionicons name={err ? 'alert-circle' : 'checkmark-circle'} size={16} color={err ? '#FF8C82' : '#5FD394'} />
      <Text style={{ color: err ? '#FFD9D5' : '#CFF3E0', fontSize: 12, fontWeight: '600', marginLeft: 6, flex: 1 }} numberOfLines={2}>
        {toast.msg}
      </Text>
    </View>
  );
}

export function Timeline({ items, t }) {
  return (
    <View style={{ paddingLeft: 6 }}>
      {items.map((it, i) => {
        const last = i === items.length - 1;
        return (
          <View key={it.s + i} style={{ flexDirection: 'row', minHeight: 44 }}>
            <View style={{ width: 16, alignItems: 'center' }}>
              <View style={[styles.dot, { backgroundColor: it.now ? C.red : C.green, borderColor: it.now ? C.red : C.green }]} />
              {!last && <View style={{ width: 2, flex: 1, backgroundColor: '#E7E9F0' }} />}
            </View>
            <View style={{ flex: 1, paddingBottom: 14, paddingLeft: 4 }}>
              <Text style={{ fontSize: 12.5, fontWeight: '700', color: it.now ? C.red : C.ink }}>{it.title}</Text>
              {it.sub ? <Text style={{ fontSize: 10.5, color: C.muted, marginTop: 2 }}>{it.sub}</Text> : null}
            </View>
          </View>
        );
      })}
    </View>
  );
}

export function Kpi({ label, value, color, sub, icon }) {
  return (
    <View style={styles.kpi}>
      <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
        <Text style={styles.kpiLabel} numberOfLines={1}>{label}</Text>
        {icon ? <Ionicons name={icon} size={13} color="#7E89A1" /> : null}
      </View>
      <Text style={[styles.kpiValue, color ? { color } : null]} numberOfLines={1}>{value}</Text>
      {sub ? <Text style={{ fontSize: 9.5, color: '#7E89A1', marginTop: 3 }}>{sub}</Text> : null}
    </View>
  );
}

export const Scroll = ({ children, ...rest }) => (
  <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 28 }} {...rest}>
    {children}
  </ScrollView>
);

const styles = StyleSheet.create({
  btn: { borderRadius: 15, overflow: 'hidden', ...S.shadow },
  btnInner: { paddingVertical: 14, paddingHorizontal: 14, alignItems: 'center', justifyContent: 'center', flexDirection: 'row' },
  btnText: { fontWeight: '800', letterSpacing: -0.2 },
  card: { backgroundColor: C.white, borderRadius: S.r, padding: 14, ...S.shadow },
  badge: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 8, paddingVertical: 3, borderRadius: 99, alignSelf: 'flex-start' },
  badgeText: { fontSize: 9.5, fontWeight: '800' },
  header: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, paddingTop: 8, paddingBottom: 12 },
  backBtn: { width: 34, height: 34, borderRadius: 11, backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center', marginRight: 10, ...S.shadow },
  headerTitle: { fontSize: 17, fontWeight: '800', color: C.ink, letterSpacing: -0.3 },
  headerSub: { fontSize: 10.5, color: C.muted, marginTop: 1 },
  escrow: {
    flexDirection: 'row', alignItems: 'flex-start', gap: 10,
    backgroundColor: '#0E1B14', borderRadius: 16, padding: 14,
  },
  escrowTitle: { fontSize: 12, fontWeight: '800', color: '#7CE3A8' },
  escrowBody: { fontSize: 10.5, color: '#9FB8AA', lineHeight: 15, marginTop: 3 },
  escrowAmt: { fontSize: 13, fontWeight: '800', color: '#fff', marginTop: 3 },
  dot: { width: 11, height: 11, borderRadius: 6, borderWidth: 2.5, marginTop: 3 },
  toast: {
    position: 'absolute', left: 16, right: 16, bottom: 96, borderRadius: 14, padding: 12,
    flexDirection: 'row', alignItems: 'center', zIndex: 999, elevation: 20,
  },
  kpi: { flex: 1, backgroundColor: '#161D2C', borderRadius: 13, padding: 11, borderWidth: 1, borderColor: '#232C3E' },
  kpiLabel: { fontSize: 9, color: '#7E89A1', textTransform: 'uppercase', letterSpacing: 0.4, flex: 1 },
  kpiValue: { fontSize: 16, fontWeight: '800', color: '#fff', marginTop: 4, letterSpacing: -0.4 },
});
