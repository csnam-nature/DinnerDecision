import 'package:dinner_decision/core/dates.dart';
import 'package:dinner_decision/core/geo.dart';
import 'package:dinner_decision/core/korean.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('거리', () {
    test('동쪽으로 300m, 북쪽으로 400m 옮기면 500m 떨어져 있다', () {
      const lat = 37.5446, lng = 127.0559;
      final moved = offsetLatLng(lat, lng, eastM: 300, northM: 400);
      expect(distanceMeters(lat, lng, moved.lat, moved.lng), closeTo(500, 3));

      final back = metersOffset(
        fromLat: lat,
        fromLng: lng,
        toLat: moved.lat,
        toLng: moved.lng,
      );
      expect(back.eastM, closeTo(300, 1));
      expect(back.northM, closeTo(400, 1));
    });

    test('거리 글자와 걷는 시간', () {
      expect(formatDistance(420), '420m');
      expect(formatDistance(1000), '1.0km');
      expect(formatDistance(1350), '1.4km');
      expect(walkMinutes(20), 1);
      expect(walkMinutes(450), 6);
    });
  });

  group('조사', () {
    test('받침이 있으면 앞의 조사, 없으면 뒤의 조사', () {
      expect(josa('한식', '을', '를'), '한식을');
      expect(josa('순대국', '이', '가'), '순대국이');
      expect(josa('마라탕', '을', '를'), '마라탕을');
      expect(josa('소바', '을', '를'), '소바를');
      expect(josa('비', '이', '가'), '비가');
    });

    test('으로/로는 ㄹ 받침 뒤에 로를 쓴다', () {
      expect(josa('한식', '으로', '로'), '한식으로');
      expect(josa('성수동2가', '으로', '로'), '성수동2가로');
      expect(josa('서울', '으로', '로'), '서울로');
    });
  });

  group('날짜', () {
    test('지난 날 수는 시각을 무시한다', () {
      expect(
        daysBetween(DateTime(2026, 11, 8, 23, 59), DateTime(2026, 11, 9, 0, 1)),
        1,
      );
      expect(
        daysBetween(DateTime(2026, 10, 28), DateTime(2026, 11, 9, 18)),
        12,
      );
    });

    test('표시 글자', () {
      expect(formatMonthDay(DateTime(2026, 11, 7)), '11/7 (토)');
      expect(formatFullDate(DateTime(2026, 11, 9)), '2026-11-09 (월)');
      expect(relativeDay(0), '오늘');
      expect(relativeDay(2), '그제');
      expect(relativeDay(5), '5일 전');
    });
  });
}
