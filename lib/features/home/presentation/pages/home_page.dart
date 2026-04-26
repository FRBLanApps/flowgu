import '../../../../shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../core/utils/async_value.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../contests/domain/models/contest.dart';
import '../../domain/models/dashboard_summary.dart';
import '../controllers/home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController()..load();
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
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.signatureAccent.withAlpha(0x26), // 0.15 * 255
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.signatureAccent.withAlpha(0x4C), // 0.3 * 255
                ),
              ),
              child: Text(
                'F',
                style: GoogleFonts.outfit(
                  color: AppTheme.signatureAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Flowgu',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return switch (_controller.state) {
            AsyncInitial<DashboardSummary>() ||
            AsyncLoading<DashboardSummary>() =>
              const Center(
                child: CircularProgressIndicator(),
              ),
            AsyncError<DashboardSummary>(message: final message) =>
              AppEmptyState(
                title: context.t('home.loadFailed'),
                message: message,
                icon: Icons.error_outline,
              ),
            AsyncData<DashboardSummary>(value: final summary) =>
              RefreshIndicator(
                onRefresh: _controller.load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _FortuneCard(summary: summary),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildShortcut(
                          context,
                          Icons.edit_note,
                          context.t('profile.problemSets'),
                          AppRoutes.problemSets,
                        ),
                        _buildShortcut(
                          context,
                          Icons.history,
                          '讨论',
                          AppRoutes.discussions,
                        ),
                        _buildShortcut(
                          context,
                          Icons.leaderboard,
                          '排名',
                          AppRoutes.rankings,
                        ),
                        _buildShortcut(
                          context,
                          Icons.school,
                          context.t('feed.title'),
                          AppRoutes.feed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: context.t('home.recentContests'),
                      actionLabel: context.t('common.all'),
                      onAction: () =>
                          Navigator.pushNamed(context, AppRoutes.contests),
                    ),
                    const SizedBox(height: 8),
                    for (final contest in summary.recentContests)
                      _ContestTile(contest: contest),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }

  Widget _buildShortcut(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushNamed(context, route),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _FortuneCard extends StatelessWidget {
  const _FortuneCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.fortuneTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(summary.fortuneRating),
                  backgroundColor: Colors.amber.withValues(alpha: 0.18),
                  side: BorderSide(color: Colors.amber.withValues(alpha: 0.45)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(summary.fortuneContent),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FortuneAdviceColumn(
                    label: context.t('home.fortune.good'),
                    color: Colors.green,
                    items: summary.fortuneGood,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FortuneAdviceColumn(
                    label: context.t('home.fortune.bad'),
                    color: Colors.red,
                    items: summary.fortuneBad,
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

class _FortuneAdviceColumn extends StatelessWidget {
  const _FortuneAdviceColumn({
    required this.label,
    required this.color,
    required this.items,
  });

  final String label;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(item),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContestTile extends StatelessWidget {
  const _ContestTile({required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.emoji_events, color: Colors.amber),
      title: Text(contest.title),
      subtitle: Text(contest.startsAt),
      trailing: StatusChip(
        label: contest.statusLabel,
        color: contest.status == ContestStatus.running
            ? Colors.green
            : Colors.orange,
      ),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.contestDetail,
        arguments: contest,
      ),
    );
  }
}
