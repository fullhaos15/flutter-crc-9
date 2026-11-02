import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_helpers.dart';

/// Widget-тесты экрана создания поста: навигация, валидация (некорректный ввод),
/// взаимодействие нескольких элементов (поля + выпадающий список + кнопка).
void main() {
  late UiFakeApi api;

  setUp(() => api = UiFakeApi());

  Future<void> openForm(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(buildApp(api));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  testWidgets('6. переход на форму: заголовок, поля и кнопка «Отправить»', (tester) async {
    await openForm(tester);

    expect(find.widgetWithText(AppBar, 'Новый пост'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Заголовок'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Текст'), findsOneWidget);
    expect(find.text('Автор'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Отправить'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Post Explorer'), findsOneWidget);
  });

  testWidgets('7. некорректный ввод: пустая форма и слишком короткие значения', (tester) async {
    await openForm(tester);

    // Пустая форма.
    await tester.tap(find.text('Отправить'));
    await tester.pump();
    expect(find.text('Введите заголовок'), findsOneWidget);
    expect(find.text('Введите текст поста'), findsOneWidget);
    expect(find.text('Выберите автора'), findsOneWidget);

    // Слишком короткие значения.
    await tester.enterText(find.widgetWithText(TextFormField, 'Заголовок'), 'abc');
    await tester.enterText(find.widgetWithText(TextFormField, 'Текст'), 'short');
    await tester.tap(find.text('Отправить'));
    await tester.pump();
    expect(find.text('Заголовок: от 5 до 100 символов'), findsOneWidget);
    expect(find.text('Текст: от 10 до 1000 символов'), findsOneWidget);

    // Запрос на сервер не уходил.
    expect(find.text('Ответ сервера'), findsNothing);
  });

  testWidgets('8. корректная отправка: ответ сервера и новый пост вверху списка',
      (tester) async {
    await openForm(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Заголовок'), 'Hello world');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Текст'), 'Some interesting body text');

    // Выбор автора в выпадающем списке.
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bob').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Отправить'));
    await tester.pumpAndSettle();

    // Ответ сервера (FakePostApi возвращает id = 101).
    expect(find.text('Ответ сервера'), findsOneWidget);
    expect(find.text('id: 101'), findsOneWidget);
    expect(find.text('userId: 2'), findsOneWidget);
    expect(find.text('title: Hello world'), findsOneWidget);
    expect(find.text('Пост создан (локально)'), findsOneWidget); // SnackBar

    // Возврат на список: пост сверху с пометкой.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Hello world'), findsOneWidget);
    expect(find.text('создан локально'), findsOneWidget);
  });
}
