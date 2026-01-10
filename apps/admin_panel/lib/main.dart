import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'features/auth/ui/admin_login_screen.dart';
import 'features/home/ui/admin_home_screen.dart';
import 'features/notifications/ui/notifications_screen.dart';
import 'features/restaurants/ui/create_restaurant_placeholder.dart';
import 'features/orders/ui/orders_placeholder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mighty Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const RootGate(),
      routes: {
        NotificationsScreen.route: (_) => const NotificationsScreen(),
        CreateRestaurantPlaceholder.route: (_) => const CreateRestaurantPlaceholder(),
        OrdersPlaceholder.route: (_) => const OrdersPlaceholder(),
      },
    );
  }
}

/// Logged out -> Login
/// Logged in  -> AdminHome (menu)
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: sb.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = sb.auth.currentSession;
        if (session == null) return const AdminLoginScreen();
        return const AdminHomeScreen();
      },
    );
  }
}
