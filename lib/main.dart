import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/theme/app_theme_controller.dart';
import 'core/network/app_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppThemeController.instance.restore();
  await AppSession.clearLegacySavedLoginOnce();
  await AppSession.restore();
  runApp(const FlowguApp());
}
