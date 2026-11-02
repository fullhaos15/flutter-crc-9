import 'package:equatable/equatable.dart';

import '../../core/error/app_exception.dart';
import '../local/post_cache.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../remote/post_api.dart';

/// Параметры списка: фильтр по автору и порядок сортировки по ID.
class PostQuery extends Equatable {
  const PostQuery({this.userId, this.ascending = true});

  final int? userId;
  final bool ascending;

  PostQuery copyWith({int? userId, bool clearUser = false, bool? ascending}) =>
      PostQuery(
        userId: clearUser ? null : (userId ?? this.userId),
        ascending: ascending ?? this.ascending,
      );

  String get cacheKey =>
      'posts_${userId ?? 'all'}_${ascending ? 'asc' : 'desc'}';

  @override
  List<Object?> get props => [userId, ascending];
}

class PostRepository {
  PostRepository({required PostApi api, required PostCache cache})
      : _api = api,
        _cache = cache;

  static const pageSize = 10;

  final PostApi _api;
  final PostCache _cache;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Сохранённая первая страница (для мгновенного показа).
  Future<List<Post>> getCachedFirstPage(PostQuery query) =>
      _cache.readPosts(query.cacheKey);

  /// Загрузка страницы. Первая страница обновляет кэш;
  /// при ошибке прежний кэш не удаляется.
  Future<List<Post>> fetchPosts(PostQuery query, int page) => _guard(() async {
        final posts = await _api.getPosts(
          page: page,
          limit: pageSize,
          userId: query.userId,
          sort: 'id',
          order: query.ascending ? 'asc' : 'desc',
        );
        if (page == 1) {
          try {
            await _cache.writePosts(query.cacheKey, posts);
          } catch (_) {/* ошибка кэша не должна ломать загрузку */}
        }
        return posts;
      });

  Future<Post> getPost(int id) => _guard(() => _api.getPost(id));

  Future<List<Post>> getPostsByUser(int userId) =>
      _guard(() => _api.getPostsByUser(userId));

  Future<List<Comment>> getComments(int postId) =>
      _guard(() => _api.getComments(postId));

  Future<User> getUser(int id) => _guard(() => _api.getUser(id));

  /// Список авторов; при ошибке сети берём сохранённых.
  Future<List<User>> getUsers() async {
    try {
      final users = await _api.getUsers();
      try {
        await _cache.writeUsers(users);
      } catch (_) {}
      return users;
    } catch (e) {
      final cached = await _cache.readUsers();
      if (cached.isNotEmpty) return cached;
      throw AppException.from(e);
    }
  }

  Future<Post> createPost(CreatePostRequest request) =>
      _guard(() => _api.createPost(request));
}
