import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/luogu_json.dart';

class RankingsPage extends StatelessWidget {
  const RankingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('排名'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '咕值'),
              Tab(text: '等级分'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RankingList(future: _fetchRanking('/ranking')),
            _RankingList(future: _fetchRanking('/ranking/elo')),
          ],
        ),
      ),
    );
  }

  Future<List<_RankingItem>> _fetchRanking(String path) async {
    final json = await ApiClient().getJson(
      path,
      responseType: LuoguResponseType.lentille,
      query: const {'page': '1'},
    );
    final data = LuoguJson.unwrap(json);
    final ranking = LuoguJson.listAt(data, const ['ranking', 'result']);
    return ranking
        .asMap()
        .entries
        .where((entry) => entry.value is Map)
        .map((entry) {
      final item = Map<String, Object?>.from(entry.value as Map);
      final user = LuoguJson.mapAt(item, 'user');
      return _RankingItem(
        rank: entry.key + 1,
        name: LuoguJson.stringValue(user, const ['name'], fallback: '未知用户'),
        uid: LuoguJson.stringValue(user, const ['uid'], fallback: '?'),
        rating: LuoguJson.intValue(item, const ['rating', 'score']),
      );
    }).toList(growable: false);
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.future});

  final Future<List<_RankingItem>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_RankingItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final items = snapshot.data ?? const [];
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${item.rank}')),
              title: Text(item.name),
              subtitle: Text('UID ${item.uid}'),
              trailing: Text('${item.rating}'),
            );
          },
        );
      },
    );
  }
}

class _RankingItem {
  const _RankingItem({
    required this.rank,
    required this.name,
    required this.uid,
    required this.rating,
  });

  final int rank;
  final String name;
  final String uid;
  final int rating;
}
