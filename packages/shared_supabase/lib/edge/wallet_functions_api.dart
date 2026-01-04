import 'edge_functions.dart';

class WalletFunctionsApi {
  Future<Map<String, dynamic>> adminTopupByUniqueCode({
    required String uniqueCode,
    required int amount,
  }) {
    return EdgeFunctions.call(
      'admin_topup_by_unique_code',
      body: {
        'unique_code': uniqueCode,
        'amount': amount,
        'type': 'topup',
      },
    );
  }
}
