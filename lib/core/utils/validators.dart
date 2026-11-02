/// Валидация формы создания поста (задание F).
class Validators {
  static String? title(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите заголовок';
    if (v.length < 5 || v.length > 100) {
      return 'Заголовок: от 5 до 100 символов';
    }
    return null;
  }

  static String? body(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите текст поста';
    if (v.length < 10 || v.length > 1000) {
      return 'Текст: от 10 до 1000 символов';
    }
    return null;
  }

  static String? userId(int? value) =>
      value == null ? 'Выберите автора' : null;
}
