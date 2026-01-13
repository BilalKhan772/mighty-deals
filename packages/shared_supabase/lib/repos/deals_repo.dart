import 'package:shared_models/deal_model.dart';
import '../supabase_client.dart';
import '../supabase_tables.dart';

class DealsRepoSB {
  // ✅ Daily seed: changes every 24h (UTC day)
  String _dailySeed() {
    final now = DateTime.now().toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}'; // YYYYMMDD
  }

  // =======================================================
  // ✅ Daily shuffled listDeals (city + category + search + paging)
  // =======================================================
  Future<List<DealModel>> listDeals({
    required String city,
    required String category,
    required String searchRestaurantName,
    required int limit,
    required int offset,
  }) async {
    final seed = _dailySeed();

    try {
      final rows = await SB.client.rpc(
        'list_deals_shuffled',
        params: {
          'p_city': city,
          'p_category': category,
          'p_search': searchRestaurantName.trim(),
          'p_limit': limit,
          'p_offset': offset,
          'p_seed': seed,
        },
      );

      // rows is List<dynamic> (jsonb) -> Map<String,dynamic>
      final list = (rows as List)
          .map((e) => DealModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      return list;
    } catch (_) {
      // ✅ Fallback (old behavior): created_at desc
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

      final rows2 = await q
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (rows2 as List)
          .map((e) => DealModel.fromMap(e as Map<String, dynamic>))
          .toList();
    }
  }

  // =======================================================
  // ✅ Daily shuffled listDealsByRestaurant (paging-friendly)
  // =======================================================
  Future<List<DealModel>> listDealsByRestaurant({
    required String restaurantId,
  }) async {
    final seed = _dailySeed();

    // NOTE: existing signature has no limit/offset.
    // We keep it as-it-is, but still shuffle deterministically.
    // If you want paging here too, tell me, I’ll update signature.
    const int limit = 5000; // big enough fallback
    const int offset = 0;

    try {
      final rows = await SB.client.rpc(
        'list_deals_by_restaurant_shuffled',
        params: {
          'p_restaurant_id': restaurantId,
          'p_limit': limit,
          'p_offset': offset,
          'p_seed': seed,
        },
      );

      final list = (rows as List)
          .map((e) => DealModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      return list;
    } catch (_) {
      // ✅ Fallback (old behavior)
      final rows2 = await SB.client
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

      return (rows2 as List)
          .map((e) => DealModel.fromMap(e as Map<String, dynamic>))
          .toList();
    }
  }
}
