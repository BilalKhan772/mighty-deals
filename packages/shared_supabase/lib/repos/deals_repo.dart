import 'package:shared_models/deal_model.dart';
import '../supabase_client.dart';
import '../supabase_tables.dart';

class DealsRepoSB {
  Future<List<DealModel>> listDeals({
    required String city,
    required String category,
    required String searchRestaurantName,
    required int limit,
    required int offset,
  }) async {
    var q = SB.client
        .from(Tables.deals)
        .select('''
          id,
          restaurant_id,
          city,
          title,
          description,
          category,
          price_mighty,
          price_rs,
          tag,
          is_active,
          created_at,
          restaurant:restaurants(
            id,
            name,
            city,
            address,
            phone,
            whatsapp,
            photo_url,
            is_restricted,
            is_deleted
          )
        ''')
        .eq('city', city)
        .eq('is_active', true);

    if (category != 'All') {
      q = q.eq('category', category);
    }

    final s = searchRestaurantName.trim();
    if (s.isNotEmpty) {
      q = q.ilike('restaurants.name', '%$s%');
    }

    final rows = await q
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (rows as List)
        .map((e) => DealModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ✅ NEW: Restaurant specific deals (for RestaurantViewScreen Deals tab)
  Future<List<DealModel>> listDealsByRestaurant({
    required String restaurantId,
  }) async {
    final rows = await SB.client
        .from(Tables.deals)
        .select('''
          id,
          restaurant_id,
          city,
          title,
          description,
          category,
          price_mighty,
          price_rs,
          tag,
          is_active,
          created_at,
          restaurant:restaurants(
            id,
            name,
            city,
            address,
            phone,
            whatsapp,
            photo_url,
            is_restricted,
            is_deleted
          )
        ''')
        .eq('restaurant_id', restaurantId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => DealModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
