import 'package:flutter/material.dart';

import '../../deals/ui/deals_screen.dart';
import '../../spins/ui/spins_screen.dart';
import '../../wallet/ui/wallet_screen.dart';
import '../../profile/ui/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  // ✅ NOT const (to avoid const list errors)
  final screens = [
  const DealsScreen(),
  const SpinsScreen(),
  const WalletScreen(),
  const ProfileScreen(),
];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Deals'),
          BottomNavigationBarItem(icon: Icon(Icons.casino), label: 'Spins'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
