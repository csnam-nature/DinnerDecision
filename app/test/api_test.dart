import 'dart:convert';
import 'dart:typed_data';

import 'package:dinner_decision/data/api/api_client.dart';
import 'package:dinner_decision/data/repositories/location_repository.dart';
import 'package:dinner_decision/data/repositories/place_repository.dart';
import 'package:dinner_decision/domain/models/app_location.dart';
import 'package:dinner_decision/domain/models/cuisine.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// 서버 대신 응답하는 가짜 HTTP. 받은 요청을 [requests]에 쌓는다.
class FakeServer implements HttpClientAdapter {
  FakeServer(this.handler);

  final Object Function(RequestOptions request) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final result = handler(options);
    if (result is DioException) throw result;
    final (status, body) = result is (int, Object) ? result : (200, result);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient clientFor(FakeServer server, {TokenProvider? token}) {
  final dio = Dio()..httpClientAdapter = server;
  return ApiClient(baseUrl: 'https://api.test', dio: dio, appCheckToken: token);
}

Map<String, Object> place(String id, String category, {String road = ''}) => {
  'id': id,
  'name': '식당$id',
  'category': category,
  'phone': '',
  'address': '서울 성동구 성수동2가 1',
  'roadAddress': road,
  'lat': 37.5446,
  'lng': 127.0559,
  'url': 'http://place.map.kakao.com/$id',
  'distanceM': 120,
};

void main() {
  final mapper = loadTestConfig().cuisineMapper;

  group('ApiPlaceRepository', () {
    test('서버 식당을 앱 분류로 바꾼다', () async {
      final server = FakeServer(
        (_) => {
          'places': [
            place('1', '음식점 > 한식 > 해장국', road: '서울 성동구 성수이로 1'),
            place('2', '음식점 > 중식 > 중국요리'),
          ],
          'complete': true,
          'truncated': false,
        },
      );
      final repo = ApiPlaceRepository(
        client: clientFor(server),
        mapper: mapper,
      );
      final list = await repo.fetchNearby(
        lat: 37.5446,
        lng: 127.0559,
        radiusM: 1000,
      );

      expect(list.map((r) => r.cuisine), [Cuisine.korean, Cuisine.chinese]);
      expect(list.first.tags, containsAll(['국밥', '해장국']));
      expect(list.first.roadAddress, '서울 성동구 성수이로 1');
      // 도로명 주소가 없으면 지번 주소를 쓴다.
      expect(list.last.roadAddress, '서울 성동구 성수동2가 1');
      expect((await repo.findById('2'))?.name, '식당2');

      final request = server.requests.single;
      expect(request.path, '/places');
      expect(request.queryParameters, {
        'lat': '37.54460',
        'lng': '127.05590',
        'radius': 1000,
      });
    });

    test('서버가 일부만 주면 다 채울 때까지 다시 부른다 (최대 maxRounds)', () async {
      var round = 0;
      final server = FakeServer((_) {
        round++;
        return {
          'places': [for (var i = 0; i < round; i++) place('$i', '음식점 > 일식')],
          'complete': round >= 3,
        };
      });
      final repo = ApiPlaceRepository(
        client: clientFor(server),
        mapper: mapper,
      );
      final list = await repo.fetchNearby(lat: 37.5, lng: 127, radiusM: 1000);
      expect(server.requests, hasLength(3));
      expect(list, hasLength(3));
      expect(repo.lastComplete, isTrue);

      final limited = ApiPlaceRepository(
        client: clientFor(FakeServer((_) => {'places': [], 'complete': false})),
        mapper: mapper,
        maxRounds: 2,
      );
      await limited.fetchNearby(lat: 37.5, lng: 127, radiusM: 1000);
      expect(limited.lastComplete, isFalse);
    });

    test('서버 오류 코드와 네트워크 오류를 구분한다', () async {
      final rateLimited = ApiPlaceRepository(
        client: clientFor(
          FakeServer(
            (_) => (
              429,
              {
                'error': {'code': 'RATE_LIMITED', 'message': '요청이 너무 많습니다'},
              },
            ),
          ),
        ),
        mapper: mapper,
      );
      await expectLater(
        rateLimited.fetchNearby(lat: 37.5, lng: 127, radiusM: 1000),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'RATE_LIMITED')
              .having((e) => e.statusCode, 'status', 429),
        ),
      );

      final offline = ApiPlaceRepository(
        client: clientFor(
          FakeServer(
            (r) =>
                DioException.connectionError(requestOptions: r, reason: 'down'),
          ),
        ),
        mapper: mapper,
      );
      await expectLater(
        offline.fetchNearby(lat: 37.5, lng: 127, radiusM: 1000),
        throwsA(
          isA<ApiException>().having((e) => e.isOffline, 'offline', true),
        ),
      );
    });

    test('App Check 토큰이 있으면 헤더로 보낸다', () async {
      final server = FakeServer((_) => {'places': [], 'complete': true});
      final repo = ApiPlaceRepository(
        client: clientFor(server, token: () async => 'token-123'),
        mapper: mapper,
      );
      await repo.fetchNearby(lat: 37.5, lng: 127, radiusM: 500);
      expect(
        server.requests.single.headers['X-Firebase-AppCheck'],
        'token-123',
      );
    });
  });

  group('DeviceLocationRepository.search', () {
    test('검색 결과를 위치로 바꾼다', () async {
      final server = FakeServer(
        (_) => {
          'results': [
            {
              'name': '강남역 2호선',
              'detail': '서울 강남구 강남대로 396',
              'lat': 37.4979,
              'lng': 127.0276,
            },
          ],
        },
      );
      final repo = DeviceLocationRepository(clientFor(server));
      final results = await repo.search('강남역');
      expect(results.single.name, '강남역 2호선');
      expect(results.single.source, LocationSource.search);
      expect(server.requests.single.queryParameters, {'query': '강남역'});
    });
  });
}
