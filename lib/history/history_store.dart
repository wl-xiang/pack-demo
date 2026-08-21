import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dice_record.dart';

/// 历史记录持久化存储（JSON 编码后写入 SharedPreferences）。
class HistoryStore {
  HistoryStore(this._prefs);

  static const String _key = 'dice_roll.history.v1';

  /// 最多保留的历史条数，超出时丢弃最旧的记录。
  static const int maxRecords = 200;

  final SharedPreferences _prefs;

  /// 读取全部记录（可能为空；损坏数据会被安全跳过）。
  List<DiceRecord> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const <DiceRecord>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <DiceRecord>[];
      }
      final records = <DiceRecord>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            final record = DiceRecord.fromJson(item);
            if (record.isValid) {
              records.add(record);
            }
          } catch (_) {
            // 单条损坏的记录不影响其余数据。
          }
        }
      }
      return records;
    } catch (_) {
      return const <DiceRecord>[];
    }
  }

  /// 保存全部记录。
  Future<void> save(List<DiceRecord> records) {
    return _prefs.setString(
      _key,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }
}
