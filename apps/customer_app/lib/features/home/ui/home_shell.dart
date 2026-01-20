import 'dart:async';
import 'package:flutter/material.dart';

import '../../deals/ui/deals_screen.dart';
import '../../spins/ui/spins_screen.dart';
import '../../wallet/ui/wallet_screen.dart';
import '../../profile/ui/profile_screen.dart';

// ✅ ADD
import '../../../core/network/network_status.dart';
import '../../../core/widgets/no_internet_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  late final StreamSubscription<bool> _netSub;
  bool _offline = false;

  final screens = const [
    DealsScreen(),
    SpinsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _offline = !NetworkStatus.I.hasInternet;
    _netSub = NetworkStatus.I.onChanged.listen((ok) {
      if (!mounted) return;
      setState(() => _offline = !ok);
    });
  }

  @override
  void dispose() {
    _netSub.cancel();
    super.dispose();
  }

  bool _needsInternet(int i) {
    // Wallet + Profile must be online (Supabase fetch)
    // Deals/Spins: tum baad me cache add kar sakte ho, abhi online better.
    return i == 2 || i == 3;
  }

  @override
  Widget build(BuildContext context) {
    final block = _offline && _needsInternet(index);

    return Scaffold(
      body: block
          ? NoInternetView(
              onRetry: () => setState(() => _offline = !NetworkStatus.I.hasInternet),
            )
          : screens[index],

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black12,
                offset: Offset(0, -2),
              )
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => setState(() => index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF06B6D4),
            unselectedItemColor: Colors.black54,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.local_offer_outlined),
                activeIcon: Icon(Icons.local_offer),
                label: 'Deals',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.casino_outlined),
                activeIcon: Icon(Icons.casino),
                label: 'Spins',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
