import 'package:shared_supabase/supabase_client.dart';

class DealsAdminRepo {
  const DealsAdminRepo();

  Future<List<Map<String, dynamic>>> fetchDeals({
    String? restaurantId,
    String? city,
    String? searchRestaurantName,
  }) async {
    var q = SB.client
        .from('deals')
        .select('*, restaurant:restaurants(id,name,city,is_restricted,is_deleted)');

    if (restaurantId != null && restaurantId.trim().isNotEmpty) {
      q = q.eq('restaurant_id', restaurantId.trim());
    }

    if (city != null && city.trim().isNotEmpty) {
      q = q.eq('city', city.trim());
    }

    final res = await q.order('created_at', ascending: false);
    final list = (res as List).cast<Map<String, dynamic>>();

    if (searchRestaurantName != null && searchRestaurantName.trim().isNotEmpty) {
      final s = searchRestaurantName.trim().toLowerCase();
      return list.where((row) {
        final r = row['restaurant'] as Map<String, dynamic>?;
        final rn = (r?['name'] ?? '').toString().toLowerCase();
        return rn.contains(s);
      }).toList();
    }

    return list;
  }

  Future<void> upsertDeal({
    String? id,
    required String restaurantId,
    required String city,
    required String title,
    String? description,
    required String category,
    int? priceRs,
    required int priceMighty,
    String? tag,
  }) async {
    final payload = {
      if (id != null) 'id': id,
      'restaurant_id': restaurantId,
      'city': city,
      'title': title,
      'description': description,
      'category': category,
      'price_rs': priceRs,
      'price_mighty': priceMighty,
      'tag': tag,
      'is_active': true,
    };

    if (id == null) {
      await SB.client.from('deals').insert(payload);
    } else {
      await SB.client.from('deals').update(payload).eq('id', id);
    }
  }

  Future<void> softDeleteDeal(String id) async {
    await SB.client.from('deals').update({'is_active': false}).eq('id', id);
  }
}
