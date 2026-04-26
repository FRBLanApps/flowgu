import '../../../../shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/luogu_json.dart';
import '../../../../core/utils/async_value.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_markdown.dart';
import '../../../../shared/widgets/app_snackbars.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../problems/domain/models/problem.dart';
import '../../domain/models/contest.dart';
import '../controllers/contest_detail_controller.dart';

class ContestDetailPage extends StatefulWidget {
  const ContestDetailPage({
    required this.argument,
    super.key,
  });

  final Object? argument;

  @override
  State<ContestDetailPage> createState() => _ContestDetailPageState();
}

class _ContestDetailPageState extends State<ContestDetailPage> {
  late final ContestDetailController _controller;
  late final Contest? _initialContest;

  @override
  void initState() {
    super.initState();
    _controller = ContestDetailController();
    _initialContest =
        widget.argument is Contest ? widget.argument as Contest : null;
    if (_initialContest != null) {
      _controller.load(_initialContest);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _initialContest?.id ?? widget.argument?.toString() ?? '未知比赛';

    return Scaffold(
      appBar: AppBar(title: Text(id)),
      body: _initialContest == null
          ? const AppEmptyState(title: '缺少比赛信息', message: '请从比赛列表进入详情')
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return switch (_controller.state) {
                  AsyncInitial<Contest>() ||
                  AsyncLoading<Contest>() =>
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  AsyncError<Contest>(message: final message) => AppEmptyState(
                      title: '比赛详情加载失败',
                      message: message,
                      icon: Icons.error_outline,
                    ),
                  AsyncData<Contest>(value: final contest) =>
                    _ContestDetailContent(contest: contest),
                };
              },
            ),
    );
  }
}

class _ContestDetailContent extends StatelessWidget {
  const _ContestDetailContent({required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          contest.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(
              label: contest.sourceLabel,
              color: contest.source == ContestSource.atcoder
                  ? Colors.deepOrange
                  : Colors.blue,
            ),
            StatusChip(
              label: contest.statusLabel,
              color: contest.status == ContestStatus.running
                  ? Colors.green
                  : Colors.orange,
            ),
            if (contest.ratedRange != null)
              StatusChip(label: contest.ratedRange!, color: Colors.indigo),
            if (contest.duration != null)
              StatusChip(label: contest.duration!, color: Colors.teal),
            if (contest.joined)
              const StatusChip(label: '已报名', color: Colors.green),
          ],
        ),
        const SizedBox(height: 16),
        _InfoRow(label: '开始时间', value: contest.startsAt),
        _InfoRow(label: '赛制', value: contest.rule),
        _InfoRow(label: '分类', value: contest.category),
        _InfoRow(
          label: '题目数量',
          value: contest.problemCount?.toString() ??
              contest.problems.length.toString(),
        ),
        _ContestDescription(description: contest.description),
        const SizedBox(height: 20),
        Text('题目列表', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (contest.problems.isEmpty)
          const _MutedText('题目列表暂未公开，或当前接口需要登录/报名后查看。')
        else
          for (final problem in contest.problems)
            _ContestProblemTile(
              contest: contest,
              problem: problem,
            ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => _joinContest(context),
          icon: const Icon(Icons.how_to_reg),
          label: Text(contest.joined ? '已报名' : '报名'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showScoreboard(context),
          icon: const Icon(Icons.leaderboard),
          label: const Text('榜单'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _copyOriginalUrl(context),
          icon: const Icon(Icons.open_in_new),
          label: Text(contest.url == null ? '暂无原站链接' : '复制原站链接'),
        ),
      ],
    );
  }

  Future<void> _joinContest(BuildContext context) async {
    if (contest.source != ContestSource.luogu) {
      _copyOriginalUrl(context);
      return;
    }

    try {
      await ApiClient().postJson(
        '/contest/${contest.id}/join',
        body: const {},
        csrfToken: await ApiClient().fetchCsrfToken('/contest/${contest.id}'),
      );
      if (context.mounted) {
        showFeatureSnackBar(context, '报名成功');
      }
    } on Object catch (error) {
      if (context.mounted) {
        showFeatureSnackBar(context, '报名失败：$error');
      }
    }
  }

  Future<void> _showScoreboard(BuildContext context) async {
    if (contest.source != ContestSource.luogu) {
      _copyOriginalUrl(context);
      return;
    }

    try {
      final json = await ApiClient().getJson(
        '/fe/api/contest/scoreboard/${contest.id}',
        query: const {'page': '1'},
      );
      final rows = _scoreboardRows(json);
      if (!context.mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) {
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '榜单',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (rows.isEmpty)
                    const ListTile(title: Text('暂无榜单数据'))
                  else
                    for (final row in rows.take(30))
                      ListTile(
                        leading: CircleAvatar(child: Text('${row.rank}')),
                        title: Text(row.name),
                        subtitle: Text('分数 ${row.score}'),
                        trailing: Text(row.runningTime),
                      ),
                ],
              ),
            ),
          );
        },
      );
    } on Object catch (error) {
      if (context.mounted) {
        showFeatureSnackBar(context, '榜单加载失败：$error');
      }
    }
  }

  List<_ScoreboardRow> _scoreboardRows(Map<String, Object?> json) {
    final data = LuoguJson.unwrap(json);
    final rawRows = [
      ...LuoguJson.listAt(data, const ['scoreboard', 'result']),
      ...LuoguJson.listAt(data, const ['ranking', 'result']),
      ...LuoguJson.listAt(data, const ['result']),
    ];

    return rawRows.whereType<Map>().toList().asMap().entries.map((entry) {
      final row = Map<String, Object?>.from(entry.value);
      final user = LuoguJson.mapAt(row, 'user');
      return _ScoreboardRow(
        rank: entry.key + 1,
        name: LuoguJson.stringValue(user, const ['name'], fallback: '未知用户'),
        score: LuoguJson.intValue(row, const ['score'], fallback: 0),
        runningTime:
            '${LuoguJson.intValue(row, const ['runningTime'], fallback: 0)}',
      );
    }).toList(growable: false);
  }

  Future<void> _copyOriginalUrl(BuildContext context) async {
    final url = contest.url;
    if (url == null || url.isEmpty) {
      showFeatureSnackBar(context, '暂无原站链接');
      return;
    }

    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      showFeatureSnackBar(context, '原站链接已复制');
    }
  }
}

class _ScoreboardRow {
  const _ScoreboardRow({
    required this.rank,
    required this.name,
    required this.score,
    required this.runningTime,
  });

  final int rank;
  final String name;
  final int score;
  final String runningTime;
}

class _ContestDescription extends StatelessWidget {
  const _ContestDescription({required this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    final text = description?.trim();
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('比赛说明', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AppMarkdown(data: text),
        ],
      ),
    );
  }
}

class _ContestProblemTile extends StatelessWidget {
  const _ContestProblemTile({
    required this.contest,
    required this.problem,
  });

  final Contest contest;
  final ContestProblem problem;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${problem.id} ${problem.title}'),
        subtitle: Text(_subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.problemDetail,
            arguments: Problem(
              id: problem.id,
              title: problem.title,
              difficulty: _difficultyFromLuogu(problem.difficulty),
              acceptRate: 0,
              isAccepted: false,
              source: contest.source == ContestSource.atcoder
                  ? ProblemSource.atcoder
                  : ProblemSource.luogu,
              url: contest.source == ContestSource.atcoder
                  ? '$_contestBaseUrl/tasks/$_atCoderTaskId'
                  : 'https://www.luogu.com.cn/problem/${problem.id}',
              description: '比赛题目详情正在从题库接口加载。',
            ),
          );
        },
      ),
    );
  }

  String get _subtitle {
    final chunks = <String>[];
    if (problem.score != null && problem.score! > 0) {
      chunks.add('${problem.score} 分');
    }
    if (problem.difficulty != null && problem.difficulty! > 0) {
      chunks.add('难度 ${problem.difficulty}');
    }

    return chunks.isEmpty ? '点击查看题面' : chunks.join(' · ');
  }

  String get _atCoderTaskId {
    if (problem.id.startsWith('${contest.id}_')) {
      return problem.id;
    }

    return '${contest.id}_${problem.id.toLowerCase()}';
  }

  String get _contestBaseUrl {
    return contest.url ?? 'https://atcoder.jp/contests/${contest.id}';
  }

  ProblemDifficulty _difficultyFromLuogu(int? difficulty) {
    return switch (difficulty ?? 0) {
      0 => ProblemDifficulty.unrated,
      1 => ProblemDifficulty.beginner,
      2 => ProblemDifficulty.easy,
      3 => ProblemDifficulty.normal,
      4 => ProblemDifficulty.medium,
      5 => ProblemDifficulty.hard,
      6 => ProblemDifficulty.provincial,
      _ => ProblemDifficulty.noi,
    };
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.outline),
    );
  }
}
