import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';

enum SubmitStatus { idle, submitting, success, failure }

enum UsersStatus { loading, ready, error }

class CreatePostState extends Equatable {
  const CreatePostState({
    this.submit = SubmitStatus.idle,
    this.usersStatus = UsersStatus.loading,
    this.users = const [],
    this.created,
    this.error,
  });

  final SubmitStatus submit;
  final UsersStatus usersStatus;
  final List<User> users;
  final Post? created;
  final String? error;

  CreatePostState copyWith({
    SubmitStatus? submit,
    UsersStatus? usersStatus,
    List<User>? users,
    Post? created,
    String? error,
    bool clearError = false,
  }) =>
      CreatePostState(
        submit: submit ?? this.submit,
        usersStatus: usersStatus ?? this.usersStatus,
        users: users ?? this.users,
        created: created ?? this.created,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [submit, usersStatus, users, created, error];
}

class CreatePostCubit extends Cubit<CreatePostState> {
  CreatePostCubit(this._repo) : super(const CreatePostState());

  final PostRepository _repo;

  Future<void> loadUsers() async {
    emit(state.copyWith(usersStatus: UsersStatus.loading));
    try {
      emit(state.copyWith(
        usersStatus: UsersStatus.ready,
        users: await _repo.getUsers(),
      ));
    } on AppException catch (e) {
      emit(state.copyWith(usersStatus: UsersStatus.error, error: e.message));
    }
  }

  Future<void> submit({
    required String title,
    required String body,
    required int userId,
  }) async {
    // Защита от повторного нажатия во время запроса.
    if (state.submit == SubmitStatus.submitting) return;
    emit(state.copyWith(submit: SubmitStatus.submitting, clearError: true));
    try {
      final created = await _repo.createPost(
        CreatePostRequest(title: title.trim(), body: body.trim(), userId: userId),
      );
      emit(state.copyWith(submit: SubmitStatus.success, created: created));
    } on AppException catch (e) {
      emit(state.copyWith(submit: SubmitStatus.failure, error: e.message));
    }
  }
}
