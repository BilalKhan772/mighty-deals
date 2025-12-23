class WalletModel {
  final String userId;
  final int balance;

  WalletModel({required this.userId, required this.balance});

  factory WalletModel.fromMap(Map<String, dynamic> m) => WalletModel(
        userId: m['user_id'] as String,
        balance: (m['balance'] as int?) ?? 0,
      );
}
