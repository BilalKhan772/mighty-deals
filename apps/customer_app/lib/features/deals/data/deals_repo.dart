import 'package:shared_supabase/shared_supabase.dart';
import 'package:shared_models/deal_model.dart';

class DealsRepo {
  final _sb = DealsRepoSB();

  Future<List<DealModel>> listDeals({
    required String city,
    required String category,
    required String searchRestaurantName,
    required int limit,
    required int offset,
  }) {
    return _sb.listDeals(
      city: city,
      category: category,
      searchRestaurantName: searchRestaurantName,
      limit: limit,
      offset: offset,
    );
  }

  // ✅ NEW
  Future<List<DealModel>> listDealsByRestaurant({
    required String restaurantId,
  }) {
    return _sb.listDealsByRestaurant(restaurantId: restaurantId);
  }
}
