import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'data/local/post_cache.dart';
import 'data/remote/post_api.dart';
import 'data/repositories/post_repository.dart';
import 'presentation/screens/post_list_screen.dart';
import 'presentation/state/post_list_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final dio = DioClient().dio; // единственный экземпляр Dio
  final repository = PostRepository(
    api: PostApi(dio),
    cache: SharedPrefsPostCache(prefs),
  );
  runApp(PostExplorerApp(repository: repository));
}

class PostExplorerApp extends StatelessWidget {
  const PostExplorerApp({super.key, required this.repository});

  final PostRepository repository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: BlocProvider(
        create: (_) => PostListCubit(repository)
          ..load()
          ..loadUsers(),
        child: MaterialApp(
          title: 'Post Explorer',
          theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
          home: const PostListScreen(),
        ),
      ),
    );
  }
}
