import '../../../../shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_theme_controller.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../core/network/app_session.dart';
import '../../../../core/utils/async_value.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../data/luogu_language_repository.dart';
import '../../domain/models/code_submission.dart';
import '../../domain/models/problem.dart';
import '../controllers/submit_controller.dart';

class SubmitPage extends StatefulWidget {
  const SubmitPage({
    required this.argument,
    super.key,
  });

  final Object? argument;

  @override
  State<SubmitPage> createState() => _SubmitPageState();
}

class _SubmitPageState extends State<SubmitPage> {
  late final SubmitController _controller;
  late final LuoguLanguageRepository _languageRepository;
  late final _CodeEditingController _codeController;
  late final TextEditingController _captchaController;
  late final Problem? _problem;
  late final Future<List<SubmitLanguage>> _languagesFuture;

  SubmitLanguage _language = SubmitLanguages.cpp17;
  bool _enableO2 = false;
  String? _navigatedRecordId;

  @override
  void initState() {
    super.initState();
    _controller = SubmitController();
    _languageRepository = LuoguLanguageRepository();
    _problem = widget.argument is Problem ? widget.argument as Problem : null;
    _languagesFuture = _languageRepository.fetchSubmitLanguages(
      acceptedIds: _problem?.acceptLanguages ?? const [],
    );
    _enableO2 =
        AppThemeController.instance.defaultO2 && SubmitLanguages.cpp17.canO2;
    _codeController = _CodeEditingController(
      text: _language.template,
      language: _language,
    );
    _captchaController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _codeController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problem;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          problem == null
              ? context.t('submit.title')
              : context.t('submit.problemTitle', args: {'id': problem.id}),
        ),
      ),
      body: problem == null
          ? AppEmptyState(
              title: context.t('submit.missingProblemTitle'),
              message: context.t('submit.missingProblemMessage'),
            )
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                _navigateToRecordIfReady();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      problem.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${problem.sourceLabel} · ${problem.difficultyLabel}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SessionStatus(
                      onRefresh: () => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<SubmitLanguage>>(
                      future: _languagesFuture,
                      builder: (context, snapshot) {
                        final languages =
                            snapshot.data ?? SubmitLanguages.values;
                        final selected = _selectedLanguage(languages);

                        return DropdownButtonFormField<SubmitLanguage>(
                          value: selected,
                          decoration: InputDecoration(
                            labelText:
                                snapshot.connectionState == ConnectionState.done
                                    ? context.t('submit.language')
                                    : context.t('submit.syncingLanguages'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            for (final language in languages)
                              DropdownMenuItem(
                                value: language,
                                child: Text(language.name),
                              ),
                          ],
                          onChanged: _controller.state.isLoading
                              ? null
                              : (language) {
                                  if (language == null) {
                                    return;
                                  }
                                  _changeLanguage(language);
                                },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.t('submit.enableO2')),
                      subtitle: Text(
                        _language.canO2
                            ? context.t('submit.o2Supported')
                            : context.t('submit.o2Unsupported'),
                      ),
                      value: _enableO2 && _language.canO2,
                      onChanged: _controller.state.isLoading || !_language.canO2
                          ? null
                          : (value) => setState(() => _enableO2 = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      enabled: !_controller.state.isLoading,
                      minLines: 16,
                      maxLines: 28,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: context.t('submit.code'),
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _captchaController,
                      enabled: !_controller.state.isLoading,
                      decoration: InputDecoration(
                        labelText: context.t('submit.captcha'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _controller.state.isLoading
                          ? null
                          : () => _submit(problem),
                      icon: _controller.state.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(
                        _controller.state.isLoading
                            ? context.t('submit.submitting')
                            : context.t('submit.submit'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SubmissionResultView(state: _controller.state),
                  ],
                );
              },
            ),
    );
  }

  void _submit(Problem problem) {
    _controller.submit(
      CodeSubmissionRequest(
        problem: problem,
        language: _language,
        code: _codeController.text,
        enableO2: _enableO2,
        captcha: _captchaController.text.trim(),
      ),
    );
  }

  void _navigateToRecordIfReady() {
    final result = _controller.state.data;
    final recordId = result?.recordId;
    if (result == null ||
        !result.success ||
        recordId == null ||
        recordId.isEmpty ||
        _navigatedRecordId == recordId ||
        !AppThemeController.instance.autoOpenRecord) {
      return;
    }

    _navigatedRecordId = recordId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context)
          .pushNamed(AppRoutes.recordDetail, arguments: recordId);
    });
  }

  SubmitLanguage _selectedLanguage(List<SubmitLanguage> languages) {
    for (final language in languages) {
      if (language.id == _language.id) {
        return language;
      }
    }

    final selected =
        languages.isEmpty ? SubmitLanguages.cpp17 : languages.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && selected.id != _language.id) {
        _changeLanguage(
          selected,
          replaceTemplate: _codeController.text.trim().isEmpty,
        );
      }
    });
    return selected;
  }

  void _changeLanguage(
    SubmitLanguage language, {
    bool replaceTemplate = true,
  }) {
    setState(() {
      _language = language;
      _codeController.language = language;
      if (!language.canO2) {
        _enableO2 = false;
      }
      if (replaceTemplate && language.template.isNotEmpty) {
        _codeController.text = language.template;
      }
    });
  }
}

class _SessionStatus extends StatelessWidget {
  const _SessionStatus({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppSession.listenable,
      builder: (context, _, __) {
        final loggedIn = AppSession.hasLuoguSession;
        final color = loggedIn ? Colors.green : Colors.orange;

        return Row(
          children: [
            Icon(
              loggedIn ? Icons.verified_user : Icons.info_outline,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                loggedIn
                    ? context.t('submit.luoguLoggedIn')
                    : context.t('submit.luoguLoggedOut'),
                style: TextStyle(color: color),
              ),
            ),
            IconButton(
              tooltip: context.t('submit.refreshLogin'),
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        );
      },
    );
  }
}

class _SubmissionResultView extends StatelessWidget {
  const _SubmissionResultView({required this.state});

  final AsyncValue<CodeSubmissionResult> state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AsyncInitial<CodeSubmissionResult>() ||
      AsyncLoading<CodeSubmissionResult>() =>
        const SizedBox.shrink(),
      AsyncError<CodeSubmissionResult>(message: final message) => _ResultCard(
          success: false,
          title: context.t('submit.failed'),
          message: message,
        ),
      AsyncData<CodeSubmissionResult>(value: final result) => _ResultCard(
          success: result.success,
          title: result.success
              ? context.t('submit.succeeded')
              : context.t('submit.incomplete'),
          message: result.message,
          recordId: result.recordId,
        ),
    };
  }
}

class _CodeEditingController extends TextEditingController {
  _CodeEditingController({
    required String text,
    required this.language,
  }) : super(text: text);

  SubmitLanguage language;

  static final _keywordPattern = RegExp(
    r'\b(class|const|final|var|void|int|long|double|float|bool|char|string|String|return|if|else|for|while|do|switch|case|break|continue|import|include|using|namespace|public|private|protected|static|new|try|catch|throw|throws|fn|let|mut|def|pass|from|as|in|range|func|package|struct|enum|impl|trait|use|match)\b',
  );
  static final _numberPattern = RegExp(r'\b\d+(?:\.\d+)?\b');
  static final _stringPattern =
      RegExp(r'''("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')''');
  static final _commentPattern = RegExp(r'(//[^\n]*|#[^\n]*|/\*[\s\S]*?\*/)');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle(fontFamily: 'monospace');
    if (!AppThemeController.instance.syntaxHighlight) {
      return TextSpan(style: baseStyle, text: text);
    }

    final theme = Theme.of(context).colorScheme;
    final spans = <TextSpan>[];
    final matches = <_HighlightMatch>[];

    void collect(RegExp pattern, TextStyle textStyle) {
      for (final match in pattern.allMatches(text)) {
        matches.add(
          _HighlightMatch(
            match.start,
            match.end,
            textStyle,
          ),
        );
      }
    }

    collect(_stringPattern, TextStyle(color: theme.tertiary));
    collect(_commentPattern, TextStyle(color: theme.outline));
    collect(_numberPattern, TextStyle(color: theme.secondary));
    collect(
      _keywordPattern,
      TextStyle(
        color: theme.primary,
        fontWeight: FontWeight.w700,
      ),
    );

    matches.sort((a, b) => a.start.compareTo(b.start));
    var cursor = 0;
    for (final match in matches) {
      if (match.start < cursor) {
        continue;
      }
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: match.style,
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return TextSpan(style: baseStyle, children: spans);
  }
}

class _HighlightMatch {
  const _HighlightMatch(this.start, this.end, this.style);

  final int start;
  final int end;
  final TextStyle style;
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.success,
    required this.title,
    required this.message,
    this.recordId,
  });

  final bool success;
  final String title;
  final String message;
  final String? recordId;

  @override
  Widget build(BuildContext context) {
    final color = success ? Colors.green : Colors.orange;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.info_outline,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(message),
            if (recordId != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.recordDetail, arguments: recordId),
                icon: const Icon(Icons.receipt_long),
                label: Text(context.t('submit.viewRecord')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
