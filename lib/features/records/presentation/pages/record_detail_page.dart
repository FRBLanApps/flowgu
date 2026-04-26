import '../../../../shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme_controller.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../core/utils/async_value.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../domain/models/submission_record.dart';
import '../controllers/record_detail_controller.dart';

class RecordDetailPage extends StatefulWidget {
  const RecordDetailPage({
    required this.recordId,
    super.key,
  });

  final String? recordId;

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  late final RecordDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RecordDetailController();
    final id = widget.recordId;
    if (id != null && id.isNotEmpty) {
      _controller.load(
        id,
        retryOnFailure: AppThemeController.instance.recordRetry,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.recordId ?? 'unknown';

    return Scaffold(
      appBar: AppBar(title: Text(id)),
      body: widget.recordId == null
          ? AppEmptyState(
              title: context.t('recordDetail.missingTitle'),
              message: context.t('recordDetail.missingMessage'),
            )
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return switch (_controller.state) {
                  AsyncInitial<SubmissionRecord>() ||
                  AsyncLoading<SubmissionRecord>() =>
                    _LoadingRecord(retryCount: _controller.retryCount),
                  AsyncError<SubmissionRecord>(message: final message) =>
                    AppEmptyState(
                      title: context.t('recordDetail.loadFailed'),
                      message: message,
                      icon: Icons.error_outline,
                    ),
                  AsyncData<SubmissionRecord>(value: final record) =>
                    _RecordDetailContent(record: record),
                };
              },
            ),
    );
  }
}

class _LoadingRecord extends StatelessWidget {
  const _LoadingRecord({required this.retryCount});

  final int retryCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            retryCount == 0
                ? context.t('recordDetail.loading')
                : context.t(
                    'recordDetail.retrying',
                    args: {'count': retryCount},
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecordDetailContent extends StatelessWidget {
  const _RecordDetailContent({required this.record});

  final SubmissionRecord record;

  @override
  Widget build(BuildContext context) {
    final color = _resultColor(record.result);

    return RefreshIndicator(
      onRefresh: () async {
        final state = context.findAncestorStateOfType<_RecordDetailPageState>();
        await state?._controller.load(
          record.id,
          retryOnFailure: AppThemeController.instance.recordRetry,
        );
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${record.problemId} ${record.problemTitle}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(label: record.resultLabel, color: color),
              if (record.score != null)
                _MetricChip(label: '${record.score} 分', color: Colors.indigo),
              _MetricChip(label: record.language, color: Colors.blueGrey),
              _MetricChip(label: record.duration, color: Colors.teal),
              _MetricChip(label: record.memory, color: Colors.deepPurple),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: context.t('recordDetail.recordId'), value: record.id),
          _InfoRow(
            label: context.t('recordDetail.submitter'),
            value: record.userName,
          ),
          _InfoRow(
            label: context.t('recordDetail.submittedAt'),
            value: record.submittedAt,
          ),
          _InfoRow(
            label: context.t('recordDetail.statusCode'),
            value: record.statusCode.toString(),
          ),
          if (record.compileMessage != null &&
              record.compileMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              context.t('records.compileInfo'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _CodeBlock(text: record.compileMessage!),
          ],
          const SizedBox(height: 20),
          Text(
            context.t('recordDetail.testPoints'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (record.subtasks.isEmpty)
            Text(
              record.isFinal
                  ? context.t('records.noTestDetails')
                  : context.t('records.judgingHint'),
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            )
          else
            for (final subtask in record.subtasks)
              _SubtaskCard(subtask: subtask),
          if (record.sourceCode != null &&
              record.sourceCode!.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              context.t('recordDetail.sourceCode'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _CodeBlock(text: record.sourceCode!),
          ],
        ],
      ),
    );
  }
}

class _SubtaskCard extends StatelessWidget {
  const _SubtaskCard({required this.subtask});

  final SubmissionSubtask subtask;

  @override
  Widget build(BuildContext context) {
    final color = _resultColor(subtask.status);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Subtask #${subtask.id}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _MetricChip(label: subtask.status.resultLabel, color: color),
                const SizedBox(width: 8),
                _MetricChip(label: '${subtask.score} 分', color: Colors.indigo),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: context.t('recordDetail.time'),
              value: '${subtask.time}ms',
            ),
            _InfoRow(
              label: context.t('recordDetail.memory'),
              value: '${subtask.memory}KB',
            ),
            if (subtask.testCases.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final testCase in subtask.testCases)
                _TestCaseTile(testCase: testCase),
            ],
          ],
        ),
      ),
    );
  }
}

class _TestCaseTile extends StatelessWidget {
  const _TestCaseTile({required this.testCase});

  final SubmissionTestCase testCase;

  @override
  Widget build(BuildContext context) {
    final color = _resultColor(testCase.status);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Text(
          '#${testCase.id}',
          style: TextStyle(color: color, fontSize: 11),
        ),
      ),
      title: Text('${testCase.status.resultLabel} · ${testCase.score} 分'),
      subtitle: Text(
        [
          '${testCase.time}ms',
          '${testCase.memory}KB',
          if (testCase.description != null) testCase.description!,
          if (testCase.signal != null) 'signal ${testCase.signal}',
          if (testCase.exitCode != null) 'exit ${testCase.exitCode}',
        ].join(' · '),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color, fontSize: 12),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }
}

Color _resultColor(SubmissionResult result) {
  return switch (result) {
    SubmissionResult.accepted => Colors.green,
    SubmissionResult.waiting ||
    SubmissionResult.judging ||
    SubmissionResult.compiling =>
      Colors.orange,
    SubmissionResult.compileError ||
    SubmissionResult.wrongAnswer ||
    SubmissionResult.timeLimitExceeded ||
    SubmissionResult.runtimeError =>
      Colors.red,
    SubmissionResult.unknown => Colors.grey,
  };
}
