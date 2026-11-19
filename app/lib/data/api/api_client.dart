import 'package:dio/dio.dart';

/// 서버(Cloudflare Workers) 주소. 빌드할 때 넣는다.
///
/// ```
/// flutter run --dart-define=API_BASE_URL=https://dinner-api.<계정>.workers.dev
/// ```
/// 비어 있으면 예시 데이터로 동작한다.
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// 서버 호출이 실패한 이유. [code]는 서버가 보낸 값(예: RATE_LIMITED)이거나
/// 네트워크 문제면 [ApiException.network], [ApiException.timeout].
class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.statusCode});

  static const network = 'NETWORK';
  static const timeout = 'TIMEOUT';
  static const badResponse = 'BAD_RESPONSE';

  final String code;
  final String message;
  final int? statusCode;

  bool get isOffline => code == network || code == timeout;

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}

/// App Check 토큰을 주는 함수. Firebase를 붙이면 넣는다 (PLAN.md 6장).
typedef TokenProvider = Future<String?> Function();

/// 서버 API를 부르는 곳. JSON을 받아 Map으로 돌려준다.
class ApiClient {
  ApiClient({
    required String baseUrl,
    Dio? dio,
    this.appCheckToken,
    Duration timeout = const Duration(seconds: 15),
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: timeout,
               receiveTimeout: timeout,
               responseType: ResponseType.json,
             ),
           ) {
    _dio.options.baseUrl = baseUrl;
  }

  final Dio _dio;
  final TokenProvider? appCheckToken;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    final token = await appCheckToken?.call();
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: query,
        options: Options(headers: {'X-Firebase-AppCheck': ?token}),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(ApiException.badResponse, '서버 응답을 읽을 수 없어요');
      }
      return data;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  static ApiException _toApiException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(ApiException.timeout, '서버 응답이 늦어요');
      case DioExceptionType.connectionError:
        return const ApiException(ApiException.network, '인터넷에 연결되어 있지 않아요');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final body = e.response?.data;
        if (body is Map && body['error'] is Map) {
          final error = body['error'] as Map;
          return ApiException(
            error['code'] as String? ?? ApiException.badResponse,
            error['message'] as String? ?? '서버 오류가 발생했어요',
            statusCode: status,
          );
        }
        return ApiException(
          ApiException.badResponse,
          '서버 오류가 발생했어요 ($status)',
          statusCode: status,
        );
      default:
        return ApiException(ApiException.network, e.message ?? '서버에 연결하지 못했어요');
    }
  }
}
