import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/core/utils/validators.dart';

/// Unit-тесты валидации формы создания поста (Validators).
/// Это чистая логика без UI: вход -> строка с ошибкой или null.
void main() {
  group('Validators.title', () {
    test('null и пустая строка -> «Введите заголовок»', () {
      expect(Validators.title(null), 'Введите заголовок');
      expect(Validators.title(''), 'Введите заголовок');
    });

    test('строка из одних пробелов считается пустой', () {
      expect(Validators.title('      '), 'Введите заголовок');
    });

    test('граница снизу: 4 символа — ошибка, 5 — допустимо', () {
      expect(Validators.title('abcd'), 'Заголовок: от 5 до 100 символов');
      expect(Validators.title('abcde'), isNull);
    });

    test('граница сверху: 100 символов — допустимо, 101 — ошибка', () {
      expect(Validators.title('a' * 100), isNull);
      expect(Validators.title('a' * 101), 'Заголовок: от 5 до 100 символов');
    });

    test('пробелы по краям обрезаются перед проверкой длины', () {
      expect(Validators.title('  abcd  '), isNotNull); // после trim — 4 символа
      expect(Validators.title('  abcde  '), isNull);
    });
  });

  group('Validators.body', () {
    test('null и пробелы -> «Введите текст поста»', () {
      expect(Validators.body(null), 'Введите текст поста');
      expect(Validators.body('   \n  '), 'Введите текст поста');
    });

    test('граница снизу: 9 символов — ошибка, 10 — допустимо', () {
      expect(Validators.body('123456789'), 'Текст: от 10 до 1000 символов');
      expect(Validators.body('1234567890'), isNull);
    });

    test('граница сверху: 1000 — допустимо, 1001 — ошибка', () {
      expect(Validators.body('x' * 1000), isNull);
      expect(Validators.body('x' * 1001), 'Текст: от 10 до 1000 символов');
    });
  });

  group('Validators.userId', () {
    test('автор не выбран (null) -> ошибка', () {
      expect(Validators.userId(null), 'Выберите автора');
    });

    test('автор выбран -> ошибки нет', () {
      expect(Validators.userId(1), isNull);
    });
  });
}
