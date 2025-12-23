import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_supabase/shared_supabase.dart';

final restaurantsRepoProvider = Provider<RestaurantsRepo>((ref) => RestaurantsRepo());

final restaurantProvider = FutureProvider.family((ref, String id) async {
  return ref.read(restaurantsRepoProvider).getRestaurant(id);
});

final restaurantMenuProvider = FutureProvider.family((ref, String id) async {
  return ref.read(restaurantsRepoProvider).listMenuItems(id);
});

class RestaurantViewScreen extends ConsumerWidget {
  final String restaurantId;
  const RestaurantViewScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(restaurantProvider(restaurantId));
    final menu = ref.watch(restaurantMenuProvider(restaurantId));

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant')),
      body: r.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (rest) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rest.name, style: Theme.of(context).textTheme.headlineSmall),
              Text('${rest.city} • ${rest.address ?? ''}'),
              const SizedBox(height: 8),
              Text('Phone: ${rest.phone ?? '-'}'),
              Text('WhatsApp: ${rest.whatsapp ?? '-'}'),
              const SizedBox(height: 16),
              const Text('Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: menu.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (items) => ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(items[i]['name']?.toString() ?? ''),
                      subtitle: Text('Rs ${items[i]['price_rs'] ?? '-'}'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
