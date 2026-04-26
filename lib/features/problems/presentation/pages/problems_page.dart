import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../core/utils/async_value.dart';
import '../../../../shared/styles/semantic_colors.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/luogu_tag_catalog.dart';
import '../../domain/models/problem.dart';
import '../controllers/problems_controller.dart';

class ProblemsPage extends StatefulWidget {
  const ProblemsPage({super.key});

  @override
  State<ProblemsPage> createState() => _ProblemsPageState();
}

class _ProblemsPageState extends State<ProblemsPage> {
  late final ProblemsController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ProblemsController()..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('problems.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.sell_outlined),
            tooltip: context.t('problems.tags'),
            onPressed: _showTagSheet,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: context.t('problems.sort'),
            onPressed: _showSortDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              controller: _searchController,
              hintText: context.t('problems.searchHint'),
              leading: const Icon(Icons.search),
              onSubmitted: _controller.search,
              trailing: [
                IconButton(
                  tooltip: context.t('problems.clear'),
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    _controller.search('');
                  },
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final selectedTag = LuoguTagCatalog.findById(_controller.tag);
              if (selectedTag == null) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Chip(
                      label: Text(selectedTag.name),
                      onDeleted: () => _controller.filterByTag(null),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return switch (_controller.state) {
                  AsyncInitial<List<Problem>>() ||
                  AsyncLoading<List<Problem>>() =>
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  AsyncError<List<Problem>>(message: final message) =>
                    AppEmptyState(
                      title: context.t('problems.loadFailed'),
                      message: message,
                      icon: Icons.error_outline,
                    ),
                  AsyncData<List<Problem>>(value: final problems)
                      when problems.isEmpty =>
                    AppEmptyState(
                      title: context.t('problems.emptyTitle'),
                      message: context.t('problems.emptyMessage'),
                      icon: Icons.search_off,
                    ),
                  AsyncData<List<Problem>>(value: final problems) =>
                    RefreshIndicator(
                      onRefresh: _controller.load,
                      child: ListView.builder(
                        itemCount: problems.length,
                        itemBuilder: (context, index) {
                          final problem = problems[index];
                          return ListTile(
                            leading: SizedBox(
                              width: 56,
                              child: Center(
                                child: Text(
                                  problem.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(problem.title),
                            subtitle: Row(
                              children: [
                                StatusChip(
                                  label: problem.difficultyLabel,
                                  color: SemanticColors.problemDifficulty(
                                    problem.difficulty,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.t(
                                    'problems.acceptRate',
                                    args: {
                                      'rate':
                                          problem.acceptRate.toStringAsFixed(1),
                                    },
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              problem.isAccepted
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: problem.isAccepted
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.problemDetail,
                              arguments: problem,
                            ),
                          );
                        },
                      ),
                    ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTagSheet() async {
    final selected = await showDialog<String?>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
          child: _TagPickerSheet(selectedTagId: _controller.tag),
        ),
      ),
    );

    if (!mounted) return;
    await _controller.filterByTag(selected);
  }

  Future<void> _showFilterSheet() async {
    final selected = await showDialog<ProblemDifficulty?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.t('problems.pickDifficulty')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    _controller.difficulty == null
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(context.t('problems.allDifficulty')),
                  onTap: () => Navigator.pop(context),
                ),
                for (final difficulty in ProblemDifficulty.values)
                  RadioListTile<ProblemDifficulty>(
                    value: difficulty,
                    groupValue: _controller.difficulty,
                    title: Text(difficulty.difficultyLabel),
                    onChanged: (value) => Navigator.pop(context, value),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    await _controller.filterByDifficulty(selected);
  }

  Future<void> _showSortDialog() async {
    final selected = await showDialog<ProblemSortOption>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.t('problems.pickSort')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in ProblemSortOption.values)
                RadioListTile<ProblemSortOption>(
                  value: option,
                  groupValue: _controller.sortOption,
                  title: Text(_sortLabel(option)),
                  onChanged: (value) => Navigator.pop(context, value),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    await _controller.sortBy(selected);
  }

  String _sortLabel(ProblemSortOption option) {
    return switch (option) {
      ProblemSortOption.idAsc => context.t('problems.sort.idAsc'),
      ProblemSortOption.idDesc => context.t('problems.sort.idDesc'),
      ProblemSortOption.difficultyAsc =>
        context.t('problems.sort.difficultyAsc'),
      ProblemSortOption.difficultyDesc =>
        context.t('problems.sort.difficultyDesc'),
      ProblemSortOption.acceptRateDesc =>
        context.t('problems.sort.acceptRateDesc'),
      ProblemSortOption.acceptRateAsc =>
        context.t('problems.sort.acceptRateAsc'),
    };
  }
}

class _TagPickerSheet extends StatefulWidget {
  const _TagPickerSheet({required this.selectedTagId});

  final String? selectedTagId;

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  final _searchController = TextEditingController();
  int _type = 2;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _searchController.text.trim().toLowerCase();
    final tags = LuoguTagCatalog.byType(_type).where((tag) {
      return keyword.isEmpty ||
          tag.name.toLowerCase().contains(keyword) ||
          '${tag.id}'.contains(keyword);
    }).toList(growable: false);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SearchBar(
                controller: _searchController,
                hintText: context.t('problems.searchTagHint'),
                leading: const Icon(Icons.search),
                onChanged: (_) => setState(() {}),
                trailing: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final type in LuoguTagCatalog.types)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(type.name),
                        selected: _type == type.id,
                        onSelected: (_) => setState(() => _type = type.id),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 16),
            ListTile(
              leading: Icon(
                widget.selectedTagId == null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(context.t('problems.allTags')),
              onTap: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final id = '${tag.id}';
                  return ListTile(
                    leading: Icon(
                      widget.selectedTagId == id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(tag.name),
                    subtitle: Text('#${tag.id}'),
                    onTap: () => Navigator.pop(context, id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
