import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_card_style.dart';
import '../../../../app/theme/app_theme_controller.dart';
import '../../../../core/utils/async_value.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../domain/models/contest.dart';
import '../controllers/contests_controller.dart';

class ContestsPage extends StatefulWidget {
  const ContestsPage({super.key});

  @override
  State<ContestsPage> createState() => _ContestsPageState();
}

class _ContestsPageState extends State<ContestsPage> {
  late final ContestsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ContestsController()..load();
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
        title: const Text('比赛'),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: '洛谷官方赛'),
                Tab(text: '个人公开赛'),
                Tab(text: 'AtCoder'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => _ContestList(
                      state: _controller.official,
                      onRefresh: _controller.load,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => _ContestList(
                      state: _controller.publicContests,
                      onRefresh: _controller.load,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => _ContestList(
                      state: _controller.atcoder,
                      onRefresh: _controller.load,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContestList extends StatelessWidget {
  const _ContestList({
    required this.state,
    required this.onRefresh,
  });

  final AsyncValue<List<Contest>> state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AsyncInitial<List<Contest>>() ||
      AsyncLoading<List<Contest>>() =>
        const Center(
          child: CircularProgressIndicator(),
        ),
      AsyncError<List<Contest>>(message: final message) => AppEmptyState(
          title: '比赛加载失败',
          message: message,
          icon: Icons.error_outline,
        ),
      AsyncData<List<Contest>>(value: final contests) when contests.isEmpty =>
        const AppEmptyState(
          title: '暂无比赛',
          message: '当前分类暂时没有可显示的比赛',
          icon: Icons.emoji_events_outlined,
        ),
      AsyncData<List<Contest>>(value: final contests) => RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: contests.length,
            itemBuilder: (context, index) {
              final contest = contests[index];

              return _ContestCard(
                contest: contest,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.contestDetail,
                  arguments: contest,
                ),
              );
            },
          ),
        ),
    };
  }
}

class _ContestCard extends StatelessWidget {
  const _ContestCard({
    required this.contest,
    required this.onTap,
  });

  final Contest contest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final style = AppThemeController.instance.cardStyle;
    final statusColor = contest.status == ContestStatus.running
        ? Colors.green
        : contest.source == ContestSource.atcoder
            ? Colors.deepOrange
            : Colors.orange;
    final radius = BorderRadius.circular(28);
    final decoration = _contestCardDecoration(
      style: style,
      scheme: scheme,
      dark: dark,
      radius: radius,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Ink(
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Row(
                children: [
                  Icon(
                    contest.source == ContestSource.atcoder
                        ? Icons.code
                        : Icons.emoji_events_outlined,
                    color: scheme.primary.withValues(alpha: 0.92),
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          contest.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: style == AppCardStyle.flat
                                ? Colors.white
                                : scheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            contest.sourceLabel,
                            contest.rule,
                            contest.startsAt,
                            if (contest.duration != null) contest.duration!,
                          ].join(' | '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: (style == AppCardStyle.flat
                                    ? Colors.white
                                    : scheme.onSurface)
                                .withValues(alpha: 0.62),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  StatusChip(
                    label: contest.statusLabel,
                    color: statusColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _contestCardDecoration({
    required AppCardStyle style,
    required ColorScheme scheme,
    required bool dark,
    required BorderRadius radius,
  }) {
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.22 : 0.16),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];

    return switch (style) {
      AppCardStyle.flat => BoxDecoration(
          color: const Color(0xFF25272D).withValues(alpha: 0.94),
          borderRadius: radius,
          border: Border.all(
            color: Colors.white.withValues(alpha: dark ? 0.08 : 0.10),
          ),
          boxShadow: shadow,
        ),
      AppCardStyle.frosted => BoxDecoration(
          color: scheme.surface.withValues(alpha: dark ? 0.62 : 0.78),
          borderRadius: radius,
          border: Border.all(
            color: scheme.onSurface.withValues(alpha: dark ? 0.10 : 0.14),
          ),
          boxShadow: shadow,
        ),
      AppCardStyle.liquid => BoxDecoration(
          color: scheme.surface.withValues(alpha: dark ? 0.56 : 0.74),
          borderRadius: radius,
          border: Border.all(
            color: Colors.white.withValues(alpha: dark ? 0.12 : 0.42),
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface.withValues(alpha: dark ? 0.62 : 0.82),
              scheme.surfaceContainerHighest.withValues(
                alpha: dark ? 0.46 : 0.70,
              ),
              scheme.primary.withValues(alpha: dark ? 0.07 : 0.09),
            ],
            stops: const [0, 0.72, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.30 : 0.12),
              blurRadius: 22,
              spreadRadius: -2,
              offset: const Offset(0, 12),
            ),
          ],
        ),
    };
  }
}
