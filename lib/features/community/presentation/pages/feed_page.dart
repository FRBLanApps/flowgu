import 'package:flutter/material.dart';

import '../../../../core/i18n/app_i18n.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/app_session.dart';
import '../../../../core/network/luogu_json.dart';
import '../../../../shared/widgets/login_required.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _controller = TextEditingController();
  late Future<List<_FeedItem>> _future = _fetchFeed();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('feed.title'))),
      body: ValueListenableBuilder<int>(
        valueListenable: AppSession.listenable,
        builder: (context, _, __) {
          if (!AppSession.hasLuoguSession) {
            return LoginRequired(message: context.t('login.feedMessage'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: context.t('feed.postLabel'),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: context.t('feed.postTooltip'),
                      onPressed: _postFeed,
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<_FeedItem>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('${snapshot.error}'));
                    }
                    final feeds = snapshot.data ?? const [];
                    if (feeds.isEmpty) {
                      return Center(child: Text(context.t('feed.empty')));
                    }
                    return ListView.separated(
                      itemCount: feeds.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final feed = feeds[index];
                        return ListTile(
                          leading: const Icon(Icons.dynamic_feed_outlined),
                          title: Text(feed.author),
                          subtitle: Text(feed.content),
                          onTap: () => _showFeedDetail(context, feed),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<_FeedItem>> _fetchFeed() async {
    final json = await ApiClient().getJson(
      '/api/feed/list',
      query: const {'page': '1'},
    );
    final feeds = LuoguJson.listAt(json, const ['feeds']);
    return feeds.whereType<Map>().map((raw) {
      final feed = Map<String, Object?>.from(raw);
      final user = LuoguJson.mapAt(feed, 'user');
      return _FeedItem(
        author: LuoguJson.stringValue(user, const ['name'], fallback: '未知用户'),
        content:
            LuoguJson.stringValue(feed, const ['content'], fallback: '$feed'),
        url: _feedUrl(feed),
      );
    }).toList(growable: false);
  }

  String? _feedUrl(Map<String, Object?> feed) {
    final id = LuoguJson.stringValue(feed, const ['id', 'feedId']);
    if (id.isEmpty) {
      return null;
    }
    return 'https://www.luogu.com.cn/feed/$id';
  }

  Future<void> _postFeed() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      return;
    }
    await ApiClient().postForm(
      '/api/feed/postBenben',
      body: {'content': content},
      csrfToken: await ApiClient().fetchCsrfToken('/'),
    );
    _controller.clear();
    setState(() {
      _future = _fetchFeed();
    });
  }

  Future<void> _showFeedDetail(BuildContext context, _FeedItem feed) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(feed.author),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SelectableText(
              feed.url == null
                  ? feed.content
                  : '${feed.content}\n\n${feed.url}',
            ),
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

class _FeedItem {
  const _FeedItem({
    required this.author,
    required this.content,
    this.url,
  });

  final String author;
  final String content;
  final String? url;
}
