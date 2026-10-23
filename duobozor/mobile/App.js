// DuoBozor — App root: ErrorBoundary + auth gate + аниматсияи экранҳо + tab bar
import React, { useState, useCallback, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, StatusBar, SafeAreaView, Animated, Easing, Pressable, Platform } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { AppProvider, useApp } from './src/store';
import { C, S } from './src/theme';
import { Toast, Loader, Btn } from './src/components/ui';
import TabBar from './src/components/TabBar';
import AuthScreen from './src/screens/AuthScreen';
import HomeScreen from './src/screens/HomeScreen';
import SearchScreen from './src/screens/SearchScreen';
import ProductScreen from './src/screens/ProductScreen';
import GroupBuyScreen from './src/screens/GroupBuyScreen';
import { CartScreen, CheckoutScreen } from './src/screens/CartScreen';
import { OrdersScreen, OrderDetailScreen } from './src/screens/OrdersScreen';
import WalletScreen from './src/screens/WalletScreen';
import ProfileScreen from './src/screens/ProfileScreen';
import SellerScreen from './src/screens/SellerScreen';
import AdminScreen from './src/screens/AdminScreen';
import NotificationsScreen from './src/screens/NotificationsScreen';

/* ── Ҳимоя аз ҳама гуна хатои экран: барнома намеафтад ── */
class ErrorBoundary extends React.Component {
  constructor(props) { super(props); this.state = { error: null }; }
  static getDerivedStateFromError(error) { return { error }; }
  componentDidCatch() { /* метавонем ба Sentry фиристем */ }
  render() {
    if (this.state.error) {
      return (
        <View style={styles.err}>
          <Text style={{ fontSize: 40 }}>🛠️</Text>
          <Text style={styles.errTitle}>Хатои ногаҳонӣ</Text>
          <Text style={styles.errBody}>{String(this.state.error.message || this.state.error).slice(0, 160)}</Text>
          <Btn title="Аз нав кӯшиш" style={{ marginTop: 18, width: 200 }} onPress={() => this.setState({ error: null })} />
        </View>
      );
    }
    return this.props.children;
  }
}

const TABS = ['home', 'search', 'cart', 'orders', 'profile'];

/** Экран бо аниматсияи вуруд (fade + slide) ва тугмаи бозгашт дар ҳолати хатогӣ */
function ScreenIn({ children, k }) {
  const a = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    a.setValue(0);
    Animated.timing(a, { toValue: 1, duration: 260, easing: Easing.out(Easing.cubic), useNativeDriver: true }).start();
  }, [k]);
  return (
    <Animated.View style={{
      flex: 1,
      opacity: a,
      transform: [{ translateX: a.interpolate({ inputRange: [0, 1], outputRange: [26, 0] }) }],
    }}>
      <ErrorBoundary key={k}>{children}</ErrorBoundary>
    </Animated.View>
  );
}

function Shell() {
  const { t, ready, state, toast, showToast, myOrders } = useApp();
  const [tab, setTab] = useState(0);
  const [stack, setStack] = useState([]);
  const [searchCat, setSearchCat] = useState(null);

  const push = useCallback((screen, params) => setStack((s) => [...s, { screen, params }]), []);
  const pop = useCallback(() => setStack((s) => s.slice(0, -1)), []);

  const go = useCallback((screen, params) => {
    if (TABS.includes(screen)) {
      setStack([]);
      setTab(TABS.indexOf(screen));
      if (screen === 'search') setSearchCat(params || null);
      return;
    }
    if (screen === 'newgroup') { setStack([]); setTab(1); showToast(t('choose_product'), 'ok'); return; }
    if (screen === 'invite') { showToast(t('group_invite_sent'), 'ok'); return; }
    push(screen, params);
  }, [push, showToast, t]);

  if (!ready) return <Loader />;

  if (!state.user) {
    return (
      <SafeAreaView style={styles.root}>
        <StatusBar barStyle="light-content" backgroundColor={C.red} />
        <ErrorBoundary>
          <AuthScreen />
        </ErrorBoundary>
        <Toast toast={toast} />
      </SafeAreaView>
    );
  }

  const top = stack[stack.length - 1];
  const orderBadge = myOrders.filter((o) => o.escrow.state === 'held').length;

  const renderTab = () => {
    switch (TABS[tab]) {
      case 'search': return <SearchScreen go={go} initialCat={searchCat} />;
      case 'cart': return <CartScreen go={go} />;
      case 'orders': return <OrdersScreen go={go} />;
      case 'profile': return <ProfileScreen go={go} />;
      default: return <HomeScreen go={go} />;
    }
  };

  const renderStack = () => {
    if (!top) return null;
    switch (top.screen) {
      case 'product': return <ProductScreen id={top.params} back={pop} go={go} />;
      case 'group': return <GroupBuyScreen id={top.params} back={pop} go={go} />;
      case 'checkout': return <CheckoutScreen back={pop} go={go} />;
      case 'order': return <OrderDetailScreen id={top.params} back={pop} />;
      case 'wallet': return <WalletScreen back={pop} />;
      case 'seller': return <SellerScreen back={pop} go={go} />;
      case 'admin': return <AdminScreen back={pop} />;
      case 'notifications': return <NotificationsScreen back={pop} />;
      default: return null;
    }
  };

  return (
    <SafeAreaView style={styles.root}>
      <StatusBar barStyle={top ? 'dark-content' : 'light-content'} backgroundColor={top ? C.bg : C.red} />
      {state.offline ? (
        <View style={styles.offline}>
          <Ionicons name="cloud-offline" size={12} color="#7A4E00" />
          <Text style={{ fontSize: 10, fontWeight: '800', color: '#7A4E00', marginLeft: 6 }}>{t('offline_banner')}</Text>
        </View>
      ) : null}

      <View style={{ flex: 1 }}>
        <ScreenIn k={top ? `${top.screen}:${top.params || ''}` : `tab:${tab}`}>
          {top ? renderStack() : renderTab()}
        </ScreenIn>
        <Toast toast={toast} />
      </View>

      {!top ? (
        <TabBar
          active={tab}
          onChange={(i) => {
            if (i === 'newgroup') { setTab(1); showToast(t('choose_product'), 'ok'); return; }
            if (i === 'invite') { showToast(t('group_invite_sent'), 'ok'); return; }
            setTab(i);
          }}
          t={t}
          cartCount={state.cart.reduce((a, b) => a + b.qty, 0)}
          orderBadge={orderBadge}
        />
      ) : null}
    </SafeAreaView>
  );
}

export default function App() {
  return (
    <AppProvider>
      <ErrorBoundary>
        <Shell />
      </ErrorBoundary>
    </AppProvider>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: C.bg },
  offline: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', backgroundColor: '#FFF4DC', paddingVertical: 5 },
  err: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: C.bg, padding: 24 },
  errTitle: { fontSize: 16, fontWeight: '800', color: C.ink, marginTop: 10 },
  errBody: { fontSize: 11, color: C.muted, textAlign: 'center', marginTop: 8, lineHeight: 16 },
});
