import '../models/restaurant.dart';

/// 추천 이유의 종류. 점수 규칙마다 하나씩 남긴다 (PLAN.md 9.4).
enum ReasonCode {
  newPlace,
  longAgo,
  cuisineRotate,
  weatherWet,
  weatherCold,
  weatherHot,
  weatherNice,
  weatherDusty,
  ratedHigh,
  near,
}

class Reason {
  const Reason({
    required this.code,
    required this.points,
    required this.emoji,
    required this.text,
    required this.short,
  });

  final ReasonCode code;

  /// 이 이유가 더한 점수. 큰 순서로 화면에 보인다.
  final double points;
  final String emoji;

  /// 큰 카드에 보이는 문장.
  final String text;

  /// 작은 후보 카드에 보이는 한마디.
  final String short;
}

class Recommendation {
  const Recommendation({
    required this.place,
    required this.score,
    required this.reasons,
  });

  final NearbyPlace place;
  final int score;

  /// 점수가 큰 이유부터 최대 3개, 마지막은 항상 거리.
  final List<Reason> reasons;
}

class RecommendResult {
  const RecommendResult({
    required this.picks,
    required this.candidateCount,
    required this.relaxed,
  });

  /// 점수가 높은 순서. 첫 번째를 큰 카드로 보여준다.
  final List<Recommendation> picks;
  final int candidateCount;

  /// 후보가 너무 적어서 '같은 식당 피하기' 기간을 3일로 줄였는지.
  final bool relaxed;
}
