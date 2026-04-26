import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/luogu_json.dart';

class DiscussionsPage extends StatelessWidget {
  const DiscussionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleRemoteListPage(
      title: '讨论',
      future: _fetchPosts(),
      emptyText: '暂无讨论',
    );
  }

  Future<List<_RemoteItem>> _fetchPosts() async {
    final json = await ApiClient().getJson(
      '/discuss',
      responseType: LuoguResponseType.lentille,
      query: const {'page': '1'},
    );
    final data = LuoguJson.unwrap(json);
    final posts = LuoguJson.listAt(data, const ['posts', 'result']);
    return posts.whereType<Map>().map((raw) {
      final post = Map<String, Object?>.from(raw);
      final author = LuoguJson.mapAt(post, 'author');
      final forum = LuoguJson.mapAt(post, 'forum');
      final authorName = LuoguJson.stringValue(
        author,
        const ['name'],
        fallback: '未知用户',
      );
      final forumName = LuoguJson.stringValue(
        forum,
        const ['name'],
        fallback: '讨论',
      );
      final replyCount = LuoguJson.intValue(post, const ['replyCount']);
      return _RemoteItem(
        title: LuoguJson.stringValue(post, const ['title'], fallback: '未命名帖子'),
        subtitle: '$authorName · $forumName · $replyCount 回复',
        icon: Icons.forum_outlined,
        url: _postUrl(post),
        content: LuoguJson.stringValue(
          post,
          const ['content', 'summary'],
        ),
      );
    }).toList(growable: false);
  }

  String? _postUrl(Map<String, Object?> post) {
    final id = LuoguJson.stringValue(post, const ['id', 'pid']);
    if (id.isEmpty) {
      return null;
    }
    return 'https://www.luogu.com.cn/discuss/$id';
  }
}

class _SimpleRemoteListPage extends StatelessWidget {
  const _SimpleRemoteListPage({
    required this.title,
    required this.future,
    required this.emptyText,
  });

  final String title;
  final Future<List<_RemoteItem>> future;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<_RemoteItem>>(
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
            return Center(child: Text(emptyText));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                onTap: () => _showItemDetail(context, item),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showItemDetail(BuildContext context, _RemoteItem item) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final body = [
          item.subtitle,
          if (item.content != null && item.content!.isNotEmpty) item.content!,
          if (item.url != null) item.url!,
        ].join('\n\n');
        return AlertDialog(
          title: Text(item.title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SelectableText(body),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
        );
      },
    );
  }
}

class _RemoteItem {
  const _RemoteItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.url,
    this.content,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? url;
  final String? content;
}
