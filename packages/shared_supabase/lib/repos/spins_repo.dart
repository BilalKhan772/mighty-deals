import 'package:shared_models/spin_entry_model.dart';
import 'package:shared_models/spin_model.dart';
import '../mappers/spin_mapper.dart';
import '../supabase_client.dart';
import '../supabase_tables.dart';

class SpinsRepoSB {
  Future<List<SpinModel>> listSpinsForCity({
    required String city,
    int limit = 20,
  }) async {
    final rows = await SB.client
        .from(Tables.spins)
        .select('''
          id, city, deal_text, free_slots, paid_cost_per_slot,
          reg_open_at, reg_close_at, status,
          winner_user_id, winner_code,
          created_at
        ''')
        .eq('city', city)
        .inFilter('status', ['published', 'running', 'finished', 'closed'])
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((e) => SpinMapper.toSpin(e as Map<String, dynamic>))
        .toList();
  }

  Future<SpinModel?> getSpinById(String spinId) async {
    final row = await SB.client
        .from(Tables.spins)
        .select('''
          id, city, deal_text, free_slots, paid_cost_per_slot,
          reg_open_at, reg_close_at, status,
          winner_user_id, winner_code,
          created_at
        ''')
        .eq('id', spinId)
        .maybeSingle();

    if (row == null) return null;
    return SpinMapper.toSpin(row as Map<String, dynamic>);
  }

  Future<List<SpinEntryModel>> listParticipants({
    required String spinId,
    int limit = 50,
  }) async {
    final rows = await SB.client
        .from(Tables.spinEntries)
        .select('''
          id, spin_id, user_id, entry_type, user_code, created_at
        ''')
        .eq('spin_id', spinId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((e) => SpinMapper.toEntry(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> participantsCount(String spinId) async {
    final res = await SB.client.rpc(
      'rpc_spin_participants_count',
      params: {'p_spin_id': spinId}, // ✅ keep this (matches your RPC)
    );

    if (res == null) return 0;
    if (res is int) return res;
    return int.tryParse(res.toString()) ?? 0;
  }
}
