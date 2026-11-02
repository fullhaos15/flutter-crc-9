import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/app_exception.dart';

/// Добавляет технические заголовки и централизованно превращает
/// любые ошибки Dio в [AppException] (кладётся в DioException.error).
class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll({
      'X-App-Name': 'PostExplorer',
      'X-App-Version': '1.0.0',
      'X-Request-Id': DateTime.now().microsecondsSinceEpoch.toString(),
    });
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = AppException.from(err);
    // Технические подробности — только в лог разработки.
    debugPrint('[API ERROR] ${err.requestOptions.method} '
        '${err.requestOptions.uri} -> ${exception.technical ?? exception.message}');
    handler.next(err.copyWith(error: exception));
  }
}
