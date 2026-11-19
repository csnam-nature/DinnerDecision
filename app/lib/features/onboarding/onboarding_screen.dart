import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/common_widgets.dart';

/// S-01 온보딩. 시스템 권한 창을 띄우기 전에 위치가 왜 필요한지 먼저 알려준다.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _points = [
    ('📍', '내 주변 1km 맛집을 한눈에'),
    ('✨', '날씨와 내가 먹은 기록을 보고 겹치지 않게 추천해요'),
    ('📅', '간 곳은 달력에 차곡차곡 쌓여요'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Gap.xl),
                      const ExcludeSemantics(
                        child: Text('🍽', style: TextStyle(fontSize: 56)),
                      ),
                      const SizedBox(height: Gap.lg),
                      Text('오늘 저녁,\n고민 끝!', style: context.text.headlineMedium),
                      const SizedBox(height: Gap.xl),
                      for (final (emoji, text) in _points)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Gap.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ExcludeSemantics(
                                child: Text(
                                  emoji,
                                  style: context.text.bodyLarge,
                                ),
                              ),
                              const SizedBox(width: Gap.md),
                              Expanded(
                                child: Text(
                                  text,
                                  style: context.text.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Gap.lg),
                decoration: BoxDecoration(
                  color: context.colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(Radii.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📍 위치 권한이 필요해요', style: context.text.titleMedium),
                    const SizedBox(height: Gap.xs),
                    Text(
                      '주변 식당을 찾을 때만 쓰고, 위치는 서버에 저장하지 않아요.',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.go(Routes.nearby);
                    showNotReady(context, '위치 권한 요청은 아직 연결 전이라 예시 위치로 시작해요');
                  },
                  child: const Text('위치 권한 허용하기'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => context.go(Routes.location),
                  child: const Text('나중에 (위치 직접 설정)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
