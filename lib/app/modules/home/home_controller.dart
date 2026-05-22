import 'package:get/get.dart';

import '../../data/models/cash_entry.dart';
import '../../data/services/storage_service.dart';

class HomeController extends GetxController {
  HomeController({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  final StorageService _storageService;

  final entries = <CashEntry>[].obs;

  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;

  DateTime _monthOnly(DateTime d) => DateTime(d.year, d.month);

  int _compareMonth(DateTime a, DateTime b) {
    if (a.year != b.year) return a.year.compareTo(b.year);
    return a.month.compareTo(b.month);
  }

  DateTime _minMonth(DateTime a, DateTime b) => _compareMonth(a, b) <= 0 ? a : b;

  DateTime _maxMonth(DateTime a, DateTime b) => _compareMonth(a, b) >= 0 ? a : b;

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  DateTime? get _earliestEntryMonth {
    if (entries.isEmpty) return null;
    var min = _monthOnly(entries.first.createdAt);
    for (final e in entries) {
      final m = _monthOnly(e.createdAt);
      min = _minMonth(min, m);
    }
    return min;
  }

  DateTime? get _latestEntryMonth {
    if (entries.isEmpty) return null;
    var max = _monthOnly(entries.first.createdAt);
    for (final e in entries) {
      final m = _monthOnly(e.createdAt);
      max = _maxMonth(max, m);
    }
    return max;
  }

  void _clampSelectedMonthToRange() {
    final months = availableMonths;
    if (months.isEmpty) return;

    final selected = _monthOnly(selectedMonth.value);
    final newest = months.first;
    final oldest = months.last;

    if (_compareMonth(selected, newest) > 0) {
      selectedMonth.value = newest;
      return;
    }
    if (_compareMonth(selected, oldest) < 0) {
      selectedMonth.value = oldest;
      return;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  List<DateTime> get availableMonths {
    final base = _currentMonth;
    final earliest = _earliestEntryMonth;
    final latest = _latestEntryMonth;

    final start = _minMonth(earliest ?? base, DateTime(base.year, base.month - 11));
    final end = _maxMonth(base, latest ?? base);

    final months = <DateTime>[];
    var cursor = DateTime(start.year, start.month);
    while (_compareMonth(cursor, end) <= 0) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    months.sort((a, b) => _compareMonth(b, a));
    return months;
  }

  void setMonth(DateTime month) {
    selectedMonth.value = DateTime(month.year, month.month);
  }

  List<CashEntry> get entriesForSelectedMonth {
    final m = selectedMonth.value;
    final start = DateTime(m.year, m.month);
    final end = DateTime(m.year, m.month + 1);
    final list = entries
        .where((e) => !e.createdAt.isBefore(start) && e.createdAt.isBefore(end))
        .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  double get cashInTotalUsd {
    return entriesForSelectedMonth
        .where((e) => e.type == CashEntryType.cashIn)
        .fold<double>(0, (sum, e) => sum + e.amountUsd);
  }

  double get cashOutTotalUsd {
    return entriesForSelectedMonth
        .where((e) => e.type == CashEntryType.cashOut)
        .fold<double>(0, (sum, e) => sum + e.amountUsd);
  }

  double get netTotalUsd => cashInTotalUsd - cashOutTotalUsd;

  double get cashInTotalKhr {
    return entriesForSelectedMonth
        .where((e) => e.type == CashEntryType.cashIn)
        .fold<double>(0, (sum, e) => sum + e.amountKhr);
  }

  double get cashOutTotalKhr {
    return entriesForSelectedMonth
        .where((e) => e.type == CashEntryType.cashOut)
        .fold<double>(0, (sum, e) => sum + e.amountKhr);
  }

  double get netTotalKhr => cashInTotalKhr - cashOutTotalKhr;

  Future<void> addEntry({
    required CashEntryType type,
    required double amountUsd,
    required double amountKhr,
    required String note,
    DateTime? createdAt,
  }) async {
    final entry = CashEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      amountUsd: amountUsd,
      amountKhr: amountKhr,
      createdAt: createdAt ?? DateTime.now(),
      note: note,
    );

    entries.add(entry);
    _clampSelectedMonthToRange();
    await _save();
  }

  Future<void> deleteEntry(String id) async {
    entries.removeWhere((e) => e.id == id);
    _clampSelectedMonthToRange();
    await _save();
  }

  Future<void> updateEntry({
    required String id,
    required CashEntryType type,
    required double amountUsd,
    required double amountKhr,
    required String note,
    required DateTime createdAt,
  }) async {
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final updated = CashEntry(
      id: id,
      type: type,
      amountUsd: amountUsd,
      amountKhr: amountKhr,
      createdAt: createdAt,
      note: note,
    );
    entries[idx] = updated;
    // Ensure ordering and month clamping remain sensible
    entries.refresh();
    _clampSelectedMonthToRange();
    await _save();
  }

  Future<void> clearAll() async {
    entries.clear();
    await _storageService.clearAll();
    selectedMonth.value = _currentMonth;
  }

  Future<void> _load() async {
    final raw = await _storageService.readEntriesRaw();
    if (raw == null || raw.isEmpty) return;

    try {
      entries.assignAll(CashEntry.decodeList(raw));
      _clampSelectedMonthToRange();
    } catch (_) {
      entries.clear();
      selectedMonth.value = _currentMonth;
    }
  }

  Future<void> _save() async {
    final raw = CashEntry.encodeList(entries);
    await _storageService.writeEntriesRaw(raw);
  }
}
