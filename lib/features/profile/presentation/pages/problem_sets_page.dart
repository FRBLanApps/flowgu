import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/app_session.dart';
import '../../../../core/network/luogu_json.dart';
import '../../../../shared/widgets/login_required.dart';

class ProblemSetsPage extends StatefulWidget {
  const ProblemSetsPage({super.key});

  @override
  State<ProblemSetsPage> createState() => _ProblemSetsPageState();
}

class _ProblemSetsPageState extends State<ProblemSetsPage> {
  late Future<List<_ProblemSetItem>> _markedFuture;
  late Future<List<_ProblemSetItem>> _createdFuture;

  @override
  void initState() {
    super.initState();
    _resetFutures();
    AppSession.listenable.addListener(_handleSessionChanged);
  }

  @override
  void dispose() {
    AppSession.listenable.removeListener(_handleSessionChanged);
    super.dispose();
  }

  void _handleSessionChanged() {
    if (!mounted) {
      return;
    }

    setState(_resetFutures);
  }

  void _resetFutures() {
    _markedFuture = _fetchMarked();
    _createdFuture = _fetchCreated();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppSession.listenable,
      builder: (context, _, __) {
        if (!AppSession.hasLuoguSession) {
          return Scaffold(
            appBar: AppBar(title: Text(context.t('profile.problemSets'))),
            body: LoginRequired(message: context.t('login.problemSetsMessage')),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: const _ProblemSetsAppBar(),
            body: TabBarView(
              children: [
                _ProblemSetList(future: _markedFuture),
                _ProblemSetList(future: _createdFuture),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<_ProblemSetItem>> _fetchMarked() async {
    return _guardAuthError(() async {
      final json = await ApiClient().getJson(
        '/api/user/markedTrainings',
        query: const {'page': '1'},
      );
      final items = LuoguJson.listAt(json, const ['trainingParticipations']);
      return items.whereType<Map>().map((raw) {
        final participation = Map<String, Object?>.from(raw);
        return _problemSetFromJson(LuoguJson.mapAt(participation, 'training'));
      }).toList(growable: false);
    });
  }

  Future<List<_ProblemSetItem>> _fetchCreated() async {
    return _guardAuthError(() async {
      final json = await ApiClient().getJson(
        '/api/user/createdTrainings',
        query: const {'page': '1'},
      );
      final items = LuoguJson.listAt(json, const ['trainings']);
      return items
          .whereType<Map>()
          .map((raw) => _problemSetFromJson(Map<String, Object?>.from(raw)))
          .toList(growable: false);
    });
  }

  Future<List<_ProblemSetItem>> _guardAuthError(
    Future<List<_ProblemSetItem>> Function() loader,
  ) async {
    try {
      return await loader();
    } on AppException catch (error) {
      if (_isLoginRequired(error)) {
        AppSession.clear();
        return const [];
      }
      rethrow;
    }
  }

  bool _isLoginRequired(AppException error) {
    return error.message.contains('UserNotLoggedInException') ||
        error.message.contains('该洛谷接口需要登录') ||
        error.message.contains('HTTP 403');
  }

  _ProblemSetItem _problemSetFromJson(Map<String, Object?> json) {
    return _ProblemSetItem(
      id: LuoguJson.stringValue(json, const ['id'], fallback: '?'),
      name: LuoguJson.stringValue(json, const ['name'], fallback: '未命名题单'),
      problemCount: LuoguJson.intValue(json, const ['problemCount']),
    );
  }
}

class _ProblemSetsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ProblemSetsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(context.t('profile.problemSets')),
      bottom: const TabBar(
        tabs: [
          Tab(text: '收藏'),
          Tab(text: '创建'),
        ],
      ),
    );
  }
}

class _ProblemSetList extends StatelessWidget {
  const _ProblemSetList({required this.future});

  final Future<List<_ProblemSetItem>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ProblemSetItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('暂无题单，或当前接口需要登录'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: const Icon(Icons.folder_copy_outlined),
              title: Text(item.name),
              subtitle: Text('ID ${item.id} · ${item.problemCount} 题'),
            );
          },
        );
      },
    );
  }
}

class _ProblemSetItem {
  const _ProblemSetItem({
    required this.id,
    required this.name,
    required this.problemCount,
  });

  final String id;
  final String name;
  final int problemCount;
}
