import 'package:flutter/material.dart';
import '../logic/restaurants_controller.dart';

class CreateRestaurantPlaceholder extends StatefulWidget {
  static const route = '/create-restaurant';
  const CreateRestaurantPlaceholder({super.key});

  @override
  State<CreateRestaurantPlaceholder> createState() => _CreateRestaurantPlaceholderState();
}

class _CreateRestaurantPlaceholderState extends State<CreateRestaurantPlaceholder> {
  final c = RestaurantsController();

  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final pass = TextEditingController();
  final name = TextEditingController();
  final city = TextEditingController();
  final address = TextEditingController();
  final phone = TextEditingController();
  final whatsapp = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    name.dispose();
    city.dispose();
    address.dispose();
    phone.dispose();
    whatsapp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await c.createRestaurant(
        email: email.text.trim(),
        password: pass.text,
        name: name.text.trim(),
        city: city.text.trim(),
        address: address.text.trim().isEmpty ? null : address.text.trim(),
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
        whatsapp: whatsapp.text.trim().isEmpty ? null : whatsapp.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant account created ✅')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        return Scaffold(
          appBar: AppBar(title: const Text('Create Restaurant')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(labelText: 'Restaurant Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: city,
                        decoration: const InputDecoration(labelText: 'City'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: address,
                        decoration: const InputDecoration(labelText: 'Address (optional)'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: phone,
                              decoration: const InputDecoration(labelText: 'Phone (optional)'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: whatsapp,
                              decoration: const InputDecoration(labelText: 'WhatsApp (optional)'),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      TextFormField(
                        controller: email,
                        decoration: const InputDecoration(labelText: 'Login Email'),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: pass,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: c.loading ? null : _submit,
                        child: c.loading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Create'),
                      ),
                      if (c.error != null) ...[
                        const SizedBox(height: 12),
                        Text(c.error!, style: const TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
