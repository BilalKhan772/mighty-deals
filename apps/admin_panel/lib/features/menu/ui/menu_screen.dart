import 'package:flutter/material.dart';
import '../logic/menu_admin_controller.dart';
import '../../restaurants/data/restaurants_repo.dart';

class MenuAdminScreen extends StatefulWidget {
  static const route = '/admin-menu';

  final String? restaurantId;
  final bool hideFilters;

  const MenuAdminScreen({
    super.key,
    this.restaurantId,
    this.hideFilters = false,
  });

  @override
  State<MenuAdminScreen> createState() => _MenuAdminScreenState();
}

class _MenuAdminScreenState extends State<MenuAdminScreen> {
  final c = MenuAdminController();
  final restaurantsRepo = const RestaurantsRepo();

  @override
  void initState() {
    super.initState();
    c.restaurantIdFilter = widget.restaurantId;
    c.load();
  }

  Future<void> _openCreateDialog() async {
    final restaurants = await restaurantsRepo.fetchRestaurants();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => _MenuFormDialog(
        restaurants: restaurants,
        fixedRestaurantId: widget.restaurantId,
        onSave: (payload) => c.saveItem(
          restaurantId: payload.restaurantId,
          name: payload.name,
          priceRs: payload.priceRs,
        ),
      ),
    );
  }

  Future<void> _openEditDialog(Map<String, dynamic> item) async {
    final restaurants = await restaurantsRepo.fetchRestaurants();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => _MenuFormDialog(
        restaurants: restaurants,
        fixedRestaurantId: widget.restaurantId,
        existing: item,
        onSave: (payload) => c.saveItem(
          id: item['id'] as String,
          restaurantId: payload.restaurantId,
          name: payload.name,
          priceRs: payload.priceRs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: widget.hideFilters ? EdgeInsets.zero : const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                widget.restaurantId != null ? 'Menu (This Restaurant)' : 'Menu Items (Admin)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ],
          ),
          if (c.loading) const LinearProgressIndicator(),
          if (c.error != null) ...[
            const SizedBox(height: 8),
            Text(c.error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: c.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final m = c.items[i];
                final id = m['id'] as String;
                final name = (m['name'] ?? '') as String;
                final rs = m['price_rs'] as int?;
                final active = (m['is_active'] ?? true) as bool;

                final rest = m['restaurant'] as Map<String, dynamic>?;
                final restName = (rest?['name'] ?? '') as String;

                return ListTile(
                  title: Text('$name ${rs != null ? "• Rs $rs" : ""}'),
                  subtitle: Text('${widget.restaurantId != null ? "" : "$restName • "}${active ? "ACTIVE" : "INACTIVE"}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openEditDialog(m),
                      ),
                      IconButton(
                        tooltip: 'Soft delete',
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete item?'),
                              content: const Text('This will set is_active=false.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok == true) await c.deleteItem(id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.hideFilters) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Menu Items (Admin)')),
      body: body,
    );
  }
}

class _MenuPayload {
  final String restaurantId;
  final String name;
  final int? priceRs;

  _MenuPayload({required this.restaurantId, required this.name, required this.priceRs});
}

class _MenuFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> restaurants;
  final String? fixedRestaurantId;
  final Map<String, dynamic>? existing;
  final Future<void> Function(_MenuPayload payload) onSave;

  const _MenuFormDialog({
    required this.restaurants,
    required this.onSave,
    this.fixedRestaurantId,
    this.existing,
  });

  @override
  State<_MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends State<_MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();

  String? restaurantId;
  final name = TextEditingController();
  final priceRs = TextEditingController();

  @override
  void initState() {
    super.initState();
    restaurantId = widget.fixedRestaurantId ?? widget.existing?['restaurant_id'] as String?;

    final ex = widget.existing;
    if (ex != null) {
      name.text = (ex['name'] ?? '').toString();
      priceRs.text = (ex['price_rs'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    name.dispose();
    priceRs.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (restaurantId == null) return;

    final rs = priceRs.text.trim().isEmpty ? null : int.tryParse(priceRs.text.trim());

    await widget.onSave(_MenuPayload(
      restaurantId: restaurantId!,
      name: name.text.trim(),
      priceRs: rs,
    ));

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Menu Item' : 'Add Menu Item'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              DropdownButtonFormField<String>(
                value: restaurantId,
                items: widget.restaurants
                    .map((r) => DropdownMenuItem(
                          value: r['id'] as String,
                          child: Text('${r['name']} (${r['city']})'),
                        ))
                    .toList(),
                onChanged: widget.fixedRestaurantId != null ? null : (v) => setState(() => restaurantId = v),
                decoration: const InputDecoration(labelText: 'Restaurant'),
                validator: (v) => (v == null || v.isEmpty) ? 'Select restaurant' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Item name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: priceRs,
                decoration: const InputDecoration(labelText: 'Price Rs (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
