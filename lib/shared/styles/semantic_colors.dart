import 'package:flutter/material.dart';

import '../../features/problems/domain/models/problem.dart';

class SemanticColors {
  const SemanticColors._();

  static Color problemDifficulty(ProblemDifficulty difficulty) {
    return switch (difficulty) {
      ProblemDifficulty.unrated => Colors.blueGrey,
      ProblemDifficulty.beginner => const Color(0xFFB0BEC5),
      ProblemDifficulty.easy => const Color(0xFF4CAF50),
      ProblemDifficulty.normal => const Color(0xFF00A6A6),
      ProblemDifficulty.medium => const Color(0xFF2196F3),
      ProblemDifficulty.hard => const Color(0xFF9C27B0),
      ProblemDifficulty.provincial => const Color(0xFFFF9800),
      ProblemDifficulty.noi => const Color(0xFFE53935),
    };
  }

  static Color luoguRank(String rankName) {
    final normalized = rankName.toLowerCase();
    if (normalized.contains('red') || rankName.contains('红')) {
      return const Color(0xFFE53935);
    }
    if (normalized.contains('orange') || rankName.contains('橙')) {
      return const Color(0xFFFF9800);
    }
    if (normalized.contains('yellow') || rankName.contains('黄')) {
      return const Color(0xFFF6C026);
    }
    if (normalized.contains('green') || rankName.contains('绿')) {
      return const Color(0xFF2EAD4A);
    }
    if (normalized.contains('blue') || rankName.contains('蓝')) {
      return const Color(0xFF2F80ED);
    }
    if (normalized.contains('purple') ||
        normalized.contains('violet') ||
        rankName.contains('紫')) {
      return const Color(0xFF9C27B0);
    }
    if (normalized.contains('gray') ||
        normalized.contains('grey') ||
        rankName.contains('灰')) {
      return Colors.blueGrey;
    }
    return const Color(0xFF2EAD4A);
  }
}
