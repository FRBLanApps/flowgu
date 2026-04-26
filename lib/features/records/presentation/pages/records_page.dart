import '../../../../shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../core/network/app_session.dart';
import '../../../../core/utils/async_value.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/login_required.dart';
import '../../data/luogu_records_repository.dart';
import '../../domain/models/submission_record.dart';
import '../controllers/records_controller.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  late final RecordsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RecordsController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('records.title')),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: AppSession.listenable,
        builder: (context, _, __) {
          if (!AppSession.hasLuoguSession) {
            return LoginRequired(
              message: context.t('login.luoguRecordsMessage'),
            );
          }
          if (_controller.state is AsyncInitial<List<SubmissionRecord>> ||
              _controller.state is AsyncError<List<SubmissionRecord>>) {
            Future.microtask(_controller.load);
          }

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return switch (_controller.state) {
                AsyncInitial<List<SubmissionRecord>>() ||
                AsyncLoading<List<SubmissionRecord>>() =>
                  const Center(child: CircularProgressIndicator()),
                AsyncError<List<SubmissionRecord>>(message: final message) =>
                  AppEmptyState(
                    title: context.t('records.loadFailed'),
                    message: message,
                    icon: Icons.error_outline,
                  ),
                AsyncData<List<SubmissionRecord>>(value: final records) =>
                  RefreshIndicator(
                    onRefresh: _controller.load,
                    child: ListView.separated(
                      itemCount: records.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return _RecordExpansion(record: record);
                      },
                    ),
                  ),
              };
            },
          );
        },
      ),
    );
  }
}

class _RecordExpansion extends StatefulWidget {
  const _RecordExpansion({required this.record});

  final SubmissionRecord record;

  @override
  State<_RecordExpansion> createState() => _RecordExpansionState();
}

class _RecordExpansionState extends State<_RecordExpansion> {
  late Future<SubmissionRecord> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture =
        LuoguRecordsRepository().fetchRecordDetail(widget.record.id);
  }

  @override
  void didUpdateWidget(covariant _RecordExpansion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.id != widget.record.id) {
      _detailFuture =
          LuoguRecordsRepository().fetchRecordDetail(widget.record.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final color = _resultColor(record.result);

    return ExpansionTile(
      initiallyExpanded: true,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            record.resultLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
      title: Text('${record.problemId} ${record.problemTitle}'),
      subtitle: Text(
        '${record.userName} • ${record.language} • ${record.duration} • ${record.memory}'
        '${record.score == null ? '' : ' • ${record.score} 分'}',
      ),
      trailing: Text(
        record.submittedAt,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        FutureBuilder<SubmissionRecord>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return _RecordDetailFallback(
                message: '${snapshot.error}',
                onOpenDetail: () => Navigator.pushNamed(
                  context,
                  AppRoutes.recordDetail,
                  arguments: record.id,
                ),
              );
            }

            final detail = snapshot.data ?? record;
            return _ExpandedRecordDetail(
              record: detail,
              onOpenDetail: () => Navigator.pushNamed(
                context,
                AppRoutes.recordDetail,
                arguments: detail.id,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ExpandedRecordDetail extends StatelessWidget {
  const _ExpandedRecordDetail({
    required this.record,
    required this.onOpenDetail,
  });

  final SubmissionRecord record;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniChip(
              label: record.resultLabel,
              color: _resultColor(record.result),
            ),
            if (record.score != null)
              _MiniChip(label: '${record.score} 分', color: Colors.indigo),
            _MiniChip(label: record.language, color: Colors.blueGrey),
            _MiniChip(label: record.duration, color: Colors.teal),
            _MiniChip(label: record.memory, color: Colors.deepPurple),
          ],
        ),
        const SizedBox(height: 10),
        if (record.compileMessage != null &&
            record.compileMessage!.trim().isNotEmpty) ...[
          Text(
            context.t('records.compileInfo'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          _CompactCodeBlock(text: record.compileMessage!),
          const SizedBox(height: 10),
        ],
        if (record.subtasks.isEmpty)
          Text(
            record.isFinal
                ? context.t('records.noTestDetails')
                : context.t('records.judgingHint'),
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          )
        else
          for (final subtask in record.subtasks)
            _ExpandedSubtask(subtask: subtask),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onOpenDetail,
            icon: const Icon(Icons.open_in_new),
            label: Text(context.t('common.openDetails')),
          ),
        ),
      ],
    );
  }
}

class _ExpandedSubtask extends StatelessWidget {
  const _ExpandedSubtask({required this.subtask});

  final SubmissionSubtask subtask;

  @override
  Widget build(BuildContext context) {
    final color = _resultColor(subtask.status);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
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
                _MiniChip(label: subtask.status.resultLabel, color: color),
                const SizedBox(width: 6),
                _MiniChip(label: '${subtask.score} 分', color: Colors.indigo),
              ],
            ),
            const SizedBox(height: 6),
            Text('${subtask.time}ms · ${subtask.memory}KB'),
            if (subtask.testCases.isNotEmpty) ...[
              const Divider(),
              for (final testCase in subtask.testCases)
                _ExpandedTestCase(testCase: testCase),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpandedTestCase extends StatelessWidget {
  const _ExpandedTestCase({required this.testCase});

  final SubmissionTestCase testCase;

  @override
  Widget build(BuildContext context) {
    final color = _resultColor(testCase.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              '#${testCase.id}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              '${testCase.status.resultLabel} · ${testCase.score} 分 · '
              '${testCase.time}ms · ${testCase.memory}KB'
              '${testCase.description == null ? '' : ' · ${testCase.description}'}',
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordDetailFallback extends StatelessWidget {
  const _RecordDetailFallback({
    required this.message,
    required this.onOpenDetail,
  });

  final String message;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t('records.detailFailed', args: {'message': message}),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onOpenDetail,
            icon: const Icon(Icons.open_in_new),
            label: Text(context.t('common.openDetailPage')),
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
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
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }
}

class _CompactCodeBlock extends StatelessWidget {
  const _CompactCodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
