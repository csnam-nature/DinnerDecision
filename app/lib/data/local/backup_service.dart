import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../providers.dart';
import 'backup.dart';
import 'stored_data.dart';

/// 복원 전에 보여줄 백업 내용.
class BackupContents {
  const BackupContents(this.data, this.photos);

  final StoredData data;
  final Map<String, List<int>> photos;

  int get logCount => data.logs.length;
}

/// 백업 파일 만들기·복원 (F-12).
class BackupService {
  BackupService(this._ref);

  final Ref _ref;

  /// 지금 앱의 기록·설정·숨긴 식당.
  StoredData current() {
    final excluded = _ref.read(excludedProvider);
    return StoredData(
      logs: _ref.read(mealLogsProvider),
      settings: _ref.read(settingsProvider),
      excludedIds: excluded.keys.toSet(),
      restaurants: {..._ref.read(knownRestaurantsProvider), ...excluded},
      onboardingDone: true,
    );
  }

  /// 백업 zip을 만들어 공유 시트를 연다. 만든 파일 경로를 돌려준다.
  Future<String> export() async {
    final data = current();
    final photos = <String, List<int>>{};
    final store = _ref.read(photoStoreProvider);
    if (store != null) {
      for (final log in data.logs) {
        final name = log.photoPath;
        if (name == null) continue;
        final file = store.file(name);
        if (await file.exists()) photos[name] = await file.readAsBytes();
      }
    }
    final now = _ref.read(clockProvider)();
    final bytes = Backup.encode(data, now: now, photos: photos);
    final files = _ref.read(deviceFilesProvider);
    final path = p.join((await files.tempDir()).path, Backup.fileName(now));
    await File(path).writeAsBytes(bytes, flush: true);
    await files.share(path, subject: '오늘 저녁 뭐 먹지 백업');
    return path;
  }

  /// 백업 파일을 골라 읽는다. 취소하면 null, 잘못된 파일이면 [BackupException].
  Future<BackupContents?> pick() async {
    final path = await _ref.read(deviceFilesProvider).pickBackup();
    if (path == null) return null;
    return read(path);
  }

  Future<BackupContents> read(String path) async {
    final decoded = Backup.decode(await File(path).readAsBytes());
    return BackupContents(decoded.data, decoded.photos);
  }

  /// 지금 기록을 지우고 백업 내용으로 바꾼다.
  Future<void> restore(BackupContents contents) async {
    final store = _ref.read(photoStoreProvider);
    if (store != null) {
      for (final MapEntry(key: name, value: bytes) in contents.photos.entries) {
        await store.put(name, bytes);
      }
    }
    await _ref.read(localStoreProvider).replaceAll(contents.data);
    _ref.read(storedDataProvider.notifier).replace(contents.data);
  }
}
