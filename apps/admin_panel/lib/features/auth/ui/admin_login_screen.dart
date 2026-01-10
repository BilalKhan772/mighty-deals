import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/admin_auth_repo.dart';
import '../logic/admin_auth_controller.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  late final AdminAuthController c;
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    c = AdminAuthController(AdminAuthRepo(Supabase.instance.client));
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AnimatedBuilder(
            animation: c,
            builder: (context, _) {
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Admin Login',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to manage notifications',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (c.error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            c.error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      FilledButton(
                        onPressed: c.loading
                            ? null
                            : () => c.login(emailCtrl.text, passCtrl.text),
                        child: c.loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Login'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
