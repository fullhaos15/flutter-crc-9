import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_interceptor.dart';

/// Единый клиент Dio. Экземпляр создаётся один раз в main().
class DioClient {
  DioClient({Dio? dio}) : dio = dio ?? _build();

  static const baseUrl = 'https://jsonplaceholder.typicode.com';

  final Dio dio;

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(ApiInterceptor());
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
    }
    return dio;
  }
}
