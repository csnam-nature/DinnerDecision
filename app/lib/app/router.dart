import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/calendar/calendar_screen.dart';
import '../features/meal_log_edit/meal_log_draft.dart';
import '../features/meal_log_edit/meal_log_edit_screen.dart';
import '../features/nearby/location_screen.dart';
import '../features/nearby/nearby_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/recommend/recommend_screen.dart';
import '../features/restaurant_detail/restaurant_detail_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/settings_sub_screens.dart';
import 'home_shell.dart';

/// 화면 주소 (UI_PLAN.md 3장).
abstract final class Routes {
  static const nearby = '/nearby';
  static const recommend = '/recommend';
  static const calendar = '/calendar';
  static const settings = '/settings';
  static const excluded = '/settings/excluded';
  static const dislikes = '/settings/dislikes';
  static const backup = '/settings/backup';
  static const onboarding = '/onboarding';
  static const location = '/location';

  /// 기록 입력·수정. `extra`로 [MealLogDraft]를 넘긴다.
  static const mealLog = '/log';

  static String restaurant(String id) =>
      '/restaurant/${Uri.encodeComponent(id)}';
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();
  // 탭 위를 덮는 화면은 rootKey에 올려서 하단 탭이 보이지 않게 한다.
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.nearby,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.nearby,
                builder: (_, _) => const NearbyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.recommend,
                builder: (_, _) => const RecommendScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.calendar,
                builder: (_, _) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'excluded',
                    parentNavigatorKey: rootKey,
                    builder: (_, _) => const ExcludedScreen(),
                  ),
                  GoRoute(
                    path: 'dislikes',
                    parentNavigatorKey: rootKey,
                    builder: (_, _) => const DislikesScreen(),
                  ),
                  GoRoute(
                    path: 'backup',
                    parentNavigatorKey: rootKey,
                    builder: (_, _) => const BackupScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.location, builder: (_, _) => const LocationScreen()),
      GoRoute(
        path: '/restaurant/:id',
        builder: (_, state) =>
            RestaurantDetailScreen(restaurantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.mealLog,
        pageBuilder: (_, state) => MaterialPage(
          fullscreenDialog: true,
          child: MealLogEditScreen(initial: state.extra as MealLogDraft?),
        ),
      ),
    ],
  );
});
