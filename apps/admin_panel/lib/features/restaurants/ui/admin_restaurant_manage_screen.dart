import 'dart:html' as html; // Flutter Web only
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../deals/data/deals_admin_repo.dart';
import '../../menu/data/menu_admin_repo.dart';
import '../data/restaurants_repo.dart';

class AdminRestaurantManageScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  const AdminRestaurantManageScreen({super.key, required this.restaurant});

  @override
  State<AdminRestaurantManageScreen> createState() => _AdminRestaurantManageScreenState();
}

class _AdminRestaurantManageScreenState extends State<AdminRestaurantManageScreen> {
  final restaurantsRepo = const RestaurantsRepo();
  final dealsRepo = const DealsAdminRepo();
  final menuRepo = const MenuAdminRepo();

  late Map<String, dynamic> r;
  bool loading = false;
  String? error;

  List<Map<String, dynamic>> deals = [];
  List<Map<String, dynamic>> menuItems = [];

  late final TextEditingController address;
  late final TextEditingController phone;
  late final TextEditingController whatsapp;

  @override
  void initState() {
    super.initState();
    r = Map<String, dynamic>.from(widget.restaurant);

    address = TextEditingController(text: (r['address'] ?? '').toString());
    phone = TextEditingController(text: (r['phone'] ?? '').toString());
    whatsapp = TextEditingController(text: (r['whatsapp'] ?? '').toString());

    _loadAll();
  }

  @override
  void dispose() {
    address.dispose();
    phone.dispose();
    whatsapp.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final id = r['id'] as String;

      // refresh restaurant
      r = await restaurantsRepo.fetchRestaurantById(id);

      // refresh lists
      deals = await dealsRepo.fetchDeals(restaurantId: id);
      menuItems = await menuRepo.fetchMenuItems(restaurantId: id);
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveContact() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await restaurantsRepo.updateRestaurant(
        restaurantId: r['id'] as String,
        address: address.text.trim().isEmpty ? null : address.text.trim(),
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
        whatsapp: whatsapp.text.trim().isEmpty ? null : whatsapp.text.trim(),
      );

      await _loadAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact updated ✅')),
      );
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    await input.onChange.first;
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) return;

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;

    final bytes = Uint8List.view(reader.result as ByteBuffer);
    final contentType = file.type.isNotEmpty ? file.type : 'image/jpeg';

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await restaurantsRepo.uploadRestaurantPhoto(
        restaurantId: r['id'] as String,
        bytes: bytes,
        contentType: contentType,
      );
      await _loadAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded ✅')),
      );
    } catch (e) {
      setState(() => error = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---------------- DEALS CRUD ----------------

  Future<void> _addOrEditDeal({Map<String, dynamic>? existing}) async {
    final title = TextEditingController(text: (existing?['title'] ?? '').toString());
    final desc = TextEditingController(text: (existing?['description'] ?? '').toString());
    final category = TextEditingController(text: (existing?['category'] ?? 'All').toString());
    final priceMighty = TextEditingController(text: (existing?['price_mighty'] ?? 0).toString());
    final priceRs = TextEditingController(text: (existing?['price_rs'] ?? '').toString());
    final tag = TextEditingController(text: (existing?['tag'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Deal' : 'Edit Deal'),
        content: SizedBox(
          width: 520,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 10),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceMighty,
                      decoration: const InputDecoration(labelText: 'Price Mighty'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: priceRs,
                      decoration: const InputDecoration(labelText: 'Price Rs (optional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: tag, decoration: const InputDecoration(labelText: 'Tag (optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await dealsRepo.upsertDeal(
        id: existing?['id'] as String?,
        restaurantId: r['id'] as String,
        city: (r['city'] ?? '').toString(),
        title: title.text.trim(),
        description: desc.text.trim().isEmpty ? null : desc.text.trim(),
        category: category.text.trim().isEmpty ? 'All' : category.text.trim(),
        priceRs: priceRs.text.trim().isEmpty ? null : int.tryParse(priceRs.text.trim()),
        priceMighty: int.tryParse(priceMighty.text.trim()) ?? 0,
        tag: tag.text.trim().isEmpty ? null : tag.text.trim(),
      );

      await _loadAll();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deleteDeal(String id) async {
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

    if (ok != true) return;

    setState(() => loading = true);
    try {
      await dealsRepo.softDeleteDeal(id);
      await _loadAll();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---------------- MENU CRUD ----------------

  Future<void> _addOrEditMenu({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: (existing?['name'] ?? '').toString());
    final priceRs = TextEditingController(text: (existing?['price_rs'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Menu Item' : 'Edit Menu Item'),
        content: SizedBox(
          width: 520,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Item name')),
              const SizedBox(height: 10),
              TextField(controller: priceRs, decoration: const InputDecoration(labelText: 'Price Rs (optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await menuRepo.upsertMenuItem(
        id: existing?['id'] as String?,
        restaurantId: r['id'] as String,
        name: name.text.trim(),
        priceRs: priceRs.text.trim().isEmpty ? null : int.tryParse(priceRs.text.trim()),
      );

      await _loadAll();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deleteMenu(String id) async {
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

    if (ok != true) return;

    setState(() => loading = true);
    try {
      await menuRepo.softDeleteMenuItem(id);
      await _loadAll();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final name = (r['name'] ?? '').toString();
    final city = (r['city'] ?? '').toString();
    final photoUrl = (r['photo_url'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (loading) const LinearProgressIndicator(),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 10),

            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty ? const Icon(Icons.restaurant, size: 28) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '$name • $city',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  onPressed: loading ? null : _pickAndUploadPhoto,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Upload Photo'),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Text('Contact Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 10),
            TextField(controller: whatsapp, decoration: const InputDecoration(labelText: 'WhatsApp')),
            const SizedBox(height: 10),
            TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: loading ? null : _saveContact,
                child: const Text('Save Contact'),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text('Deals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                TextButton.icon(
                  onPressed: loading ? null : () => _addOrEditDeal(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const Divider(),

            if (deals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No deals yet.'),
              ),

            ...deals.map((d) {
              final title = (d['title'] ?? '').toString();
              final mighty = (d['price_mighty'] ?? 0).toString();
              final active = (d['is_active'] ?? true) == true;

              return ListTile(
                title: Text('$title • $mighty Mighty'),
                subtitle: Text(active ? 'ACTIVE' : 'INACTIVE'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: loading ? null : () => _addOrEditDeal(existing: d),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: loading ? null : () => _deleteDeal(d['id'] as String),
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text('Menu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                TextButton.icon(
                  onPressed: loading ? null : () => _addOrEditMenu(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const Divider(),

            if (menuItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No menu items yet.'),
              ),

            ...menuItems.map((m) {
              final n = (m['name'] ?? '').toString();
              final rs = m['price_rs'];
              final active = (m['is_active'] ?? true) == true;

              return ListTile(
                title: Text('$n ${rs != null ? "• Rs $rs" : ""}'),
                subtitle: Text(active ? 'ACTIVE' : 'INACTIVE'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: loading ? null : () => _addOrEditMenu(existing: m),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: loading ? null : () => _deleteMenu(m['id'] as String),
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
