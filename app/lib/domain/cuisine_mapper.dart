import 'models/cuisine.dart';

/// 카카오 분류 글자를 앱 분류와 세부 메뉴 태그로 바꾼다.
/// 규칙은 assets/config/cuisine_mapping.json 에서 읽는다.
class CuisineMapper {
  const CuisineMapper({
    required this.level2,
    required this.byKeyword,
    required this.tagKeywords,
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

  /// 예: "음식점 > 한식 > 해장국" → (한식, 해장국, [국밥, 국물, 탕, 해장국])
  ({Cuisine cuisine, String subCategory, List<String> tags}) classify(
    String categoryName,
  ) {
    final parts = categoryName
        .split('>')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    // 첫 단계는 항상 "음식점"이라 분류에 쓰지 않는다.
    final detail = parts.length > 1 ? parts.sublist(1) : parts;
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

    final subCategory = detail.isEmpty ? '' : detail.last;
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
