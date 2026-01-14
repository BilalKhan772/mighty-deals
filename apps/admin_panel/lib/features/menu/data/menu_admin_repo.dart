import 'package:shared_supabase/supabase_client.dart';

class MenuAdminRepo {
  const MenuAdminRepo();

  Future<List<Map<String, dynamic>>> fetchMenuItems({String? restaurantId}) async {
    var q = SB.client
        .from('menu_items')
        .select('*, restaurant:restaurants(id,name,city)');

    if (restaurantId != null && restaurantId.trim().isNotEmpty) {
      q = q.eq('restaurant_id', restaurantId.trim());
    }

    final res = await q.order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> upsertMenuItem({
    String? id,
    required String restaurantId,
    required String name,
    int? priceRs,
  }) async {
    final payload = {
      if (id != null) 'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'price_rs': priceRs,
      'is_active': true,
    };

    if (id == null) {
      await SB.client.from('menu_items').insert(payload);
    } else {
      await SB.client.from('menu_items').update(payload).eq('id', id);
    }
  }

  Future<void> softDeleteMenuItem(String id) async {
    await SB.client.from('menu_items').update({'is_active': false}).eq('id', id);
  }
}
