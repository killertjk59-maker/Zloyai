// DuoBozor — App root: auth gate + tab bar (morph/ripple/FAB) + stack
import React, { useState, useCallback } from 'react';
import { View, StyleSheet, StatusBar, SafeAreaView, Platform, Text } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { AppProvider, useApp } from './src/store';
import { C } from './src/theme';
import { Toast, Loader } from './src/components/ui';
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

const TABS = ['home', 'search', 'cart', 'orders', 'profile'];

function Shell() {
  const { t, ready, state, toast, showToast, myOrders, myGroupBuys } = useApp();
  const [tab, setTab] = useState(0);
  const [stack, setStack] = useState([]);

  const push = useCallback((screen, params) => setStack((s) => [...s, { screen, params }]), []);
  const pop = useCallback(() => setStack((s) => s.slice(0, -1)), []);

  const go = useCallback((screen, params) => {
    if (TABS.includes(screen)) {
      setStack([]);
      setTab(TABS.indexOf(screen));
      return;
    }
    if (screen === 'group' || screen === 'invite') {
      showToast(t('group_invite_sent'));
      return;
    }
    if (screen === 'wallet') { push('wallet'); return; }
    push(screen, params);
  }, [push, showToast, t]);

  if (!ready) return <Loader />;

  if (!state.user) {
    return (
      <SafeAreaView style={styles.root}>
        <StatusBar barStyle="light-content" backgroundColor={C.red} />
        <AuthScreen />
        <Toast toast={toast} />
      </SafeAreaView>
    );
  }

  const top = stack[stack.length - 1];
  const orderBadge = myOrders.filter((o) => o.escrow.state === 'held').length;

  const renderTab = () => {
    switch (TABS[tab]) {
      case 'search': return <SearchScreen go={go} />;
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
      case 'wallet': return <WalletScreen />;
      case 'seller': return <SellerScreen back={pop} go={go} />;
      case 'admin': return <AdminScreen back={pop} />;
      default: return null;
    }
  };

  return (
    <SafeAreaView style={styles.root}>
      <StatusBar barStyle={top ? 'dark-content' : 'light-content'} backgroundColor={top ? C.bg : C.red} />
      {state.offline ? (
        <View style={styles.offline}>
          <Ionicons name="cloud-offline" size={12} color="#7A4E00" />
          <Text style={{ fontSize: 10, fontWeight: '700', color: '#7A4E00', marginLeft: 6 }}>
            {t('offline_banner')}
          </Text>
        </View>
      ) : null}

      <View style={{ flex: 1 }}>
        {top ? renderStack() : renderTab()}
        <Toast toast={toast} />
      </View>

      {!top ? (
        <TabBar
          active={tab}
          onChange={(i) => {
            if (i === 'group') { go('search'); showToast('Молро интихоб кун → «Гурӯҳ соз»'); return; }
            if (i === 'invite') { showToast(t('group_invite_sent')); return; }
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
      <Shell />
    </AppProvider>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: C.bg },
  offline: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    backgroundColor: '#FFF4DC', paddingVertical: 5,
  },
});
