import 'package:shared_supabase/shared_supabase.dart';
import 'package:shared_models/wallet_model.dart';
import 'package:shared_models/wallet_ledger_model.dart';

class WalletRepo {
  final _repo = WalletRepoSB();

  Future<WalletModel> getMyWallet() => _repo.getMyWallet();

  Future<List<WalletLedgerModel>> listMyLedger({int limit = 50}) =>
      _repo.listMyLedger(limit: limit);
}
