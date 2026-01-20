// apps/customer_app/lib/app.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/push_service.dart';

// ✅ ADD: network status
import 'core/network/network_status.dart';

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

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      // ✅ Always refresh user-dependent providers on auth changes
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.tokenRefreshed) {
        ref.invalidate(currentUserCityProvider);
        ref.invalidate(dealsControllerProvider);
        ref.invalidate(dealsQueryProvider);

        ref.invalidate(myProfileProvider);
        ref.invalidate(myWalletProvider);
        ref.invalidate(myLedgerProvider);
      }

      // ✅ After sign-in: wait a bit, then read city, then upsert token
      if (event == AuthChangeEvent.signedIn) {
        Future.microtask(() async {
          // Give providers/profile some time
          await Future.delayed(const Duration(seconds: 1));

          // ✅ If widget disposed meanwhile, stop safely
          if (!mounted) return;

          // Try up to 3 times to get city
          String? city;
          for (int i = 0; i < 3; i++) {
            final asyncCity = ref.read(currentUserCityProvider);
            city = asyncCity.maybeWhen(
              data: (v) => v,
              orElse: () => null,
            );

            if (city != null && city.isNotEmpty) break;
            await Future.delayed(const Duration(milliseconds: 600));

            if (!mounted) return;
          }

          print("🏙️ City resolved after sign-in: $city");

          if (city != null && city.isNotEmpty) {
            // ✅ CHANGE #1: Skip token upsert when offline (prevents Supabase errors)
            if (!NetworkStatus.I.hasInternet) {
              print("⚠️ Offline: token upsert skipped.");
              return;
            }

            // ✅ CHANGE #2: Wrap in try/catch so no crash even if network drops
            try {
              await PushService.instance.upsertToken(city: city);
            } catch (e) {
              print("⚠️ Token upsert failed (ignored): $e");
            }
          } else {
            print("⚠️ City is still null/empty, token not saved yet.");
          }
        });
      }

      // ✅ DO NOT delete tokens here on signedOut
      // Because after signOut, auth may be gone and RLS won't allow delete.
      // Token delete should happen BEFORE signOut (we do it in ProfileScreen logout button).
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
