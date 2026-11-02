import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';

/// Раздельные статусы: список, подгрузка страницы и источник данных
/// не завязаны на один флаг isLoading.
enum ListStatus { loading, success, error }

enum LoadMoreStatus { idle, loading, error }

enum DataSource { server, cache }

const _unset = Object();

class PostListState extends Equatable {
  const PostListState({
    this.status = ListStatus.loading,
    this.loadMore = LoadMoreStatus.idle,
    this.source = DataSource.server,
    this.refreshing = false,
    this.items = const [],
    this.localPosts = const [],
    this.page = 0,
    this.hasMore = true,
    this.query = const PostQuery(),
    this.search = '',
    this.users = const [],
    this.errorMessage,
    this.notice,
    this.loadMoreError,
  });

  final ListStatus status;
  final LoadMoreStatus loadMore;
  final DataSource source;

  /// Идёт фоновое обновление (например, поверх кэша).
  final bool refreshing;
  final List<Post> items;
  final List<Post> localPosts;
  final int page;
  final bool hasMore;
  final PostQuery query;
  final String search;
  final List<User> users;
  final String? errorMessage;

  /// Сообщение при показе кэша из-за ошибки обновления.
  final String? notice;
  final String? loadMoreError;

  /// Локальные посты сверху + загруженные, с учётом поиска и фильтра.
  List<Post> get visiblePosts {
    final s = search.trim().toLowerCase();
    bool match(Post p) => s.isEmpty || p.title.toLowerCase().contains(s);
    final local = localPosts.where(
      (p) => (query.userId == null || p.userId == query.userId) && match(p),
    );
    return [...local, ...items.where(match)];
  }

  bool get isEmpty => status == ListStatus.success && visiblePosts.isEmpty;

  int get loadedCount => items.length + localPosts.length;

  PostListState copyWith({
    ListStatus? status,
    LoadMoreStatus? loadMore,
    DataSource? source,
    bool? refreshing,
    List<Post>? items,
    List<Post>? localPosts,
    int? page,
    bool? hasMore,
    PostQuery? query,
    String? search,
    List<User>? users,
    Object? errorMessage = _unset,
    Object? notice = _unset,
    Object? loadMoreError = _unset,
  }) {
    return PostListState(
      status: status ?? this.status,
      loadMore: loadMore ?? this.loadMore,
      source: source ?? this.source,
      refreshing: refreshing ?? this.refreshing,
      items: items ?? this.items,
      localPosts: localPosts ?? this.localPosts,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      search: search ?? this.search,
      users: users ?? this.users,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      notice: identical(notice, _unset) ? this.notice : notice as String?,
      loadMoreError: identical(loadMoreError, _unset)
          ? this.loadMoreError
          : loadMoreError as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        loadMore,
        source,
        refreshing,
        items,
        localPosts,
        page,
        hasMore,
        query,
        search,
        users,
        errorMessage,
        notice,
        loadMoreError,
      ];
}

class PostListCubit extends Cubit<PostListState> {
  PostListCubit(this._repo) : super(const PostListState());

  final PostRepository _repo;

  /// Токен запроса: ответы устаревших запросов (до смены фильтра) игнорируются,
  /// поэтому старые и новые результаты не смешиваются.
  int _token = 0;

  /// Страницы, которые сейчас загружаются (защита от дублей).
  final Set<int> _inFlight = {};

  /// Первичная загрузка / сброс: сначала кэш, затем сервер.
  Future<void> load() => _load(keepItems: false);

  /// Pull-to-refresh: список остаётся на экране, пока идёт запрос.
  Future<void> refresh() => _load(keepItems: true);

  Future<void> _load({required bool keepItems}) async {
    final token = ++_token;
    _inFlight.clear();
    final query = state.query;

    if (keepItems) {
      emit(state.copyWith(
        refreshing: true,
        loadMore: LoadMoreStatus.idle,
        notice: null,
        loadMoreError: null,
      ));
    } else {
      emit(state.copyWith(
        status: ListStatus.loading,
        loadMore: LoadMoreStatus.idle,
        source: DataSource.server,
        refreshing: false,
        items: const [],
        page: 0,
        hasMore: true,
        errorMessage: null,
        notice: null,
        loadMoreError: null,
      ));
      final cached = await _repo.getCachedFirstPage(query);
      if (token != _token) return;
      if (cached.isNotEmpty) {
        emit(state.copyWith(
          status: ListStatus.success,
          source: DataSource.cache,
          refreshing: true,
          items: cached,
          page: 1,
          hasMore: cached.length >= PostRepository.pageSize,
        ));
      }
    }

    try {
      final posts = await _repo.fetchPosts(query, 1);
      if (token != _token) return;
      emit(state.copyWith(
        status: ListStatus.success,
        source: DataSource.server,
        refreshing: false,
        items: posts,
        page: 1,
        hasMore: posts.length >= PostRepository.pageSize,
        errorMessage: null,
        notice: null,
      ));
    } on AppException catch (e) {
      if (token != _token) return;
      if (state.items.isNotEmpty) {
        // Последний успешный результат не удаляем.
        emit(state.copyWith(
          status: ListStatus.success,
          source: DataSource.cache,
          refreshing: false,
          notice: e.message,
        ));
      } else {
        emit(state.copyWith(
          status: ListStatus.error,
          refreshing: false,
          errorMessage: e.message,
        ));
      }
    }
  }

  Future<void> loadMore() async {
    if (state.status != ListStatus.success ||
        !state.hasMore ||
        state.refreshing ||
        state.loadMore == LoadMoreStatus.loading) {
      return;
    }
    final page = state.page + 1;
    if (!_inFlight.add(page)) return;
    final token = _token;
    emit(state.copyWith(loadMore: LoadMoreStatus.loading, loadMoreError: null));
    try {
      final posts = await _repo.fetchPosts(state.query, page);
      if (token != _token) return;
      final known = state.items.map((p) => p.id).toSet();
      emit(state.copyWith(
        items: [...state.items, ...posts.where((p) => !known.contains(p.id))],
        page: page,
        hasMore: posts.length >= PostRepository.pageSize,
        loadMore: LoadMoreStatus.idle,
      ));
    } on AppException catch (e) {
      if (token != _token) return;
      emit(state.copyWith(
        loadMore: LoadMoreStatus.error,
        loadMoreError: e.message,
      ));
    } finally {
      _inFlight.remove(page);
    }
  }

  /// Фильтр по автору: страницы сбрасываются, результаты не смешиваются.
  Future<void> setUserId(int? userId) {
    final q = state.query;
    emit(state.copyWith(
      query: userId == null ? q.copyWith(clearUser: true) : q.copyWith(userId: userId),
    ));
    return load();
  }

  Future<void> toggleSort() {
    emit(state.copyWith(query: state.query.copyWith(ascending: !state.query.ascending)));
    return load();
  }

  /// Поиск по заголовку — локально, среди уже загруженных постов.
  void setSearch(String value) => emit(state.copyWith(search: value));

  Future<void> resetFilters() {
    emit(state.copyWith(query: const PostQuery(), search: ''));
    return load();
  }

  Future<void> loadUsers() async {
    try {
      emit(state.copyWith(users: await _repo.getUsers()));
    } on AppException {
      // Фильтр по автору просто останется без списка.
    }
  }

  /// Создан новый пост: показываем сверху с пометкой «создан локально».
  void addLocalPost(Post post) =>
      emit(state.copyWith(localPosts: [post.asLocal(), ...state.localPosts]));
}
