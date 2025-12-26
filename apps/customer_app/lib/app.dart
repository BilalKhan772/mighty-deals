// apps/customer_app/lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

// Providers to invalidate on auth change
import 'features/deals/logic/deals_controller.dart';
import 'features/profile/logic/profile_controller.dart';
import 'features/wallet/logic/wallet_controller.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    // 🔥 Listen to Supabase auth changes (login/logout/user update)
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.tokenRefreshed) {
        // ✅ Reset / refresh all user-dependent providers
        ref.invalidate(currentUserCityProvider);
        ref.invalidate(dealsControllerProvider);
        ref.invalidate(dealsQueryProvider);

        ref.invalidate(myProfileProvider);
        ref.invalidate(myWalletProvider);
        ref.invalidate(myLedgerProvider);
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mighty Deals',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
