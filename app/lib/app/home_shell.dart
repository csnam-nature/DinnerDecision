import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'theme/app_colors.dart';

/// 하단 탭: 주변 · 추천 · 달력 · 설정.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.brand;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // 지금 탭을 다시 누르면 그 탭의 첫 화면으로 돌아간다.
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: '주변',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined, color: brand),
            selectedIcon: Icon(Icons.auto_awesome, color: brand),
            label: '추천',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '달력',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
