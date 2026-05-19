import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _entriesKey = 'cash_entries_v1';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String?> readEntriesRaw() async {
    final p = await _prefs;
    return p.getString(_entriesKey);
  }

  Future<void> writeEntriesRaw(String raw) async {
    final p = await _prefs;
    await p.setString(_entriesKey, raw);
  }

  Future<void> clearAll() async {
    final p = await _prefs;
    await p.remove(_entriesKey);
  }
}
