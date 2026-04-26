import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../core/i18n/app_i18n.dart';
import '../../features/profile/domain/models/linked_account.dart';

class LoginRequired extends StatelessWidget {
  const LoginRequired({
    required this.message,
    this.platform = AccountPlatform.luogu,
    super.key,
  });

  final String message;
  final AccountPlatform platform;

  @override
  Widget build(BuildContext context) {
    final platformLabel = platform == AccountPlatform.luogu ? '洛谷' : 'AtCoder';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              context.t(
                'login.requiredTitle',
                args: {'platform': platformLabel},
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.login,
                arguments: platform,
              ),
              icon: const Icon(Icons.login),
              label: Text(
                context.t('login.go', args: {'platform': platformLabel}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
