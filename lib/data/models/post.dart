import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

@JsonSerializable(checked: true)
class Post {
  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
    this.isLocal = false,
  });

  final int userId;
  final int id;
  final String title;
  final String body;

  /// Пост создан локально (сервер JSONPlaceholder его не сохраняет).
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isLocal;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);

  Post asLocal() => Post(
        userId: userId,
        id: id,
        title: title,
        body: body,
        isLocal: true,
      );
}

/// Тело POST /posts.
@JsonSerializable()
class CreatePostRequest {
  const CreatePostRequest({
    required this.title,
    required this.body,
    required this.userId,
  });

  final String title;
  final String body;
  final int userId;

  factory CreatePostRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePostRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreatePostRequestToJson(this);
}
