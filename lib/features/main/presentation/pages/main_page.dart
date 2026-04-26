import 'package:flutter/material.dart';

import '../../../../core/i18n/app_i18n.dart';
import '../../../../features/home/presentation/pages/home_page.dart';
import '../../../../features/problems/presentation/pages/problems_page.dart';
import '../../../../features/contests/presentation/pages/contests_page.dart';
import '../../../../features/records/presentation/pages/records_page.dart';
import '../../../../features/profile/presentation/pages/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final List<Widget> _pages = const [
    HomePage(),
    ProblemsPage(),
    ContestsPage(),
    RecordsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..value = 1.0;
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() => _currentIndex = index);
        _fadeController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 40, right: 40, bottom: 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: isDark ? 0.70 : 0.88),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black38 : Colors.black12,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: RepaintBoundary(
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                height: 68,
                selectedIndex: _currentIndex,
                onDestinationSelected: _onTabTapped,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: context.t('nav.home'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.list_alt),
                    selectedIcon: const Icon(Icons.list_alt_rounded),
                    label: context.t('nav.problems'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.emoji_events_outlined),
                    selectedIcon: const Icon(Icons.emoji_events),
                    label: context.t('nav.contests'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.receipt_long_outlined),
                    selectedIcon: const Icon(Icons.receipt_long),
                    label: context.t('nav.records'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    label: context.t('nav.profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
