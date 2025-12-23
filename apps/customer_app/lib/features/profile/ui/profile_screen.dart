import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final phoneController = TextEditingController();
  final whatsappController = TextEditingController();
  final addressController = TextEditingController();

  String selectedCity = 'Peshawar';

  @override
  void dispose() {
    phoneController.dispose();
    whatsappController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final updateState = ref.watch(profileUpdateControllerProvider);

    ref.listen(profileUpdateControllerProvider, (_, next) {
      next.whenOrNull(
        data: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated ✅')),
        ),
        error: (e, __) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myProfileProvider),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (profile) {
          // Pre-fill only once (avoid overwriting user typing)
          if (phoneController.text.isEmpty) phoneController.text = profile.phone ?? '';
          if (whatsappController.text.isEmpty) whatsappController.text = profile.whatsapp ?? '';
          if (addressController.text.isEmpty) addressController.text = profile.address ?? '';
          selectedCity = profile.city ?? selectedCity;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Unique ID'),
                  subtitle: Text(profile.uniqueCode),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: whatsappController,
                decoration: const InputDecoration(labelText: 'WhatsApp'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedCity,
                items: const ['Peshawar', 'Islamabad', 'Lahore', 'Karachi']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => selectedCity = v ?? selectedCity),
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: updateState.isLoading
                    ? null
                    : () async {
                        await ref.read(profileUpdateControllerProvider.notifier).update(
                              phone: phoneController.text,
                              whatsapp: whatsappController.text,
                              address: addressController.text,
                              city: selectedCity,
                            );
                      },
                child: updateState.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
