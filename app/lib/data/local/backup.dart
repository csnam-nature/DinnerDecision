import 'dart:convert';

import 'package:archive/archive.dart';

import 'codec.dart';
import 'stored_data.dart';

/// 백업 파일 (F-12). zip 하나에 기록 JSON과 사진을 넣는다.
///
/// ```
/// dinner-backup-20261119.zip
/// ├─ backup.json   { app, format, exportedAt, logs, restaurants, excludedIds, settings }
/// └─ photos/…jpg
/// ```
abstract final class Backup {
  static const app = 'dinner_decision';

  /// 형식을 바꾸면 올리고 [decode]에서 예전 형식도 읽게 한다.
  static const format = 1;
  static const jsonName = 'backup.json';
  static const photoDir = 'photos/';

  static String fileName(DateTime now) =>
      'dinner-backup-${Codec.date(now).replaceAll('-', '')}.zip';

  static List<int> encode(
    StoredData data, {
    required DateTime now,
    Map<String, List<int>> photos = const {},
  }) {
    final json = {
      'app': app,
      'format': format,
      'exportedAt': now.toIso8601String(),
      'logs': [for (final l in data.logs) Codec.mealLog(l)],
      'restaurants': [
        for (final r in data.restaurants.values) Codec.restaurant(r),
      ],
      'excludedIds': data.excludedIds.toList()..sort(),
      'settings': Codec.settings(data.settings),
    };
    final archive = Archive()
      ..addFile(
        ArchiveFile.bytes(
          jsonName,
          utf8.encode(const JsonEncoder.withIndent(' ').convert(json)),
        ),
      );
    for (final MapEntry(key: name, value: bytes) in photos.entries) {
      // 사진은 이미 압축돼 있어 다시 압축하지 않는다.
      archive.addFile(
        ArchiveFile.bytes('$photoDir$name', bytes)
          ..compression = CompressionType.none,
      );
    }
    return ZipEncoder().encode(archive);
  }

  /// 백업 파일을 읽는다. 이 앱의 백업이 아니거나 망가졌으면 [BackupException].
  static ({StoredData data, Map<String, List<int>> photos}) decode(
    List<int> bytes,
  ) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      throw const BackupException('백업 파일(zip)이 아니에요');
    }
    // zip이 아닌 파일은 예외 없이 빈 묶음으로 읽히기도 한다.
    if (archive.isEmpty) throw const BackupException('백업 파일(zip)이 아니에요');
    final jsonFile = archive.findFile(jsonName);
    if (jsonFile == null) {
      throw const BackupException('이 앱에서 만든 백업 파일이 아니에요');
    }
    final Map<String, Object?> json;
    try {
      json = jsonDecode(utf8.decode(jsonFile.content)) as Map<String, Object?>;
    } on Object {
      throw const BackupException('백업 파일이 망가졌어요');
    }
    if (json['app'] != app) {
      throw const BackupException('이 앱에서 만든 백업 파일이 아니에요');
    }
    final version = json['format'];
    if (version is! int || version > format) {
      throw const BackupException('더 새 버전 앱에서 만든 백업이에요. 앱을 업데이트해 주세요');
    }
    try {
      final restaurants = [
        for (final r in json['restaurants'] as List<Object?>? ?? const [])
          Codec.parseRestaurant(r as Map<String, Object?>),
      ];
      final data = StoredData(
        logs: [
          for (final l in json['logs'] as List<Object?>? ?? const [])
            Codec.parseMealLog(l as Map<String, Object?>),
        ],
        restaurants: {for (final r in restaurants) r.id: r},
        excludedIds: {
          for (final id in json['excludedIds'] as List<Object?>? ?? const [])
            id as String,
        },
        settings: Codec.parseSettings(
          json['settings'] as Map<String, Object?>? ?? const {},
        ),
        onboardingDone: true,
      );
      final photos = <String, List<int>>{
        for (final f in archive.files)
          if (f.isFile &&
              f.name.startsWith(photoDir) &&
              f.name.length > photoDir.length)
            f.name.substring(photoDir.length): f.content,
      };
      return (data: data, photos: photos);
    } on Object {
      throw const BackupException('백업 파일이 망가졌어요');
    }
  }
}

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => 'BackupException: $message';
}
