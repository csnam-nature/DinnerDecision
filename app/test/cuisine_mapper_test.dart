import 'package:dinner_decision/domain/models/cuisine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  final mapper = loadTestConfig().cuisineMapper;

  test('두 번째 단계로 분류를 정한다', () {
    expect(mapper.classify('음식점 > 한식 > 해장국').cuisine, Cuisine.korean);
    expect(mapper.classify('음식점 > 분식').cuisine, Cuisine.korean);
    expect(mapper.classify('음식점 > 중식 > 중국요리').cuisine, Cuisine.chinese);
    expect(mapper.classify('음식점 > 일식 > 초밥,롤').cuisine, Cuisine.japanese);
    expect(mapper.classify('음식점 > 양식 > 이탈리안').cuisine, Cuisine.western);
    expect(mapper.classify('음식점 > 패스트푸드 > 햄버거').cuisine, Cuisine.western);
    expect(mapper.classify('음식점 > 치킨').cuisine, Cuisine.western);
  });

  test('목록에 없는 분류는 기타', () {
    expect(mapper.classify('음식점 > 아시아음식 > 베트남음식').cuisine, Cuisine.etc);
    expect(mapper.classify('음식점 > 술집 > 호프,요리주점').cuisine, Cuisine.etc);
    expect(mapper.classify('').cuisine, Cuisine.etc);
  });

  test('떡·한과는 한식으로 본다', () {
    expect(mapper.classify('음식점 > 간식 > 떡,한과').cuisine, Cuisine.korean);
    expect(mapper.classify('음식점 > 간식 > 제과,베이커리').cuisine, Cuisine.etc);
  });

  test('세부 분류와 태그를 뽑는다', () {
    final result = mapper.classify('음식점 > 한식 > 해장국');
    expect(result.subCategory, '해장국');
    expect(result.tags, containsAll(['국밥', '국물', '탕', '해장국']));

    expect(mapper.classify('음식점 > 일식 > 초밥,롤').tags, containsAll(['초밥', '회']));
    expect(mapper.classify('음식점 > 한식 > 냉면').tags, contains('냉'));
  });

  group('실제 카카오 분류 (2026-11-19 성수동 주변 응답)', () {
    // (카카오 분류, 앱 분류, 화면에 보일 세부 분류)
    const cases = [
      ('음식점 > 한식', Cuisine.korean, '한식'),
      ('음식점 > 중식 > 중국요리', Cuisine.chinese, '중국요리'),
      ('음식점 > 한식 > 육류,고기', Cuisine.korean, '육류/고기'),
      ('음식점 > 간식 > 제과,베이커리', Cuisine.etc, '제과/베이커리'),
      ('음식점 > 일식 > 일본식라면', Cuisine.japanese, '일본식라면'),
      ('음식점 > 중식', Cuisine.chinese, '중식'),
      ('음식점 > 한식 > 국밥', Cuisine.korean, '국밥'),
      ('음식점 > 한식 > 육류,고기 > 닭요리', Cuisine.korean, '닭요리'),
      ('음식점 > 한식 > 해물,생선', Cuisine.korean, '해물/생선'),
      ('음식점 > 한식 > 육류,고기 > 삼겹살', Cuisine.korean, '삼겹살'),
      ('음식점 > 술집 > 일본식주점', Cuisine.etc, '일본식주점'),
      ('음식점 > 한식 > 육류,고기 > 갈비', Cuisine.korean, '갈비'),
      ('음식점 > 한식 > 국수', Cuisine.korean, '국수'),
      ('음식점 > 한식 > 국수 > 칼국수', Cuisine.korean, '칼국수'),
      ('음식점 > 양식', Cuisine.western, '양식'),
      ('음식점 > 분식', Cuisine.korean, '분식'),
      ('음식점 > 샐러드', Cuisine.western, '샐러드'),
      ('음식점 > 아시아음식 > 동남아음식 > 베트남음식', Cuisine.etc, '베트남음식'),
      ('음식점 > 한식 > 국밥 > 완산골명가', Cuisine.korean, '국밥'),
      ('음식점 > 한식 > 순대', Cuisine.korean, '순대'),
      ('음식점 > 한식 > 찌개,전골', Cuisine.korean, '찌개/전골'),
      ('음식점 > 분식 > 떡볶이', Cuisine.korean, '떡볶이'),
      ('음식점 > 양식 > 피자', Cuisine.western, '피자'),
      ('음식점 > 술집 > 칵테일바', Cuisine.etc, '칵테일바'),
      ('음식점 > 한식 > 해물,생선 > 회', Cuisine.korean, '회'),
      ('음식점 > 일식 > 돈까스,우동', Cuisine.japanese, '돈까스/우동'),
      ('음식점 > 한식 > 해물,생선 > 매운탕,해물탕', Cuisine.korean, '매운탕/해물탕'),
      ('음식점 > 일식 > 초밥,롤', Cuisine.japanese, '초밥/롤'),
      ('음식점 > 아시아음식 > 동남아음식 > 태국음식', Cuisine.etc, '태국음식'),
      ('음식점 > 술집 > 호프,요리주점', Cuisine.etc, '호프/요리주점'),
      ('음식점 > 한식 > 육류,고기 > 족발,보쌈', Cuisine.korean, '족발/보쌈'),
      ('음식점 > 한식 > 육류,고기 > 교대이층집', Cuisine.korean, '육류/고기'),
      ('음식점 > 한식 > 해물,생선 > 조개 > 갯벌의조개', Cuisine.korean, '조개'),
      ('음식점 > 술집 > 와인바', Cuisine.etc, '와인바'),
      ('음식점 > 한식 > 육류,고기 > 닭요리 > 보끔당', Cuisine.korean, '닭요리'),
      ('음식점 > 패스트푸드 > 샌드위치 > 써브웨이', Cuisine.western, '샌드위치'),
      ('음식점 > 한식 > 순대 > 순대실록', Cuisine.korean, '순대'),
      ('음식점 > 양식 > 햄버거', Cuisine.western, '햄버거'),
      ('음식점 > 일식', Cuisine.japanese, '일식'),
      ('음식점 > 치킨 > 맛닭꼬', Cuisine.western, '치킨'),
      ('음식점 > 간식 > 제과,베이커리 > 뚜레쥬르', Cuisine.etc, '제과/베이커리'),
      ('음식점 > 패스트푸드 > 롯데리아', Cuisine.western, '패스트푸드'),
    ];

    for (final (raw, cuisine, sub) in cases) {
      test(raw, () {
        final result = mapper.classify(raw);
        expect(result.cuisine, cuisine);
        expect(result.subCategory, sub);
      });
    }

    test('가게 이름은 세부 분류·태그에 들어가지 않는다', () {
      for (final brand in ['완산골명가', '롯데리아', '써브웨이', '뚜레쥬르', '맛닭꼬']) {
        for (final (raw, _, _) in cases.where((c) => c.$1.contains(brand))) {
          final result = mapper.classify(raw);
          expect(result.subCategory, isNot(brand), reason: raw);
          expect(result.tags, isNot(contains(brand)), reason: raw);
        }
      }
    });

    test('날씨 추천에 쓰는 태그가 붙는다', () {
      expect(
        mapper.classify('음식점 > 일식 > 일본식라면').tags,
        containsAll(['라멘', '국물']),
      );
      expect(
        mapper.classify('음식점 > 한식 > 해물,생선 > 매운탕,해물탕').tags,
        containsAll(['탕', '국물']),
      );
      expect(mapper.classify('음식점 > 한식 > 해물,생선 > 회').tags, contains('회'));
      expect(
        mapper.classify('음식점 > 일식 > 돈까스,우동').tags,
        containsAll(['돈까스', '우동']),
      );
      expect(
        mapper.classify('음식점 > 한식 > 찌개,전골').tags,
        containsAll(['찌개', '전골', '국물']),
      );
      expect(mapper.classify('음식점 > 한식 > 국밥 > 완산골명가').tags, contains('국밥'));
      expect(mapper.classify('음식점 > 샐러드').tags, contains('샐러드'));
      expect(
        mapper.classify('음식점 > 한식 > 육류,고기 > 갈비').tags,
        containsAll(['고기', '구이']),
      );
    });
  });
}
