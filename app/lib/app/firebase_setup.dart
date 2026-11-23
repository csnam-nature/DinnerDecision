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

/// 개인정보가 담겼을 수 있는 오류 대신 보내는 것: 어디서(area) 어떤 종류(type)의 오류인지만.
/// 예: DB 오류 메시지에는 저장하려던 기록(식당, 메뉴, 메모)이 들어갈 수 있다.
class SanitizedError implements Exception {
  SanitizedError(this.area, Object error) : type = error.runtimeType.toString();

  final String area;
  final String type;

  @override
  String toString() => '$area: $type';
}

/// 처리하지 못한 오류를 어딘가에 남긴다. Firebase가 없으면 아무것도 하지 않는다.
abstract interface class ErrorReporter {
  /// [reason]은 어디서 났는지 짧게. 위치·기록 내용 같은 개인정보는 넣지 않는다.
  void record(Object error, StackTrace? stack, {String? reason, bool fatal});

  /// 기록 내용이 담겼을 수 있는 오류(백업·복원, 기기 DB)는 이것으로 보낸다.
  /// 오류 내용은 빼고 종류와 코드 위치만 보낸다. 자세한 내용은 화면과 기기 로그에만 남긴다.
  void recordSanitized(String area, Object error, StackTrace? stack);

  /// 개발용: 시험 오류를 남기고 바로 보낸다.
  Future<void> sendTestReport();
}

class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  void recordSanitized(String area, Object error, StackTrace? stack) {}

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
///
/// 디버그 빌드에서는 개발 중 오류가 쌓이지 않게 [record]가 아무것도 하지 않고,
/// [sendTestReport](설정 › 개발용)로 보낸 시험 오류만 기록한다.
class CrashlyticsReporter implements ErrorReporter {
  CrashlyticsReporter(this._crashlytics, {this.recordInDebug = false});

  final FirebaseCrashlytics _crashlytics;
  final bool recordInDebug;

  @override
  void record(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    if (kDebugMode && !recordInDebug) return;
    unawaited(
      _crashlytics
          .recordError(error, stack, reason: reason, fatal: fatal)
          .catchError((Object e) => debugPrint('오류 보고 실패: $e')),
    );
  }

  @override
  void recordSanitized(String area, Object error, StackTrace? stack) =>
      record(SanitizedError(area, error), stack, reason: area);

  /// 시험 오류를 기록한다. Crashlytics는 기록한 오류를 **앱을 다시 켤 때** 보낸다.
  @override
  Future<void> sendTestReport() => _crashlytics.recordError(
    StateError('Crashlytics 연결 시험 (설정 › 개발용)'),
    StackTrace.current,
    reason: 'test',
  );
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
    // 전송은 항상 켠다. 꺼 두면 기록한 오류를 휴대폰에 쌓아만 두고 보내지 않는다.
    // 대신 디버그 빌드에서는 개발 중 오류를 Crashlytics로 넘기지 않는다 (시험 버튼만).
    await crashlytics.setCrashlyticsCollectionEnabled(true);
    await crashlytics.setCustomKey('mode', serverMode ? 'server' : 'sample');
    await crashlytics.setCustomKey('build', kDebugMode ? 'debug' : 'release');
    if (!kDebugMode) {
      FlutterError.onError = crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        reporter.record(error, stack, reason: 'uncaught', fatal: true);
        return true;
      };
    }
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
