import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../state/post_list_cubit.dart';
import '../widgets/common_widgets.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final _controller = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.hasClients &&
          _controller.position.pixels >=
              _controller.position.maxScrollExtent - 200) {
        context.read<PostListCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PostListCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Explorer'),
        actions: [
          BlocBuilder<PostListCubit, PostListState>(
            buildWhen: (a, b) => a.query != b.query,
            builder: (_, s) => IconButton(
              tooltip: s.query.ascending
                  ? 'Сортировка по ID: по возрастанию'
                  : 'Сортировка по ID: по убыванию',
              icon: Icon(s.query.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward),
              onPressed: cubit.toggleSort,
            ),
          ),
          IconButton(
            tooltip: 'Сбросить фильтры',
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () {
              _searchController.clear();
              cubit.resetFilters();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Новый пост'),
      ),
      body: BlocBuilder<PostListCubit, PostListState>(
        builder: (context, s) => Column(
          children: [
            _Filters(state: s, searchController: _searchController),
            if (s.source == DataSource.cache && s.status == ListStatus.success)
              InfoBanner(
                loading: s.refreshing,
                text: s.refreshing
                    ? 'Показаны сохранённые данные. Обновляем…'
                    : 'Показаны сохранённые данные'
                        '${s.notice != null ? '\n${s.notice}' : ''}',
              ),
            Expanded(child: _content(context, s)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, PostListState s) {
    final cubit = context.read<PostListCubit>();
    switch (s.status) {
      case ListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ListStatus.error:
        return ErrorView(message: s.errorMessage ?? 'Ошибка', onRetry: cubit.load);
      case ListStatus.success:
        final posts = s.visiblePosts;
        if (posts.isEmpty) {
          return RefreshIndicator(
            onRefresh: cubit.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    s.search.isNotEmpty
                        ? 'Среди загруженных постов ничего не найдено'
                        : 'Постов нет',
                  ),
                ),
                if (s.search.isNotEmpty && s.hasMore)
                  Center(
                    child: TextButton(
                      onPressed: cubit.loadMore,
                      child: const Text('Загрузить ещё посты'),
                    ),
                  ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView.builder(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: posts.length + 1,
            itemBuilder: (context, i) {
              if (i == posts.length) return _Footer(state: s);
              return _PostTile(post: posts[i]);
            },
          ),
        );
    }
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.searchController});

  final PostListState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PostListCubit>();
    final selected = state.users.any((u) => u.id == state.query.userId)
        ? state.query.userId
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: cubit.setSearch,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Поиск по заголовку',
              // Явно показываем область поиска.
              helperText:
                  'Ищет только среди загруженных постов (${state.loadedCount}), не по всему набору',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Автор: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: selected,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Все авторы'),
                    ),
                    ...state.users.map(
                      (u) => DropdownMenuItem<int?>(
                        value: u.id,
                        child: Text(u.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: cubit.setUserId,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(post.isLocal ? '+' : '${post.id}')),
      title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        post.body.replaceAll('\n', ' '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: post.isLocal ? const LocalChip() : null,
      onTap: () {
        if (post.isLocal) {
          // JSONPlaceholder не хранит созданные посты — детали с сервера недоступны.
          showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(post.title),
              content: Text(
                '${post.body}\n\nПост создан локально: сервер JSONPlaceholder '
                'не сохраняет POST-запросы.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              post: post,
              repository: context.read<PostRepository>(),
            ),
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final PostListState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PostListCubit>();
    Widget child;
    if (state.loadMore == LoadMoreStatus.loading) {
      child = const CircularProgressIndicator();
    } else if (state.loadMore == LoadMoreStatus.error) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(state.loadMoreError ?? 'Не удалось загрузить страницу'),
          TextButton.icon(
            onPressed: cubit.loadMore,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      );
    } else if (state.hasMore) {
      child = state.search.isNotEmpty
          ? TextButton(
              onPressed: cubit.loadMore,
              child: const Text('Загрузить ещё посты'),
            )
          : const SizedBox.shrink();
    } else {
      child = const Text('Это все посты');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: child),
    );
  }
}
