import 'package:flutter/foundation.dart';

import '../domain/models/problem.dart';

class FavoriteProblemStore {
  const FavoriteProblemStore._();

  static final ValueNotifier<List<Problem>> listenable =
      ValueNotifier<List<Problem>>(const []);

  static bool contains(String problemId) {
    return listenable.value.any((problem) => problem.id == problemId);
  }

  static void toggle(Problem problem) {
    final current = [...listenable.value];
    final index = current.indexWhere((item) => item.id == problem.id);
    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.insert(0, problem);
    }

    listenable.value = List.unmodifiable(current);
  }
}
