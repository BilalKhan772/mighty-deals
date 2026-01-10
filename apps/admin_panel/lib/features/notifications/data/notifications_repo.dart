import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsRepo {
  final SupabaseClient _sb;

  NotificationsRepo(this._sb);

  Future<Map<String, dynamic>> sendSpinPublished(String spinId) async {
    final res = await _sb.functions.invoke(
      'notify_spin_published',
      body: {'spin_id': spinId},
    );

    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return {'ok': true, 'data': data};
  }

  Future<Map<String, dynamic>> sendSpinWinner(String spinId) async {
    final res = await _sb.functions.invoke(
      'notify_spin_winner',
      body: {'spin_id': spinId},
    );

    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return {'ok': true, 'data': data};
  }
}
