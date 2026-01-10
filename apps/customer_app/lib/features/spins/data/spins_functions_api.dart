import 'package:shared_supabase/edge/edge_functions.dart';

class SpinsFunctionsApi {
  Future<Map<String, dynamic>> joinFree({required String spinId}) {
    // ✅ Free bhi isi function se handle ho raha hai (entry_type = free)
    return EdgeFunctions.call('spin_register_paid', body: {
      'spin_id': spinId,
      'entry_type': 'free',
    });
  }

  Future<Map<String, dynamic>> joinPaid({required String spinId}) {
    return EdgeFunctions.call('spin_register_paid', body: {
      'spin_id': spinId,
      'entry_type': 'paid',
    });
  }
}
