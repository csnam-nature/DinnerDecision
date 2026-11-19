import 'package:dinner_decision/app/app.dart';
import 'package:dinner_decision/app/widgets/naver_map_view.dart';
import 'package:dinner_decision/core/map_links.dart';
import 'package:dinner_decision/data/external_launcher.dart';
import 'package:dinner_decision/data/providers.dart';
import 'package:dinner_decision/data/repositories/place_repository.dart';
import 'package:dinner_decision/domain/models/cuisine.dart';
import 'package:dinner_decision/domain/models/restaurant.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

/// 연 주소를 기억하는 가짜. [installed]에 있는 스킴만 앱이 있다고 답한다.
class FakeLauncher implements ExternalLauncher {
  FakeLauncher({this.installed = const {}, this.canOpenAnything = true});

  final Set<String> installed;
  final bool canOpenAnything;
  final opened = <Uri>[];

  @override
  Future<bool> canOpen(Uri uri) async => installed.contains(uri.scheme);

  @override
  Future<bool> open(Uri uri) async {
    if (!canOpenAnything && !installed.contains(uri.scheme)) return false;
    opened.add(uri);
    return true;
  }
}

const restaurant = Restaurant(
  id: '123',
  name: '성수 할매순대국',
  categoryRaw: '음식점 > 한식 > 순대',
  cuisine: Cuisine.korean,
  subCategory: '순대',
  tags: ['국밥'],
  roadAddress: '서울 성동구 성수이로 12길 3',
  phone: '02-555-0110',
  lat: 37.5446,
  lng: 127.0559,
  kakaoUrl: 'http://place.map.kakao.com/123',
);

void main() {
  group('주소 만들기', () {
    test('네이버 지도 앱 장소·도보 길찾기', () {
      final place = naverMapPlace(
        name: '성수 할매순대국',
        lat: 37.5446,
        lng: 127.0559,
      );
      expect(place.scheme, 'nmap');
      expect(place.host, 'place');
      expect(place.queryParameters, {
        'lat': '37.5446000',
        'lng': '127.0559000',
        'name': '성수 할매순대국',
        'appname': 'kr.naturetec.dinnerdecision',
      });
      // 공백은 + 가 아니라 %20 (네이버 지도 URL 스킴 예시와 같게)
      expect(place.toString(), contains('name=%EC%84%B1%EC%88%98%20'));

      final route = naverMapWalkRoute(name: 'A&B', lat: 37.5, lng: 127);
      expect(route.host, 'route');
      expect(route.path, '/walk');
      expect(route.queryParameters['dname'], 'A&B');
      expect(route.queryParameters.containsKey('slat'), isFalse);
    });

    test('네이버 지도 웹은 동네 이름을 붙여 검색한다', () {
      expect(
        naverMapWeb(name: '진짬뽕', area: '성동구').toString(),
        'https://map.naver.com/p/search/%EC%A7%84%EC%A7%AC%EB%BD%95%20%EC%84%B1%EB%8F%99%EA%B5%AC',
      );
      expect(areaOf('서울 성동구 성수이로 12길 3'), '성동구');
      expect(areaOf('경기 성남시 분당구 정자일로 95'), '분당구');
      expect(areaOf('경기 양평군 양평읍 시민로 1'), '양평군');
      expect(areaOf(''), '');
    });

    test('카카오 장소는 https로, 전화는 숫자만', () {
      expect(
        kakaoPlace('http://place.map.kakao.com/123').toString(),
        'https://place.map.kakao.com/123',
      );
      expect(kakaoPlace(null), isNull);
      expect(kakaoPlace(''), isNull);
      expect(phoneCall('02-555-0110').toString(), 'tel:025550110');
      expect(phoneCall(''), isNull);
    });

    test('처음 줌 레벨은 반경이 넓을수록 작다', () {
      final z1 = initialZoom(spanM: 1080, lat: 37.5, sizePx: 390);
      final z2 = initialZoom(spanM: 2160, lat: 37.5, sizePx: 390);
      expect(z1, inInclusiveRange(13, 16));
      expect(z1 - z2, closeTo(1, 0.01));
      expect(initialZoom(spanM: 1000, lat: 37.5, sizePx: 0), 15);
    });
  });

  group('RestaurantLinks', () {
    test('네이버 지도 앱이 있으면 앱으로 연다', () async {
      final launcher = FakeLauncher(installed: {'nmap'});
      final result = await RestaurantLinks(launcher).openNaverMap(restaurant);
      expect(result, OpenResult.app);
      expect(launcher.opened.single.scheme, 'nmap');
    });

    test('앱이 없으면 네이버 지도 웹으로 연다', () async {
      final launcher = FakeLauncher();
      final links = RestaurantLinks(launcher);
      expect(await links.openWalkRoute(restaurant), OpenResult.web);
      expect(launcher.opened.single.host, 'map.naver.com');
    });

    test('카카오 장소·전화', () async {
      final launcher = FakeLauncher();
      final links = RestaurantLinks(launcher);
      expect(await links.openKakaoPlace(restaurant), OpenResult.app);
      expect(await links.call(restaurant), OpenResult.app);
      expect(launcher.opened.map((u) => u.scheme), ['https', 'tel']);
    });

    test('열 수 없으면 failed', () async {
      final links = RestaurantLinks(FakeLauncher(canOpenAnything: false));
      expect(await links.openNaverMap(restaurant), OpenResult.failed);
      expect(
        await links.call(
          const Restaurant(
            id: '1',
            name: 'x',
            categoryRaw: '',
            cuisine: Cuisine.etc,
            subCategory: '',
            tags: [],
            roadAddress: '',
            phone: '',
            lat: 0,
            lng: 0,
          ),
        ),
        OpenResult.failed,
      );
    });
  });

  testWidgets('식당 상세의 버튼이 외부 앱을 연다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final launcher = FakeLauncher(installed: {'nmap'});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(loadTestConfig()),
          clockProvider.overrideWithValue(() => testToday),
          placeRepositoryProvider.overrideWithValue(
            FakePlaceRepository(delay: Duration.zero),
          ),
          externalLauncherProvider.overrideWithValue(launcher),
        ],
        child: const DinnerDecisionApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('성수 할매순대국'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('네이버 지도'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('길찾기'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('02-555'));
    await tester.pumpAndSettle();

    expect(launcher.opened.map((u) => '${u.scheme}:${u.host}'), [
      'nmap:place',
      'nmap:route',
      'tel:',
    ]);
    // 예시 식당은 카카오 주소가 없어 카카오 버튼을 숨긴다.
    expect(find.textContaining('카카오 장소 정보'), findsNothing);

    await tester.tap(find.text('서울 성동구 성수이로 12길 3'));
    await tester.pump();
    expect(find.text('주소를 복사했어요'), findsOneWidget);
  });
}
