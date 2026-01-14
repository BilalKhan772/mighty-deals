import 'package:flutter/foundation.dart';
import '../data/deals_admin_repo.dart';

class DealsAdminController extends ChangeNotifier {
  DealsAdminController({DealsAdminRepo? repo}) : _repo = repo ?? const DealsAdminRepo();

  final DealsAdminRepo _repo;

  bool loading = false;
  String? error;

  List<Map<String, dynamic>> deals = [];

  String cityFilter = '';
  String restaurantSearch = '';

  // ✅ when opened from restaurant manage screen
  String? restaurantIdFilter;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      deals = await _repo.fetchDeals(
        restaurantId: restaurantIdFilter,
        city: cityFilter.trim().isEmpty ? null : cityFilter,
        searchRestaurantName: restaurantSearch.trim().isEmpty ? null : restaurantSearch,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveDeal({
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
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _repo.upsertDeal(
        id: id,
        restaurantId: restaurantId,
        city: city,
        title: title,
        description: description,
        category: category,
        priceRs: priceRs,
        priceMighty: priceMighty,
        tag: tag,
      );
      await load();
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDeal(String id) async {
    await _repo.softDeleteDeal(id);
    await load();
  }
}
