import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/wallet_repo.dart';

final walletRepoProvider = Provider<WalletRepo>((ref) => WalletRepo());

final myWalletProvider = FutureProvider((ref) async {
  return ref.read(walletRepoProvider).getMyWallet();
});

final myLedgerProvider = FutureProvider((ref) async {
  return ref.read(walletRepoProvider).listMyLedger(limit: 50);
});
