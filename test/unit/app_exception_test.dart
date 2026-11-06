import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/core/error/app_exception.dart';

DioException _dio(DioExceptionType type, {int? status, Object? error}) {
  final ro = RequestOptions(path: '/posts');
  return DioException(
    requestOptions: ro,
    type: type,
    error: error,
    response: status == null
        ? null
        : Response(requestOptions: ro, statusCode: status),
  );
}

void main() {
  group('AppException.from — классификация ошибок', () {
    test('таймауты Dio -> timeout', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(AppException.from(_dio(t)).type, AppErrorType.timeout);
      }
    });

    test('connectionError и SocketException -> noConnection', () {
      expect(
        AppException.from(_dio(DioExceptionType.connectionError)).type,
        AppErrorType.noConnection,
      );
      expect(
        AppException.from(
          _dio(DioExceptionType.unknown,
              error: const SocketException('no net')),
        ).type,
        AppErrorType.noConnection,
      );
    });

    test('4xx -> client (404 с отдельным текстом), 5xx -> server', () {
      final notFound =
          AppException.from(_dio(DioExceptionType.badResponse, status: 404));
      expect(notFound.type, AppErrorType.client);
      expect(notFound.statusCode, 404);
      expect(notFound.message, contains('404'));

      final bad =
          AppException.from(_dio(DioExceptionType.badResponse, status: 400));
      expect(bad.type, AppErrorType.client);

      final server =
          AppException.from(_dio(DioExceptionType.badResponse, status: 503));
      expect(server.type, AppErrorType.server);
      expect(server.statusCode, 503);
    });

    test('FormatException и TypeError -> parse', () {
      expect(AppException.from(const FormatException('bad')).type,
          AppErrorType.parse);
      expect(AppException.from(TypeError()).type, AppErrorType.parse);
    });

    test('неизвестная ошибка -> unknown, исходный AppException не меняется',
        () {
      expect(AppException.from(Exception('???')).type, AppErrorType.unknown);

      const original =
          AppException(AppErrorType.server, 'msg', statusCode: 500);
      expect(identical(AppException.from(original), original), isTrue);
    });

    test(
        'AppException, положенный interceptor-ом в DioException.error, достаётся как есть',
        () {
      const inner = AppException(AppErrorType.timeout, 'таймаут');
      final e = _dio(DioExceptionType.unknown, error: inner);
      expect(AppException.from(e), same(inner));
    });
  });
}
