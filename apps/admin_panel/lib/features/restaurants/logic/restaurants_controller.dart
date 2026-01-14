import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../data/restaurants_repo.dart';

class RestaurantsController extends ChangeNotifier {
  RestaurantsController({RestaurantsRepo? repo}) : _repo = repo ?? const RestaurantsRepo();

  final RestaurantsRepo _repo;

  bool loading = false;
  String? error;

  List<Map<String, dynamic>> restaurants = [];

  String cityFilter = '';
  String search = '';

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      restaurants = await _repo.fetchRestaurants(
        city: cityFilter.trim().isEmpty ? null : cityFilter,
        search: search.trim().isEmpty ? null : search,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createRestaurant({
    required String email,
    required String password,
    required String name,
    required String city,
    String? address,
    String? phone,
    String? whatsapp,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _repo.createRestaurantViaFunction(
        email: email,
        password: password,
        name: name,
        city: city,
        address: address,
        phone: phone,
        whatsapp: whatsapp,
      );
      await load();
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleRestrict(String id, bool restricted) async {
    await _repo.setRestricted(id, restricted);
    await load();
  }

  Future<void> deleteRestaurant(String id) async {
    await _repo.softDeleteRestaurant(id);
    await load();
  }

  Future<void> uploadPhoto({
    required String restaurantId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _repo.uploadRestaurantPhoto(
        restaurantId: restaurantId,
        bytes: bytes,
        contentType: contentType,
      );
      await load();
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      rethrow;
    }
  }
}
