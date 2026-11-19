import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/api/api_client.dart';
import '../../data/repositories/location_repository.dart';
import '../router.dart';
import 'common_widgets.dart';

/// 주변 식당·추천을 불러오지 못했을 때의 안내. 이유에 따라 문구와 버튼이 다르다.
class LoadErrorView extends ConsumerWidget {
  const LoadErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = this.error;
    if (error is LocationException) {
      return StateView(
        emoji: '📍',
        title: '현재 위치를 알 수 없어요',
        message: '${error.failure.message}\n위치를 직접 골라도 돼요',
        actionLabel: '위치 설정',
        onAction: () => context.push(Routes.location),
      );
    }
    if (error is ApiException) {
      final (emoji, title, message) = switch (error.code) {
        ApiException.network || ApiException.timeout => (
          '📡',
          '식당 목록을 불러오지 못했어요',
          '인터넷 연결을 확인한 뒤 다시 시도해 주세요',
        ),
        'RATE_LIMITED' => ('⏳', '잠깐 쉬었다가 다시 시도해 주세요', error.message),
        'UPSTREAM_LIMIT' => ('⏳', '오늘 검색이 너무 많아 잠시 쉬고 있어요', '조금 뒤에 다시 시도해 주세요'),
        _ => ('⚠️', '식당 목록을 불러오지 못했어요', error.message),
      };
      return StateView(
        emoji: emoji,
        title: title,
        message: message,
        actionLabel: '다시 시도',
        onAction: onRetry,
      );
    }
    return StateView(
      emoji: '📡',
      title: '식당 목록을 불러오지 못했어요',
      message: '인터넷 연결을 확인한 뒤 다시 시도해 주세요',
      actionLabel: '다시 시도',
      onAction: onRetry,
    );
  }
}
