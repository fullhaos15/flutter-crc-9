import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/core/error/app_exception.dart';

import '../helpers.dart';

/// Unit-тесты преобразования любых ошибок в понятный AppException.
void main() {
  final ro = RequestOptions(path: '/posts');

  AppException convert(Object e) => AppException.from(e);

  test('таймаут -> AppErrorType.timeout', () {
    final e = convert(
      DioException(requestOptions: ro, type: DioExceptionType.receiveTimeout),
    );
    expect(e.type, AppErrorType.timeout);
  });

  test('нет сети (connectionError) -> noConnection', () {
    final e = convert(
      DioException(requestOptions: ro, type: DioExceptionType.connectionError),
    );
    expect(e.type, AppErrorType.noConnection);
    expect(e.message, 'Нет подключения к интернету.');
  });

  test('SocketException внутри DioException.unknown -> noConnection', () {
    final e = convert(DioException(
      requestOptions: ro,
      type: DioExceptionType.unknown,
      error: const SocketException('no route'),
    ));
    expect(e.type, AppErrorType.noConnection);
  });

  test('404 -> client с текстом «не найдены», код сохраняется', () {
    final e = convert(serverError(404));
    expect(e.type, AppErrorType.client);
    expect(e.statusCode, 404);
    expect(e.message, contains('не найдены'));
  });

  test('500 -> server, в сообщении виден код', () {
    final e = convert(serverError(503));
    expect(e.type, AppErrorType.server);
    expect(e.message, contains('503'));
  });

  test('FormatException (битый JSON) -> parse', () {
    expect(convert(const FormatException('bad')).type, AppErrorType.parse);
  });

  test('неизвестная ошибка -> unknown, технические детали не в сообщении', () {
    final e = convert(StateError('secret internals'));
    expect(e.type, AppErrorType.unknown);
    expect(e.message, isNot(contains('secret internals')));
    expect(e.technical, contains('secret internals'));
  });

  test('AppException проходит без изменений (тот же объект)', () {
    const original = AppException(AppErrorType.timeout, 'x');
    expect(identical(convert(original), original), isTrue);
  });
}
