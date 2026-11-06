import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/core/utils/validators.dart';

void main() {
  group('Validators.title', () {
    test('null, пустая строка и одни пробелы — ошибка «Введите заголовок»', () {
      expect(Validators.title(null), 'Введите заголовок');
      expect(Validators.title(''), 'Введите заголовок');
      expect(Validators.title('     '), 'Введите заголовок');
    });

    test('короче 5 символов (после trim) — ошибка длины', () {
      expect(Validators.title('abcd'), 'Заголовок: от 5 до 100 символов');
      expect(Validators.title('  ab  '), 'Заголовок: от 5 до 100 символов');
    });

    test('границы допустимой длины: 5 и 100 — ок, 101 — ошибка', () {
      expect(Validators.title('a' * 5), isNull);
      expect(Validators.title('a' * 100), isNull);
      expect(Validators.title('a' * 101), isNotNull);
    });
  });

  group('Validators.body', () {
    test('пустой текст — ошибка', () {
      expect(Validators.body(''), 'Введите текст поста');
      expect(Validators.body(null), 'Введите текст поста');
    });

    test('границы допустимой длины: 10 и 1000 — ок, 9 и 1001 — ошибка', () {
      expect(Validators.body('a' * 9), isNotNull);
      expect(Validators.body('a' * 10), isNull);
      expect(Validators.body('a' * 1000), isNull);
      expect(Validators.body('a' * 1001), isNotNull);
    });
  });

  group('Validators.userId', () {
    test('автор не выбран — ошибка, выбран — ок', () {
      expect(Validators.userId(null), 'Выберите автора');
      expect(Validators.userId(3), isNull);
    });
  });
}
