import 'package:flutter/material.dart';

import '../../features/community/presentation/pages/discussions_page.dart';
import '../../features/community/presentation/pages/feed_page.dart';
import '../../features/community/presentation/pages/rankings_page.dart';
import '../../features/contests/presentation/pages/contest_detail_page.dart';
import '../../features/contests/presentation/pages/contests_page.dart';
import '../../features/main/presentation/pages/main_page.dart';
import '../../features/problems/presentation/pages/problem_detail_page.dart';
import '../../features/problems/presentation/pages/submit_page.dart';
import '../../features/profile/domain/models/linked_account.dart';
import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/presentation/pages/account_login_page.dart';
import '../../features/profile/presentation/pages/app_settings_page.dart';
import '../../features/profile/presentation/pages/favorites_page.dart';
import '../../features/profile/presentation/pages/problem_sets_page.dart';
import '../../features/profile/presentation/pages/user_home_page.dart';
import '../../features/records/presentation/pages/record_detail_page.dart';
import '../../features/records/presentation/pages/records_page.dart';
import '../../features/search/presentation/pages/search_page.dart';

class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const search = '/search';
  static const settings = '/settings';
  static const problemDetail = '/problems/detail';
  static const submit = '/problems/submit';
  static const contests = '/contests';
  static const contestDetail = '/contests/detail';
  static const records = '/records';
  static const recordDetail = '/records/detail';
  static const favorites = '/profile/favorites';
  static const problemSets = '/profile/problem-sets';
  static const discussions = '/community/discussions';
  static const rankings = '/community/rankings';
  static const feed = '/community/feed';
  static const login = '/profile/login';
  static const userHome = '/profile/home';

  static Map<String, WidgetBuilder> get routes {
    return {
      home: (_) => const MainPage(),
      search: (_) => const SearchPage(),
      settings: (_) => const AppSettingsPage(),
      favorites: (_) => const FavoritesPage(),
      problemSets: (_) => const ProblemSetsPage(),
      contests: (_) => const ContestsPage(),
      records: (_) => const RecordsPage(),
      discussions: (_) => const DiscussionsPage(),
      rankings: (_) => const RankingsPage(),
      feed: (_) => const FeedPage(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) {
        return switch (settings.name) {
          problemDetail => ProblemDetailPage(argument: settings.arguments),
          submit => SubmitPage(argument: settings.arguments),
          contestDetail => ContestDetailPage(argument: settings.arguments),
          recordDetail =>
            RecordDetailPage(recordId: settings.arguments as String?),
          login => AccountLoginPage(
              platform: settings.arguments is AccountPlatform
                  ? settings.arguments! as AccountPlatform
                  : null,
            ),
          userHome => _userHomePage(settings.arguments),
          _ => const MainPage(),
        };
      },
    );
  }

  static Widget _userHomePage(Object? argument) {
    if (argument is UserProfile) {
      return UserHomePage(uid: argument.uid, initialProfile: argument);
    }
    return UserHomePage(uid: argument?.toString() ?? '1');
  }
}
