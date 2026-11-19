import 'models/cuisine.dart';

/// 카카오 분류 글자를 앱 분류와 세부 메뉴 태그로 바꾼다.
/// 규칙은 assets/config/cuisine_mapping.json 에서 읽는다.
class CuisineMapper {
  const CuisineMapper({
    required this.level2,
    required this.byKeyword,
    required this.tagKeywords,
    this.categories = const {},
  });

  factory CuisineMapper.fromJson(Map<String, dynamic> json) {
    Cuisine parse(Object? name) => Cuisine.values.byName(name as String);
    return CuisineMapper(
      level2: {
        for (final e in (json['level2'] as Map<String, dynamic>).entries)
          e.key: parse(e.value),
      },
      byKeyword: [
        for (final item in json['byKeyword'] as List<dynamic>)
          (
            contains: item['contains'] as String,
            cuisine: parse(item['cuisine']),
          ),
      ],
      categories: {
        for (final name in json['categories'] as List<dynamic>? ?? const [])
          name as String,
      },
      tagKeywords: {
        for (final e in (json['tagKeywords'] as Map<String, dynamic>).entries)
          e.key: List<String>.from(e.value as List<dynamic>),
      },
    );
  }

  /// 분류 두 번째 단계 → 앱 분류. 예: 분식 → 한식
  final Map<String, Cuisine> level2;

  /// 두 번째 단계로 못 정했을 때 글자가 들어 있으면 적용. 예: 떡 → 한식
  final List<({String contains, Cuisine cuisine})> byKeyword;

  /// 분류 글자에 들어 있으면 붙이는 태그. 예: 해장국 → 국밥, 국물, 탕
  final Map<String, List<String>> tagKeywords;

  /// 세 번째 단계부터 세부 분류로 인정하는 이름. 나머지는 가게 이름(프랜차이즈)으로 본다.
  /// 예: '음식점 > 한식 > 국밥 > 완산골명가'의 '완산골명가'
  final Set<String> categories;

  /// 쉼표가 들어간 이름(예: 육류,고기)은 카카오 분류 이름이라 목록에 없어도 분류로 본다.
  bool _isCategory(String name) =>
      categories.contains(name) || name.contains(',');

  /// 예: "음식점 > 한식 > 해장국" → (한식, 해장국, [국밥, 국물, 탕, 해장국])
  ///     "음식점 > 패스트푸드 > 롯데리아" → (양식, 패스트푸드, [패스트푸드])
  ({Cuisine cuisine, String subCategory, List<String> tags}) classify(
    String categoryName,
  ) {
    final parts = categoryName
        .split('>')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    // 첫 단계는 항상 "음식점"이라 분류에 쓰지 않는다.
    final all = parts.length > 1 ? parts.sublist(1) : parts;
    // 두 번째 단계(한식, 중식 …)는 항상 분류다. 그 아래는 처음 나온 가게 이름 앞까지만 쓴다.
    final detail = <String>[];
    for (final (i, part) in all.indexed) {
      if (i > 0 && !_isCategory(part)) break;
      detail.add(part);
    }
    final joined = detail.join(' ');

    var cuisine = detail.isEmpty ? null : level2[detail.first];
    if (cuisine == null) {
      for (final rule in byKeyword) {
        if (joined.contains(rule.contains)) {
          cuisine = rule.cuisine;
          break;
        }
      }
    }

    // 화면에 보이는 글자라 '육류,고기'는 '육류/고기'로 바꾼다.
    final subCategory = detail.isEmpty ? '' : detail.last.replaceAll(',', '/');
    final tags = <String>{};
    for (final entry in tagKeywords.entries) {
      if (joined.contains(entry.key)) tags.addAll(entry.value);
    }
    if (subCategory.isNotEmpty) tags.add(subCategory);

    return (
      cuisine: cuisine ?? Cuisine.etc,
      subCategory: subCategory,
      tags: tags.toList(),
    );
  }
}
