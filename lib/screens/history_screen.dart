import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../models/dice_record.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/dice_face.dart';
import '../widgets/glass_background.dart';

/// 历史记录页：查看、删除、清空摇骰记录。
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: controller.records.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: controller.records.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final record = controller.records[index];
                              return _RecordTile(
                                key: ValueKey('record-${record.id}'),
                                record: record,
                                onDelete: () =>
                                    _deleteRecord(context, record, index),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: tokens.textPrimary,
            ),
            tooltip: '返回',
          ),
          Text(
            '历史记录',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.glassBorder, width: 1),
            ),
            child: Text(
              '${controller.recordCount} 条',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: controller.hasRecords
                ? () => _confirmClearAll(context)
                : null,
            icon: Icon(
              Icons.delete_sweep_rounded,
              size: 24,
              color: controller.hasRecords
                  ? AppTheme.danger
                  : tokens.textSecondary.withValues(alpha: 0.4),
            ),
            tooltip: '清空记录',
          ),
        ],
      ),
    );
  }

  void _deleteRecord(BuildContext context, DiceRecord record, int index) {
    final messenger = ScaffoldMessenger.of(context);
    controller.removeRecord(record.id);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('已删除一条记录'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '撤销',
          textColor: const Color(0xFFB4B9FF),
          onPressed: () => controller.restoreRecord(record, index),
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空历史记录'),
        content: Text('确定要删除全部 ${controller.recordCount} 条记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('全部清空'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await controller.clearAll();
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(const SnackBar(content: Text('历史记录已清空')));
      }
    }
  }
}

/// 单条历史记录卡片：迷你骰子 + 时间 + 总和，左滑删除。
class _RecordTile extends StatelessWidget {
  const _RecordTile({super.key, required this.record, required this.onDelete});

  final DiceRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Dismissible(
      key: ValueKey('dismiss-${record.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF07278), AppTheme.danger],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.glassBorder, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final value in record.values)
                        DiceFace(value: value, size: 26),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatRecordTime(record.timestamp),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${record.sum}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  '总和',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 空状态提示。
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(opacity: 0.55, child: DiceFace(value: 1, size: 84)),
          const SizedBox(height: 22),
          Text(
            '还没有记录',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '摇一把骰子，结果会出现在这里',
            style: TextStyle(fontSize: 13.5, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
