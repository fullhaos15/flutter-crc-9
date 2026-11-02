import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/data/models/post.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';
import 'package:post_explorer/presentation/state/create_post_cubit.dart';
import 'package:post_explorer/presentation/state/post_list_cubit.dart';

import '../helpers.dart';

/// API, у которого создание поста падает с ошибкой сервера.
class _FailingCreateApi extends FakePostApi {
  @override
  Future<Post> createPost(CreatePostRequest body) async => throw serverError(500);
}

void main() {
  group('PostQuery', () {
    test('cacheKey различается для фильтра и сортировки', () {
      expect(const PostQuery().cacheKey, 'posts_all_asc');
      expect(const PostQuery(userId: 2, ascending: false).cacheKey, 'posts_2_desc');
    });

    test('copyWith(clearUser) сбрасывает автора; равенство по значению', () {
      const q = PostQuery(userId: 3);
      expect(q.copyWith(clearUser: true).userId, isNull);
      expect(const PostQuery(userId: 3), q);
    });
  });

  group('PostListState.visiblePosts', () {
    final items = [
      const Post(userId: 1, id: 1, title: 'Alpha', body: 'b'),
      const Post(userId: 1, id: 2, title: 'Beta', body: 'b'),
    ];
    const local = Post(userId: 2, id: 101, title: 'Alpha local', body: 'b', isLocal: true);

    test('локальные посты идут сверху', () {
      final s = PostListState(items: items, localPosts: const [local]);
      expect(s.visiblePosts.first.id, 101);
      expect(s.visiblePosts.length, 3);
    });

    test('поиск без учёта регистра по заголовку', () {
      final s = PostListState(items: items, localPosts: const [local], search: 'ALPHA');
      expect(s.visiblePosts.map((p) => p.id), [101, 1]);
    });

    test('локальный пост другого автора скрывается фильтром по автору', () {
      final s = PostListState(
        items: items,
        localPosts: const [local],
        query: const PostQuery(userId: 1),
      );
      expect(s.visiblePosts.map((p) => p.id), [1, 2]);
    });

    test('isEmpty: true только когда загрузка успешна и ничего не найдено', () {
      expect(const PostListState().isEmpty, isFalse); // ещё loading
      final s = PostListState(
        status: ListStatus.success,
        items: items,
        search: 'zzz',
      );
      expect(s.isEmpty, isTrue);
    });
  });

  group('CreatePostCubit', () {
    late FakePostApi api;
    late CreatePostCubit cubit;

    setUp(() {
      api = FakePostApi();
      cubit = CreatePostCubit(PostRepository(api: api, cache: InMemoryCache()));
    });

    tearDown(() => cubit.close());

    test('submit: пробелы обрезаются, статус success, ответ сохранён', () async {
      await cubit.submit(title: '  Hello world  ', body: '  Some body text  ', userId: 1);
      expect(cubit.state.submit, SubmitStatus.success);
      expect(cubit.state.created?.title, 'Hello world');
      expect(cubit.state.created?.body, 'Some body text');
    });

    test('submit: ошибка сервера -> failure с понятным текстом', () async {
      final failing = CreatePostCubit(
        PostRepository(api: _FailingCreateApi(), cache: InMemoryCache()),
      );
      addTearDown(failing.close);

      await failing.submit(title: 'Hello world', body: 'Some body text', userId: 1);
      expect(failing.state.submit, SubmitStatus.failure);
      expect(failing.state.error, contains('500'));
      expect(failing.state.created, isNull);
    });
  });
}
