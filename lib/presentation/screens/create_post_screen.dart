import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/validators.dart';
import '../../data/repositories/post_repository.dart';
import '../state/create_post_cubit.dart';
import '../state/post_list_cubit.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  int? _userId;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => CreatePostCubit(c.read<PostRepository>())..loadUsers(),
      child: BlocConsumer<CreatePostCubit, CreatePostState>(
        listenWhen: (a, b) => a.submit != b.submit,
        listener: (context, s) {
          if (s.submit == SubmitStatus.success && s.created != null) {
            context.read<PostListCubit>().addLocalPost(s.created!);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Пост создан (локально)')),
            );
          } else if (s.submit == SubmitStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.error ?? 'Не удалось создать пост')),
            );
          }
        },
        builder: (context, s) {
          final submitting = s.submit == SubmitStatus.submitting;
          return Scaffold(
            appBar: AppBar(title: const Text('Новый пост')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _title,
                        enabled: !submitting,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Заголовок',
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.title,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _body,
                        enabled: !submitting,
                        maxLength: 1000,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Текст',
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.body,
                      ),
                      const SizedBox(height: 12),
                      if (s.usersStatus == UsersStatus.loading)
                        const LinearProgressIndicator()
                      else if (s.usersStatus == UsersStatus.error)
                        Row(
                          children: [
                            Expanded(
                                child: Text(
                                    s.error ?? 'Не удалось загрузить авторов')),
                            TextButton(
                              onPressed:
                                  context.read<CreatePostCubit>().loadUsers,
                              child: const Text('Повторить'),
                            ),
                          ],
                        )
                      else
                        DropdownButtonFormField<int>(
                          initialValue: _userId,
                          decoration: const InputDecoration(
                            labelText: 'Автор',
                            border: OutlineInputBorder(),
                          ),
                          items: s.users
                              .map((u) => DropdownMenuItem(
                                  value: u.id, child: Text(u.name)))
                              .toList(),
                          onChanged: submitting
                              ? null
                              : (v) => setState(() => _userId = v),
                          validator: Validators.userId,
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          // Кнопка блокируется на время запроса.
                          onPressed: submitting
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<CreatePostCubit>().submit(
                                          title: _title.text,
                                          body: _body.text,
                                          userId: _userId!,
                                        );
                                  }
                                },
                          child: submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Отправить'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (s.created != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ответ сервера',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('id: ${s.created!.id}'),
                          Text('userId: ${s.created!.userId}'),
                          Text('title: ${s.created!.title}'),
                          Text('body: ${s.created!.body}'),
                          const SizedBox(height: 8),
                          const Text(
                            'JSONPlaceholder не сохраняет пост: он добавлен '
                            'только в локальный список с пометкой «создан локально».',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
