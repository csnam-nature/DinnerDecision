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
}
