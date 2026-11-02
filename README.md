# Post Explorer (SRS 8 + SRS 9)

Flutter-приложение для просмотра, поиска и создания постов (JSONPlaceholder).
Стек: **Dio + Retrofit**, **json_serializable**, **Bloc/Cubit**, кэш на **SharedPreferences**.

## Запуск

```bash
flutter create . --platforms=android,ios   # один раз: создаёт android/ios (lib/ и pubspec не перезаписываются)
flutter pub get
dart run flutter_launcher_icons   # генерирует иконку из assets/icon/app_icon.png (нужны android/ios)
dart run build_runner build --delete-conflicting-outputs   # генерирует *.g.dart
flutter run
flutter test
```

## Архитектура

```
Presentation (screens, widgets, Cubit)  ->  Repository (кэш, ошибки)  ->  Remote (Retrofit + Dio)
```
UI не обращается к Dio: экраны работают только с Cubit, Cubit — с `PostRepository`.

## API (Retrofit, `data/remote/post_api.dart`)
| Метод | Endpoint | Назначение |
|---|---|---|
| GET | /posts?_page&_limit (+userId, _sort, _order) | список с пагинацией, фильтром и сортировкой |
| GET | /posts/{id} | детали поста |
| GET | /posts?userId={id} | посты автора (на экране деталей) |
| GET | /posts/{id}/comments | комментарии |
| POST | /posts | создание поста |
| GET | /users, /users/{id} | авторы (фильтр, форма, детали) |

## Поведение кэша
- **Первый запуск:** кэша нет → индикатор загрузки → данные с сервера → запись в кэш.
- **Повторное открытие:** сразу показывается сохранённая первая страница с плашкой «Показаны сохранённые данные. Обновляем…», параллельно идёт запрос; при успехе список заменяется свежими данными, кэш обновляется, плашка исчезает.
- **Нет интернета:** при наличии кэша остаётся последний успешный результат с плашкой «Показаны сохранённые данные» и текстом ошибки; кэш не удаляется. Без кэша — экран ошибки с кнопкой «Повторить».
- **Pull-to-refresh:** список остаётся на экране, пока идёт запрос.
- Кэш хранится отдельно для каждого сочетания фильтр/сортировка.

## Состояния и ошибки
- Раздельные статусы: `ListStatus` (loading/success/error), `LoadMoreStatus` (idle/loading/error), `DataSource` (server/cache), `SubmitStatus` для формы. Empty — вычисляется (`state.isEmpty`).
- `AppException` различает: нет соединения, таймаут, 4xx, 5xx, ошибку JSON, неизвестную. Пользователь видит понятный текст, технические детали — в `debugPrint`.
- Ошибка JSON не роняет приложение: `@JsonSerializable(checked: true)` + преобразование в `AppException.parse`.

## Пагинация и фильтры
- 10 постов на страницу, подгрузка за 200 px до конца, индикатор внизу, при ошибке — текст и «Повторить».
- Защита от дублей: проверка `loadMore == loading` + множество страниц «в полёте».
- Смена фильтра/сортировки увеличивает токен запроса: ответы устаревших запросов игнорируются, страницы сбрасываются.
- Поиск по заголовку локальный; в интерфейсе подписано «Ищет только среди загруженных постов».

## Создание поста
Валидация (title 5–100, body 10–1000, автор из списка) → POST через Retrofit → кнопка блокируется на время запроса → показ ответа сервера → пост появляется вверху списка с пометкой «создан локально» (JSONPlaceholder его не сохраняет, детали такого поста недоступны).

## Тесты (`flutter test`)
JSON→Post, Post→JSON, загрузка через репозиторий, ошибка сервера (500/404), некорректный JSON, фильтрация и поиск, защита от дублей страницы, ошибка подгрузки + retry, показ кэша при ошибке, POST через `http_mock_adapter`, валидаторы.

## SRS 9: иконка и тесты
**Иконка:** `assets/icon/app_icon.png` (1024×1024, лупа над карточкой поста — тематика приложения), для Android Adaptive Icon — `app_icon_foreground.png` (прозрачный фон, содержимое в «безопасной зоне») + фон `#3F51B5`. Настройка — секция `flutter_launcher_icons` в `pubspec.yaml`.

**Тесты** (`flutter test`):
| Файл | Вид | Что проверяет |
|---|---|---|
| `test/unit/validators_test.dart` | Unit | валидаторы формы: пустые/пробелы/null, границы 5/100 и 10/1000, автор |
| `test/unit/app_exception_test.dart` | Unit | преобразование ошибок: таймаут, нет сети, 404, 5xx, битый JSON, неизвестная |
| `test/unit/state_logic_test.dart` | Unit | `PostQuery`, `visiblePosts`/`isEmpty`, `CreatePostCubit` (успех, ошибка) |
| `test/widget/post_list_screen_test.dart` | Widget | главный экран, поиск, сортировка, ошибка + «Повторить», переход на детали и назад |
| `test/widget/create_post_screen_test.dart` | Widget | переход на форму, некорректный ввод, полная отправка формы |
| `test/post_test.dart` | Unit | тесты из SRS 8 (JSON, репозиторий, пагинация, кэш, POST) |
