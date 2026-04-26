import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../core/network/app_session.dart';
import '../../../../core/utils/async_value.dart';
import '../../../../shared/styles/semantic_colors.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_snackbars.dart';
import '../../domain/models/linked_account.dart';
import '../../domain/models/user_profile.dart';
import '../controllers/account_link_controller.dart';
import '../controllers/profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileController _controller;
  late final AccountLinkController _accountController;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController()..load();
    _accountController = AccountLinkController();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('profile.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return switch (_controller.state) {
            AsyncInitial<UserProfile>() ||
            AsyncLoading<UserProfile>() =>
              const Center(
                child: CircularProgressIndicator(),
              ),
            AsyncError<UserProfile>(message: final message) => AppEmptyState(
                title: context.t('profile.loadFailed'),
                message: message,
                icon: Icons.error_outline,
              ),
            AsyncData<UserProfile>(value: final profile) => RefreshIndicator(
                onRefresh: _controller.load,
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    ListTile(
                      onTap: AppSession.hasLuoguSession
                          ? () => Navigator.pushNamed(
                                context,
                                AppRoutes.userHome,
                                arguments: profile,
                              )
                          : () => Navigator.pushNamed(
                                context,
                                AppRoutes.login,
                                arguments: AccountPlatform.luogu,
                              ),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: profile.avatarUrl == null ||
                                profile.avatarUrl!.isEmpty
                            ? null
                            : NetworkImage(profile.avatarUrl!),
                        child: profile.avatarUrl == null ||
                                profile.avatarUrl!.isEmpty
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      ),
                      title: Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'UID: ${profile.uid} | '),
                            TextSpan(
                              text: profile.rankName,
                              style: TextStyle(
                                color: SemanticColors.luoguRank(
                                  profile.rankName,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: _controller.load,
                        child: Text(context.t('common.sync')),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          '${profile.acceptedCount}',
                          context.t('profile.accepted'),
                        ),
                        _buildStatItem(
                          '${profile.submissionCount}',
                          context.t('profile.submissions'),
                        ),
                        _buildStatItem(
                          '${profile.ranking}',
                          context.t('profile.ranking'),
                        ),
                        _buildStatItem(
                          '${profile.valuation}',
                          context.t('profile.valuation'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        context.t('profile.accountLinks'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _accountController,
                      builder: (context, _) {
                        return Column(
                          children: [
                            for (final account in _accountController.accounts)
                              _buildAccountTile(context, account),
                            ValueListenableBuilder<int>(
                              valueListenable: AppSession.listenable,
                              builder: (context, _, __) {
                                if (!AppSession.hasLuoguSession) {
                                  return const SizedBox.shrink();
                                }
                                return ListTile(
                                  leading: const Icon(Icons.cookie_outlined),
                                  title: Text(context.t('profile.copyCookie')),
                                  trailing: const Icon(Icons.copy),
                                  onTap: () => _copyLuoguCookie(context),
                                );
                              },
                            ),
                            if (_accountController.state.isLoading)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: LinearProgressIndicator(),
                              ),
                          ],
                        );
                      },
                    ),
                    const Divider(),
                    _buildActionTile(
                      context,
                      icon: Icons.star_border,
                      title: context.t('profile.favorites'),
                      route: AppRoutes.favorites,
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.edit_note,
                      title: context.t('profile.problemSets'),
                      route: AppRoutes.problemSets,
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.history,
                      title: context.t('profile.records'),
                      route: AppRoutes.records,
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.color_lens_outlined,
                      title: context.t('profile.theme'),
                      route: AppRoutes.settings,
                    ),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, LinkedAccount account) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: _PlatformIcon(platform: account.platform),
      ),
      title: Text(account.platformLabel),
      subtitle: Text(
        account.isConnected
            ? _accountSubtitle(account)
            : context.t('profile.notConnected'),
      ),
      trailing: TextButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.login,
            arguments: account.platform,
          );
          if (result is LinkedAccount) {
            if (!context.mounted) return;
            _accountController.applyAccount(result);
            showFeatureSnackBar(context, context.t('auth.accountConnected'));
            await _controller.load();
          }
        },
        child: Text(
          account.isConnected
              ? context.t('common.switch')
              : context.t('common.login'),
        ),
      ),
      onLongPress: account.isConnected
          ? () async {
              await _accountController.disconnect(account.platform);
              if (context.mounted) {
                showFeatureSnackBar(context, context.t('profile.disconnected'));
              }
            }
          : null,
    );
  }

  String _accountSubtitle(LinkedAccount account) {
    if (account.detail == null || account.detail!.isEmpty) {
      return account.username;
    }

    return '${account.username} · ${account.detail}';
  }

  Future<void> _copyLuoguCookie(BuildContext context) async {
    final cookie = AppSession.cookieHeader;
    if (cookie == null || cookie.isEmpty) {
      showFeatureSnackBar(context, context.t('profile.cookieEmpty'));
      return;
    }
    await Clipboard.setData(ClipboardData(text: cookie));
    if (context.mounted) {
      showFeatureSnackBar(context, context.t('profile.cookieCopied'));
    }
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    Object? arguments,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.pushNamed(context, route, arguments: arguments),
    );
  }
}

class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon({required this.platform});

  final AccountPlatform platform;

  @override
  Widget build(BuildContext context) {
    final url = switch (platform) {
      AccountPlatform.luogu => 'https://www.luogu.com.cn/favicon.ico',
      AccountPlatform.atcoder => 'https://img.atcoder.jp/assets/favicon.png',
    };

    return Image.network(
      url,
      width: 28,
      height: 28,
      errorBuilder: (context, error, stackTrace) =>
          Text(platform == AccountPlatform.luogu ? '洛' : 'A'),
    );
  }
}
