/// 历史记录时间的友好格式化：今天 / 昨天 / 具体日期，带精确到秒的时间。
String formatRecordTime(DateTime time, {DateTime? now}) {
  final nowValue = now ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final hms = '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';

  final isSameDay =
      time.year == nowValue.year &&
      time.month == nowValue.month &&
      time.day == nowValue.day;
  if (isSameDay) {
    return '今天 $hms';
  }

  final yesterday = nowValue.subtract(const Duration(days: 1));
  final isYesterday =
      time.year == yesterday.year &&
      time.month == yesterday.month &&
      time.day == yesterday.day;
  if (isYesterday) {
    return '昨天 $hms';
  }

  final date = '${time.month}月${time.day}日';
  if (time.year != nowValue.year) {
    return '${time.year}年$date $hms';
  }
  return '$date $hms';
}
