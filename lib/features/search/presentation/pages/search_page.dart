import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../shared/styles/semantic_colors.dart';
import '../../../problems/data/luogu_problem_repository.dart';
import '../../../problems/domain/models/problem.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _repository = LuoguProblemRepository();
  final _controller = TextEditingController();
  Future<List<Problem>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchProblems();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('search.title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _controller,
              hintText: context.t('search.hint'),
              leading: const Icon(Icons.search),
              onSubmitted: _search,
              trailing: [
                IconButton(
                  tooltip: context.t('common.search'),
                  onPressed: () => _search(_controller.text),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Problem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }

                final problems = snapshot.data ?? const [];
                if (problems.isEmpty) {
                  return Center(child: Text(context.t('search.empty')));
                }

                return ListView.separated(
                  itemCount: problems.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final problem = problems[index];
                    return ListTile(
                      title: Text('${problem.id} ${problem.title}'),
                      subtitle: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: problem.difficultyLabel,
                              style: TextStyle(
                                color: SemanticColors.problemDifficulty(
                                  problem.difficulty,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' · ${context.t(
                                'problems.acceptRate',
                                args: {
                                  'rate': problem.acceptRate.toStringAsFixed(1),
                                },
                              )}',
                            ),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
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
          ),
        ],
      ),
    );
  }

  void _search(String keyword) {
    setState(() {
      _future = _repository.fetchProblems(keyword: keyword.trim());
    });
  }
}
