import 'dart:io';

import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

/// Типы ошибок, которые различает приложение (раздел 6 задания).
enum AppErrorType { noConnection, timeout, client, server, parse, unknown }

class AppException implements Exception {
  const AppException(
    this.type,
    this.message, {
    this.statusCode,
    this.technical,
  });

  final AppErrorType type;

  /// Понятное пользователю сообщение.
  final String message;
  final int? statusCode;

  /// Технические детали — только для логов разработки.
  final String? technical;

  /// Единая точка преобразования любой ошибки в [AppException].
  factory AppException.from(Object error) {
    if (error is AppException) return error;

    if (error is DioException) {
      final inner = error.error;
      if (inner is AppException) return inner;

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AppException(
            AppErrorType.timeout,
            'Сервер слишком долго отвечает. Попробуйте ещё раз.',
            technical: error.message,
          );
        case DioExceptionType.connectionError:
          return AppException(
            AppErrorType.noConnection,
            'Нет подключения к интернету.',
            technical: error.message,
          );
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode ?? 0;
          if (code >= 500) {
            return AppException(
              AppErrorType.server,
              'Ошибка сервера ($code). Попробуйте позже.',
              statusCode: code,
              technical: error.message,
            );
          }
          if (code >= 400) {
            return AppException(
              AppErrorType.client,
              code == 404
                  ? 'Данные не найдены (404).'
                  : 'Некорректный запрос ($code).',
              statusCode: code,
              technical: error.message,
            );
          }
          return AppException(
            AppErrorType.unknown,
            'Неожиданный ответ сервера ($code).',
            statusCode: code,
          );
        case DioExceptionType.cancel:
          return const AppException(AppErrorType.unknown, 'Запрос отменён.');
        case DioExceptionType.badCertificate:
          return AppException(
            AppErrorType.unknown,
            'Не удалось установить защищённое соединение.',
            technical: error.message,
          );
        case DioExceptionType.unknown:
          if (inner is SocketException) {
            return AppException(
              AppErrorType.noConnection,
              'Нет подключения к интернету.',
              technical: inner.message,
            );
          }
          if (inner != null && _isParseError(inner)) {
            return _parse(inner);
          }
          return AppException(
            AppErrorType.unknown,
            'Что-то пошло не так. Попробуйте ещё раз.',
            technical: '${error.error}',
          );
      }
    }

    if (_isParseError(error)) return _parse(error);

    return AppException(
      AppErrorType.unknown,
      'Что-то пошло не так. Попробуйте ещё раз.',
      technical: '$error',
    );
  }

  static bool _isParseError(Object e) =>
      e is CheckedFromJsonException || e is FormatException || e is TypeError;

  static AppException _parse(Object e) => AppException(
        AppErrorType.parse,
        'Сервер вернул некорректные данные.',
        technical: '$e',
      );

  @override
  String toString() => 'AppException($type, $statusCode): $message | $technical';
}
