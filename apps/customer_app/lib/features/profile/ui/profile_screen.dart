// apps/customer_app/lib/features/profile/ui/profile_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/routing/route_names.dart';
import '../../wallet/logic/wallet_controller.dart';
import '../logic/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _invalidateAll(WidgetRef ref) {
    ref.invalidate(myProfileProvider);
    ref.invalidate(myWalletProvider);
    ref.invalidate(myLedgerProvider);
  }

  Color w(double a) => Colors.white.withAlpha((a * 255).round());

  static const List<String> _cities = [
    'Abbottabad',
    'Dera Ismail Khan',
    'Faisalabad',
    'Islamabad',
    'Karachi',
    'Mardan',
    'Multan',
    'Peshawar',
    'Rawalpindi',
    'Sialkot',
    'Swabi',
    'Swat',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final updateState = ref.watch(profileUpdateControllerProvider);

    ref.listen(profileUpdateControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated ✅')),
          );
        },
        error: (e, _) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update failed: $e')),
          );
        },
      );
    });

    const double topGap = 14;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 18,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            onPressed: () => ref.invalidate(myProfileProvider),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF070B14),
              Color(0xFF040814),
            ],
          ),
        ),
        child: profileAsync.when(
          loading: () => const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SafeArea(
            child: Center(
              child: Text(
                e.toString(),
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (p) {
            final isSaving = updateState.isLoading;

            final phoneValue =
                (p.phone == null || p.phone!.isEmpty) ? '-' : p.phone!;
            final waValue =
                (p.whatsapp == null || p.whatsapp!.isEmpty) ? '-' : p.whatsapp!;
            final addressValue =
                (p.address == null || p.address!.isEmpty) ? '-' : p.address!;
            final cityValue =
                (p.city == null || p.city!.isEmpty) ? '-' : p.city!;

            return SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: topGap),

                        _ProfileField(label: 'Unique ID', value: p.uniqueCode),
                        const SizedBox(height: 12),

                        _ProfileField(label: 'Phone', value: phoneValue),
                        const SizedBox(height: 12),

                        _ProfileField(label: 'WhatsApp', value: waValue),
                        const SizedBox(height: 12),

                        _ProfileField(label: 'Address', value: addressValue),
                        const SizedBox(height: 12),

                        _ProfileField(label: 'City', value: cityValue),
                        const SizedBox(height: 18),

                        SizedBox(
                          height: 56,
                          child: _PrimaryButton(
                            text: isSaving ? 'Saving...' : 'Edit',
                            onPressed: isSaving
                                ? null
                                : () => _openEditSheet(
                                      context: context,
                                      ref: ref,
                                      initialPhone: p.phone ?? '',
                                      initialWhatsapp: p.whatsapp ?? '',
                                      initialAddress: p.address ?? '',
                                      initialCity: p.city ?? '',
                                    ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () async {
                              final shouldLogout = await _showLogoutDialog(context);
                              if (shouldLogout != true) return;

                              await Supabase.instance.client.auth.signOut();
                              _invalidateAll(ref);

                              if (!context.mounted) return;
                              context.go(RouteNames.login);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: w(0.20)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B1220),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Log out?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Log out',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openEditSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String initialPhone,
    required String initialWhatsapp,
    required String initialAddress,
    required String initialCity,
  }) {
    final phoneC = TextEditingController(text: initialPhone);
    final waC = TextEditingController(text: initialWhatsapp);
    final addrC = TextEditingController(text: initialAddress);

    String city = _cities.contains(initialCity) ? initialCity : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF060A14),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.10)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.20),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _LabeledTextField(
                        label: 'Phone',
                        controller: phoneC,
                        hint: '03xx xxxx xxx',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),

                      _LabeledTextField(
                        label: 'WhatsApp',
                        controller: waC,
                        hint: '03xx xxxx xxx',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),

                      _LabeledTextField(
                        label: 'Address',
                        controller: addrC,
                        hint: 'Street / Area',
                        keyboardType: TextInputType.streetAddress,
                      ),
                      const SizedBox(height: 10),

                      _LabeledCityDropdown(
                        label: 'City',
                        value: city.isEmpty ? null : city,
                        items: _cities,
                        onChanged: (v) => setState(() => city = v ?? ''),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final phone = phoneC.text.trim();
                            final wa = waC.text.trim();
                            final addr = addrC.text.trim();
                            final c = city.trim();

                            if (phone.isEmpty || wa.isEmpty || addr.isEmpty || c.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all fields')),
                              );
                              return;
                            }

                            await ref.read(profileUpdateControllerProvider.notifier).update(
                                  phone: phone,
                                  whatsapp: wa,
                                  address: addr,
                                  city: c,
                                );

                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return _GlassTile(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  final Widget child;
  const _GlassTile({required this.child});

  @override
  Widget build(BuildContext context) {
    const radius = 18.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(10, 18, 32, 0.45),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0.10),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const _PrimaryButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF06B6D4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

// ✅ Label outside + TextField inside (NO floating labels)
class _LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _LabeledTextField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
              filled: true,
              fillColor: const Color.fromRGBO(255, 255, 255, 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF06B6D4)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledCityDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _LabeledCityDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: value,
            dropdownColor: const Color(0xFF0B1220),
            items: items
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(color: Colors.white)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Select your city',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
              filled: true,
              fillColor: const Color.fromRGBO(255, 255, 255, 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF06B6D4)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
