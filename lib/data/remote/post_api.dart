import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';

part 'post_api.g.dart';

@RestApi()
abstract class PostApi {
  factory PostApi(Dio dio, {String? baseUrl}) = _PostApi;

  /// 1. Список постов с пагинацией (+ необязательный фильтр по автору и сортировка).
  @GET('/posts')
  Future<List<Post>> getPosts({
    @Query('_page') required int page,
    @Query('_limit') required int limit,
    @Query('userId') int? userId,
    @Query('_sort') String? sort,
    @Query('_order') String? order,
  });

  /// 2. Подробная информация о посте.
  @GET('/posts/{id}')
  Future<Post> getPost(@Path('id') int id);

  /// 3. Посты конкретного пользователя.
  @GET('/posts')
  Future<List<Post>> getPostsByUser(@Query('userId') int userId);

  /// 4. Комментарии к посту.
  @GET('/posts/{id}/comments')
  Future<List<Comment>> getComments(@Path('id') int id);

  /// 5. Создание поста.
  @POST('/posts')
  Future<Post> createPost(@Body() CreatePostRequest body);

  /// Дополнительно: авторы.
  @GET('/users')
  Future<List<User>> getUsers();

  @GET('/users/{id}')
  Future<User> getUser(@Path('id') int id);
}
