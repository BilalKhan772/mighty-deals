import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/notifications_repo.dart';
import '../logic/notifications_controller.dart';

class NotificationsScreen extends StatefulWidget {
  static const route = '/notifications';

  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsController controller;
  final spinIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final repo = NotificationsRepo(Supabase.instance.client);
    controller = NotificationsController(repo);
  }

  @override
  void dispose() {
    spinIdCtrl.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    // RootGate will redirect to login automatically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send Spin Notifications',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Paste Spin ID and send Publish / Winner notification.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),

                        const Text('Spin ID'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: spinIdCtrl,
                          decoration: const InputDecoration(
                            hintText: 'ec59efea-ad49-4ae3-b8c8-d7db81c0189d',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: controller.loading
                                  ? null
                                  : () => controller.sendPublished(spinIdCtrl.text),
                              icon: const Icon(Icons.campaign),
                              label: const Text('Send Published'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: controller.loading
                                  ? null
                                  : () => controller.sendWinner(spinIdCtrl.text),
                              icon: const Icon(Icons.emoji_events),
                              label: const Text('Send Winner'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        if (controller.loading) const LinearProgressIndicator(),
                        const SizedBox(height: 16),

                        const Text('Response'),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                controller.message.isEmpty ? '—' : controller.message,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
