// duobozor/mobile/src/components/TabBar.js
// Morphing pill + ripple + FAB — ҳамаи аниматсияҳо бо useNativeDriver: true (устувор)
import React, { useEffect, useRef, useState } from 'react';
import { View, Text, Pressable, Animated, StyleSheet, Dimensions, Easing } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { C, S, G } from '../theme';

const { width: W } = Dimensions.get('window');
const BAR_H = 68;
const SLOTS = 6;
const SLOT_W = W / SLOTS;
const PILL_W = 58;

// index дар TABS ↔ slot (FAB дар байни 2 ва 3)
const TABS = [
  { key: 'home', icon: 'home-outline', on: 'home', label: 'tab_home' },
  { key: 'search', icon: 'search-outline', on: 'search', label: 'tab_search' },
  { key: 'fab', fab: true },
  { key: 'cart', icon: 'bag-outline', on: 'bag', label: 'tab_cart' },
  { key: 'orders', icon: 'receipt-outline', on: 'receipt', label: 'tab_orders' },
  { key: 'profile', icon: 'person-outline', on: 'person', label: 'tab_profile' },
];
const KEYS = ['home', 'search', 'cart', 'orders', 'profile'];
const TAB_INDEX = { home: 0, search: 1, cart: 2, orders: 3, profile: 4 };
const slotOf = (i) => (i < 2 ? i : i + 1);

function Ripple({ x, y }) {
  const p = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    Animated.timing(p, { toValue: 1, duration: 520, easing: Easing.out(Easing.quad), useNativeDriver: true }).start();
  }, []);
  const size = 44;
  return (
    <Animated.View
      pointerEvents="none"
      style={{
        position: 'absolute',
        width: size, height: size, borderRadius: size / 2,
        left: Math.max(0, x - size / 2), top: Math.max(0, y - size / 2),
        backgroundColor: C.red,
        opacity: p.interpolate({ inputRange: [0, 0.15, 1], outputRange: [0, 0.3, 0] }),
        transform: [{ scale: p.interpolate({ inputRange: [0, 1], outputRange: [0.3, 2.4] }) }],
      }}
    />
  );
}

export default function TabBar({ active, onChange, t, cartCount, orderBadge }) {
  const pill = useRef(new Animated.Value(slotOf(active || 0) * SLOT_W + (SLOT_W - PILL_W) / 2)).current;
  const pillScale = useRef(new Animated.Value(1)).current;
  const iconScales = useRef([0, 1, 2, 3, 4].map(() => new Animated.Value(0))).current;
  const fabRot = useRef(new Animated.Value(0)).current;
  const menu = useRef(new Animated.Value(0)).current;
  const [fabOpen, setFabOpen] = useState(false);
  const [ripples, setRipples] = useState({});

  const animateActive = (idx) => {
    Animated.parallel([
      Animated.spring(pill, {
        toValue: slotOf(idx) * SLOT_W + (SLOT_W - PILL_W) / 2,
        useNativeDriver: true, damping: 17, stiffness: 190, mass: 0.8,
      }),
      Animated.sequence([
        Animated.timing(pillScale, { toValue: 0.82, duration: 110, useNativeDriver: true }),
        Animated.spring(pillScale, { toValue: 1, useNativeDriver: true, damping: 10, stiffness: 240 }),
      ]),
      ...iconScales.map((v, i) => Animated.spring(v, {
        toValue: i === idx ? 1 : 0, useNativeDriver: true, damping: 12, stiffness: 220,
      })),
    ]).start();
  };

  useEffect(() => { animateActive(active || 0); }, [active]);

  const press = (tabIdx, e) => {
    const idx = tabIdx < 2 ? tabIdx : tabIdx - 1;
    const x = e && e.nativeEvent ? e.nativeEvent.locationX : 20;
    const y = e && e.nativeEvent ? e.nativeEvent.locationY : 20;
    const id = Date.now();
    const key = KEYS[idx];
    setRipples((r) => ({ ...r, [key]: { id, x, y } }));
    setTimeout(() => setRipples((r) => { const n = { ...r }; delete n[key]; return n; }), 560);
    animateActive(idx);
    onChange(idx);
  };

  const toggleFab = () => {
    const next = !fabOpen;
    setFabOpen(next);
    Animated.parallel([
      Animated.spring(fabRot, { toValue: next ? 1 : 0, useNativeDriver: true, damping: 13, stiffness: 190 }),
      Animated.timing(menu, { toValue: next ? 1 : 0, duration: 220, easing: Easing.out(Easing.cubic), useNativeDriver: true }),
    ]).start();
  };

  const fabActions = [
    { key: 'newgroup', icon: 'people', label: t('create_group'), color: C.red, bg: C.redSoft },
    { key: 'invite', icon: 'gift', label: t('group_invite'), color: C.goldText, bg: C.yellowSoft },
  ];

  const order = TABS.slice(0, 2).concat([TABS[2]], TABS.slice(3));

  return (
    <View style={styles.wrap}>
      <View style={styles.bar}>
        <Animated.View
          pointerEvents="none"
          style={[styles.pill, { transform: [{ translateX: pill }, { scale: pillScale }] }]}
        />
        {order.map((tab, slot) => {
          if (tab.fab) {
            return (
              <View key="fab" style={styles.slot}>
                {fabActions.map((a, k) => (
                  <Animated.View
                    key={a.key}
                    pointerEvents={fabOpen ? 'auto' : 'none'}
                    style={[styles.fabItem, {
                      opacity: menu,
                      transform: [
                        { translateY: menu.interpolate({ inputRange: [0, 1], outputRange: [18 + k * 10, 0] }) },
                        { scale: menu.interpolate({ inputRange: [0, 1], outputRange: [0.8, 1] }) },
                      ],
                    }]}
                  >
                    <Pressable
                      onPress={() => { toggleFab(); onChange(a.key); }}
                      style={styles.fabItemInner}
                    >
                      <Text style={styles.fabLabel}>{a.label}</Text>
                      <View style={[styles.fabIcon, { backgroundColor: a.bg }]}>
                        <Ionicons name={a.icon} size={14} color={a.color} />
                      </View>
                    </Pressable>
                  </Animated.View>
                ))}
                <Pressable testID="fab" onPress={toggleFab} hitSlop={10} style={{ marginTop: -22 }}>
                  <Animated.View style={{
                    transform: [
                      { rotate: fabRot.interpolate({ inputRange: [0, 1], outputRange: ['0deg', '135deg'] }) },
                      { scale: fabRot.interpolate({ inputRange: [0, 1], outputRange: [1, 1.06] }) },
                    ],
                  }}>
                    <LinearGradient colors={G.brand} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.fab}>
                      <Ionicons name="add" size={27} color="#fff" />
                    </LinearGradient>
                  </Animated.View>
                </Pressable>
              </View>
            );
          }

          const idx = TAB_INDEX[tab.key];
          const isActive = active === idx;
          const badge = tab.key === 'cart' ? cartCount : tab.key === 'orders' ? orderBadge : 0;
          const rip = ripples[tab.key];
          const iconScale = iconScales[idx];
          return (
            <Pressable key={tab.key} testID={'tab-' + tab.key} style={styles.slot} onPress={(e) => press(slot, e)}>
              {rip ? <Ripple x={rip.x} y={rip.y} /> : null}
              <Animated.View style={{ transform: [{ scale: iconScale.interpolate({ inputRange: [0, 1], outputRange: [1, 1.16] }) }] }}>
                <Ionicons name={isActive ? tab.on : tab.icon} size={22} color={isActive ? C.red : '#9AA3B7'} />
              </Animated.View>
              <Text style={[styles.label, isActive && { color: C.red, fontWeight: '800' }]} numberOfLines={1}>
                {t(tab.label)}
              </Text>
              {badge > 0 ? (
                <View style={styles.badge}><Text style={styles.badgeTxt}>{badge > 9 ? '9+' : badge}</Text></View>
              ) : null}
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { backgroundColor: '#fff', borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: C.line },
  bar: { height: BAR_H, flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff' },
  slot: { width: SLOT_W, height: BAR_H - 8, alignItems: 'center', justifyContent: 'center' },
  pill: {
    position: 'absolute', top: 8, width: PILL_W, height: 50, borderRadius: 17,
    backgroundColor: 'rgba(232,64,42,0.10)', borderWidth: 1.5, borderColor: 'rgba(232,64,42,0.22)',
  },
  label: { fontSize: 9, marginTop: 3, color: '#9AA3B7', fontWeight: '600' },
  badge: {
    position: 'absolute', top: 8, right: SLOT_W / 2 - 18, minWidth: 16, height: 16, borderRadius: 8,
    paddingHorizontal: 4, backgroundColor: C.red, alignItems: 'center', justifyContent: 'center',
    borderWidth: 1.5, borderColor: '#fff',
  },
  badgeTxt: { color: '#fff', fontSize: 8.5, fontWeight: '800' },
  fab: {
    width: 54, height: 54, borderRadius: 19, alignItems: 'center', justifyContent: 'center',
    shadowColor: C.red, shadowOpacity: 0.45, shadowRadius: 14, shadowOffset: { width: 0, height: 8 }, elevation: 12,
  },
  fabItem: { position: 'absolute', bottom: 44, alignItems: 'center' },
  fabItemInner: {
    flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 15,
    paddingVertical: 8, paddingHorizontal: 12, ...S.shadow, elevation: 10,
  },
  fabLabel: { fontSize: 11, fontWeight: '800', color: C.ink, marginRight: 8 },
  fabIcon: { width: 26, height: 26, borderRadius: 9, alignItems: 'center', justifyContent: 'center' },
});
