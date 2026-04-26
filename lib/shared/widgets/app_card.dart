import 'package:flutter/material.dart';

import '../../app/theme/app_card_style.dart';
import '../../app/theme/app_corner_radius.dart';
import '../../app/theme/app_theme_controller.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.elevation,
    this.shape,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final radiusValue = theme.cornerRadius.value;
    final radius = BorderRadius.circular(radiusValue);
    final cardStyle = theme.cardStyle;

    Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      );
    }

    if (cardStyle == AppCardStyle.flat) {
      return Card(
        margin: margin ?? EdgeInsets.zero,
        elevation: elevation ?? 0,
        shape: shape ??
            RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.12),
              ),
            ),
        color: color ?? scheme.surface.withValues(alpha: isDark ? 0.45 : 0.85),
        child: content,
      );
    }

    Color bgColor;
    List<BoxShadow>? shadows;
    Border? border;

    if (cardStyle == AppCardStyle.frosted) {
      bgColor = scheme.surface.withValues(alpha: isDark ? 0.54 : 0.78);
      border = Border.all(
        color: scheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.15),
      );
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      bgColor = scheme.surface.withValues(alpha: isDark ? 0.58 : 0.74);
      border = Border.all(
        color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.65),
        width: 1.1,
      );
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.10),
          blurRadius: 22,
          spreadRadius: -2,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: scheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
          blurRadius: 30,
          spreadRadius: -8,
        ),
      ];
    }

    final container = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: border,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: cardStyle == AppCardStyle.liquid
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.surface.withValues(alpha: isDark ? 0.66 : 0.84),
                      scheme.surfaceContainerHighest.withValues(
                        alpha: isDark ? 0.44 : 0.66,
                      ),
                      scheme.primary.withValues(alpha: isDark ? 0.07 : 0.09),
                    ],
                    stops: const [0, 0.72, 1],
                  )
                : null,
            borderRadius: radius,
          ),
          child: content,
        ),
      ),
    );

    return RepaintBoundary(child: container);
  }
}
