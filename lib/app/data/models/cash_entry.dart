import 'dart:convert';

enum CashEntryType { cashIn, cashOut }

class CashEntry {
  CashEntry({
    required this.id,
    required this.type,
    required this.amountUsd,
    required this.amountKhr,
    required this.createdAt,
    required this.note,
  });

  final String id;
  final CashEntryType type;
  final double amountUsd;
  final double amountKhr;
  final DateTime createdAt;
  final String note;

  bool get isCashIn => type == CashEntryType.cashIn;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amountUsd': amountUsd,
      'amountKhr': amountKhr,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'note': note,
    };
  }

  static CashEntry fromMap(Map<String, dynamic> map) {
    final legacyAmount = map['amount'];
    final amountUsdRaw = map['amountUsd'] ?? legacyAmount;
    final amountKhrRaw = map['amountKhr'];

    return CashEntry(
      id: map['id'] as String,
      type: CashEntryType.values.byName(map['type'] as String),
      amountUsd: (amountUsdRaw as num?)?.toDouble() ?? 0,
      amountKhr: (amountKhrRaw as num?)?.toDouble() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      note: (map['note'] as String?) ?? '',
    );
  }

  static String encodeList(List<CashEntry> entries) {
    final list = entries.map((e) => e.toMap()).toList();
    return jsonEncode(list);
  }

  static List<CashEntry> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <CashEntry>[];
    return decoded
        .whereType<Map>()
        .map((e) => CashEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}
