class SpinModel {
  final String id;
  final String city;
  final String dealText;
  final int freeSlots;
  final int paidCostPerSlot;
  final DateTime? regOpenAt;
  final DateTime? regCloseAt;
  final String status; // draft/published/closed/running/finished
  final String? winnerUserId;
  final String? winnerCode;

  SpinModel({
    required this.id,
    required this.city,
    required this.dealText,
    required this.freeSlots,
    required this.paidCostPerSlot,
    required this.regOpenAt,
    required this.regCloseAt,
    required this.status,
    required this.winnerUserId,
    required this.winnerCode,
  });

  factory SpinModel.fromMap(Map<String, dynamic> m) {
    DateTime? dt(dynamic v) => v == null ? null : DateTime.parse(v.toString());

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return SpinModel(
      id: m['id'] as String,
      city: (m['city'] ?? '') as String,
      dealText: (m['deal_text'] ?? '') as String,
      freeSlots: toInt(m['free_slots']),
      paidCostPerSlot: toInt(m['paid_cost_per_slot']),
      regOpenAt: dt(m['reg_open_at']),
      regCloseAt: dt(m['reg_close_at']),
      status: (m['status'] ?? 'draft') as String,
      winnerUserId: m['winner_user_id'] as String?,
      winnerCode: m['winner_code'] as String?,
    );
  }

  /// Prefer DB winner_code (e.g. "#4227") -> "User#4227"
  /// Fallback: if winner_code missing but winner_user_id exists -> show short id
  String get displayWinnerCode {
    final c = winnerCode;
    if (c != null && c.isNotEmpty) {
      final digits = c.startsWith('#') ? c.substring(1) : c;
      return 'User#$digits';
    }

    final uid = winnerUserId;
    if (uid != null && uid.isNotEmpty) {
      // fallback short form
      final short = uid.length >= 4 ? uid.substring(0, 4) : uid;
      return 'Winner($short)';
    }

    return '';
  }
}
