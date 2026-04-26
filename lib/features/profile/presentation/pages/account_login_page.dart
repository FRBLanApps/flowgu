import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/i18n/app_i18n.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/async_value.dart';
import '../../../../shared/widgets/app_snackbars.dart';
import '../../domain/models/account_auth.dart';
import '../../domain/models/linked_account.dart';
import '../controllers/account_link_controller.dart';

class AccountLoginPage extends StatefulWidget {
  const AccountLoginPage({this.platform, super.key});

  final AccountPlatform? platform;

  @override
  State<AccountLoginPage> createState() => _AccountLoginPageState();
}

class _AccountLoginPageState extends State<AccountLoginPage> {
  late AccountPlatform _platform = widget.platform ?? AccountPlatform.luogu;
  late AccountLoginMode _mode = _platform == AccountPlatform.luogu
      ? AccountLoginMode.password
      : AccountLoginMode.password;
  late final AccountLinkController _controller;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cookieController = TextEditingController();
  final _captchaController = TextEditingController();
  final _captchaClient = ApiClient();
  var _captchaKey = 0;

  @override
  void initState() {
    super.initState();
    _controller = AccountLinkController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _cookieController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLuogu = _platform == AccountPlatform.luogu;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('accountLogin.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<AccountPlatform>(
            segments: const [
              ButtonSegment(
                value: AccountPlatform.luogu,
                icon: Icon(Icons.school_outlined),
                label: Text('洛谷'),
              ),
              ButtonSegment(
                value: AccountPlatform.atcoder,
                icon: Icon(Icons.code),
                label: Text('AtCoder'),
              ),
            ],
            selected: {_platform},
            onSelectionChanged: (value) {
              setState(() {
                _platform = value.first;
                _mode = _platform == AccountPlatform.luogu
                    ? AccountLoginMode.password
                    : AccountLoginMode.password;
              });
            },
          ),
          const SizedBox(height: 16),
          SegmentedButton<AccountLoginMode>(
            segments: [
              ButtonSegment(
                value: AccountLoginMode.password,
                icon: const Icon(Icons.password),
                label: Text(context.t('accountLogin.password')),
              ),
              if (isLuogu)
                const ButtonSegment(
                  value: AccountLoginMode.cookie,
                  icon: Icon(Icons.cookie_outlined),
                  label: Text('Cookie'),
                )
              else
                ButtonSegment(
                  value: AccountLoginMode.publicProfile,
                  icon: const Icon(Icons.public),
                  label: Text(context.t('accountLogin.publicProfile')),
                ),
            ],
            selected: {_mode},
            onSelectionChanged: (value) => setState(() => _mode = value.first),
          ),
          const SizedBox(height: 16),
          if (_mode != AccountLoginMode.cookie) ...[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: isLuogu
                    ? context.t('accountLogin.luoguUsername')
                    : context.t('accountLogin.atcoderId'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_mode == AccountLoginMode.password) ...[
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: context.t('accountLogin.password'),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
          ],
          if (isLuogu && _mode == AccountLoginMode.password) ...[
            TextField(
              controller: _captchaController,
              decoration: InputDecoration(
                labelText: context.t('accountLogin.captcha'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            _LuoguCaptchaImage(
              client: _captchaClient,
              refreshKey: _captchaKey,
              onRefresh: () => setState(() => _captchaKey += 1),
            ),
            const SizedBox(height: 12),
          ],
          if (isLuogu && _mode == AccountLoginMode.cookie) ...[
            TextField(
              controller: _cookieController,
              decoration: InputDecoration(
                labelText: context.t('accountLogin.cookie'),
                border: const OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 12),
          ],
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final loading = _controller.state.isLoading;
              return FilledButton.icon(
                onPressed: loading ? null : _submit,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  loading
                      ? context.t('accountLogin.connecting')
                      : context.t('accountLogin.connect'),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            isLuogu
                ? context.t('accountLogin.luoguNote')
                : _mode == AccountLoginMode.password
                    ? context.t('accountLogin.atcoderPasswordNote')
                    : context.t('accountLogin.atcoderPublicNote'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    await _controller.connect(
      AccountAuthRequest(
        platform: _platform,
        mode: _mode,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        cookie: _cookieController.text.trim(),
        captcha: _captchaController.text.trim(),
      ),
    );
    if (!mounted) return;

    switch (_controller.state) {
      case AsyncData<AccountAuthResult>(value: final result):
        showFeatureSnackBar(context, context.t(result.message));
        Navigator.pop(context, result.account);
      case AsyncError<AccountAuthResult>(message: final message):
        showFeatureSnackBar(context, message);
      default:
        break;
    }
  }
}

class _LuoguCaptchaImage extends StatelessWidget {
  const _LuoguCaptchaImage({
    required this.client,
    required this.refreshKey,
    required this.onRefresh,
  });

  final ApiClient client;
  final int refreshKey;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 120,
            height: 44,
            child: FutureBuilder<Uint8List>(
              key: ValueKey(refreshKey),
              future: client.getBytes(
                '/lg4/captcha',
                query: {
                  '_t': DateTime.now().millisecondsSinceEpoch.toString(),
                },
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const ColoredBox(
                    color: Color(0x11000000),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const ColoredBox(
                    color: Color(0x11000000),
                    child: Center(child: Icon(Icons.image_not_supported)),
                  );
                }

                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: context.t('accountLogin.refreshCaptcha'),
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}
