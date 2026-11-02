import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/comment.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';
import 'post_list_cubit.dart' show ListStatus;

class PostDetailState extends Equatable {
  const PostDetailState({
    this.status = ListStatus.loading,
    this.post,
    this.author,
    this.comments = const [],
    this.authorPosts = const [],
    this.error,
  });

  final ListStatus status;
  final Post? post;
  final User? author;
  final List<Comment> comments;
  final List<Post> authorPosts;
  final String? error;

  @override
  List<Object?> get props => [status, post, author, comments, authorPosts, error];
}

class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit(this._repo, Post initial)
      : _initial = initial,
        super(PostDetailState(post: initial));

  final PostRepository _repo;
  final Post _initial;

  Future<void> load() async {
    emit(PostDetailState(post: state.post ?? _initial));
    try {
      final r = await Future.wait<Object>([
        _repo.getPost(_initial.id),
        _repo.getUser(_initial.userId),
        _repo.getComments(_initial.id),
        _repo.getPostsByUser(_initial.userId),
      ]);
      emit(PostDetailState(
        status: ListStatus.success,
        post: r[0] as Post,
        author: r[1] as User,
        comments: r[2] as List<Comment>,
        authorPosts: r[3] as List<Post>,
      ));
    } on AppException catch (e) {
      emit(PostDetailState(
        status: ListStatus.error,
        post: state.post,
        error: e.message,
      ));
    }
  }
}
