import 'dart:io';

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dinner_decision/app/firebase_setup.dart';
import 'package:dinner_decision/data/device_files.dart';
import 'package:dinner_decision/data/local/app_database.dart';
import 'package:dinner_decision/data/local/backup.dart';
import 'package:dinner_decision/data/local/codec.dart';
import 'package:dinner_decision/data/local/photo_store.dart';
import 'package:dinner_decision/data/local/stored_data.dart';
import 'package:dinner_decision/data/providers.dart';
import 'package:dinner_decision/domain/models/app_settings.dart';
import 'package:dinner_decision/domain/models/cuisine.dart';
import 'package:dinner_decision/domain/models/meal_log.dart';
import 'package:dinner_decision/domain/models/restaurant.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

const r1 = Restaurant(
  id: 'k1',
  name: '진짬뽕',
  categoryRaw: '음식점 > 중식 > 중국요리',
  cuisine: Cuisine.chinese,
  subCategory: '중국요리',
  tags: ['짬뽕'],
  roadAddress: '서울 성동구 성수이로 2',
  phone: '',
  lat: 37.54,
  lng: 127.05,
);

MealLog log(int id, {String? photo}) => MealLog(
  id: id,
  date: DateTime(2026, 11, id),
  mealType: MealType.dinner,
  restaurantId: 'k1',
  restaurantName: '진짬뽕',
  cuisine: Cuisine.chinese,
  rating: 5,
  photoPath: photo,
);

/// 공유한 파일을 기억하고, 고를 파일을 정해 둘 수 있는 가짜.
class FakeDeviceFiles implements DeviceFiles {
  FakeDeviceFiles(this.temp);

  final Directory temp;
  String? shared;
  String? toPick;

  @override
  Future<String?> pickPhoto(PhotoSource source) async => null;

  @override
  Future<void> share(String path, {required String subject}) async =>
      shared = path;

  @override
  Future<List<int>?> pickBackup() async => switch (toPick) {
    final path? => File(path).readAsBytesSync(),
    null => null,
  };

  @override
  Future<Directory> tempDir() async => temp;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory temp;
  setUp(() => temp = Directory.systemTemp.createTempSync('dinner_test'));
  tearDown(() => temp.deleteSync(recursive: true));

  group('Backup 파일', () {
    test('기록·식당·설정·사진을 그대로 되살린다', () {
      final data = StoredData(
        logs: [
          log(1, photo: 'a.jpg'),
          log(2),
        ],
        restaurants: const {'k1': r1},
        excludedIds: const {'k1'},
        settings: const AppSettings(radiusM: 500, dislikedTags: {'회'}),
      );
      final bytes = Backup.encode(
        data,
        now: DateTime(2026, 11, 19),
        photos: {
          'a.jpg': [1, 2, 3],
        },
      );
      final back = Backup.decode(bytes);
      expect(back.data.logs.map(Codec.mealLog), data.logs.map(Codec.mealLog));
      expect(back.data.restaurants['k1']?.name, '진짬뽕');
      expect(back.data.excludedIds, {'k1'});
      expect(back.data.settings.radiusM, 500);
      expect(back.data.settings.dislikedTags, {'회'});
      expect(back.data.onboardingDone, isTrue);
      expect(back.photos, {
        'a.jpg': [1, 2, 3],
      });
      expect(
        Backup.fileName(DateTime(2026, 11, 19)),
        'dinner-backup-20261119.zip',
      );
    });

    test('잘못된 파일은 이유와 함께 거절한다', () {
      expect(
        () => Backup.decode([1, 2, 3]),
        throwsA(
          isA<BackupException>().having((e) => e.message, 'm', contains('zip')),
        ),
      );
      final other = ZipEncoder().encode(
        Archive()..addFile(
          ArchiveFile.string('backup.json', '{"app":"other","format":1}'),
        ),
      );
      expect(
        () => Backup.decode(other),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'm',
            contains('아니에요'),
          ),
        ),
      );
      final newer = ZipEncoder().encode(
        Archive()..addFile(
          ArchiveFile.string(
            'backup.json',
            '{"app":"dinner_decision","format":99}',
          ),
        ),
      );
      expect(
        () => Backup.decode(newer),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'm',
            contains('업데이트'),
          ),
        ),
      );
    });
  });

  group('리뷰 반영: 복원 오류와 개인정보', () {
    test('같은 번호의 기록이 두 번 있어도 복원된다 (뒤의 것을 씀)', () async {
      final archive = Archive()
        ..addFile(
          ArchiveFile.string(
            'backup.json',
            jsonEncode({
              'app': 'dinner_decision',
              'format': 1,
              'logs': [
                Codec.mealLog(log(1)),
                {...Codec.mealLog(log(1)), 'memo': '고친 메모'},
              ],
              'restaurants': [Codec.restaurant(r1)],
              'excludedIds': [],
              'settings': {},
            }),
          ),
        );
      final decoded = Backup.decode(ZipEncoder().encode(archive));
      expect(decoded.data.logs, hasLength(1));
      expect(decoded.data.logs.single.memo, '고친 메모');

      // DB에 같은 번호가 섞여 들어가도 실패하지 않는다.
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.replaceAll(StoredData(logs: [log(1), log(1)]));
      expect((await db.load()).logs, hasLength(1));
    });

    test('Crashlytics에는 오류 내용 없이 종류만 보낸다', () {
      final error = Exception('INSERT failed: 진짬뽕, 메모: 비밀 메모');
      final sanitized = SanitizedError('backup', error);
      expect(sanitized.toString(), 'backup: _Exception');
      expect(sanitized.toString(), isNot(contains('진짬뽕')));
      expect(sanitized.toString(), isNot(contains('메모')));
    });
  });

  group('PhotoStore', () {
    test('사진을 복사하고, 쓰지 않는 사진을 정리한다', () async {
      final store = PhotoStore(Directory('${temp.path}/photos'));
      final source = File('${temp.path}/picked.JPG')..writeAsBytesSync([9, 9]);
      final name = await store.add(source.path);
      expect(name, endsWith('.jpg'));
      expect(store.file(name).readAsBytesSync(), [9, 9]);
      await store.put('b.jpg', [1]);

      expect(await store.removeUnused({name}), 1);
      expect(store.file('b.jpg').existsSync(), isFalse);
      expect(store.file(name).existsSync(), isTrue);
    });
  });

  group('저장 연동', () {
    ProviderContainer containerFor(
      AppDatabase db,
      StoredData data, {
      PhotoStore? photos,
      DeviceFiles? files,
    }) {
      final c = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(loadTestConfig()),
          clockProvider.overrideWithValue(() => testToday),
          localStoreProvider.overrideWithValue(db),
          storedDataProvider.overrideWith(() => StoredDataController(data)),
          photoStoreProvider.overrideWithValue(photos),
          if (files != null) deviceFilesProvider.overrideWithValue(files),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('기록·설정·숨긴 식당·온보딩이 앱을 다시 켜도 남는다', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final first = containerFor(db, await db.load());

      first.read(mealLogsProvider.notifier).save(log(1), restaurant: r1);
      first
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(radiusM: 2000));
      first.read(settingsProvider.notifier).toggleDislike('매운');
      first.read(excludedProvider.notifier).hide(r1);
      first.read(onboardingDoneProvider.notifier).complete();
      await pumpEventQueue();

      // 다시 켠 것처럼 DB에서 새로 읽는다.
      final again = containerFor(db, await db.load());
      expect(again.read(mealLogsProvider).map((l) => l.id), [1]);
      expect(again.read(settingsProvider).radiusM, 2000);
      expect(again.read(settingsProvider).dislikedTags, {'매운'});
      expect(again.read(excludedProvider).keys, ['k1']);
      expect(again.read(knownRestaurantsProvider)['k1']?.name, '진짬뽕');
      expect(again.read(onboardingDoneProvider), isTrue);
      expect(again.read(mealLogsProvider.notifier).newId(), 2);

      again.read(mealLogsProvider.notifier).delete(1);
      again.read(excludedProvider.notifier).restore('k1');
      await pumpEventQueue();
      final data = await db.load();
      expect(data.logs, isEmpty);
      expect(data.excludedIds, isEmpty);
    });

    test('백업을 만들고 다른 휴대폰에 복원한다', () async {
      final oldDb = AppDatabase(NativeDatabase.memory());
      addTearDown(oldDb.close);
      final oldPhotos = PhotoStore(Directory('${temp.path}/old'));
      await oldPhotos.put('a.jpg', [7, 7, 7]);
      final files = FakeDeviceFiles(temp);
      final old = containerFor(
        oldDb,
        await oldDb.load(),
        photos: oldPhotos,
        files: files,
      );
      old
          .read(mealLogsProvider.notifier)
          .save(log(1, photo: 'a.jpg'), restaurant: r1);
      old.read(mealLogsProvider.notifier).save(log(2));
      old.read(excludedProvider.notifier).hide(r1);
      await pumpEventQueue();

      final path = await old.read(backupServiceProvider).export();
      expect(files.shared, path);
      expect(path, endsWith('dinner-backup-20261109.zip'));

      // 새 휴대폰: 기록 하나가 이미 있다.
      final newDb = AppDatabase(NativeDatabase.memory());
      addTearDown(newDb.close);
      await newDb.saveLog(log(9));
      final newPhotos = PhotoStore(Directory('${temp.path}/new'));
      final newFiles = FakeDeviceFiles(temp)..toPick = path;
      final fresh = containerFor(
        newDb,
        await newDb.load(),
        photos: newPhotos,
        files: newFiles,
      );

      final contents = await fresh.read(backupServiceProvider).pick();
      expect(contents!.logCount, 2);
      await fresh.read(backupServiceProvider).restore(contents);

      expect(fresh.read(mealLogsProvider).map((l) => l.id), [2, 1]);
      expect(fresh.read(excludedProvider).keys, ['k1']);
      expect(newPhotos.file('a.jpg').readAsBytesSync(), [7, 7, 7]);
      final saved = await newDb.load();
      expect(saved.logs.map((l) => l.id), [2, 1]);
      expect(saved.excludedIds, {'k1'});
      // 복원 뒤 새 기록 번호가 겹치지 않는다.
      expect(fresh.read(mealLogsProvider.notifier).newId(), 3);
    });
  });
}
