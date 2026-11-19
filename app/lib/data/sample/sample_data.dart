import '../../core/geo.dart';
import '../../domain/models/app_location.dart';
import '../../domain/models/cuisine.dart';
import '../../domain/models/meal_log.dart';
import '../../domain/models/restaurant.dart';
import '../../domain/models/weather.dart';

/// 서버와 DB를 붙이기 전까지 화면을 채우는 예시 데이터.
/// 서버 주소 없이 실행(예시 데이터 모드)하거나 테스트할 때만 쓴다.

const sampleLocations = [
  AppLocation(
    name: '성수동2가',
    lat: 37.5446,
    lng: 127.0559,
    detail: '서울 성동구 성수동2가',
  ),
  AppLocation(
    name: '정자동',
    lat: 37.3660,
    lng: 127.1085,
    detail: '경기 성남시 분당구 정자동',
  ),
  AppLocation(name: '강남역', lat: 37.4979, lng: 127.0276, detail: '서울 강남구 역삼동'),
  AppLocation(
    name: '판교역',
    lat: 37.3948,
    lng: 127.1112,
    detail: '경기 성남시 분당구 백현동',
  ),
];

/// 설정의 '예시 날씨'에서 고를 수 있는 날씨.
enum SampleWeather {
  rain(
    '비 · 9℃',
    Weather(tempC: 9, precipitation: Precipitation.rain, sky: Sky.cloudy),
  ),
  clear('맑음 · 19℃', Weather(tempC: 19, dust: DustLevel.good)),
  hot('폭염 · 31℃', Weather(tempC: 31)),
  cold('한파 · -3℃', Weather(tempC: -3)),
  dust(
    '미세먼지 나쁨 · 14℃',
    Weather(tempC: 14, sky: Sky.cloudy, dust: DustLevel.bad),
  );

  const SampleWeather(this.label, this.weather);

  final String label;
  final Weather weather;
}

class _Seed {
  const _Seed(
    this.n,
    this.name,
    this.cuisine,
    this.sub,
    this.tags,
    this.eastM,
    this.northM,
    this.road,
  );

  final int n;
  final String name;
  final Cuisine cuisine;
  final String sub;
  final List<String> tags;
  final double eastM;
  final double northM;
  final String road;
}

const _k = Cuisine.korean, _c = Cuisine.chinese, _j = Cuisine.japanese;
const _w = Cuisine.western, _e = Cuisine.etc;

const _seeds = [
  _Seed(1, '성수 할매순대국', _k, '순대국', ['국밥', '국물', '순대국'], 80, -90, '성수이로 12길 3'),
  _Seed(2, '뚝섬 김치찌개', _k, '김치찌개', ['찌개', '국물', '매운'], -210, 150, '뚝섬로 1나길 15'),
  _Seed(3, '골목 칼국수', _k, '칼국수', ['칼국수', '국물'], 400, 500, '성수일로 8길 22'),
  _Seed(4, '서울숲 고깃집', _k, '삼겹살', ['고기', '구이'], -350, -300, '왕십리로 5길 9'),
  _Seed(5, '평양냉면 연', _k, '냉면', ['냉면', '냉'], 600, -350, '아차산로 17길 48'),
  _Seed(6, '성수 감자탕', _k, '감자탕', ['탕', '국물', '매운'], -150, 620, '성덕정길 34'),
  _Seed(7, '엄마손 분식', _k, '떡볶이', ['분식', '매운'], 120, 260, '연무장길 41'),
  _Seed(8, '새벽 해장국', _k, '해장국', ['국밥', '국물', '탕'], -700, 200, '성수이로 7길 27'),
  _Seed(9, '두부마을 전골', _k, '두부전골', ['전골', '국물'], 520, 640, '상원길 16'),
  _Seed(10, '진짬뽕', _c, '짬뽕', ['짬뽕', '국물', '매운'], 300, -230, '성수이로 20길 5'),
  _Seed(11, '홍마라', _c, '마라탕', ['마라탕', '국물', '매운'], -420, -520, '서울숲길 17'),
  _Seed(12, '성수 반점', _c, '짜장면', ['짜장면', '튀김'], -90, -480, '뚝섬로 13길 8'),
  _Seed(13, '하얼빈 양꼬치', _c, '양꼬치', ['양꼬치', '구이', '고기'], 760, 120, '아차산로 78'),
  _Seed(14, '스시 하루', _j, '초밥', ['초밥', '회'], -180, -150, '연무장5길 12'),
  _Seed(15, '라멘 하나비', _j, '라멘', ['라멘', '국물'], 450, 80, '성수일로 4길 30'),
  _Seed(16, '카츠 성수', _j, '돈까스', ['돈까스', '튀김'], -520, 380, '성수이로 22길 37'),
  _Seed(17, '소바 키노', _j, '소바', ['소바', '냉'], 230, 820, '광나루로 6길 10'),
  _Seed(
    18,
    '샤브 정원',
    _j,
    '샤브샤브',
    ['샤브샤브', '전골', '국물', '고기'],
    -640,
    -560,
    '서울숲2길 32',
  ),
  _Seed(19, '트라토리아 성수', _w, '파스타', ['파스타'], 160, -360, '연무장길 7'),
  _Seed(20, '루카 화덕피자', _w, '피자', ['피자'], -300, 520, '서울숲4길 19'),
  _Seed(21, '스테이크 72', _w, '스테이크', ['스테이크', '고기', '구이'], 700, -620, '아차산로 49'),
  _Seed(22, '버거 클럽', _w, '햄버거', ['햄버거', '튀김'], -60, 380, '성수일로 10길 14'),
  _Seed(23, '그린볼 샐러드', _w, '샐러드', ['샐러드', '냉'], 340, 300, '연무장7길 6'),
  _Seed(24, '포 사이공', _e, '쌀국수', ['쌀국수', '국물'], -260, 60, '뚝섬로 9길 11'),
  _Seed(25, '성수 이자카야', _e, '이자카야', ['술집'], 580, 400, '성수이로 24길 2'),
  // 여기부터는 1km 밖. 반경을 2km로 넓히면 보인다.
  _Seed(26, '왕십리 곱창', _k, '곱창', ['곱창', '구이', '고기'], -1150, -700, '왕십리로 21'),
  _Seed(27, '훠궈 하우스', _c, '훠궈', ['훠궈', '국물', '매운'], 1300, 600, '광나루로 130'),
  _Seed(28, '오마카세 미루', _j, '오마카세', ['초밥', '회'], 900, 1100, '성수이로 26길 18'),
  _Seed(29, '브런치 라운지', _w, '브런치', ['브런치'], -1400, 300, '서울숲6길 3'),
];

String sampleRestaurantId(int n) => 'sample-$n';

/// 주어진 위치 주변에 예시 식당을 놓는다. 어느 위치를 골라도 같은 식당이 같은 거리에 나온다.
List<Restaurant> sampleRestaurantsAround(double lat, double lng) {
  return [
    for (final s in _seeds)
      () {
        final at = offsetLatLng(lat, lng, eastM: s.eastM, northM: s.northM);
        return Restaurant(
          id: sampleRestaurantId(s.n),
          name: s.name,
          categoryRaw: '음식점 > ${s.cuisine.label} > ${s.sub}',
          cuisine: s.cuisine,
          subCategory: s.sub,
          tags: s.tags,
          roadAddress: '서울 성동구 ${s.road}',
          phone: '02-555-01${(s.n + 9).toString().padLeft(2, '0')}',
          lat: at.lat,
          lng: at.lng,
        );
      }(),
  ];
}

/// 오늘을 기준으로 지난 날짜에 놓은 예시 기록.
List<MealLog> sampleMealLogs(DateTime today) {
  final base = DateTime(today.year, today.month, today.day);
  var nextId = 1;
  MealLog log(
    int daysAgo,
    int? seedNo,
    String menu,
    int rating,
    String weather, {
    String memo = '',
    MealType meal = MealType.dinner,
    String? name,
    Cuisine? cuisine,
  }) {
    final seed = seedNo == null
        ? null
        : _seeds.firstWhere((s) => s.n == seedNo);
    return MealLog(
      id: nextId++,
      date: base.subtract(Duration(days: daysAgo)),
      mealType: meal,
      restaurantId: seedNo == null ? null : sampleRestaurantId(seedNo),
      restaurantName: seed?.name ?? name!,
      cuisine: seed?.cuisine ?? cuisine!,
      menu: menu,
      rating: rating,
      memo: memo,
      weatherText: weather,
    );
  }

  return [
    log(1, 19, '봉골레 파스타', 4, '🌤 맑음 · 16℃'),
    log(2, 14, '모둠초밥', 5, '☔ 비 · 11℃', memo: '광어가 특히 좋았음'),
    log(4, 2, '김치찌개', 4, '☁️ 흐림 · 12℃'),
    log(6, 10, '짬뽕', 3, '🌤 맑음 · 14℃', memo: '조금 짰음'),
    log(
      6,
      null,
      '제육볶음',
      3,
      '🌤 맑음 · 14℃',
      meal: MealType.lunch,
      name: '회사 구내식당',
      cuisine: Cuisine.korean,
    ),
    log(12, 1, '순대국', 4, '☁️ 흐림 · 13℃', memo: '얼큰함'),
    log(16, 22, '치즈버거', 4, '🌤 맑음 · 17℃'),
    log(19, 15, '돈코츠 라멘', 5, '☔ 비 · 15℃', memo: '국물 진함, 또 갈 것'),
    log(23, 4, '삼겹살', 4, '🌤 맑음 · 18℃'),
    log(31, 20, '마르게리타', 4, '🌤 맑음 · 21℃'),
    log(38, 1, '순대국밥', 3, '☁️ 흐림 · 20℃'),
  ];
}
