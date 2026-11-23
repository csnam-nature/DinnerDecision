import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/firebase_setup.dart';
import 'app/startup_error_app.dart';
import 'app/widgets/app_map_view.dart';
import 'app/widgets/naver_map_view.dart';
import 'data/api/api_client.dart';
import 'data/app_config.dart';
import 'data/local/app_database.dart';
import 'data/local/photo_store.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 오류 수집을 가장 먼저 켜야 시작 중에 난 오류도 남는다.
  final firebase = await initFirebase(serverMode: apiBaseUrl.isNotEmpty);
  debugPrint('[시작] Firebase ${firebase.enabled ? '사용' : '안 씀'}');
  final List<Override> overrides;
  try {
    overrides = await _startup();
  } on Object catch (e, stack) {
    // 첫 화면에서 멈춰 있지 않고 무엇이 잘못됐는지 보여준다.
    debugPrint('시작 실패: $e\n$stack');
    firebase.reporter.record(e, stack, reason: 'startup', fatal: true);
    runApp(StartupErrorApp(error: e));
    return;
  }
  runApp(
    ProviderScope(
      overrides: [
        ...overrides,
        firebaseEnabledProvider.overrideWithValue(firebase.enabled),
        errorReporterProvider.overrideWithValue(firebase.reporter),
        appCheckTokenProvider.overrideWithValue(firebase.appCheckToken),
      ],
      child: const DinnerDecisionApp(),
    ),
  );
}

/// 시작 준비. 어디서 멈추는지 로그로 알 수 있게 단계마다 남긴다.
Future<List<Override>> _startup() async {
  final watch = Stopwatch()..start();
  void step(String what) =>
      debugPrint('[시작] $what (${watch.elapsedMilliseconds}ms)');

  final config = await AppConfig.load(rootBundle);
  step('규칙 파일');
  await initNaverMap();
  step('네이버 지도 ${AppMapView.useNaverMap ? '사용' : '안 씀'}');
  final docs = await getApplicationDocumentsDirectory();
  final photos = PhotoStore(Directory(p.join(docs.path, 'photos')));
  step('앱 폴더');

  // 서버 모드에서는 기록·설정을 기기 DB에 저장한다.
  // 예시 데이터 모드는 지금처럼 예시 기록을 메모리에만 둔다.
  final storage = apiBaseUrl.isEmpty
      ? const <Override>[]
      : await _deviceStorage(photos).timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException('기기 DB를 여는 데 20초가 넘게 걸렸어요'),
        );
  step('기기 DB');

  return [
    appConfigProvider.overrideWithValue(config),
    photoStoreProvider.overrideWithValue(photos),
    ...storage,
  ];
}

Future<List<Override>> _deviceStorage(PhotoStore photos) async {
  final db = AppDatabase();
  final data = await db.load();
  // 지운 기록의 사진은 '되돌리기' 때문에 바로 지우지 않고, 다음에 켤 때 정리한다.
  try {
    await photos.removeUnused({for (final log in data.logs) ?log.photoPath});
  } on FileSystemException catch (e) {
    debugPrint('사진 정리 실패: $e');
  }
  return [
    localStoreProvider.overrideWithValue(db),
    storedDataProvider.overrideWith(() => StoredDataController(data)),
  ];
}
