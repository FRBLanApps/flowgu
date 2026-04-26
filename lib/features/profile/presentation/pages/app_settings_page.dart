import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme_controller.dart';
import '../../../../app/theme/app_visual_effect.dart';
import '../../../../app/theme/app_card_style.dart';
import '../../../../app/theme/app_corner_radius.dart';
import '../../../../core/i18n/app_i18n.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeController = AppThemeController.instance;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('settings.title'))),
      body: AnimatedBuilder(
        animation: themeController,
        builder: (context, _) {
          return ListView(
            children: [
              _SectionTitle(context.t('settings.appearance')),
              ListTile(
                leading: const Icon(Icons.translate),
                title: Text(context.t('settings.language')),
                trailing: DropdownButton<Locale>(
                  value: themeController.locale,
                  items: [
                    DropdownMenuItem(
                      value: const Locale('zh', 'CN'),
                      child: Text(context.t('settings.language.zh')),
                    ),
                    DropdownMenuItem(
                      value: const Locale('en', 'US'),
                      child: Text(context.t('settings.language.en')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      themeController.setLocale(value);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined),
                      label: Text(context.t('settings.theme.light')),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined),
                      label: Text(context.t('settings.theme.dark')),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto_outlined),
                      label: Text(context.t('settings.theme.system')),
                    ),
                  ],
                  selected: {themeController.themeMode},
                  onSelectionChanged: (value) =>
                      themeController.setThemeMode(value.first),
                ),
              ),
              _ColorEditorTile(
                title: context.t('settings.primaryColor'),
                subtitle: context.t('settings.primaryColorDesc'),
                color: themeController.seedColor,
                onChanged: themeController.setSeedColor,
              ),
              _ColorEditorTile(
                title: context.t('settings.accentColor'),
                subtitle: context.t('settings.accentColorDesc'),
                color: themeController.accentColor,
                onChanged: themeController.setAccentColor,
              ),
              const Divider(),
              _SectionTitle(context.t('settings.uiStyle')),
              ListTile(
                leading: const Icon(Icons.style_outlined),
                title: Text(context.t('settings.cardStyle')),
                subtitle: Text(context.t(themeController.cardStyle.i18nKey)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(context.t('settings.cardStyle')),
                        content: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final style in AppCardStyle.values)
                                RadioListTile<AppCardStyle>(
                                  value: style,
                                  groupValue: themeController.cardStyle,
                                  title: Text(context.t(style.i18nKey)),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    themeController.setCardStyle(value);
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.rounded_corner_outlined),
                title: Text(context.t('settings.cornerRadius')),
                subtitle: Text(context.t(themeController.cornerRadius.i18nKey)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(context.t('settings.cornerRadius')),
                        content: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final radius in AppCornerRadius.values)
                                RadioListTile<AppCornerRadius>(
                                  value: radius,
                                  groupValue: themeController.cornerRadius,
                                  title: Text(context.t(radius.i18nKey)),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    themeController.setCornerRadius(value);
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              _SectionTitle(context.t('settings.visualEffect')),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  context.t('settings.visualEffectDesc'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              _VisualEffectGrid(
                selected: themeController.visualEffect,
                accent: themeController.accentColor,
                onSelected: themeController.setVisualEffect,
              ),
              const Divider(),
              _SectionTitle(context.t('settings.submit')),
              SwitchListTile(
                title: Text(context.t('settings.autoOpenRecord')),
                value: themeController.autoOpenRecord,
                onChanged: themeController.setAutoOpenRecord,
              ),
              SwitchListTile(
                title: Text(context.t('settings.recordRetry')),
                subtitle: Text(context.t('settings.recordRetryDesc')),
                value: themeController.recordRetry,
                onChanged: themeController.setRecordRetry,
              ),
              SwitchListTile(
                title: Text(context.t('settings.defaultO2')),
                subtitle: Text(context.t('settings.defaultO2Desc')),
                value: themeController.defaultO2,
                onChanged: themeController.setDefaultO2,
              ),
              const Divider(),
              _SectionTitle(context.t('settings.display')),
              SwitchListTile(
                title: Text(context.t('settings.syntaxHighlight')),
                value: themeController.syntaxHighlight,
                onChanged: themeController.setSyntaxHighlight,
              ),
              SwitchListTile(
                title: Text(context.t('settings.latexAccent')),
                value: themeController.latexAccent,
                onChanged: themeController.setLatexAccent,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(context.t('settings.network')),
                subtitle: Text(context.t('settings.networkDesc')),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ColorEditorTile extends StatelessWidget {
  const _ColorEditorTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.tune),
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => _ColorEditorDialog(
          title: title,
          initialColor: color,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ColorEditorDialog extends StatefulWidget {
  const _ColorEditorDialog({
    required this.title,
    required this.initialColor,
    required this.onChanged,
  });

  final String title;
  final Color initialColor;
  final ValueChanged<Color> onChanged;

  @override
  State<_ColorEditorDialog> createState() => _ColorEditorDialogState();
}

class _ColorEditorDialogState extends State<_ColorEditorDialog> {
  late int _red = (widget.initialColor.r * 255).round();
  late int _green = (widget.initialColor.g * 255).round();
  late int _blue = (widget.initialColor.b * 255).round();

  Color get _color => Color.fromARGB(255, _red, _green, _blue);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.t('settings.editColor', args: {'title': widget.title}),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 30, backgroundColor: _color),
          const SizedBox(height: 16),
          _ColorSlider(
            label: 'R',
            value: _red,
            color: Colors.red,
            onChanged: (value) => setState(() => _red = value),
          ),
          _ColorSlider(
            label: 'G',
            value: _green,
            color: Colors.green,
            onChanged: (value) => setState(() => _green = value),
          ),
          _ColorSlider(
            label: 'B',
            value: _blue,
            color: Colors.blue,
            onChanged: (value) => setState(() => _blue = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t('settings.cancel')),
        ),
        FilledButton(
          onPressed: () {
            widget.onChanged(_color);
            Navigator.pop(context);
          },
          child: Text(context.t('settings.apply')),
        ),
      ],
    );
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(label, style: TextStyle(color: color)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            max: 255,
            divisions: 255,
            label: '$value',
            activeColor: color,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
        SizedBox(width: 36, child: Text('$value')),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _VisualEffectGrid extends StatelessWidget {
  const _VisualEffectGrid({
    required this.selected,
    required this.accent,
    required this.onSelected,
  });

  final AppVisualEffect selected;
  final Color accent;
  final ValueChanged<AppVisualEffect> onSelected;

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeController.instance;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth > 720
              ? 4
              : constraints.maxWidth > 480
                  ? 3
                  : 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EffectGroup(
                title: context.t('effects.group.light'),
                effects: kLightVisualEffects,
                selected: selected,
                accent: accent,
                columns: cols,
                onSelected: onSelected,
              ),
              const SizedBox(height: 16),
              _EffectGroup(
                title: context.t('effects.group.dark'),
                effects: kDarkVisualEffects,
                selected: selected,
                accent: accent,
                columns: cols,
                onSelected: onSelected,
              ),
              const SizedBox(height: 16),
              Text(
                context.t('effects.group.custom'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _CustomBackgroundTile(
                isSelected: selected == AppVisualEffect.customImage,
                accent: accent,
                url: controller.customBackgroundUrl,
                onSelected: () => onSelected(AppVisualEffect.customImage),
                onEdit: () => _editCustomBackground(context, controller),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editCustomBackground(
    BuildContext context,
    AppThemeController controller,
  ) async {
    final textController = TextEditingController(
      text: controller.customBackgroundUrl ?? '',
    );
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.t('effects.customImage')),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                labelText: context.t('effects.customImage.url'),
                hintText: 'https://example.com/background.jpg',
              ),
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.t('settings.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: Text(context.t('common.clear')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, textController.text),
              child: Text(context.t('settings.apply')),
            ),
          ],
        );
      },
    );
    textController.dispose();
    if (result == null) return;
    controller.setCustomBackgroundUrl(result);
    onSelected(AppVisualEffect.customImage);
  }
}

class _EffectGroup extends StatelessWidget {
  const _EffectGroup({
    required this.title,
    required this.effects,
    required this.selected,
    required this.accent,
    required this.columns,
    required this.onSelected,
  });

  final String title;
  final List<AppVisualEffect> effects;
  final AppVisualEffect selected;
  final Color accent;
  final int columns;
  final ValueChanged<AppVisualEffect> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: effects.length,
          itemBuilder: (context, i) {
            final effect = effects[i];
            return _EffectTile(
              effect: effect,
              isSelected: effect == selected,
              accent: accent,
              onTap: () => onSelected(effect),
            );
          },
        ),
      ],
    );
  }
}

class _CustomBackgroundTile extends StatelessWidget {
  const _CustomBackgroundTile({
    required this.isSelected,
    required this.accent,
    required this.url,
    required this.onSelected,
    required this.onEdit,
  });

  final bool isSelected;
  final Color accent;
  final String? url;
  final VoidCallback onSelected;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accent
                  : scheme.onSurface.withValues(alpha: 0.10),
              width: isSelected ? 2 : 1,
            ),
            color: scheme.surface.withValues(alpha: 0.62),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 112,
                  height: 68,
                  child: url == null || url!.isEmpty
                      ? ColoredBox(
                          color: accent.withValues(alpha: 0.12),
                          child: Icon(Icons.image_outlined, color: accent),
                        )
                      : Image.network(
                          url!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return ColoredBox(
                              color: accent.withValues(alpha: 0.12),
                              child: Icon(Icons.broken_image, color: accent),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.t('effects.customImage'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      url == null || url!.isEmpty
                          ? context.t('effects.customImage.desc')
                          : url!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.t('effects.customImage.edit'),
                onPressed: onEdit,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EffectTile extends StatelessWidget {
  const _EffectTile({
    required this.effect,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final AppVisualEffect effect;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = context.t(effect.i18nKey);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accent
                  : scheme.onSurface.withValues(alpha: 0.10),
              width: isSelected ? 2 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: isSelected ? 0.22 : 0.08),
                scheme.surface.withValues(alpha: 0.6),
              ],
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _EffectPreview(effect: effect, accent: accent),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, size: 18, color: accent),
                ],
              ),
              Text(
                context.t(effect.descKey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EffectPreview extends StatelessWidget {
  const _EffectPreview({
    required this.effect,
    required this.accent,
  });

  final AppVisualEffect effect;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _EffectPreviewPainter(
          effect: effect,
          accent: accent,
          seed: scheme.primary,
          isDark: isDark,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _EffectPreviewPainter extends CustomPainter {
  const _EffectPreviewPainter({
    required this.effect,
    required this.accent,
    required this.seed,
    required this.isDark,
  });

  final AppVisualEffect effect;
  final Color accent;
  final Color seed;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = isDark ? const Color(0xFF08111E) : const Color(0xFFF6FAFF);
    canvas.drawRect(rect, Paint()..color = bg);

    switch (effect) {
      case AppVisualEffect.aurora:
        _paintAurora(canvas, size);
      case AppVisualEffect.mesh:
        _paintMesh(canvas, size);
      case AppVisualEffect.glass:
        _paintGlass(canvas, size);
      case AppVisualEffect.cyberGrid:
        _paintCyberGrid(canvas, size);
      case AppVisualEffect.particles:
        _paintParticles(canvas, size);
      case AppVisualEffect.waves:
        _paintWaves(canvas, size);
      case AppVisualEffect.noise:
        _paintNoise(canvas, size);
      case AppVisualEffect.minimal:
        _paintMinimal(canvas, size);
      case AppVisualEffect.orthogonalGrid:
        _paintOrthogonalGrid(canvas, size);
      case AppVisualEffect.constellation:
        _paintConstellation(canvas, size);
      case AppVisualEffect.ribbon:
        _paintRibbon(canvas, size);
      case AppVisualEffect.bokeh:
        _paintBokeh(canvas, size);
      case AppVisualEffect.customImage:
        _paintCustomImage(canvas, size);
    }
  }

  void _paintAurora(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.12 + i * 0.24);
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          (i.isEven ? accent : seed).withValues(alpha: isDark ? 0.55 : 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(x, 0, size.width * 0.18, size.height));
      canvas.drawRect(
        Rect.fromLTWH(x, 0, size.width * 0.18, size.height),
        paint,
      );
    }
  }

  void _paintMesh(Canvas canvas, Size size) {
    final paint = Paint();
    final circles = [
      (Offset(size.width * 0.25, size.height * 0.28), accent),
      (Offset(size.width * 0.78, size.height * 0.35), seed),
      (
        Offset(size.width * 0.50, size.height * 0.78),
        Color.lerp(accent, seed, 0.5)!,
      ),
    ];
    for (final entry in circles) {
      paint.color = entry.$2.withValues(alpha: isDark ? 0.38 : 0.28);
      canvas.drawCircle(entry.$1, size.shortestSide * 0.34, paint);
    }
  }

  void _paintGlass(Canvas canvas, Size size) {
    _paintMesh(canvas, size);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.10 : 0.55)
      ..style = PaintingStyle.fill;
    for (final rect in [
      Rect.fromLTWH(
        size.width * 0.10,
        size.height * 0.16,
        size.width * 0.55,
        size.height * 0.34,
      ),
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.52,
        size.width * 0.55,
        size.height * 0.30,
      ),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: isDark ? 0.22 : 0.75),
      );
    }
  }

  void _paintCyberGrid(Canvas canvas, Size size) {
    final horizon = size.height * 0.52;
    canvas.drawCircle(
      Offset(size.width * 0.5, horizon),
      size.shortestSide * 0.20,
      Paint()..color = accent.withValues(alpha: 0.55),
    );
    final paint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.65 : 0.42)
      ..strokeWidth = 1;
    for (var i = 0; i <= 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(
        Offset(size.width / 2, horizon),
        Offset(x, size.height),
        paint,
      );
    }
    for (var i = 1; i <= 5; i++) {
      final y = horizon + (size.height - horizon) * i * i / 25;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintParticles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.85 : 0.55);
    for (var i = 0; i < 26; i++) {
      final x = size.width * ((i * 37) % 100) / 100;
      final y = size.height * ((i * 61) % 100) / 100;
      canvas.drawCircle(Offset(x, y), 1.1 + (i % 3) * 0.6, paint);
    }
  }

  void _paintWaves(Canvas canvas, Size size) {
    for (var layer = 0; layer < 3; layer++) {
      final path = Path()..moveTo(0, size.height);
      final base = size.height * (0.48 + layer * 0.15);
      for (var x = 0.0; x <= size.width; x += 8) {
        final y =
            base + ((x / size.width * 6 + layer).sinLike()) * (8 - layer * 1.5);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = (layer.isEven ? accent : seed)
              .withValues(alpha: 0.25 + layer * 0.12),
      );
    }
  }

  void _paintNoise(Canvas canvas, Size size) {
    _paintMinimal(canvas, size);
    final paint = Paint();
    for (var i = 0; i < 80; i++) {
      final x = size.width * ((i * 17) % 100) / 100;
      final y = size.height * ((i * 43) % 100) / 100;
      paint.color =
          (i.isEven ? Colors.white : Colors.black).withValues(alpha: 0.08);
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }
  }

  void _paintMinimal(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: [
            isDark ? const Color(0xFF0B111A) : Colors.white,
            isDark ? const Color(0xFF121A25) : const Color(0xFFEFF5FB),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 2),
      Paint()..color = accent,
    );
  }

  void _paintOrthogonalGrid(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.34 : 0.22)
      ..strokeWidth = 1;
    final dotPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.72 : 0.48);
    const step = 22.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (var x = 0.0; x <= size.width; x += step) {
      for (var y = 0.0; y <= size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.8, dotPaint);
      }
    }
  }

  void _paintConstellation(Canvas canvas, Size size) {
    final points = <Offset>[
      Offset(size.width * 0.18, size.height * 0.30),
      Offset(size.width * 0.34, size.height * 0.42),
      Offset(size.width * 0.52, size.height * 0.24),
      Offset(size.width * 0.70, size.height * 0.44),
      Offset(size.width * 0.82, size.height * 0.68),
      Offset(size.width * 0.40, size.height * 0.74),
    ];
    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }
    for (final point in points) {
      canvas.drawCircle(
        point,
        2.2,
        Paint()..color = Colors.white.withValues(alpha: isDark ? 0.95 : 0.75),
      );
    }
  }

  void _paintRibbon(Canvas canvas, Size size) {
    for (var i = -2; i < 6; i++) {
      final path = Path()
        ..moveTo(size.width * (i * 0.22), size.height)
        ..lineTo(size.width * (i * 0.22 + 0.20), size.height)
        ..lineTo(size.width * (i * 0.22 + 0.55), 0)
        ..lineTo(size.width * (i * 0.22 + 0.35), 0)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = (i.isEven ? accent : seed).withValues(alpha: 0.26),
      );
    }
  }

  void _paintBokeh(Canvas canvas, Size size) {
    for (var i = 0; i < 8; i++) {
      final center = Offset(
        size.width * ((i * 29) % 100) / 100,
        size.height * ((i * 47) % 100) / 100,
      );
      canvas.drawCircle(
        center,
        size.shortestSide * (0.08 + (i % 3) * 0.035),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: 0.30),
      );
    }
  }

  void _paintCustomImage(Canvas canvas, Size size) {
    _paintMinimal(canvas, size);
    final rect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.18,
      size.width * 0.64,
      size.height * 0.58,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = accent.withValues(alpha: 0.16),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: 0.48),
    );
    canvas.drawCircle(
      Offset(rect.left + rect.width * 0.72, rect.top + rect.height * 0.32),
      7,
      Paint()..color = accent.withValues(alpha: 0.50),
    );
    final mountain = Path()
      ..moveTo(rect.left + rect.width * 0.10, rect.bottom - 8)
      ..lineTo(rect.left + rect.width * 0.36, rect.top + rect.height * 0.56)
      ..lineTo(rect.left + rect.width * 0.50, rect.bottom - 8)
      ..lineTo(rect.left + rect.width * 0.64, rect.top + rect.height * 0.44)
      ..lineTo(rect.right - 8, rect.bottom - 8)
      ..close();
    canvas.drawPath(
      mountain,
      Paint()..color = accent.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _EffectPreviewPainter old) =>
      old.effect != effect ||
      old.accent != accent ||
      old.seed != seed ||
      old.isDark != isDark;
}

extension _PreviewTrig on double {
  double sinLike() {
    var x = this % 6.28318;
    if (x > 3.14159) x -= 6.28318;
    return x * (1 - x.abs() / 3.14159);
  }
}
