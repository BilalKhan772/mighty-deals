import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_supabase/supabase_client.dart';

class RestaurantsRepo {
  const RestaurantsRepo();

  Future<List<Map<String, dynamic>>> fetchRestaurants({
    String? city,
    String? search,
  }) async {
    var q = SB.client.from('restaurants').select('*');

    if (city != null && city.trim().isNotEmpty) {
      q = q.eq('city', city.trim());
    }

    if (search != null && search.trim().isNotEmpty) {
      q = q.ilike('name', '%${search.trim()}%');
    }

    final res = await q.order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchRestaurantById(String restaurantId) async {
    final res = await SB.client
        .from('restaurants')
        .select('*')
        .eq('id', restaurantId)
        .maybeSingle();

    if (res == null) {
      throw Exception('Restaurant not found');
    }

    return (res as Map).cast<String, dynamic>();
  }

  Future<void> updateRestaurant({
    required String restaurantId,
    String? address,
    String? phone,
    String? whatsapp,
  }) async {
    final payload = <String, dynamic>{
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
    };

    await SB.client.from('restaurants').update(payload).eq('id', restaurantId);
  }

  Future<Map<String, dynamic>> createRestaurantViaFunction({
    required String email,
    required String password,
    required String name,
    required String city,
    String? address,
    String? phone,
    String? whatsapp,
  }) async {
    final fnRes = await SB.client.functions.invoke(
      'admin_create_restaurant',
      body: {
        'email': email,
        'password': password,
        'name': name,
        'city': city,
        'address': address,
        'phone': phone,
        'whatsapp': whatsapp,
      },
    );

    if (fnRes.status != 200) {
      throw Exception('Create failed: ${fnRes.data}');
    }

    final data = (fnRes.data as Map).cast<String, dynamic>();
    return (data['restaurant'] as Map).cast<String, dynamic>();
  }

  Future<void> setRestricted(String restaurantId, bool restricted) async {
    await SB.client
        .from('restaurants')
        .update({'is_restricted': restricted})
        .eq('id', restaurantId);
  }

  Future<void> softDeleteRestaurant(String restaurantId) async {
    await SB.client
        .from('restaurants')
        .update({'is_deleted': true})
        .eq('id', restaurantId);
  }

  Future<String> uploadRestaurantPhoto({
    required String restaurantId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    // must be logged in (storage uses auth uid)
    final user = SB.client.auth.currentUser;
    if (user == null) {
      throw Exception('Not logged in (no auth session).');
    }

    final path = '$restaurantId/profile.jpg';

    try {
      await SB.client.storage.from('restaurants').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
              cacheControl: '3600',
            ),
          );
    } catch (e) {
      // clearer message: MOSTLY policy issue
      throw Exception(
        'Storage upload failed: $e\n\n'
        'If you see "invalid input syntax for type uuid: \\"Test Restaurant\\"", '
        'then you still have a bad RLS policy calling storage.can_insert_object(...) '
        '— remove that policy and add admin insert policy.',
      );
    }

    final publicUrl = SB.client.storage.from('restaurants').getPublicUrl(path);

    await SB.client
        .from('restaurants')
        .update({'photo_url': publicUrl})
        .eq('id', restaurantId);

    return publicUrl;
  }
}
