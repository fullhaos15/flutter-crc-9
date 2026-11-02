import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:post_explorer/core/error/app_exception.dart';
import 'package:post_explorer/core/utils/validators.dart';
import 'package:post_explorer/data/models/post.dart';
import 'package:post_explorer/data/remote/post_api.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';
import 'package:post_explorer/presentation/state/post_list_cubit.dart';
import 'dart:async';

import 'helpers.dart';

void main() {
  group('JSON', () {
    test('1. JSON -> Post', () {
      final post = Post.fromJson({
        'userId': 1,
        'id': 7,
        'title': 'hello',
        'body': 'world',
      });
      expect(post.id, 7);
      expect(post.userId, 1);
      expect(post.title, 'hello');
      expect(post.isLocal, isFalse);
    });

    test('2. Post -> JSON', () {
      const post = Post(userId: 2, id: 3, title: 't', body: 'b');
      expect(post.toJson(), {'userId': 2, 'id': 3, 'title': 't', 'body': 'b'});
    });
  });

  group('PostRepository', () {
    late FakePostApi api;
    late InMemoryCache cache;
    late PostRepository repo;

    setUp(() {
      api = FakePostApi();
      cache = InMemoryCache();
      repo = PostRepository(api: api, cache: cache);
    });

    test('3. успешная загрузка постов и запись в кэш', () async {
      final posts = await repo.fetchPosts(const PostQuery(), 1);
      expect(posts.length, 10);
      expect(cache.posts[const PostQuery().cacheKey], posts);
    });

    test('4. ошибка сервера (500) -> AppException.server, кэш не стирается', () async {
      await repo.fetchPosts(const PostQuery(), 1);
      api.error = serverError(500);
      await expectLater(
        repo.fetchPosts(const PostQuery(), 1),
        throwsA(isA<AppException>().having((e) => e.type, 'type', AppErrorType.server)),
      );
      expect(cache.posts[const PostQuery().cacheKey], isNotEmpty);
    });

    test('ошибка 404 -> AppException.client', () async {
      api.error = serverError(404);
      await expectLater(
        repo.fetchPosts(const PostQuery(), 1),
        throwsA(isA<AppException>().having((e) => e.type, 'type', AppErrorType.client)),
      );
    });

    test('некорректный JSON -> AppException.parse (без падения)', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://x.test'));
      DioAdapter(dio: dio).onGet(
        '/posts/1',
        (s) => s.reply(200, {'userId': 'не число', 'id': 1}),
      );
      final r = PostRepository(api: PostApi(dio), cache: cache);
      await expectLater(
        r.getPost(1),
        throwsA(isA<AppException>().having((e) => e.type, 'type', AppErrorType.parse)),
      );
    });
  });

  group('PostListCubit', () {
    late FakePostApi api;
    late PostListCubit cubit;

    setUp(() {
      api = FakePostApi();
      cubit = PostListCubit(PostRepository(api: api, cache: InMemoryCache()));
    });

    tearDown(() => cubit.close());

    test('5a. фильтр по автору: результаты не смешиваются, страницы сброшены', () async {
      await cubit.load();
      await cubit.loadMore();
      expect(cubit.state.items.length, 20);

      await cubit.setUserId(3);
      expect(cubit.state.page, 1);
      expect(cubit.state.items.length, 10);
      expect(cubit.state.items.every((p) => p.userId == 3), isTrue);
    });

    test('5b. поиск по заголовку среди загруженных', () async {
      await cubit.load();
      cubit.setSearch('title 7');
      expect(cubit.state.visiblePosts.map((p) => p.id), [7]);
      cubit.setSearch('nothing');
      expect(cubit.state.isEmpty, isTrue);
    });

    test('6. защита от дублирующейся загрузки страницы', () async {
      await cubit.load();
      api.calls.clear();
      api.gate = Completer<void>();

      final f1 = cubit.loadMore();
      final f2 = cubit.loadMore(); // повторный вызов пока идёт первый
      api.gate!.complete();
      await Future.wait([f1, f2]);

      expect(api.calls.where((c) => c.startsWith('posts page=2')).length, 1);
      expect(cubit.state.items.length, 20);
    });

    test('ошибка подгрузки: список сохраняется, retry работает', () async {
      await cubit.load();
      api.error = serverError(500);
      await cubit.loadMore();
      expect(cubit.state.loadMore, LoadMoreStatus.error);
      expect(cubit.state.items.length, 10);

      api.error = null;
      await cubit.loadMore();
      expect(cubit.state.loadMore, LoadMoreStatus.idle);
      expect(cubit.state.items.length, 20);
    });

    test('сеть недоступна: показывается кэш', () async {
      await cubit.load(); // кэш заполнен
      api.error = serverError(500);
      await cubit.load();
      expect(cubit.state.status, ListStatus.success);
      expect(cubit.state.source, DataSource.cache);
      expect(cubit.state.items.length, 10);
      expect(cubit.state.notice, isNotNull);
    });
  });

  group('POST через mock-адаптер Dio', () {
    test('7. createPost', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://x.test'));
      DioAdapter(dio: dio).onPost(
        '/posts',
        (s) => s.reply(201, {'title': 'Hello world', 'body': 'Some body text', 'userId': 1, 'id': 101}),
        data: {'title': 'Hello world', 'body': 'Some body text', 'userId': 1},
      );
      final created = await PostApi(dio).createPost(
        const CreatePostRequest(title: 'Hello world', body: 'Some body text', userId: 1),
      );
      expect(created.id, 101);
      expect(created.title, 'Hello world');
    });
  });

  group('Validators', () {
    test('границы длины', () {
      expect(Validators.title('abcd'), isNotNull);
      expect(Validators.title('abcde'), isNull);
      expect(Validators.title('a' * 101), isNotNull);
      expect(Validators.body('123456789'), isNotNull);
      expect(Validators.body('1234567890'), isNull);
      expect(Validators.userId(null), isNotNull);
    });
  });
}
