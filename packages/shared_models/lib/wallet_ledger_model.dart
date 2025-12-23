class WalletLedgerModel {
  final String id;
  final String type;
  final int amount;
  final String? referenceType;
  final String? referenceId;
  final DateTime createdAt;

  WalletLedgerModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.referenceType,
    required this.referenceId,
    required this.createdAt,
  });

  factory WalletLedgerModel.fromMap(Map<String, dynamic> m) => WalletLedgerModel(
        id: m['id'] as String,
        type: (m['type'] as String?) ?? '',
        amount: (m['amount'] as int?) ?? 0,
        referenceType: m['reference_type'] as String?,
        referenceId: (m['reference_id'] as dynamic)?.toString(),
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
