import 'package:shared_models/wallet_model.dart';
import 'package:shared_models/wallet_ledger_model.dart';
import '../supabase_client.dart';
import '../supabase_tables.dart';

class WalletRepoSB {
  Future<WalletModel> getMyWallet() async {
    final uid = SB.auth.currentUser?.id;
    if (uid == null) throw Exception('Not logged in');

    final data = await SB.client
        .from(Tables.wallets)
        .select('user_id, balance')
        .eq('user_id', uid)
        .single();

    return WalletModel.fromMap(data);
  }

  Future<List<WalletLedgerModel>> listMyLedger({int limit = 50}) async {
    final uid = SB.auth.currentUser?.id;
    if (uid == null) throw Exception('Not logged in');

    final rows = await SB.client
        .from(Tables.walletLedger)
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((e) => WalletLedgerModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
