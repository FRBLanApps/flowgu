import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/i18n/app_i18n.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_controller.dart';
import '../shared/widgets/app_background.dart';

class FlowguApp extends StatelessWidget {
  const FlowguApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, _) {
        final theme = AppThemeController.instance;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flowgu',
          theme: AppTheme.light(theme.seedColor),
          darkTheme: AppTheme.dark(theme.seedColor),
          themeMode: theme.themeMode,
          locale: theme.locale,
          supportedLocales: AppI18n.supportedLocales,
          localizationsDelegates: const [
            ...AppI18n.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () {
                Navigator.maybePop(context);
              },
            },
            child: Focus(
              autofocus: true,
              child: AppBackground(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
          initialRoute: AppRoutes.home,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
