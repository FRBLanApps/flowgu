import '../../../../shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../core/utils/async_value.dart';
import '../../../../shared/styles/semantic_colors.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_markdown.dart';
import '../../../../shared/widgets/app_snackbars.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/favorite_problem_store.dart';
import '../../domain/models/problem.dart';
import '../controllers/problem_detail_controller.dart';

class ProblemDetailPage extends StatefulWidget {
  const ProblemDetailPage({
    required this.argument,
    super.key,
  });

  final Object? argument;

  @override
  State<ProblemDetailPage> createState() => _ProblemDetailPageState();
}

class _ProblemDetailPageState extends State<ProblemDetailPage> {
  late final ProblemDetailController _controller;
  late final Problem? _initialProblem;

  @override
  void initState() {
    super.initState();
    _controller = ProblemDetailController();
    _initialProblem =
        widget.argument is Problem ? widget.argument as Problem : null;
    if (_initialProblem != null) {
      _controller.load(_initialProblem);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _initialProblem?.id ?? widget.argument?.toString() ?? '未知题目';

    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final problem = _controller.state.data ?? _initialProblem;
            if (problem == null) {
              return Text(id);
            }

            return Text('${problem.id} ${problem.title}');
          },
        ),
      ),
      body: _initialProblem == null
          ? const AppEmptyState(title: '缺少题目信息', message: '请从题库列表进入题目详情')
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return switch (_controller.state) {
                  AsyncInitial<Problem>() ||
                  AsyncLoading<Problem>() =>
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  AsyncError<Problem>(message: final message) => AppEmptyState(
                      title: '题面加载失败',
                      message: message,
                      icon: Icons.error_outline,
                    ),
                  AsyncData<Problem>(value: final problem) =>
                    _ProblemDetailContent(problem: problem),
                };
              },
            ),
    );
  }
}

class _ProblemDetailContent extends StatelessWidget {
  const _ProblemDetailContent({required this.problem});

  final Problem problem;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          problem.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(
              label: problem.sourceLabel,
              color: problem.source == ProblemSource.atcoder
                  ? Colors.deepOrange
                  : Colors.blue,
            ),
            StatusChip(
              label: problem.difficultyLabel,
              color: SemanticColors.problemDifficulty(problem.difficulty),
            ),
            if (problem.timeLimit != null)
              StatusChip(label: problem.timeLimit!, color: Colors.teal),
            if (problem.memoryLimit != null)
              StatusChip(label: problem.memoryLimit!, color: Colors.blueGrey),
          ],
        ),
        if (problem.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('算法标签', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in problem.tags) Chip(label: Text(tag)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _copyProblemMarkdown(context),
            icon: const Icon(Icons.copy_all_outlined),
            label: Text(context.t('problem.copyMarkdown')),
          ),
        ),
        _ProblemSection(title: '题目背景', content: problem.background),
        _ProblemSection(title: '题目描述', content: problem.description),
        _ProblemSection(title: '输入格式', content: problem.inputFormat),
        _ProblemSection(title: '输出格式', content: problem.outputFormat),
        if (problem.samples.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            context.t('problem.samples'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < problem.samples.length; index++)
            _SampleBlock(index: index + 1, sample: problem.samples[index]),
        ],
        _ProblemSection(title: '说明/提示', content: problem.hint),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.of(context)
              .pushNamed(AppRoutes.submit, arguments: problem),
          icon: const Icon(Icons.upload_file),
          label: Text(context.t('problem.submitCode')),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<List<Problem>>(
          valueListenable: FavoriteProblemStore.listenable,
          builder: (context, _, __) {
            final marked = FavoriteProblemStore.contains(problem.id);
            return OutlinedButton.icon(
              onPressed: () {
                FavoriteProblemStore.toggle(problem);
                showFeatureSnackBar(
                  context,
                  marked
                      ? context.t('problem.unfavorited')
                      : context.t('problem.favorited'),
                );
              },
              icon: Icon(marked ? Icons.star : Icons.star_border),
              label: Text(
                marked
                    ? context.t('problem.unfavorite')
                    : context.t('problem.favorite'),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final url = problem.url;
            if (url == null || url.isEmpty) {
              showFeatureSnackBar(context, context.t('problem.noOrigin'));
              return;
            }
            await Clipboard.setData(ClipboardData(text: url));
            if (context.mounted) {
              showFeatureSnackBar(context, context.t('problem.originCopied'));
            }
          },
          icon: const Icon(Icons.open_in_new),
          label: Text(
            problem.url == null
                ? context.t('problem.noOrigin')
                : context.t('problem.copyOrigin'),
          ),
        ),
      ],
    );
  }

  Future<void> _copyProblemMarkdown(BuildContext context) async {
    final buffer = StringBuffer()
      ..writeln('# ${problem.id} ${problem.title}')
      ..writeln()
      ..writeln('难度：${problem.difficultyLabel}')
      ..writeln();
    _appendSection(buffer, '题目背景', problem.background);
    _appendSection(buffer, '题目描述', problem.description);
    _appendSection(buffer, '输入格式', problem.inputFormat);
    _appendSection(buffer, '输出格式', problem.outputFormat);
    for (var index = 0; index < problem.samples.length; index++) {
      final sample = problem.samples[index];
      buffer
        ..writeln('## 样例 #${index + 1}')
        ..writeln()
        ..writeln('### 输入')
        ..writeln()
        ..writeln('```text')
        ..writeln(sample.input)
        ..writeln('```')
        ..writeln()
        ..writeln('### 输出')
        ..writeln()
        ..writeln('```text')
        ..writeln(sample.output)
        ..writeln('```')
        ..writeln();
    }
    _appendSection(buffer, '说明/提示', problem.hint);

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    if (context.mounted) {
      showFeatureSnackBar(context, context.t('problem.markdownCopied'));
    }
  }

  void _appendSection(StringBuffer buffer, String title, String? content) {
    final text = content?.trim();
    if (text == null || text.isEmpty) {
      return;
    }
    buffer
      ..writeln('## $title')
      ..writeln()
      ..writeln(text)
      ..writeln();
  }
}

class _ProblemSection extends StatelessWidget {
  const _ProblemSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String? content;

  @override
  Widget build(BuildContext context) {
    final text = content?.trim();
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AppMarkdown(data: text),
        ],
      ),
    );
  }
}

class _SampleBlock extends StatelessWidget {
  const _SampleBlock({
    required this.index,
    required this.sample,
  });

  final int index;
  final ProblemSample sample;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('样例 #$index', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _SampleHeader(
              label: context.t('problem.sampleInput'),
              text: sample.input,
            ),
            const SizedBox(height: 4),
            _CodeBox(text: sample.input),
            const SizedBox(height: 8),
            _SampleHeader(
              label: context.t('problem.sampleOutput'),
              text: sample.output,
            ),
            const SizedBox(height: 4),
            _CodeBox(text: sample.output),
          ],
        ),
      ),
    );
  }
}

class _SampleHeader extends StatelessWidget {
  const _SampleHeader({
    required this.label,
    required this.text,
  });

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          tooltip: context.t(
            label == context.t('problem.sampleInput')
                ? 'problem.copySampleInput'
                : 'problem.copySampleOutput',
          ),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) {
              showFeatureSnackBar(
                context,
                context.t('problem.sampleCopied', args: {'label': label}),
              );
            }
          },
          icon: const Icon(Icons.copy, size: 18),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.text});

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
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}
