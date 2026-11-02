import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import 'widget_helpers.dart';

/// Widget-тесты главного экрана приложения (PostListScreen) и перехода на детали.
void main() {
  late UiFakeApi api;

  setUp(() => api = UiFakeApi());

  testWidgets('1. экран: заголовок, поиск, фильтр, кнопка «Новый пост», список', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(buildApp(api));

    // Пока идёт загрузка — индикатор.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Post Explorer'), findsOneWidget); // заголовок AppBar
    expect(find.byType(TextField), findsOneWidget); // поле поиска
    expect(find.text('Поиск по заголовку'), findsOneWidget);
    expect(find.text('Все авторы'), findsOneWidget); // фильтр
    expect(find.text('Новый пост'), findsOneWidget); // FAB
    expect(find.byType(FloatingActionButton), findsOneWidget);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Title 1'), findsOneWidget);
    expect(find.text('Title 10'), findsOneWidget);
  });

  testWidgets('2. поиск: список меняется после ввода текста и очищается «ничего не найдено»',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(buildApp(api));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'title 3');
    await tester.pump();
    expect(find.text('Title 3'), findsOneWidget);
    expect(find.text('Title 1'), findsNothing);
    expect(find.text('Title 2'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Среди загруженных постов ничего не найдено'), findsOneWidget);

    // «Сбросить фильтры» очищает поиск и возвращает список.
    await tester.tap(find.byTooltip('Сбросить фильтры'));
    await tester.pumpAndSettle();
    expect(find.text('Title 1'), findsOneWidget);
    expect(find.text('Среди загруженных постов ничего не найдено'), findsNothing);
  });

  testWidgets('3. кнопка сортировки: меняется иконка и порядок постов', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(buildApp(api));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.text('Title 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Сортировка по ID: по возрастанию'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    expect(find.text('Title 30'), findsOneWidget); // теперь сверху самые новые
    expect(find.text('Title 1'), findsNothing);
  });

  testWidgets('4. ошибка сервера: экран ошибки, затем «Повторить» загружает список',
      (tester) async {
    useTallScreen(tester);
    api.error = serverError(500);
    await tester.pumpWidget(buildApp(api));
    await tester.pumpAndSettle();

    expect(find.text('Ошибка сервера (500). Попробуйте позже.'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Title 1'), findsNothing);

    api.error = null; // «сервер починили»
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.text('Повторить'), findsNothing);
    expect(find.text('Title 1'), findsOneWidget);
  });

  testWidgets('5. переход: список -> детали поста -> назад', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(buildApp(api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Title 1'));
    await tester.pumpAndSettle();

    // Экран деталей.
    expect(find.text('Пост #1'), findsOneWidget);
    expect(find.text('Body of post number 1'), findsOneWidget);
    expect(find.text('Ann (@ann)'), findsOneWidget); // автор
    expect(find.text('Всего постов автора: 10'), findsOneWidget);
    expect(find.text('Комментарии (0)'), findsOneWidget);
    expect(find.text('Комментариев нет'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    // Вернулись на список.
    expect(find.text('Post Explorer'), findsOneWidget);
    expect(find.text('Пост #1'), findsNothing);
  });
}
