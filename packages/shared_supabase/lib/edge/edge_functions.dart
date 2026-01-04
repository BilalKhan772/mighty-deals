import '../supabase_client.dart';

class EdgeFunctions {
  static Future<Map<String, dynamic>> call(
    String name, {
    required Map<String, dynamic> body,
  }) async {
    final res = await SB.client.functions.invoke(name, body: body);

    if (res.status != 200) {
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error']);
      }
      throw Exception('Edge function failed (${res.status})');
    }

    final data = res.data;
    if (data is Map) return data.cast<String, dynamic>();
    return {'ok': true};
  }
}
