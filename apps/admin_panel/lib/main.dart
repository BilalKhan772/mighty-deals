import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/routing/app_router.dart';
import 'features/auth/ui/admin_login_screen.dart';
import 'features/home/ui/admin_home_screen.dart';

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

      // ✅ VERY IMPORTANT: use one router for ALL named routes
      onGenerateRoute: AppRouter.onGenerateRoute,

      // Root gate stays as home (login/home)
      home: const RootGate(),
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
