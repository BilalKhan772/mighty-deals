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
    // ✅ Start with base query
    var q = SB.client
        .from(Tables.deals)
        .select()
        .eq('city', city)
        .eq('is_active', true);

    // ✅ Category filter (skip if All)
    if (category != 'All') {
      q = q.eq('category', category);
    }

    // ✅ Simple search (optional)
    // NOTE: This assumes you have a 'title' column. If your search is restaurant name,
    // we’ll do join later. For now keep minimal & working.
    if (searchRestaurantName.trim().isNotEmpty) {
      q = q.ilike('title', '%${searchRestaurantName.trim()}%');
    }

    final rows = await q
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (rows as List)
        .map((e) => DealModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
