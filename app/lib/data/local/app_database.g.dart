// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MealLogRowsTable extends MealLogRows
    with TableInfo<$MealLogRowsTable, MealLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealLogRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealTypeMeta = const VerificationMeta(
    'mealType',
  );
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
    'meal_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restaurantIdMeta = const VerificationMeta(
    'restaurantId',
  );
  @override
  late final GeneratedColumn<String> restaurantId = GeneratedColumn<String>(
    'restaurant_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restaurantNameMeta = const VerificationMeta(
    'restaurantName',
  );
  @override
  late final GeneratedColumn<String> restaurantName = GeneratedColumn<String>(
    'restaurant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuisineMeta = const VerificationMeta(
    'cuisine',
  );
  @override
  late final GeneratedColumn<String> cuisine = GeneratedColumn<String>(
    'cuisine',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _menuMeta = const VerificationMeta('menu');
  @override
  late final GeneratedColumn<String> menu = GeneratedColumn<String>(
    'menu',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<String> photo = GeneratedColumn<String>(
    'photo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weatherTextMeta = const VerificationMeta(
    'weatherText',
  );
  @override
  late final GeneratedColumn<String> weatherText = GeneratedColumn<String>(
    'weather_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fromRecommendMeta = const VerificationMeta(
    'fromRecommend',
  );
  @override
  late final GeneratedColumn<bool> fromRecommend = GeneratedColumn<bool>(
    'from_recommend',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("from_recommend" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    mealType,
    restaurantId,
    restaurantName,
    cuisine,
    menu,
    rating,
    memo,
    photo,
    weatherText,
    fromRecommend,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('meal_type')) {
      context.handle(
        _mealTypeMeta,
        mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mealTypeMeta);
    }
    if (data.containsKey('restaurant_id')) {
      context.handle(
        _restaurantIdMeta,
        restaurantId.isAcceptableOrUnknown(
          data['restaurant_id']!,
          _restaurantIdMeta,
        ),
      );
    }
    if (data.containsKey('restaurant_name')) {
      context.handle(
        _restaurantNameMeta,
        restaurantName.isAcceptableOrUnknown(
          data['restaurant_name']!,
          _restaurantNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_restaurantNameMeta);
    }
    if (data.containsKey('cuisine')) {
      context.handle(
        _cuisineMeta,
        cuisine.isAcceptableOrUnknown(data['cuisine']!, _cuisineMeta),
      );
    } else if (isInserting) {
      context.missing(_cuisineMeta);
    }
    if (data.containsKey('menu')) {
      context.handle(
        _menuMeta,
        menu.isAcceptableOrUnknown(data['menu']!, _menuMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('photo')) {
      context.handle(
        _photoMeta,
        photo.isAcceptableOrUnknown(data['photo']!, _photoMeta),
      );
    }
    if (data.containsKey('weather_text')) {
      context.handle(
        _weatherTextMeta,
        weatherText.isAcceptableOrUnknown(
          data['weather_text']!,
          _weatherTextMeta,
        ),
      );
    }
    if (data.containsKey('from_recommend')) {
      context.handle(
        _fromRecommendMeta,
        fromRecommend.isAcceptableOrUnknown(
          data['from_recommend']!,
          _fromRecommendMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      mealType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_type'],
      )!,
      restaurantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}restaurant_id'],
      ),
      restaurantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}restaurant_name'],
      )!,
      cuisine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuisine'],
      )!,
      menu: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}menu'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      )!,
      photo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo'],
      ),
      weatherText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weather_text'],
      )!,
      fromRecommend: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}from_recommend'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MealLogRowsTable createAlias(String alias) {
    return $MealLogRowsTable(attachedDatabase, alias);
  }
}

class MealLogRow extends DataClass implements Insertable<MealLogRow> {
  final int id;

  /// yyyy-MM-dd. 시간대가 바뀌어도 날짜가 밀리지 않게 글자로 둔다.
  final String date;
  final String mealType;
  final String? restaurantId;
  final String restaurantName;
  final String cuisine;
  final String menu;
  final int rating;
  final String memo;

  /// 앱 폴더 photos/ 안의 파일 이름.
  final String? photo;
  final String weatherText;
  final bool fromRecommend;
  final DateTime updatedAt;
  const MealLogRow({
    required this.id,
    required this.date,
    required this.mealType,
    this.restaurantId,
    required this.restaurantName,
    required this.cuisine,
    required this.menu,
    required this.rating,
    required this.memo,
    this.photo,
    required this.weatherText,
    required this.fromRecommend,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['meal_type'] = Variable<String>(mealType);
    if (!nullToAbsent || restaurantId != null) {
      map['restaurant_id'] = Variable<String>(restaurantId);
    }
    map['restaurant_name'] = Variable<String>(restaurantName);
    map['cuisine'] = Variable<String>(cuisine);
    map['menu'] = Variable<String>(menu);
    map['rating'] = Variable<int>(rating);
    map['memo'] = Variable<String>(memo);
    if (!nullToAbsent || photo != null) {
      map['photo'] = Variable<String>(photo);
    }
    map['weather_text'] = Variable<String>(weatherText);
    map['from_recommend'] = Variable<bool>(fromRecommend);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MealLogRowsCompanion toCompanion(bool nullToAbsent) {
    return MealLogRowsCompanion(
      id: Value(id),
      date: Value(date),
      mealType: Value(mealType),
      restaurantId: restaurantId == null && nullToAbsent
          ? const Value.absent()
          : Value(restaurantId),
      restaurantName: Value(restaurantName),
      cuisine: Value(cuisine),
      menu: Value(menu),
      rating: Value(rating),
      memo: Value(memo),
      photo: photo == null && nullToAbsent
          ? const Value.absent()
          : Value(photo),
      weatherText: Value(weatherText),
      fromRecommend: Value(fromRecommend),
      updatedAt: Value(updatedAt),
    );
  }

  factory MealLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealLogRow(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      mealType: serializer.fromJson<String>(json['mealType']),
      restaurantId: serializer.fromJson<String?>(json['restaurantId']),
      restaurantName: serializer.fromJson<String>(json['restaurantName']),
      cuisine: serializer.fromJson<String>(json['cuisine']),
      menu: serializer.fromJson<String>(json['menu']),
      rating: serializer.fromJson<int>(json['rating']),
      memo: serializer.fromJson<String>(json['memo']),
      photo: serializer.fromJson<String?>(json['photo']),
      weatherText: serializer.fromJson<String>(json['weatherText']),
      fromRecommend: serializer.fromJson<bool>(json['fromRecommend']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'mealType': serializer.toJson<String>(mealType),
      'restaurantId': serializer.toJson<String?>(restaurantId),
      'restaurantName': serializer.toJson<String>(restaurantName),
      'cuisine': serializer.toJson<String>(cuisine),
      'menu': serializer.toJson<String>(menu),
      'rating': serializer.toJson<int>(rating),
      'memo': serializer.toJson<String>(memo),
      'photo': serializer.toJson<String?>(photo),
      'weatherText': serializer.toJson<String>(weatherText),
      'fromRecommend': serializer.toJson<bool>(fromRecommend),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MealLogRow copyWith({
    int? id,
    String? date,
    String? mealType,
    Value<String?> restaurantId = const Value.absent(),
    String? restaurantName,
    String? cuisine,
    String? menu,
    int? rating,
    String? memo,
    Value<String?> photo = const Value.absent(),
    String? weatherText,
    bool? fromRecommend,
    DateTime? updatedAt,
  }) => MealLogRow(
    id: id ?? this.id,
    date: date ?? this.date,
    mealType: mealType ?? this.mealType,
    restaurantId: restaurantId.present ? restaurantId.value : this.restaurantId,
    restaurantName: restaurantName ?? this.restaurantName,
    cuisine: cuisine ?? this.cuisine,
    menu: menu ?? this.menu,
    rating: rating ?? this.rating,
    memo: memo ?? this.memo,
    photo: photo.present ? photo.value : this.photo,
    weatherText: weatherText ?? this.weatherText,
    fromRecommend: fromRecommend ?? this.fromRecommend,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MealLogRow copyWithCompanion(MealLogRowsCompanion data) {
    return MealLogRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      restaurantId: data.restaurantId.present
          ? data.restaurantId.value
          : this.restaurantId,
      restaurantName: data.restaurantName.present
          ? data.restaurantName.value
          : this.restaurantName,
      cuisine: data.cuisine.present ? data.cuisine.value : this.cuisine,
      menu: data.menu.present ? data.menu.value : this.menu,
      rating: data.rating.present ? data.rating.value : this.rating,
      memo: data.memo.present ? data.memo.value : this.memo,
      photo: data.photo.present ? data.photo.value : this.photo,
      weatherText: data.weatherText.present
          ? data.weatherText.value
          : this.weatherText,
      fromRecommend: data.fromRecommend.present
          ? data.fromRecommend.value
          : this.fromRecommend,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealLogRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mealType: $mealType, ')
          ..write('restaurantId: $restaurantId, ')
          ..write('restaurantName: $restaurantName, ')
          ..write('cuisine: $cuisine, ')
          ..write('menu: $menu, ')
          ..write('rating: $rating, ')
          ..write('memo: $memo, ')
          ..write('photo: $photo, ')
          ..write('weatherText: $weatherText, ')
          ..write('fromRecommend: $fromRecommend, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    mealType,
    restaurantId,
    restaurantName,
    cuisine,
    menu,
    rating,
    memo,
    photo,
    weatherText,
    fromRecommend,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealLogRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.mealType == this.mealType &&
          other.restaurantId == this.restaurantId &&
          other.restaurantName == this.restaurantName &&
          other.cuisine == this.cuisine &&
          other.menu == this.menu &&
          other.rating == this.rating &&
          other.memo == this.memo &&
          other.photo == this.photo &&
          other.weatherText == this.weatherText &&
          other.fromRecommend == this.fromRecommend &&
          other.updatedAt == this.updatedAt);
}

class MealLogRowsCompanion extends UpdateCompanion<MealLogRow> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> mealType;
  final Value<String?> restaurantId;
  final Value<String> restaurantName;
  final Value<String> cuisine;
  final Value<String> menu;
  final Value<int> rating;
  final Value<String> memo;
  final Value<String?> photo;
  final Value<String> weatherText;
  final Value<bool> fromRecommend;
  final Value<DateTime> updatedAt;
  const MealLogRowsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.mealType = const Value.absent(),
    this.restaurantId = const Value.absent(),
    this.restaurantName = const Value.absent(),
    this.cuisine = const Value.absent(),
    this.menu = const Value.absent(),
    this.rating = const Value.absent(),
    this.memo = const Value.absent(),
    this.photo = const Value.absent(),
    this.weatherText = const Value.absent(),
    this.fromRecommend = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MealLogRowsCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String mealType,
    this.restaurantId = const Value.absent(),
    required String restaurantName,
    required String cuisine,
    this.menu = const Value.absent(),
    this.rating = const Value.absent(),
    this.memo = const Value.absent(),
    this.photo = const Value.absent(),
    this.weatherText = const Value.absent(),
    this.fromRecommend = const Value.absent(),
    required DateTime updatedAt,
  }) : date = Value(date),
       mealType = Value(mealType),
       restaurantName = Value(restaurantName),
       cuisine = Value(cuisine),
       updatedAt = Value(updatedAt);
  static Insertable<MealLogRow> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? mealType,
    Expression<String>? restaurantId,
    Expression<String>? restaurantName,
    Expression<String>? cuisine,
    Expression<String>? menu,
    Expression<int>? rating,
    Expression<String>? memo,
    Expression<String>? photo,
    Expression<String>? weatherText,
    Expression<bool>? fromRecommend,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (mealType != null) 'meal_type': mealType,
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (restaurantName != null) 'restaurant_name': restaurantName,
      if (cuisine != null) 'cuisine': cuisine,
      if (menu != null) 'menu': menu,
      if (rating != null) 'rating': rating,
      if (memo != null) 'memo': memo,
      if (photo != null) 'photo': photo,
      if (weatherText != null) 'weather_text': weatherText,
      if (fromRecommend != null) 'from_recommend': fromRecommend,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MealLogRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String>? mealType,
    Value<String?>? restaurantId,
    Value<String>? restaurantName,
    Value<String>? cuisine,
    Value<String>? menu,
    Value<int>? rating,
    Value<String>? memo,
    Value<String?>? photo,
    Value<String>? weatherText,
    Value<bool>? fromRecommend,
    Value<DateTime>? updatedAt,
  }) {
    return MealLogRowsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      cuisine: cuisine ?? this.cuisine,
      menu: menu ?? this.menu,
      rating: rating ?? this.rating,
      memo: memo ?? this.memo,
      photo: photo ?? this.photo,
      weatherText: weatherText ?? this.weatherText,
      fromRecommend: fromRecommend ?? this.fromRecommend,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (restaurantId.present) {
      map['restaurant_id'] = Variable<String>(restaurantId.value);
    }
    if (restaurantName.present) {
      map['restaurant_name'] = Variable<String>(restaurantName.value);
    }
    if (cuisine.present) {
      map['cuisine'] = Variable<String>(cuisine.value);
    }
    if (menu.present) {
      map['menu'] = Variable<String>(menu.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (photo.present) {
      map['photo'] = Variable<String>(photo.value);
    }
    if (weatherText.present) {
      map['weather_text'] = Variable<String>(weatherText.value);
    }
    if (fromRecommend.present) {
      map['from_recommend'] = Variable<bool>(fromRecommend.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealLogRowsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mealType: $mealType, ')
          ..write('restaurantId: $restaurantId, ')
          ..write('restaurantName: $restaurantName, ')
          ..write('cuisine: $cuisine, ')
          ..write('menu: $menu, ')
          ..write('rating: $rating, ')
          ..write('memo: $memo, ')
          ..write('photo: $photo, ')
          ..write('weatherText: $weatherText, ')
          ..write('fromRecommend: $fromRecommend, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RestaurantRowsTable extends RestaurantRows
    with TableInfo<$RestaurantRowsTable, RestaurantRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RestaurantRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excludedMeta = const VerificationMeta(
    'excluded',
  );
  @override
  late final GeneratedColumn<bool> excluded = GeneratedColumn<bool>(
    'excluded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("excluded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, data, excluded, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'restaurants';
  @override
  VerificationContext validateIntegrity(
    Insertable<RestaurantRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('excluded')) {
      context.handle(
        _excludedMeta,
        excluded.isAcceptableOrUnknown(data['excluded']!, _excludedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RestaurantRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RestaurantRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      excluded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}excluded'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RestaurantRowsTable createAlias(String alias) {
    return $RestaurantRowsTable(attachedDatabase, alias);
  }
}

class RestaurantRow extends DataClass implements Insertable<RestaurantRow> {
  final String id;

  /// Codec.restaurant 의 JSON. 항목이 늘어도 표를 바꾸지 않아도 된다.
  final String data;
  final bool excluded;
  final DateTime updatedAt;
  const RestaurantRow({
    required this.id,
    required this.data,
    required this.excluded,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    map['excluded'] = Variable<bool>(excluded);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RestaurantRowsCompanion toCompanion(bool nullToAbsent) {
    return RestaurantRowsCompanion(
      id: Value(id),
      data: Value(data),
      excluded: Value(excluded),
      updatedAt: Value(updatedAt),
    );
  }

  factory RestaurantRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RestaurantRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
      excluded: serializer.fromJson<bool>(json['excluded']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
      'excluded': serializer.toJson<bool>(excluded),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RestaurantRow copyWith({
    String? id,
    String? data,
    bool? excluded,
    DateTime? updatedAt,
  }) => RestaurantRow(
    id: id ?? this.id,
    data: data ?? this.data,
    excluded: excluded ?? this.excluded,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RestaurantRow copyWithCompanion(RestaurantRowsCompanion data) {
    return RestaurantRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
      excluded: data.excluded.present ? data.excluded.value : this.excluded,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RestaurantRow(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('excluded: $excluded, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data, excluded, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RestaurantRow &&
          other.id == this.id &&
          other.data == this.data &&
          other.excluded == this.excluded &&
          other.updatedAt == this.updatedAt);
}

class RestaurantRowsCompanion extends UpdateCompanion<RestaurantRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<bool> excluded;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RestaurantRowsCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.excluded = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RestaurantRowsCompanion.insert({
    required String id,
    required String data,
    this.excluded = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       data = Value(data),
       updatedAt = Value(updatedAt);
  static Insertable<RestaurantRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<bool>? excluded,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (excluded != null) 'excluded': excluded,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RestaurantRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? data,
    Value<bool>? excluded,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RestaurantRowsCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      excluded: excluded ?? this.excluded,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (excluded.present) {
      map['excluded'] = Variable<bool>(excluded.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RestaurantRowsCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('excluded: $excluded, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyValueRowsTable extends KeyValueRows
    with TableInfo<$KeyValueRowsTable, KeyValueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValueRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValueRowsTable createAlias(String alias) {
    return $KeyValueRowsTable(attachedDatabase, alias);
  }
}

class KeyValueRow extends DataClass implements Insertable<KeyValueRow> {
  final String key;
  final String value;
  const KeyValueRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValueRowsCompanion toCompanion(bool nullToAbsent) {
    return KeyValueRowsCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValueRow copyWith({String? key, String? value}) =>
      KeyValueRow(key: key ?? this.key, value: value ?? this.value);
  KeyValueRow copyWithCompanion(KeyValueRowsCompanion data) {
    return KeyValueRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValueRow &&
          other.key == this.key &&
          other.value == this.value);
}

class KeyValueRowsCompanion extends UpdateCompanion<KeyValueRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValueRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValueRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValueRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValueRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValueRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MealLogRowsTable mealLogRows = $MealLogRowsTable(this);
  late final $RestaurantRowsTable restaurantRows = $RestaurantRowsTable(this);
  late final $KeyValueRowsTable keyValueRows = $KeyValueRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    mealLogRows,
    restaurantRows,
    keyValueRows,
  ];
}

typedef $$MealLogRowsTableCreateCompanionBuilder =
    MealLogRowsCompanion Function({
      Value<int> id,
      required String date,
      required String mealType,
      Value<String?> restaurantId,
      required String restaurantName,
      required String cuisine,
      Value<String> menu,
      Value<int> rating,
      Value<String> memo,
      Value<String?> photo,
      Value<String> weatherText,
      Value<bool> fromRecommend,
      required DateTime updatedAt,
    });
typedef $$MealLogRowsTableUpdateCompanionBuilder =
    MealLogRowsCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String> mealType,
      Value<String?> restaurantId,
      Value<String> restaurantName,
      Value<String> cuisine,
      Value<String> menu,
      Value<int> rating,
      Value<String> memo,
      Value<String?> photo,
      Value<String> weatherText,
      Value<bool> fromRecommend,
      Value<DateTime> updatedAt,
    });

class $$MealLogRowsTableFilterComposer
    extends Composer<_$AppDatabase, $MealLogRowsTable> {
  $$MealLogRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get restaurantId => $composableBuilder(
    column: $table.restaurantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get restaurantName => $composableBuilder(
    column: $table.restaurantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cuisine => $composableBuilder(
    column: $table.cuisine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get menu => $composableBuilder(
    column: $table.menu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weatherText => $composableBuilder(
    column: $table.weatherText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fromRecommend => $composableBuilder(
    column: $table.fromRecommend,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealLogRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealLogRowsTable> {
  $$MealLogRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get restaurantId => $composableBuilder(
    column: $table.restaurantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get restaurantName => $composableBuilder(
    column: $table.restaurantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cuisine => $composableBuilder(
    column: $table.cuisine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get menu => $composableBuilder(
    column: $table.menu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weatherText => $composableBuilder(
    column: $table.weatherText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fromRecommend => $composableBuilder(
    column: $table.fromRecommend,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealLogRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealLogRowsTable> {
  $$MealLogRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<String> get restaurantId => $composableBuilder(
    column: $table.restaurantId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get restaurantName => $composableBuilder(
    column: $table.restaurantName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cuisine =>
      $composableBuilder(column: $table.cuisine, builder: (column) => column);

  GeneratedColumn<String> get menu =>
      $composableBuilder(column: $table.menu, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get photo =>
      $composableBuilder(column: $table.photo, builder: (column) => column);

  GeneratedColumn<String> get weatherText => $composableBuilder(
    column: $table.weatherText,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get fromRecommend => $composableBuilder(
    column: $table.fromRecommend,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MealLogRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealLogRowsTable,
          MealLogRow,
          $$MealLogRowsTableFilterComposer,
          $$MealLogRowsTableOrderingComposer,
          $$MealLogRowsTableAnnotationComposer,
          $$MealLogRowsTableCreateCompanionBuilder,
          $$MealLogRowsTableUpdateCompanionBuilder,
          (
            MealLogRow,
            BaseReferences<_$AppDatabase, $MealLogRowsTable, MealLogRow>,
          ),
          MealLogRow,
          PrefetchHooks Function()
        > {
  $$MealLogRowsTableTableManager(_$AppDatabase db, $MealLogRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealLogRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealLogRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealLogRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> mealType = const Value.absent(),
                Value<String?> restaurantId = const Value.absent(),
                Value<String> restaurantName = const Value.absent(),
                Value<String> cuisine = const Value.absent(),
                Value<String> menu = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<String> memo = const Value.absent(),
                Value<String?> photo = const Value.absent(),
                Value<String> weatherText = const Value.absent(),
                Value<bool> fromRecommend = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MealLogRowsCompanion(
                id: id,
                date: date,
                mealType: mealType,
                restaurantId: restaurantId,
                restaurantName: restaurantName,
                cuisine: cuisine,
                menu: menu,
                rating: rating,
                memo: memo,
                photo: photo,
                weatherText: weatherText,
                fromRecommend: fromRecommend,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required String mealType,
                Value<String?> restaurantId = const Value.absent(),
                required String restaurantName,
                required String cuisine,
                Value<String> menu = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<String> memo = const Value.absent(),
                Value<String?> photo = const Value.absent(),
                Value<String> weatherText = const Value.absent(),
                Value<bool> fromRecommend = const Value.absent(),
                required DateTime updatedAt,
              }) => MealLogRowsCompanion.insert(
                id: id,
                date: date,
                mealType: mealType,
                restaurantId: restaurantId,
                restaurantName: restaurantName,
                cuisine: cuisine,
                menu: menu,
                rating: rating,
                memo: memo,
                photo: photo,
                weatherText: weatherText,
                fromRecommend: fromRecommend,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealLogRowsTable, MealLogRow>(table),
                  BaseReferences<_$AppDatabase, $MealLogRowsTable, MealLogRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealLogRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealLogRowsTable,
      MealLogRow,
      $$MealLogRowsTableFilterComposer,
      $$MealLogRowsTableOrderingComposer,
      $$MealLogRowsTableAnnotationComposer,
      $$MealLogRowsTableCreateCompanionBuilder,
      $$MealLogRowsTableUpdateCompanionBuilder,
      (
        MealLogRow,
        BaseReferences<_$AppDatabase, $MealLogRowsTable, MealLogRow>,
      ),
      MealLogRow,
      PrefetchHooks Function()
    >;
typedef $$RestaurantRowsTableCreateCompanionBuilder =
    RestaurantRowsCompanion Function({
      required String id,
      required String data,
      Value<bool> excluded,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$RestaurantRowsTableUpdateCompanionBuilder =
    RestaurantRowsCompanion Function({
      Value<String> id,
      Value<String> data,
      Value<bool> excluded,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$RestaurantRowsTableFilterComposer
    extends Composer<_$AppDatabase, $RestaurantRowsTable> {
  $$RestaurantRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excluded => $composableBuilder(
    column: $table.excluded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RestaurantRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $RestaurantRowsTable> {
  $$RestaurantRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excluded => $composableBuilder(
    column: $table.excluded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RestaurantRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RestaurantRowsTable> {
  $$RestaurantRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<bool> get excluded =>
      $composableBuilder(column: $table.excluded, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RestaurantRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RestaurantRowsTable,
          RestaurantRow,
          $$RestaurantRowsTableFilterComposer,
          $$RestaurantRowsTableOrderingComposer,
          $$RestaurantRowsTableAnnotationComposer,
          $$RestaurantRowsTableCreateCompanionBuilder,
          $$RestaurantRowsTableUpdateCompanionBuilder,
          (
            RestaurantRow,
            BaseReferences<_$AppDatabase, $RestaurantRowsTable, RestaurantRow>,
          ),
          RestaurantRow,
          PrefetchHooks Function()
        > {
  $$RestaurantRowsTableTableManager(
    _$AppDatabase db,
    $RestaurantRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RestaurantRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RestaurantRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RestaurantRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<bool> excluded = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RestaurantRowsCompanion(
                id: id,
                data: data,
                excluded: excluded,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String data,
                Value<bool> excluded = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RestaurantRowsCompanion.insert(
                id: id,
                data: data,
                excluded: excluded,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RestaurantRowsTable, RestaurantRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RestaurantRowsTable,
                    RestaurantRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RestaurantRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RestaurantRowsTable,
      RestaurantRow,
      $$RestaurantRowsTableFilterComposer,
      $$RestaurantRowsTableOrderingComposer,
      $$RestaurantRowsTableAnnotationComposer,
      $$RestaurantRowsTableCreateCompanionBuilder,
      $$RestaurantRowsTableUpdateCompanionBuilder,
      (
        RestaurantRow,
        BaseReferences<_$AppDatabase, $RestaurantRowsTable, RestaurantRow>,
      ),
      RestaurantRow,
      PrefetchHooks Function()
    >;
typedef $$KeyValueRowsTableCreateCompanionBuilder =
    KeyValueRowsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$KeyValueRowsTableUpdateCompanionBuilder =
    KeyValueRowsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$KeyValueRowsTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValueRowsTable> {
  $$KeyValueRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValueRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValueRowsTable> {
  $$KeyValueRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValueRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValueRowsTable> {
  $$KeyValueRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValueRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValueRowsTable,
          KeyValueRow,
          $$KeyValueRowsTableFilterComposer,
          $$KeyValueRowsTableOrderingComposer,
          $$KeyValueRowsTableAnnotationComposer,
          $$KeyValueRowsTableCreateCompanionBuilder,
          $$KeyValueRowsTableUpdateCompanionBuilder,
          (
            KeyValueRow,
            BaseReferences<_$AppDatabase, $KeyValueRowsTable, KeyValueRow>,
          ),
          KeyValueRow,
          PrefetchHooks Function()
        > {
  $$KeyValueRowsTableTableManager(_$AppDatabase db, $KeyValueRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValueRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValueRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValueRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValueRowsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => KeyValueRowsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValueRowsTable, KeyValueRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $KeyValueRowsTable,
                    KeyValueRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValueRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValueRowsTable,
      KeyValueRow,
      $$KeyValueRowsTableFilterComposer,
      $$KeyValueRowsTableOrderingComposer,
      $$KeyValueRowsTableAnnotationComposer,
      $$KeyValueRowsTableCreateCompanionBuilder,
      $$KeyValueRowsTableUpdateCompanionBuilder,
      (
        KeyValueRow,
        BaseReferences<_$AppDatabase, $KeyValueRowsTable, KeyValueRow>,
      ),
      KeyValueRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MealLogRowsTableTableManager get mealLogRows =>
      $$MealLogRowsTableTableManager(_db, _db.mealLogRows);
  $$RestaurantRowsTableTableManager get restaurantRows =>
      $$RestaurantRowsTableTableManager(_db, _db.restaurantRows);
  $$KeyValueRowsTableTableManager get keyValueRows =>
      $$KeyValueRowsTableTableManager(_db, _db.keyValueRows);
}
