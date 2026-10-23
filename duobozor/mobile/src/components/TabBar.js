// duobozor/mobile/src/components/TabBar.js
// Morphing indicator + Ripple + FAB — бо Animated API-и React Native (бе dependency иловагӣ)
import React, { useEffect, useRef, useState } from 'react';
import { View, Text, Pressable, Animated, StyleSheet, Dimensions, Easing } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import * as Haptics from 'expo-haptics';
import { C, S } from '../theme';

const { width: W } = Dimensions.get('window');
const BAR_H = 66;
const TAB_W = (W - 12) / 5;

const TABS = [
  { key: 'home', icon: 'home-outline', iconOn: 'home', label: 'tab_home' },
  { key: 'search', icon: 'search-outline', iconOn: 'search', label: 'tab_search' },
  null, // FAB
  { key: 'cart', icon: 'bag-outline', iconOn: 'bag', label: 'tab_cart' },
  { key: 'orders', icon: 'receipt-outline', iconOn: 'receipt', label: 'tab_orders' },
];

function Ripple({ x, y, size }) {
  const s = useRef(new Animated.Value(0)).current;
  const o = useRef(new Animated.Value(0.28)).current;
  useEffect(() => {
    Animated.parallel([
      Animated.timing(s, { toValue: 1, duration: 520, easing: Easing.out(Easing.cubic), useNativeDriver: true }),
      Animated.timing(o, { toValue: 0, duration: 520, useNativeDriver: true }),
    ]).start();
  }, []);
  return (
    <Animated.View pointerEvents="none" style={{
      position: 'absolute', width: size, height: size, borderRadius: size / 2,
      left: x - size / 2, top: y - size / 2, backgroundColor: C.red,
      opacity: o, transform: [{ scale: s }],
    }} />
  );
}

export default function TabBar({ active, onChange, t, cartCount, orderBadge }) {
  const pillX = useRef(new Animated.Value(0)).current;
  const pillW = useRef(new Animated.Value(58)).current;
  const [ripples, setRipples] = useState({});
  const [fabOpen, setFabOpen] = useState(false);
  const fabRot = useRef(new Animated.Value(0)).current;
  const menuAnim = useRef(new Animated.Value(0)).current;
  const scaleAnims = useRef(TABS.map(() => new Animated.Value(1))).current;

  const slotOf = (i) => (i < 2 ? i : i + 1);

  const moveTo = (i) => {
    Animated.parallel([
      Animated.spring(pillX, { toValue: slotOf(i) * TAB_W + (TAB_W - 58) / 2, useNativeDriver: true, damping: 18, stiffness: 220, mass: 0.9 }),
      Animated.spring(pillW, { toValue: 58, useNativeDriver: false, damping: 18, stiffness: 220 }),
    ]).start();
  };

  useEffect(() => { pillX.setValue(slotOf(active) * TAB_W + (TAB_W - 58) / 2); }, []);

  const onTab = (i, e) => {
    try { Haptics.selectionAsync(); } catch {}
    const idx = i < 2 ? i : i - 1;
    moveTo(idx);
    const { locationX, locationY } = e.nativeEvent;
    const id = Date.now();
    setRipples((r) => ({ ...r, [idx]: { id, x: locationX, y: locationY } }));
    setTimeout(() => setRipples((r) => { const n = { ...r }; delete n[idx]; return n; }), 560);

    Animated.sequence([
      Animated.timing(scaleAnims[i], { toValue: 0.86, duration: 70, useNativeDriver: true }),
      Animated.spring(scaleAnims[i], { toValue: 1, useNativeDriver: true, damping: 12, stiffness: 260 }),
    ]).start();

    onChange(idx);
  };

  const toggleFab = () => {
    try { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); } catch {}
    const next = !fabOpen;
    setFabOpen(next);
    Animated.parallel([
      Animated.spring(fabRot, { toValue: next ? 1 : 0, useNativeDriver: true, damping: 14, stiffness: 200 }),
      Animated.timing(menuAnim, { toValue: next ? 1 : 0, duration: 220, useNativeDriver: true }),
    ]).start();
  };

  const fabActions = [
    { key: 'group', icon: 'people', color: C.red, bg: C.redSoft, label: t('create_group') },
    { key: 'invite', icon: 'gift', color: '#B47A00', bg: C.yellowSoft, label: t('group_invite') },
  ];

  return (
    <View style={styles.bar}>
      {fabOpen ? <Pressable style={StyleSheet.absoluteFill} onPress={toggleFab} /> : null}

      <Animated.View pointerEvents="none" style={[styles.pill, { width: pillW, transform: [{ translateX: pillX }] }]} />

      {TABS.map((tab, i) => {
        if (!tab) {
          return (
            <View key="fab" style={styles.fabWrap}>
              {fabActions.map((a, k) => (
                <Animated.View
                  key={a.key}
                  pointerEvents={fabOpen ? 'auto' : 'none'}
                  style={[styles.fabItem, {
                    opacity: menuAnim,
                    transform: [
                      { translateY: menuAnim.interpolate({ inputRange: [0, 1], outputRange: [14 + k * 6, 0] }) },
                      { scale: menuAnim.interpolate({ inputRange: [0, 1], outputRange: [0.85, 1] }) },
                    ],
                  }]}
                >
                  <Pressable style={styles.fabItemInner} onPress={() => { toggleFab(); onChange(a.key); }}>
                    <Text style={styles.fabItemText}>{a.label}</Text>
                    <View style={[styles.fabItemIcon, { backgroundColor: a.bg }]}>
                      <Ionicons name={a.icon} size={14} color={a.color} />
                    </View>
                  </Pressable>
                </Animated.View>
              ))}
              <Pressable onPress={toggleFab} hitSlop={6} style={{ marginTop: -20 }}>
                <Animated.View style={{
                  transform: [
                    { rotate: fabRot.interpolate({ inputRange: [0, 1], outputRange: ['0deg', '135deg'] }) },
                    { scale: fabRot.interpolate({ inputRange: [0, 1], outputRange: [1, 1.08] }) },
                  ],
                }}>
                  <LinearGradient colors={[C.red, C.orange]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.fab}>
                    <Ionicons name="add" size={26} color="#fff" />
                  </LinearGradient>
                </Animated.View>
              </Pressable>
            </View>
          );
        }

        const idx = i < 2 ? i : i - 1;
        const isActive = active === idx;
        const badge = tab.key === 'cart' ? cartCount : tab.key === 'orders' ? orderBadge : 0;
        const rip = ripples[idx];

        return (
          <Pressable key={tab.key} style={styles.tab} onPress={(e) => onTab(i, e)}>
            {rip ? <Ripple x={rip.x} y={rip.y} size={TAB_W * 1.8} /> : null}
            <Animated.View style={{ transform: [{ scale: scaleAnims[i] }] }}>
              <Ionicons name={isActive ? tab.iconOn : tab.icon} size={21} color={isActive ? C.red : '#A6AEC2'} />
            </Animated.View>
            <Text style={[styles.label, { color: isActive ? C.red : '#A6AEC2', fontWeight: isActive ? '800' : '600' }]} numberOfLines={1}>
              {t(tab.label)}
            </Text>
            {badge > 0 ? (
              <View style={styles.badge}><Text style={styles.badgeTxt}>{badge}</Text></View>
            ) : null}
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    height: BAR_H, flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff',
    borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: C.line, paddingHorizontal: 6, paddingBottom: 4,
  },
  pill: {
    position: 'absolute', top: 6, left: 6, height: 54, borderRadius: 16,
    backgroundColor: 'rgba(232,64,42,0.10)', borderWidth: 1.5, borderColor: 'rgba(232,64,42,0.20)',
  },
  tab: { width: TAB_W, height: 56, alignItems: 'center', justifyContent: 'center', overflow: 'hidden', borderRadius: 16 },
  label: { fontSize: 9, marginTop: 3 },
  badge: {
    position: 'absolute', top: 6, right: TAB_W / 2 - 16, minWidth: 15, height: 15, borderRadius: 8,
    paddingHorizontal: 4, backgroundColor: C.red, alignItems: 'center', justifyContent: 'center',
    borderWidth: 1.5, borderColor: '#fff',
  },
  badgeTxt: { color: '#fff', fontSize: 8.5, fontWeight: '800' },
  fabWrap: { width: TAB_W, alignItems: 'center', justifyContent: 'center' },
  fab: {
    width: 52, height: 52, borderRadius: 18, alignItems: 'center', justifyContent: 'center',
    shadowColor: C.red, shadowOpacity: 0.45, shadowRadius: 12, shadowOffset: { width: 0, height: 8 }, elevation: 10,
  },
  fabItem: { position: 'absolute', bottom: 46, alignItems: 'center' },
  fabItemInner: {
    flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 14,
    paddingVertical: 8, paddingHorizontal: 12, ...S.shadow, elevation: 8,
  },
  fabItemText: { fontSize: 11, fontWeight: '700', color: C.ink, marginRight: 8 },
  fabItemIcon: { width: 26, height: 26, borderRadius: 9, alignItems: 'center', justifyContent: 'center' },
});
