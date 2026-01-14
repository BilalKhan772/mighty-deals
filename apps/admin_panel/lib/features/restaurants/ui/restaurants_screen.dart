import 'package:flutter/material.dart';
import '../logic/restaurants_controller.dart';
import 'create_restaurant_placeholder.dart';
import 'admin_restaurant_manage_screen.dart';

class RestaurantsScreen extends StatefulWidget {
  static const route = '/restaurants';
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  final c = RestaurantsController();
  final city = TextEditingController();
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    c.load();
  }

  @override
  void dispose() {
    city.dispose();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Restaurants'),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, CreateRestaurantPlaceholder.route).then((_) => c.load()),
                icon: const Icon(Icons.add),
                label: const Text('Create'),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: city,
                        decoration: const InputDecoration(
                          labelText: 'City filter',
                          prefixIcon: Icon(Icons.location_city),
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Search by name',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (_) {
                          c.search = search.text.trim();
                          c.load();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        c.cityFilter = city.text.trim();
                        c.search = search.text.trim();
                        c.load();
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (c.loading) const LinearProgressIndicator(),
                if (c.error != null) ...[
                  const SizedBox(height: 8),
                  Text(c.error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: c.load,
                    child: ListView.separated(
                      itemCount: c.restaurants.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = c.restaurants[i];
                        final id = r['id'] as String;
                        final name = (r['name'] ?? '') as String;
                        final city = (r['city'] ?? '') as String;
                        final restricted = (r['is_restricted'] ?? false) as bool;
                        final deleted = (r['is_deleted'] ?? false) as bool;
                        final photoUrl = r['photo_url'] as String?;

                        return ListTile(
                          onTap: deleted
                              ? null
                              : () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminRestaurantManageScreen(restaurant: Map<String, dynamic>.from(r)),
                                    ),
                                  );
                                  await c.load(); // refresh on return
                                },
                          leading: CircleAvatar(
                            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                            child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.restaurant) : null,
                          ),
                          title: Text(name),
                          subtitle: Text('$city • ${deleted ? "DELETED" : (restricted ? "RESTRICTED" : "ACTIVE")}'),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              Switch(
                                value: restricted,
                                onChanged: deleted
                                    ? null
                                    : (v) async {
                                        await c.toggleRestrict(id, v);
                                      },
                              ),
                              IconButton(
                                tooltip: 'Soft delete',
                                onPressed: deleted
                                    ? null
                                    : () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Delete restaurant?'),
                                            content: const Text('This will soft delete (is_deleted=true).'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok == true) await c.deleteRestaurant(id);
                                      },
                                icon: const Icon(Icons.delete),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
