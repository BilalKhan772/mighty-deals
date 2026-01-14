import 'package:flutter/material.dart';
import '../logic/deals_admin_controller.dart';
import '../../restaurants/data/restaurants_repo.dart';

class DealsAdminScreen extends StatefulWidget {
  static const route = '/admin-deals';

  final String? restaurantId; // ✅ when opening from restaurant manage
  final bool hideFilters;

  const DealsAdminScreen({
    super.key,
    this.restaurantId,
    this.hideFilters = false,
  });

  @override
  State<DealsAdminScreen> createState() => _DealsAdminScreenState();
}

class _DealsAdminScreenState extends State<DealsAdminScreen> {
  final c = DealsAdminController();
  final restaurantsRepo = const RestaurantsRepo();

  final city = TextEditingController();
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    c.restaurantIdFilter = widget.restaurantId;
    c.load();
  }

  @override
  void dispose() {
    city.dispose();
    search.dispose();
    super.dispose();
  }

  Future<void> _openCreateDialog() async {
    final restaurants = await restaurantsRepo.fetchRestaurants();

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => _DealFormDialog(
        restaurants: restaurants,
        fixedRestaurantId: widget.restaurantId,
        onSave: (payload) => c.saveDeal(
          restaurantId: payload.restaurantId,
          city: payload.city,
          title: payload.title,
          description: payload.description,
          category: payload.category,
          priceRs: payload.priceRs,
          priceMighty: payload.priceMighty,
          tag: payload.tag,
        ),
      ),
    );
  }

  Future<void> _openEditDialog(Map<String, dynamic> deal) async {
    final restaurants = await restaurantsRepo.fetchRestaurants();

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => _DealFormDialog(
        restaurants: restaurants,
        fixedRestaurantId: widget.restaurantId,
        existing: deal,
        onSave: (payload) => c.saveDeal(
          id: deal['id'] as String,
          restaurantId: payload.restaurantId,
          city: payload.city,
          title: payload.title,
          description: payload.description,
          category: payload.category,
          priceRs: payload.priceRs,
          priceMighty: payload.priceMighty,
          tag: payload.tag,
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
          if (!widget.hideFilters) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: city,
                    decoration: const InputDecoration(labelText: 'City filter'),
                    onSubmitted: (_) {
                      c.cityFilter = city.text.trim();
                      c.load();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: search,
                    decoration: const InputDecoration(labelText: 'Search restaurant'),
                    onSubmitted: (_) {
                      c.restaurantSearch = search.text.trim();
                      c.load();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    c.cityFilter = city.text.trim();
                    c.restaurantSearch = search.text.trim();
                    c.load();
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Text(
                widget.restaurantId != null ? 'Deals (This Restaurant)' : 'Deals (Admin)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Deal'),
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
              itemCount: c.deals.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = c.deals[i];
                final id = d['id'] as String;
                final title = (d['title'] ?? '') as String;
                final city = (d['city'] ?? '') as String;
                final mighty = (d['price_mighty'] ?? 0) as int;
                final active = (d['is_active'] ?? true) as bool;

                final rest = d['restaurant'] as Map<String, dynamic>?;
                final restName = (rest?['name'] ?? '') as String;

                return ListTile(
                  title: Text('$title  •  $mighty Mighty'),
                  subtitle: Text('${widget.restaurantId != null ? "" : "$restName • "}$city • ${active ? "ACTIVE" : "INACTIVE"}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openEditDialog(d),
                      ),
                      IconButton(
                        tooltip: 'Soft delete',
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete deal?'),
                              content: const Text('This will set is_active=false.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok == true) await c.deleteDeal(id);
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

    // If used standalone route, show Scaffold with appbar. If embedded, just return body.
    if (widget.hideFilters) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Deals (Admin)')),
      body: body,
    );
  }
}

class _DealPayload {
  final String restaurantId;
  final String city;
  final String title;
  final String? description;
  final String category;
  final int? priceRs;
  final int priceMighty;
  final String? tag;

  _DealPayload({
    required this.restaurantId,
    required this.city,
    required this.title,
    required this.description,
    required this.category,
    required this.priceRs,
    required this.priceMighty,
    required this.tag,
  });
}

class _DealFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> restaurants;
  final String? fixedRestaurantId;
  final Map<String, dynamic>? existing;
  final Future<void> Function(_DealPayload payload) onSave;

  const _DealFormDialog({
    required this.restaurants,
    required this.onSave,
    this.fixedRestaurantId,
    this.existing,
  });

  @override
  State<_DealFormDialog> createState() => _DealFormDialogState();
}

class _DealFormDialogState extends State<_DealFormDialog> {
  final _formKey = GlobalKey<FormState>();

  String? restaurantId;
  final city = TextEditingController();
  final title = TextEditingController();
  final desc = TextEditingController();
  final category = TextEditingController(text: 'All');
  final priceRs = TextEditingController();
  final priceMighty = TextEditingController(text: '0');
  final tag = TextEditingController();

  @override
  void initState() {
    super.initState();

    // fixed restaurant (manage screen)
    restaurantId = widget.fixedRestaurantId ?? widget.existing?['restaurant_id'] as String?;

    final ex = widget.existing;
    if (ex != null) {
      city.text = (ex['city'] ?? '').toString();
      title.text = (ex['title'] ?? '').toString();
      desc.text = (ex['description'] ?? '').toString();
      category.text = (ex['category'] ?? 'All').toString();
      priceMighty.text = (ex['price_mighty'] ?? 0).toString();
      priceRs.text = (ex['price_rs'] ?? '').toString();
      tag.text = (ex['tag'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    city.dispose();
    title.dispose();
    desc.dispose();
    category.dispose();
    priceRs.dispose();
    priceMighty.dispose();
    tag.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (restaurantId == null) return;

    final mighty = int.tryParse(priceMighty.text.trim()) ?? 0;
    final rs = priceRs.text.trim().isEmpty ? null : int.tryParse(priceRs.text.trim());

    await widget.onSave(_DealPayload(
      restaurantId: restaurantId!,
      city: city.text.trim(),
      title: title.text.trim(),
      description: desc.text.trim().isEmpty ? null : desc.text.trim(),
      category: category.text.trim().isEmpty ? 'All' : category.text.trim(),
      priceRs: rs,
      priceMighty: mighty,
      tag: tag.text.trim().isEmpty ? null : tag.text.trim(),
    ));

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Deal' : 'Add Deal'),
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
                controller: city,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(controller: desc, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              TextFormField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceMighty,
                      decoration: const InputDecoration(labelText: 'Price Mighty'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: priceRs,
                      decoration: const InputDecoration(labelText: 'Price Rs (optional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(controller: tag, decoration: const InputDecoration(labelText: 'Tag (optional)')),
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
