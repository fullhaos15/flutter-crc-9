import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/data/models/user.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';
import 'package:post_explorer/main.dart';

import '../helpers.dart';

/// FakePostApi + список авторов (нужен для фильтра и формы создания).
class UiFakeApi extends FakePostApi {
  @override
  Future<List<User>> getUsers() async => const [
        User(id: 1, name: 'Ann', username: 'ann', email: 'ann@mail.test'),
        User(id: 2, name: 'Bob', username: 'bob', email: 'bob@mail.test'),
      ];

  @override
  Future<User> getUser(int id) async =>
      User(id: id, name: 'Ann', username: 'ann', email: 'ann@mail.test');
}

/// Настоящее приложение (PostExplorerApp) с поддельным API и кэшем в памяти.
Widget buildApp(UiFakeApi api) => PostExplorerApp(
      repository: PostRepository(api: api, cache: InMemoryCache()),
    );

/// Большой экран, чтобы форма и список целиком помещались в тесте.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
