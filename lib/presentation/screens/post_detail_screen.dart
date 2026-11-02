import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../state/post_detail_cubit.dart';
import '../state/post_list_cubit.dart' show ListStatus;
import '../widgets/common_widgets.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.post, required this.repository});

  final Post post;
  final PostRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PostDetailCubit(repository, post)..load(),
      child: Scaffold(
        appBar: AppBar(title: Text('Пост #${post.id}')),
        body: BlocBuilder<PostDetailCubit, PostDetailState>(
          builder: (context, s) {
            if (s.status == ListStatus.error) {
              return ErrorView(
                message: s.error ?? 'Ошибка',
                onRetry: context.read<PostDetailCubit>().load,
              );
            }
            final p = s.post ?? post;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(p.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(p.body),
                const Divider(height: 32),
                if (s.status == ListStatus.loading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (s.author != null) ...[
                    Text('Автор', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${s.author!.name} (@${s.author!.username})'),
                    Text(s.author!.email),
                    if (s.author!.address?.city != null)
                      Text('Город: ${s.author!.address!.city}'),
                    if (s.author!.company?.name != null)
                      Text('Компания: ${s.author!.company!.name}'),
                    const SizedBox(height: 8),
                    Text('Всего постов автора: ${s.authorPosts.length}'),
                    const Divider(height: 32),
                  ],
                  Text('Комментарии (${s.comments.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (s.comments.isEmpty) const Text('Комментариев нет'),
                  ...s.comments.map(
                    (c) => Card(
                      child: ListTile(
                        title: Text(c.name),
                        subtitle: Text('${c.email}\n${c.body}'),
                        isThreeLine: true,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
