import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/routing/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await precacheImage(const AssetImage('assets/splash/splash.png'), context);

      // thora sa hold
      await Future.delayed(const Duration(milliseconds: 600));

      final session = Supabase.instance.client.auth.currentSession;
      if (!mounted) return;

      context.go(session == null ? RouteNames.login : RouteNames.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splash/splash.png',
          fit: BoxFit.cover, // ✅ full screen cover
          alignment: Alignment.center, // change if you want top focus
        ),
      ),
    );
  }
}
