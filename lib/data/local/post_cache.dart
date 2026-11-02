import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';
import '../models/user.dart';

abstract class PostCache {
  Future<List<Post>> readPosts(String key);
  Future<void> writePosts(String key, List<Post> posts);
  Future<List<User>> readUsers();
  Future<void> writeUsers(List<User> users);
}

/// Простой кэш на SharedPreferences. Повреждённый кэш не приводит к падению.
class SharedPrefsPostCache implements PostCache {
  SharedPrefsPostCache(this._prefs);

  final SharedPreferences _prefs;
  static const _usersKey = 'cache_users_v1';

  @override
  Future<List<Post>> readPosts(String key) async {
    try {
      final raw = _prefs.getString('cache_$key');
      if (raw == null) return const [];
      return (jsonDecode(raw) as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> writePosts(String key, List<Post> posts) async {
    await _prefs.setString(
      'cache_$key',
      jsonEncode(posts.map((p) => p.toJson()).toList()),
    );
  }

  @override
  Future<List<User>> readUsers() async {
    try {
      final raw = _prefs.getString(_usersKey);
      if (raw == null) return const [];
      return (jsonDecode(raw) as List)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> writeUsers(List<User> users) async {
    await _prefs.setString(
      _usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }
}
