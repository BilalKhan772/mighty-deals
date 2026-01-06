class SpinEntryModel {
  final String id;
  final String spinId;
  final String userId;
  final String entryType; // free/paid
  final String? userCode; // snapshot e.g. "#1022"
  final DateTime createdAt;

  SpinEntryModel({
    required this.id,
    required this.spinId,
    required this.userId,
    required this.entryType,
    required this.userCode,
    required this.createdAt,
  });

  factory SpinEntryModel.fromMap(Map<String, dynamic> m) {
    return SpinEntryModel(
      id: m['id'] as String,
      spinId: m['spin_id'] as String,
      userId: m['user_id'] as String,
      entryType: (m['entry_type'] ?? 'free') as String,
      userCode: m['user_code'] as String?,
      createdAt: DateTime.parse(m['created_at'].toString()),
    );
  }

  String get displayUserCode {
    final c = userCode;
    if (c == null || c.isEmpty) return 'User';
    final digits = c.startsWith('#') ? c.substring(1) : c;
    return 'User#$digits';
  }
}
