import 'package:dinner_decision/app/app.dart';
import 'package:dinner_decision/data/providers.dart';
import 'package:dinner_decision/data/repositories/place_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    // 휴대폰 세로 화면 크기.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(loadTestConfig()),
          clockProvider.overrideWithValue(() => testToday),
          placeRepositoryProvider.overrideWithValue(
            FakePlaceRepository(delay: Duration.zero),
          ),
        ],
        child: const DinnerDecisionApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('주변 목록이 가까운 순으로 뜨고 분류로 거를 수 있다', (tester) async {
    await pumpApp(tester);

    expect(find.text('성수동2가'), findsOneWidget);
    expect(find.text('☔ 비 · 9℃ · 미세먼지 보통'), findsOneWidget);
    expect(find.text('전체 25'), findsOneWidget);
    expect(find.text('성수 할매순대국'), findsOneWidget);
    expect(find.text('🕘 12일 전 방문'), findsOneWidget);

    await tester.tap(find.text('🥟 중식 4'));
    await tester.pumpAndSettle();
    expect(find.text('진짬뽕'), findsOneWidget);
    expect(find.text('성수 할매순대국'), findsNothing);
  });

  testWidgets('식당을 누르면 상세가 열리고, 기록하면 달력으로 간다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('성수 할매순대국'));
    await tester.pumpAndSettle();
    expect(find.text('내 방문 기록 (2회)'), findsOneWidget);
    expect(find.text('네이버 지도'), findsOneWidget);

    await tester.tap(find.text('오늘 여기서 먹었어요'));
    await tester.pumpAndSettle();
    expect(find.text('식사 기록'), findsOneWidget);
    expect(find.text('2026-11-09 (월)'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();
    expect(find.text('달력'), findsWidgets);
    expect(find.text('기록했어요. 달력에 점이 생겼어요'), findsOneWidget);
    expect(find.text('이번 달 6번 기록 · 처음 간 곳 4곳'), findsOneWidget);
  });

  testWidgets('추천을 받으면 이유가 보이고, 결정하면 기록 화면이 채워져 열린다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('오늘의 추천 받기'));
    await tester.pumpAndSettle();
    expect(find.text('오늘 뭐 먹지? 추천 받기'), findsOneWidget);

    await tester.tap(find.text('오늘 뭐 먹지? 추천 받기'));
    await tester.pump();
    expect(find.text('날씨와 기록을 보고 고르는 중…'), findsOneWidget);
    // 고르는 연출(0.85초)이 끝날 때까지 기다린다.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('왜 추천하나요?'), findsOneWidget);
    expect(find.text('다른 후보'), findsOneWidget);
    expect(find.textContaining('걸어서'), findsWidgets);
    // 최근 7일 안에 간 곳은 나오지 않는다.
    expect(find.textContaining('스시 하루'), findsNothing);
    expect(find.textContaining('트라토리아 성수'), findsNothing);

    await tester.tap(find.text('여기로 결정'));
    await tester.pumpAndSettle();
    expect(find.text('추천에서 결정한 식당이라 미리 채워 두었어요. 별점만 남겨 주세요.'), findsOneWidget);
  });

  testWidgets('달력에서 날짜를 누르면 그날 기록이 열린다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('달력'));
    await tester.pumpAndSettle();
    expect(find.text('11월 요약'), findsOneWidget);
    expect(find.text('이번 달 5번 기록 · 처음 간 곳 4곳'), findsOneWidget);

    await tester.tap(find.text('7'));
    await tester.pumpAndSettle();
    expect(find.text('11월 7일 (토)'), findsOneWidget);
    expect(find.text('스시 하루'), findsOneWidget);
    expect(find.text('"광어가 특히 좋았음"'), findsOneWidget);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('기록을 지웠어요'), findsOneWidget);
    expect(find.text('이번 달 4번 기록 · 처음 간 곳 3곳'), findsOneWidget);
  });

  testWidgets('설정에서 반경을 넓히면 주변 식당이 늘어난다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1km'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2km').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('주변'));
    await tester.pumpAndSettle();
    expect(find.text('전체 29'), findsOneWidget);
  });
}
