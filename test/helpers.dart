import 'dart:async';

import 'package:dio/dio.dart';
import 'package:post_explorer/data/local/post_cache.dart';
import 'package:post_explorer/data/models/comment.dart';
import 'package:post_explorer/data/models/post.dart';
import 'package:post_explorer/data/models/user.dart';
import 'package:post_explorer/data/remote/post_api.dart';

class InMemoryCache implements PostCache {
  final Map<String, List<Post>> posts = {};
  List<User> users = [];

  @override
  Future<List<Post>> readPosts(String key) async => posts[key] ?? const [];
  @override
  Future<void> writePosts(String key, List<Post> p) async => posts[key] = p;
  @override
  Future<List<User>> readUsers() async => users;
  @override
  Future<void> writeUsers(List<User> u) async => users = u;
}

/// 30 постов: userId = 1..3, по 10 постов на автора.
List<Post> allPosts() => List.generate(
      30,
      (i) => Post(
        userId: i ~/ 10 + 1,
        id: i + 1,
        title: 'Title ${i + 1}',
        body: 'Body of post number ${i + 1}',
      ),
    );

class FakePostApi implements PostApi {
  final List<String> calls = [];
  Object? error;

  /// Если задан — getPosts ждёт этот completer (для теста дублей).
  Completer<void>? gate;

  @override
  Future<List<Post>> getPosts({
    required int page,
    required int limit,
    int? userId,
    String? sort,
    String? order,
  }) async {
    calls.add('posts page=$page user=$userId order=$order');
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    var list = allPosts().where((p) => userId == null || p.userId == userId).toList();
    if (order == 'desc') list = list.reversed.toList();
    return list.skip((page - 1) * limit).take(limit).toList();
  }

  @override
  Future<Post> getPost(int id) async => allPosts()[id - 1];
  @override
  Future<List<Post>> getPostsByUser(int userId) async =>
      allPosts().where((p) => p.userId == userId).toList();
  @override
  Future<List<Comment>> getComments(int id) async => [];
  @override
  Future<Post> createPost(CreatePostRequest body) async =>
      Post(userId: body.userId, id: 101, title: body.title, body: body.body);
  @override
  Future<List<User>> getUsers() async => [];
  @override
  Future<User> getUser(int id) async =>
      User(id: id, name: 'N', username: 'u', email: 'e@e.e');
}

DioException serverError(int code) {
  final ro = RequestOptions(path: '/posts');
  return DioException(
    requestOptions: ro,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: ro, statusCode: code),
  );
}
