import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

import '../../app/theme/app_theme_controller.dart';

class AppMarkdown extends StatelessWidget {
  const AppMarkdown({
    required this.data,
    this.selectable = true,
    super.key,
  });

  static Color accentColorOf(BuildContext context) {
    final controller = AppThemeController.instance;
    return controller.latexAccent
        ? controller.accentColor
        : Theme.of(context).colorScheme.primary;
  }

  final String data;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: selectable,
      inlineSyntaxes: <md.InlineSyntax>[
        _LatexSyntax(),
        _MathbbSyntax(),
      ],
      builders: <String, MarkdownElementBuilder>{
        'latex': _LatexBuilder(),
        'mathbb': _AccentInlineBuilder(),
      },
      styleSheet: _buildMarkdownStyle(context),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyle(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final accent = accentColorOf(context);

    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: textTheme.bodyMedium?.copyWith(height: 1.45),
      a: TextStyle(color: accent),
      em: TextStyle(color: accent, fontStyle: FontStyle.italic),
      strong: TextStyle(color: accent, fontWeight: FontWeight.w700),
      code: TextStyle(
        color: accent,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
    );
  }
}

class _MathbbSyntax extends md.InlineSyntax {
  _MathbbSyntax() : super(r'(?:\\|/)mathbb(?:\{[^}]+\}|[A-Za-z0-9])?');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mathbb', match.group(0)!));
    return true;
  }
}

class _LatexSyntax extends md.InlineSyntax {
  _LatexSyntax() : super(r'\$\$([\s\S]+?)\$\$|\$(?!\$)(.+?)(?<!\\)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final isBlock = match.group(1) != null;
    final source = isBlock ? match.group(1)! : match.group(2)!;
    final element = md.Element.text('latex', source.trim())
      ..attributes['display'] = isBlock ? 'block' : 'inline';
    parser.addNode(element);
    return true;
  }
}

class _LatexBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final display = element.attributes['display'] == 'block';
    final textStyle =
        (parentStyle ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
              color: AppMarkdown.accentColorOf(context),
            ) ??
            TextStyle(color: AppMarkdown.accentColorOf(context));
    final source = _normalizeLatex(element.textContent);
    final fallbackText = display ? '\$\$$source\$\$' : '\$$source\$';
    final math = Math.tex(
      source,
      textStyle: textStyle,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      onErrorFallback: (error) => Text(
        fallbackText,
        style: textStyle,
      ),
    );

    if (!display) {
      return Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: math,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: math,
        ),
      ),
    );
  }

  String _normalizeLatex(String source) {
    return source
        .replaceAllMapped(
          RegExp(r'\\mathbb\s+([A-Za-z0-9])'),
          (match) => '\\mathbb{${match.group(1)}}',
        )
        .replaceAllMapped(
          RegExp(r'\\mathbf\s+([A-Za-z0-9])'),
          (match) => '\\mathbf{${match.group(1)}}',
        )
        .replaceAllMapped(
          RegExp(r'\\bm\s+([A-Za-z0-9])'),
          (match) => '\\bm{${match.group(1)}}',
        );
  }
}

class _AccentInlineBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Text.rich(
      TextSpan(
        text: element.textContent,
        style:
            parentStyle?.copyWith(color: AppMarkdown.accentColorOf(context)) ??
                TextStyle(color: AppMarkdown.accentColorOf(context)),
      ),
    );
  }
}
