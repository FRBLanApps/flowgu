import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/luogu_json.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_markdown.dart';
import '../../../../shared/styles/semantic_colors.dart';
import '../../../records/data/luogu_records_repository.dart';
import '../../../records/domain/models/submission_record.dart';
import '../../data/luogu_profile_repository.dart';
import '../../domain/models/user_profile.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({required this.uid, this.initialProfile, super.key});

  final String uid;
  final UserProfile? initialProfile;

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  late Future<UserProfile> _profileFuture = widget.initialProfile == null
      ? LuoguProfileRepository(uid: widget.uid, preferSession: false)
          .fetchCurrentUser()
      : Future<UserProfile>.value(widget.initialProfile);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data ?? widget.initialProfile;

        return Scaffold(
          appBar: AppBar(
            title: Text(profile?.name ?? '用户主页'),
            actions: [
              IconButton(
                tooltip: '刷新',
                onPressed: () => setState(() {
                  _profileFuture = LuoguProfileRepository(
                    uid: widget.uid,
                    preferSession: false,
                  ).fetchCurrentUser();
                }),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: switch (snapshot.connectionState) {
            ConnectionState.waiting when profile == null =>
              const Center(child: CircularProgressIndicator()),
            _ when snapshot.hasError && profile == null => AppEmptyState(
                title: '主页加载失败',
                message: '${snapshot.error}',
                icon: Icons.error_outline,
              ),
            _ => _UserHomeContent(profile: profile!),
          },
        );
      },
    );
  }
}

class _UserHomeContent extends StatelessWidget {
  const _UserHomeContent({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _ProfileHeader(profile: profile)),
          const SliverPersistentHeader(
            pinned: true,
            delegate: _TabHeaderDelegate(
              TabBar(
                tabs: [
                  Tab(text: '概览'),
                  Tab(text: '提交'),
                  Tab(text: '题单'),
                  Tab(text: '动态'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _OverviewTab(profile: profile),
            _RecordsTab(uid: profile.uid),
            _TrainingTab(uid: profile.uid),
            _PostsTab(uid: profile.uid),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl;

    final hasSlogan = profile.slogan != null && profile.slogan!.isNotEmpty;

    return SizedBox(
      height: hasSlogan ? 274 : 250,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: null,
            child: SizedBox(
              height: 142,
              width: double.infinity,
              child: profile.backgroundUrl == null ||
                      profile.backgroundUrl!.isEmpty
                  ? ColoredBox(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    )
                  : Image.network(
                      profile.backgroundUrl!,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, 0.25),
                    ),
            ),
          ),
          Positioned(
            top: 120,
            left: 16,
            right: 16,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundImage: avatarUrl == null || avatarUrl.isEmpty
                      ? null
                      : NetworkImage(avatarUrl),
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 42)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'UID ${profile.uid} · '),
                      TextSpan(
                        text: profile.rankName,
                        style: TextStyle(
                          color: SemanticColors.luoguRank(profile.rankName),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasSlogan) ...[
                  const SizedBox(height: 6),
                  Text(
                    profile.slogan!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(label: '通过', value: '${profile.acceptedCount}'),
            _StatCard(label: '提交', value: '${profile.submissionCount}'),
            _StatCard(label: '排名', value: '${profile.ranking}'),
            _StatCard(label: '咕值', value: '${profile.valuation}'),
          ],
        ),
        const SizedBox(height: 20),
        Text('个人介绍', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (profile.introduction == null || profile.introduction!.isEmpty)
          const Text('这个用户还没有填写公开简介。')
        else
          AppMarkdown(data: profile.introduction!, selectable: false),
      ],
    );
  }
}

class _RecordsTab extends StatelessWidget {
  const _RecordsTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SubmissionRecord>>(
      future: LuoguRecordsRepository(userId: uid).fetchRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final records = snapshot.data ?? const [];
        if (records.isEmpty) {
          return const Center(child: Text('暂无提交记录'));
        }
        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final record = records[index];
            return ListTile(
              title: Text('${record.problemId} ${record.problemTitle}'),
              subtitle: Text(
                '${record.resultLabel} · ${record.language}'
                '${record.score == null ? '' : ' · ${record.score} 分'}',
              ),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.recordDetail,
                arguments: record.id,
              ),
            );
          },
        );
      },
    );
  }
}

class _TrainingTab extends StatelessWidget {
  const _TrainingTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return _SimpleApiList(
      future: ApiClient().getJson(
        '/api/user/createdTrainings',
        query: {'page': '1', 'user': uid},
      ),
      listPath: const ['trainings'],
      icon: Icons.folder_copy_outlined,
      emptyText: '暂无公开题单',
      titleOf: (item) =>
          LuoguJson.stringValue(item, const ['name'], fallback: '未命名题单'),
      subtitleOf: (item) =>
          'ID ${LuoguJson.stringValue(item, const ['id'], fallback: '?')}',
    );
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return _SimpleApiList(
      future: ApiClient().getJson(
        '/api/feed/list',
        query: {'page': '1', 'user': uid},
      ),
      listPath: const ['feeds'],
      icon: Icons.article_outlined,
      emptyText: '暂无公开动态',
      titleOf: (item) {
        final user = LuoguJson.mapAt(item, 'user');
        return LuoguJson.stringValue(user, const ['name'], fallback: '公开动态');
      },
      subtitleOf: (item) =>
          LuoguJson.stringValue(item, const ['content'], fallback: '$item'),
    );
  }
}

class _SimpleApiList extends StatelessWidget {
  const _SimpleApiList({
    required this.future,
    required this.listPath,
    required this.icon,
    required this.emptyText,
    required this.titleOf,
    required this.subtitleOf,
  });

  final Future<Map<String, Object?>> future;
  final List<String> listPath;
  final IconData icon;
  final String emptyText;
  final String Function(Map<String, Object?> item) titleOf;
  final String Function(Map<String, Object?> item) subtitleOf;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Object?>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final items = LuoguJson.listAt(snapshot.data ?? const {}, listPath)
            .whereType<Map>()
            .map((item) => Map<String, Object?>.from(item))
            .toList(growable: false);
        if (items.isEmpty) {
          return Center(child: Text(emptyText));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            final subtitle = subtitleOf(item);
            return ListTile(
              leading: Icon(icon),
              title: Text(titleOf(item)),
              subtitle: subtitle.isEmpty ? null : Text(subtitle),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TabHeaderDelegate(this.child);

  final TabBar child;

  @override
  double get minExtent => child.preferredSize.height;

  @override
  double get maxExtent => child.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _TabHeaderDelegate oldDelegate) => false;
}
