/// 一次摇骰子产生的历史记录。
class DiceRecord {
  const DiceRecord({
    required this.id,
    required this.values,
    required this.timestamp,
  });

  /// 唯一标识。
  final String id;

  /// 每颗骰子的点数（1-6）。
  final List<int> values;

  /// 操作时间。
  final DateTime timestamp;

  /// 总和。
  int get sum => values.fold(0, (a, b) => a + b);

  /// 骰子数量。
  int get diceCount => values.length;

  /// 数据是否有效（可被持久化与展示）。
  bool get isValid => id.isNotEmpty && values.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'values': values,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DiceRecord.fromJson(Map<String, dynamic> json) {
    final values = (json['values'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<num>()
        .map((e) => e.toInt())
        .where((v) => v >= 1 && v <= 6)
        .toList();
    return DiceRecord(
      id: json['id'] as String? ?? '',
      values: List<int>.unmodifiable(values),
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DiceRecord && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
