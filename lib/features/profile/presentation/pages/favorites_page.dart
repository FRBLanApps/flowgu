import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../shared/styles/semantic_colors.dart';
import '../../../problems/data/favorite_problem_store.dart';
import '../../../problems/domain/models/problem.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('profile.favorites'))),
      body: ValueListenableBuilder<List<Problem>>(
        valueListenable: FavoriteProblemStore.listenable,
        builder: (context, problems, _) {
          if (problems.isEmpty) {
            return Center(child: Text(context.t('favorites.empty')));
          }
          return ListView.separated(
            itemCount: problems.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final problem = problems[index];
              return ListTile(
                title: Text('${problem.id} ${problem.title}'),
                subtitle: Text(
                  problem.difficultyLabel,
                  style: TextStyle(
                    color: SemanticColors.problemDifficulty(problem.difficulty),
                  ),
                ),
                trailing: IconButton(
                  tooltip: context.t('problem.unfavorite'),
                  onPressed: () => FavoriteProblemStore.toggle(problem),
                  icon: const Icon(Icons.star),
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.problemDetail,
                  arguments: problem,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
