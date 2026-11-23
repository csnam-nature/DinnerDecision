import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../firebase_options.dart';

/// App Check 디버그 토큰. Firebase 콘솔 › App Check › 앱 › 디버그 토큰 관리에 등록한 값.
/// 비워 두면 SDK가 만든 토큰이 실행 로그에 한 번 찍힌다 (재설치하면 바뀐다).
///
/// ```
/// flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=<등록한 값>
/// ```
const appCheckDebugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

/// 처리하지 못한 오류를 어딘가에 남긴다. Firebase가 없으면 아무것도 하지 않는다.
abstract interface class ErrorReporter {
  /// [reason]은 어디서 났는지 짧게. 위치·기록 내용 같은 개인정보는 넣지 않는다.
  void record(Object error, StackTrace? stack, {String? reason, bool fatal});

  /// 개발용: 시험 오류를 남기고 바로 보낸다.
  Future<void> sendTestReport();
}

class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  void record(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {}

  @override
  Future<void> sendTestReport() async {}
}

/// Firebase Crashlytics (PLAN.md 5장, 6단계).
/// 보내는 것: 오류 내용과 위치(코드), 기기 모델·OS 버전. 위치·기록·사진은 보내지 않는다.
class CrashlyticsReporter implements ErrorReporter {
  CrashlyticsReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  void record(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    unawaited(
      _crashlytics
          .recordError(error, stack, reason: reason, fatal: fatal)
          .catchError((Object e) => debugPrint('오류 보고 실패: $e')),
    );
  }

  @override
  Future<void> sendTestReport() async {
    await _crashlytics.recordError(
      StateError('Crashlytics 연결 시험 (설정 › 개발용)'),
      StackTrace.current,
      reason: 'test',
    );
    // 디버그 빌드는 자동 전송이 꺼져 있어서 직접 보낸다.
    await _crashlytics.sendUnsentReports();
  }
}

/// Firebase를 켠 결과. 설정 파일이 없거나 실패하면 [FirebaseServices.disabled].
class FirebaseServices {
  const FirebaseServices({
    required this.enabled,
    required this.reporter,
    this.appCheckToken,
  });

  static const disabled = FirebaseServices(
    enabled: false,
    reporter: NoopErrorReporter(),
  );

  final bool enabled;
  final ErrorReporter reporter;

  /// 서버 요청 헤더에 넣을 App Check 토큰.
  final TokenProvider? appCheckToken;
}

/// Firebase 켜기. 앱 시작 때 한 번.
///
/// 설정은 `lib/firebase_options.dart`(flutterfire configure가 만든다)에서 읽는다.
/// 실패하면 Firebase 없이 지금처럼 동작한다.
Future<FirebaseServices> initFirebase({required bool serverMode}) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } on Object catch (e) {
    debugPrint('Firebase 없이 실행합니다: $e');
    return FirebaseServices.disabled;
  }

  // ── Crashlytics ──
  final crashlytics = FirebaseCrashlytics.instance;
  final reporter = CrashlyticsReporter(crashlytics);
  try {
    // 개발 중 오류까지 쌓이지 않게 출시 빌드에서만 자동으로 보낸다.
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    await crashlytics.setCustomKey('mode', serverMode ? 'server' : 'sample');
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details); // 디버그 화면의 빨간 오류 표시는 그대로
      unawaited(crashlytics.recordFlutterFatalError(details));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      reporter.record(error, stack, reason: 'uncaught', fatal: true);
      return true;
    };
  } on Object catch (e) {
    debugPrint('Crashlytics 설정 실패: $e');
  }

  // ── App Check ──
  TokenProvider? appCheckToken;
  try {
    await FirebaseAppCheck.instance.activate(
      // 개발 빌드는 디버그 토큰, 출시 빌드는 Play Integrity / App Attest.
      providerAndroid: kDebugMode
          ? AndroidDebugProvider(
              debugToken: appCheckDebugToken.isEmpty
                  ? null
                  : appCheckDebugToken,
            )
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? AppleDebugProvider(
              debugToken: appCheckDebugToken.isEmpty
                  ? null
                  : appCheckDebugToken,
            )
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    appCheckToken = () => FirebaseAppCheck.instance.getToken();
  } on Object catch (e, stack) {
    debugPrint('App Check 설정 실패: $e');
    reporter.record(e, stack, reason: 'app_check_activate');
  }

  return FirebaseServices(
    enabled: true,
    reporter: reporter,
    appCheckToken: appCheckToken,
  );
}
