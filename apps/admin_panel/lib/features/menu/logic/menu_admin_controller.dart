import 'package:flutter/foundation.dart';
import '../data/menu_admin_repo.dart';

class MenuAdminController extends ChangeNotifier {
  MenuAdminController({MenuAdminRepo? repo}) : _repo = repo ?? const MenuAdminRepo();

  final MenuAdminRepo _repo;

  bool loading = false;
  String? error;

  List<Map<String, dynamic>> items = [];

  // ✅ when opened from restaurant manage screen
  String? restaurantIdFilter;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await _repo.fetchMenuItems(
        restaurantId: restaurantIdFilter,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveItem({
    String? id,
    required String restaurantId,
    required String name,
    int? priceRs,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _repo.upsertMenuItem(
        id: id,
        restaurantId: restaurantId,
        name: name,
        priceRs: priceRs,
      );
      await load();
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    await _repo.softDeleteMenuItem(id);
    await load();
  }
}
