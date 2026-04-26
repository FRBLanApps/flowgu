import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme_controller.dart';
import '../../app/theme/app_visual_effect.dart';

/// Renders one of 12 selectable animated background effects underneath the app.
///
/// All effects share the same palette: the user's accent (#66CCFF by default)
/// plus the seed color from [AppThemeController]. Each painter is tuned to
/// match its name: aurora is a vertical light curtain, cyber-grid renders
/// a synthwave horizon, ribbons actually wave, etc.
class AppBackground extends StatefulWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  final ValueNotifier<double> _time = ValueNotifier(0);
  final ValueNotifier<Offset> _pointer = ValueNotifier(Offset.zero);
  Timer? _timer;
  DateTime? _startedAt;
  AppVisualEffect? _timerEffect;

  @override
  void dispose() {
    _timer?.cancel();
    _time.dispose();
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = AppThemeController.instance;
    final accent = theme.accentColor;
    final seed = theme.seedColor;
    final effect = theme.visualEffect;
    final shouldAnimate =
        _isAnimatedEffect(effect) && !MediaQuery.disableAnimationsOf(context);

    if (shouldAnimate) {
      _startAnimationTimer(effect);
    } else {
      _stopAnimationTimer();
    }

    return MouseRegion(
      onHover: (event) {
        final next = event.localPosition;
        if ((_pointer.value - next).distanceSquared > 16) {
          _pointer.value = next;
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: effect == AppVisualEffect.customImage
                  ? _CustomImageBackground(
                      url: theme.customBackgroundUrl,
                      isDark: isDark,
                      accent: accent,
                    )
                  : AnimatedBuilder(
                      animation: _time,
                      builder: (context, _) {
                        return CustomPaint(
                          willChange: shouldAnimate,
                          isComplex: false,
                          painter: _painterFor(
                            effect,
                            accent: accent,
                            seed: seed,
                            isDark: isDark,
                            t: shouldAnimate ? _time.value : 0,
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (isDark)
            Positioned.fill(
              child: RepaintBoundary(
                child: ValueListenableBuilder<Offset>(
                  valueListenable: _pointer,
                  builder: (context, pointer, _) {
                    return CustomPaint(
                      willChange: true,
                      painter: _PointerGlowPainter(accent, pointer),
                    );
                  },
                ),
              ),
            ),
          RepaintBoundary(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  CustomPainter _painterFor(
    AppVisualEffect effect, {
    required Color accent,
    required Color seed,
    required bool isDark,
    required double t,
  }) {
    switch (effect) {
      case AppVisualEffect.aurora:
        return _AuroraPainter(accent, seed, isDark, t);
      case AppVisualEffect.mesh:
        return _MeshPainter(accent, seed, isDark, t);
      case AppVisualEffect.glass:
        return _GlassPainter(accent, seed, isDark, t);
      case AppVisualEffect.cyberGrid:
        return _CyberGridPainter(accent, isDark, t);
      case AppVisualEffect.particles:
        return _ParticlesPainter(accent, isDark, t);
      case AppVisualEffect.waves:
        return _WavesPainter(accent, seed, isDark, t);
      case AppVisualEffect.noise:
        return _NoisePainter(accent, isDark, t);
      case AppVisualEffect.minimal:
        return _MinimalPainter(accent, isDark);
      case AppVisualEffect.orthogonalGrid:
        return _OrthogonalGridPainter(accent, seed, isDark, t);
      case AppVisualEffect.constellation:
        return _ConstellationPainter(accent, isDark, t);
      case AppVisualEffect.ribbon:
        return _RibbonPainter(accent, seed, isDark, t);
      case AppVisualEffect.bokeh:
        return _BokehPainter(accent, isDark, t);
      case AppVisualEffect.customImage:
        return _MinimalPainter(accent, isDark);
    }
  }

  bool _isAnimatedEffect(AppVisualEffect effect) {
    return effect != AppVisualEffect.minimal &&
        effect != AppVisualEffect.customImage;
  }

  void _startAnimationTimer(AppVisualEffect effect) {
    if (_timer != null && _timerEffect == effect) {
      return;
    }
    _timer?.cancel();
    _timerEffect = effect;
    _startedAt = DateTime.now();
    _timer = Timer.periodic(_frameIntervalFor(effect), (_) {
      final startedAt = _startedAt;
      if (!mounted || startedAt == null) {
        return;
      }
      _time.value =
          DateTime.now().difference(startedAt).inMilliseconds / 30000 % 1;
    });
  }

  void _stopAnimationTimer() {
    _timer?.cancel();
    _timer = null;
    _timerEffect = null;
    _startedAt = null;
    if (_time.value != 0) {
      _time.value = 0;
    }
  }

  Duration _frameIntervalFor(AppVisualEffect effect) {
    return switch (effect) {
      AppVisualEffect.noise => const Duration(milliseconds: 180),
      AppVisualEffect.aurora ||
      AppVisualEffect.mesh ||
      AppVisualEffect.bokeh =>
        const Duration(milliseconds: 120),
      _ => const Duration(milliseconds: 90),
    };
  }
}

class _CustomImageBackground extends StatelessWidget {
  const _CustomImageBackground({
    required this.url,
    required this.isDark,
    required this.accent,
  });

  final String? url;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fallback = _MinimalPainter(accent, isDark);
    final imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) {
      return CustomPaint(painter: fallback);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(painter: fallback);
          },
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white)
                .withValues(alpha: isDark ? 0.34 : 0.18),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── shared helpers ───────────────────────

/// Smooth gradient backplate used by several effects.
void _paintGradientBase(
  Canvas canvas,
  Size size,
  bool isDark, {
  Color? tint,
}) {
  final rect = Offset.zero & size;
  final dark = [const Color(0xFF050810), const Color(0xFF0C111B)];
  final light = [const Color(0xFFFAFCFF), const Color(0xFFEDF2F8)];
  canvas.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark ? dark : light,
      ).createShader(rect),
  );
  if (tint != null) {
    canvas.drawRect(
      rect,
      Paint()..color = tint.withValues(alpha: isDark ? 0.04 : 0.025),
    );
  }
}

class _PointerGlowPainter extends CustomPainter {
  _PointerGlowPainter(this.accent, this.pointer);

  final Color accent;
  final Offset pointer;

  @override
  void paint(Canvas canvas, Size size) {
    if (pointer == Offset.zero) {
      return;
    }

    final radius = math.min(size.shortestSide * 0.32, 220.0);
    canvas.drawCircle(
      pointer,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.16),
            accent.withValues(alpha: 0.055),
            Colors.transparent,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: pointer, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _PointerGlowPainter old) =>
      old.accent != accent || old.pointer != pointer;
}

// ─────────────────────────── 1. Aurora ──────────────────────────
// Vertical "northern lights" curtain: tall gradient bands sweep
// horizontally across the sky, each shimmering in/out.

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.accent, this.seed, this.isDark, this.t);

  final Color accent;
  final Color seed;
  final bool isDark;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Night-sky base for dark; soft pastel sky for light.
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF03060B), Color(0xFF0B1422), Color(0xFF050810)]
              : const [Color(0xFFEEF6FF), Color(0xFFFFFFFF), Color(0xFFF1F8FF)],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    final w = size.width;
    final h = size.height;
    final phase = t * math.pi * 2;

    // Curtain bands -- vertical strips of color drifting horizontally.
    final bands = <_AuroraBand>[
      _AuroraBand(accent, 0.20, 0.7, isDark ? 0.55 : 0.35, 1.0),
      _AuroraBand(seed, 0.45, 0.9, isDark ? 0.45 : 0.28, -0.7),
      _AuroraBand(accent, 0.70, 0.6, isDark ? 0.40 : 0.24, 0.4),
      _AuroraBand(
        _lerp(accent, seed, 0.5),
        0.85,
        0.8,
        isDark ? 0.45 : 0.28,
        -0.5,
      ),
    ];

    for (final b in bands) {
      final cx = ((b.x + math.sin(phase * b.speed + b.x * 6) * 0.06) % 1) * w;
      final width = w * 0.32;
      final left = cx - width / 2;
      // shimmer 0..1
      final shimmer = 0.6 + 0.4 * math.sin(phase * 1.5 + b.x * 10).abs();
      // soft vertical curtain gradient
      canvas.drawRect(
        Rect.fromLTWH(left, 0, width, h * b.height),
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50)
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              b.color.withValues(alpha: b.alpha * shimmer),
              b.color.withValues(alpha: b.alpha * 0.6 * shimmer),
              Colors.transparent,
            ],
            stops: const [0, 0.30, 0.70, 1],
          ).createShader(Rect.fromLTWH(left, 0, width, h * b.height)),
      );
    }

    // Twinkle stars in dark mode only.
    if (isDark) {
      final r = math.Random(7);
      final p = Paint();
      for (var i = 0; i < 40; i++) {
        final x = r.nextDouble() * w;
        final y = r.nextDouble() * h * 0.5;
        final tw = (math.sin(phase * 2 + i) + 1) / 2;
        p.color = Colors.white.withValues(alpha: 0.10 + 0.40 * tw);
        canvas.drawCircle(Offset(x, y), 0.9, p);
      }
    }

    // Bottom haze for legibility.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center,
          colors: [
            (isDark ? Colors.black : Colors.white).withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t || old.isDark != isDark;
}

class _AuroraBand {
  _AuroraBand(this.color, this.x, this.height, this.alpha, this.speed);
  final Color color;
  final double x;
  final double height;
  final double alpha;
  final double speed;
}

// ─────────────────────────── 2. Mesh ────────────────────────────
// Modern mesh-gradient: 6 large soft blobs that slowly orbit and
// blend into one another -- think Stripe / Vercel marketing pages.

class _MeshPainter extends CustomPainter {
  _MeshPainter(this.accent, this.seed, this.isDark, this.t);

  final Color accent;
  final Color seed;
  final bool isDark;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGradientBase(canvas, size, isDark, tint: accent);
    final w = size.width;
    final h = size.height;
    final phase = t * math.pi * 2;
    final colors = [
      accent,
      seed,
      _lerp(accent, seed, 0.5),
      accent,
      seed,
      _lerp(accent, Colors.white, 0.4),
    ];
    final centers = [
      const Offset(0.18, 0.22),
      const Offset(0.78, 0.18),
      const Offset(0.92, 0.62),
      const Offset(0.20, 0.78),
      const Offset(0.55, 0.50),
      const Offset(0.62, 0.88),
    ];
    for (var i = 0; i < centers.length; i++) {
      final base = centers[i];
      final dx = math.sin(phase * 0.6 + i * 1.3) * 0.08;
      final dy = math.cos(phase * 0.5 + i * 0.9) * 0.07;
      final c = Offset((base.dx + dx) * w, (base.dy + dy) * h);
      final radius = w * (0.38 + 0.05 * math.sin(phase + i));
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80)
          ..shader = RadialGradient(
            colors: [
              colors[i].withValues(alpha: isDark ? 0.45 : 0.30),
              colors[i].withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) =>
      old.t != t || old.isDark != isDark;
}

// ─────────────────────────── 3. Glass ───────────────────────────
// Frosted-glass panels stacked over a soft moving color wash.
// We can't BackdropFilter inside a CustomPaint, so we *simulate*
// frost by drawing a tinted, blurred fill plus a thin highlight
// edge and a diagonal shimmer line.

class _GlassPainter extends CustomPainter {
  _GlassPainter(this.accent, this.seed, this.isDark, this.t);

  final Color accent;
  final Color seed;
  final bool isDark;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Color wash that the glass "diffuses".
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: isDark
              ? [const Color(0xFF0B0F1A), const Color(0xFF131C2C)]
              : [const Color(0xFFEAF1F8), const Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    final phase = t * math.pi * 2;
    // Two big drifting color blobs underneath the glass.
    for (var i = 0; i < 2; i++) {
      final cx =
          size.width * (0.3 + 0.4 * i + 0.10 * math.sin(phase * 0.8 + i));
      final cy =
          size.height * (0.30 + 0.3 * i + 0.10 * math.cos(phase * 0.6 + i));
      final c = Offset(cx, cy);
      final col = i == 0 ? accent : seed;
      canvas.drawCircle(
        c,
        size.width * 0.45,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90)
          ..color = col.withValues(alpha: isDark ? 0.30 : 0.22),
      );
    }

    // Frosted panels.
    final panels = <Rect>[
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.10 + 8 * math.sin(phase),
        size.width * 0.55,
        size.height * 0.34,
      ),
      Rect.fromLTWH(
        size.width * 0.40,
        size.height * 0.50 + 8 * math.cos(phase),
        size.width * 0.55,
        size.height * 0.36,
      ),
    ];
    for (final p in panels) {
      final rrect = RRect.fromRectAndRadius(p, const Radius.circular(28));
      // Frost fill: blurred white/black wash to mimic bg blur.
      canvas.drawRRect(
        rrect,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
          ..color = (isDark ? Colors.white : Colors.white)
              .withValues(alpha: isDark ? 0.05 : 0.45),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = (isDark ? Colors.white : Colors.white)
              .withValues(alpha: isDark ? 0.04 : 0.22),
      );
      // Top highlight line.
      canvas.drawRRect(
        rrect.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: isDark ? 0.35 : 0.85),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(p),
      );
      // Diagonal shimmer.
      final shim = (t + p.left / size.width) % 1;
      final sx = p.left + p.width * shim;
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRect(
        Rect.fromLTWH(sx - 60, p.top, 120, p.height),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: isDark ? 0.06 : 0.35),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(sx - 60, p.top, 120, p.height)),
      );
      canvas.restore();
      // Edge.
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = accent.withValues(alpha: isDark ? 0.30 : 0.22),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlassPainter old) =>
      old.t != t || old.isDark != isDark;
}

// ─────────────────────────── 4. Cyber grid ──────────────────────
// Synthwave: dark gradient sky with a circular sun on the horizon
// and a perspective grid floor that scrolls toward the camera.

class _CyberGridPainter extends CustomPainter {
  _CyberGridPainter(this.accent, this.isDark, this.t);

  final Color accent;
  final bool isDark;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.55;
    final rect = Offset.zero & size;

    // Sky.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1A0B2E),
                  const Color(0xFF2A1248),
                  const Color(0xFF06080D),
                ]
              : [
                  const Color(0xFFFFE6F2),
                  const Color(0xFFE6F1FF),
                  const Color(0xFFFFFFFF),
                ],
          stops: [0, horizon / h, horizon / h + 0.001],
        ).createShader(rect),
    );

    // Sun disc on horizon with horizontal slits.
    final sunCenter = Offset(w * 0.5, horizon - 4);
    final sunR = math.min(w, h) * 0.18;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, horizon));
    canvas.drawCircle(
      sunCenter,
      sunR + 30,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
        ..color = accent.withValues(alpha: isDark ? 0.45 : 0.30),
    );
    canvas.drawCircle(
      sunCenter,
      sunR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: isDark ? 1.0 : 0.85),
            _lerp(accent, const Color(0xFFFF6FA0), 0.6)
                .withValues(alpha: isDark ? 0.95 : 0.7),
          ],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: sunR)),
    );
    // horizontal cut lines on sun
    final cutPaint = Paint()
      ..color = isDark ? const Color(0xFF06080D) : const Color(0xFFF5F8FB);
    for (var i = 0; i < 6; i++) {
      final y = sunCenter.dy - sunR * 0.1 + i * (sunR * 0.18);
      final hh = (i + 1) * 1.5;
      canvas.drawRect(
        Rect.fromLTWH(sunCenter.dx - sunR, y, sunR * 2, hh),
        cutPaint,
      );
    }
    canvas.restore();

    // Floor: perspective grid.
    final lineColor = accent.withValues(alpha: isDark ? 0.55 : 0.35);
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2;
    // verticals (radiate from horizon center)
    const cols = 24;
    for (var i = -cols ~/ 2; i <= cols ~/ 2; i++) {
      final fx = w * 0.5 + i * (w / cols) * 1.6;
      canvas.drawLine(Offset(w * 0.5, horizon), Offset(fx, h), paint);
    }
    // horizontals scroll toward viewer
    final scroll = (t * 1.0) % 1;
    for (var i = 1; i <= 14; i++) {
      // exponential spacing for perspective
      final p = ((i - scroll) / 14).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final y = horizon + (h - horizon) * (p * p);
      final alpha = (1 - (1 - p) * (1 - p)) * (isDark ? 0.6 : 0.4);
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        Paint()
          ..strokeWidth = 1
          ..color = accent.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CyberGridPainter old) =>
      old.t != t || old.isDark != isDark;
}

// ─────────────────────────── 5. Particles ───────────────────────
// Floating stardust: many small accent dots drifting upward with
// soft glow and gentle horizontal sway. Larger dots have parallax.

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter(this.accent, this.isDark, this.t);

  final Color accent;
  final bool isDark;
  final double t;

  static final List<_Particle> _particles = List.generate(110, (i) {
    final r = math.Random(i * 17 + 1);
    return _Particle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      r: 0.6 + r.nextDouble() * 2.6,
      speed: 0.04 + r.nextDouble() * 0.18,
      phase: r.nextDouble() * math.pi * 2,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintGradientBase(canvas, size, isDark);
    final w = size.width;
    final h = size.height;
    for (final p in _particles) {
      final y = ((p.y - t * p.speed) % 1 + 1) % 1;
      final x =
          (p.x + math.sin(t * math.pi * 2 * p.speed + p.phase) * 0.015) % 1;
      final tw =
          0.45 + 0.55 * (math.sin(t * math.pi * 2 + p.phase) * 0.5 + 0.5);
      final pos = Offset(x * w, y * h);
      // soft halo
      canvas.drawCircle(
        pos,
        p.r * 4,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
          ..color = accent.withValues(alpha: (isDark ? 0.18 : 0.10) * tw),
      );
      // core
      canvas.drawCircle(
        pos,
        p.r,
        Paint()..color = accent.withValues(alpha: (isDark ? 0.85 : 0.55) * tw),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => old.t != t;
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
  });
  final double x;
  final double y;
  final double r;
  final double speed;
  final double phase;
}

// ─────────────────────────── 6. Waves ───────────────────────────
// Layered ocean waves at the bottom: 4 sine-curve fills at different
// phases & alphas. Reflective glints float on the top surface.

class _WavesPainter extends CustomPainter {
  _WavesPainter(this.accent, this.seed, this.isDark, this.t);

  final Color accent;
  final Color seed;
  final bool isDark;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Sky: from light to accent tint at horizon.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF03060B), const Color(0xFF0A1422)]
              : [const Color(0xFFF7FBFF), const Color(0xFFE6F4FF)],
        ).createShader(rect),
    );

    final w = size.width;
    final h = size.height;
    final layers = [
      _WaveLayer(accent, 0.50, 36, 1.0, isDark ? 0.30 : 0.25),
      _WaveLayer(_lerp(accent, seed, 0.5), 0.62, 28, 1.4, isDark ? 0.34 : 0.28),
      _WaveLayer(seed, 0.74, 20, 0.8, isDark ? 0.38 : 0.30),
      _WaveLayer(accent, 0.86, 14, 1.7, isDark ? 0.55 : 0.45),
    ];
    for (var li = 0; li < layers.length; li++) {
      final l = layers[li];
      final base = h * l.yPct;
      final phase = t * math.pi * 2 * l.speed + li * 0.7;
      final path = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w + 2; x += 4) {
        final u = x / w;
        final y = base +
            math.sin(u * math.pi * 3 + phase) * l.amp +
            math.sin(u * math.pi * 6 + phase * 1.3) * l.amp * 0.4;
        path.lineTo(x, y);
      }
      path.lineTo(w, h);
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = l.color.withValues(alpha: l.alpha),
      );
      // glint highlight on top edge
      if (li == 0) {
        final glint = Path()..moveTo(0, base);
        for (var x = 0.0; x <= w + 2; x += 4) {
          final u = x / w;
          final y = base +
              math.sin(u * math.pi * 3 + phase) * l.amp +
              math.sin(u * math.pi * 6 + phase * 1.3) * l.amp * 0.4;
          glint.lineTo(x, y);
        }
        canvas.drawPath(
          glint,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.white.withValues(alpha: isDark ? 0.25 : 0.55),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter old) => old.t != t;
}

class _WaveLayer {
  _WaveLayer(this.color, this.yPct, this.amp, this.speed, this.alpha);
  final Color color;
  final double yPct;
  final double amp;
  final double speed;
  final double alpha;
}

// ─────────────────────────── 7. Noise ───────────────────────────
// Film grain: dense low-alpha noise dots that re-roll every frame
// plus subtle horizontal scan lines and vignette to feel cinematic.

class _NoisePainter extends CustomPainter {
  _NoisePainter(this.accent, this.isDark, this.t);

  final Color accent;
  final bool isDark;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Sepia-ish for light, deep film for dark.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0A0A0E), Color(0xFF131319)]
              : const [Color(0xFFFBF7EF), Color(0xFFF1ECE0)],
        ).createShader(rect),
    );
    // accent vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: isDark ? 0.10 : 0.06),
            Colors.transparent,
            (isDark ? Colors.black : Colors.black)
                .withValues(alpha: isDark ? 0.40 : 0.10),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(rect),
    );
    // grain
    final r = math.Random((t * 1000).round());
    final paint = Paint();
    final dots = (size.width * size.height / 700).round();
    for (var i = 0; i < dots; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      final dark = r.nextBool();
      paint.color = (dark ? Colors.black : Colors.white)
          .withValues(alpha: r.nextDouble() * (isDark ? 0.07 : 0.05));
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }
    // scan lines
    final scanPaint = Paint()
      ..color = (isDark ? Colors.black : Colors.brown)
          .withValues(alpha: isDark ? 0.10 : 0.04);
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scanPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter old) => old.t != t;
}

// ─────────────────────────── 8. Minimal ─────────────────────────
// Calm flat gradient with a single hairline accent rule and a tiny
// floating accent dot in the corner -- as restrained as possible.

class _MinimalPainter extends CustomPainter {
  _MinimalPainter(this.accent, this.isDark);

  final Color accent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0A0D14), Color(0xFF0F141C)]
              : const [Color(0xFFFFFFFF), Color(0xFFF1F4F8)],
        ).createShader(rect),
    );
    // hairline accent rule near the top-left.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 2),
      Paint()..color = accent.withValues(alpha: isDark ? 0.55 : 0.45),
    );
    // tiny dot bottom-right.
    canvas.drawCircle(
      Offset(size.width - 28, size.height - 28),
      4,
      Paint()..color = accent,
    );
    canvas.drawCircle(
      Offset(size.width - 28, size.height - 28),
      14,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = accent.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant _MinimalPainter old) => old.isDark != isDark;
}

// ─────────────────────── 9. Orthogonal grid ─────────────────────
// Straight horizontal/vertical grid with emphasized intersections.

class _OrthogonalGridPainter extends CustomPainter {
  _OrthogonalGridPainter(this.accent, this.seed, this.isDark, this.t);

  final Color accent;
  final Color seed;
  final bool isDark;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF07101B), Color(0xFF0B1624)]
              : const [Color(0xFFF8FCFF), Color(0xFFEAF4FA)],
        ).createShader(rect),
    );

    const step = 54.0;
    final shift = (t * step * 0.8) % step;
    final linePaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.18 : 0.15)
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = seed.withValues(alpha: isDark ? 0.28 : 0.22)
      ..strokeWidth = 1.4;
    final dotPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.55 : 0.38);

    final xs = <double>[];
    for (var x = -shift; x <= size.width + step; x += step) {
      xs.add(x);
      final major = ((x + shift) / step).round().isEven;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        major ? majorPaint : linePaint,
      );
    }

    final ys = <double>[];
    for (var y = -shift; y <= size.height + step; y += step) {
      ys.add(y);
      final major = ((y + shift) / step).round().isEven;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        major ? majorPaint : linePaint,
      );
    }

    for (final x in xs) {
      for (final y in ys) {
        canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrthogonalGridPainter old) =>
      old.t != t || old.isDark != isDark;
}

// ─────────────────────────── 10. Constellation ──────────────────
// Stars of varying brightness slowly drift; nearby pairs are linked
// by hairline edges that fade with distance. Brighter stars twinkle.

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter(this.accent, this.isDark, this.t);

  final Color accent;
  final bool isDark;
  final double t;

  static final List<_Star> _stars = List.generate(75, (i) {
    final r = math.Random(i * 31 + 3);
    return _Star(
      x: r.nextDouble(),
      y: r.nextDouble(),
      brightness: 0.3 + r.nextDouble() * 0.7,
      speed: 0.005 + r.nextDouble() * 0.02,
      phase: r.nextDouble() * math.pi * 2,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Deep sky.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: isDark
              ? [const Color(0xFF0B1326), const Color(0xFF03060B)]
              : [const Color(0xFFEAF1FB), const Color(0xFFFFFFFF)],
          radius: 1.2,
        ).createShader(Offset.zero & size),
    );

    final w = size.width;
    final h = size.height;
    final phase = t * math.pi * 2;
    final pts = <Offset>[];
    final brights = <double>[];
    for (final s in _stars) {
      final x = (s.x + math.sin(phase * s.speed * 8 + s.phase) * 0.01) % 1;
      final y =
          ((s.y + t * s.speed + math.cos(phase * s.speed * 6) * 0.01) % 1 + 1) %
              1;
      pts.add(Offset(x * w, y * h));
      brights.add(s.brightness);
    }

    // Edges within radius.
    const maxDist = 110.0;
    final lineBase = isDark ? 0.32 : 0.20;
    for (var i = 0; i < pts.length; i++) {
      for (var j = i + 1; j < pts.length; j++) {
        final d = (pts[i] - pts[j]).distance;
        if (d < maxDist) {
          final a =
              (1 - d / maxDist) * lineBase * (brights[i] + brights[j]) / 2;
          canvas.drawLine(
            pts[i],
            pts[j],
            Paint()
              ..strokeWidth = 0.8
              ..color = accent.withValues(alpha: a),
          );
        }
      }
    }
    // Stars.
    for (var i = 0; i < pts.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(phase * 1.5 + i);
      final b = brights[i];
      final r = 0.8 + b * 1.6;
      // halo
      canvas.drawCircle(
        pts[i],
        r * 4,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
          ..color = accent.withValues(alpha: 0.18 * b * tw),
      );
      // core white
      canvas.drawCircle(
        pts[i],
        r,
        Paint()
          ..color = Colors.white.withValues(
            alpha: (isDark ? 0.95 : 0.75) * b,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) => old.t != t;
}

class _Star {
  _Star({
    required this.x,
    required this.y,
    required this.brightness,
    required this.speed,
    required this.phase,
  });
  final double x;
  final double y;
  final double brightness;
  final double speed;
  final double phase;
}

// ─────────────────────────── 11. Ribbon ─────────────────────────
// Long curving ribbons that flow diagonally across the canvas,
// each with a slight wave deformation -- not just static stripes.

class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.accent, this.seed, this.isDark, this.t);

  final Color accent;
  final Color seed;
  final bool isDark;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGradientBase(canvas, size, isDark);
    final w = size.width;
    final h = size.height;
    final phase = t * math.pi * 2;
    final ribbons = [
      _Ribbon(accent, 0.20, 80, 0.7, isDark ? 0.30 : 0.22),
      _Ribbon(seed, 0.40, 60, -0.5, isDark ? 0.26 : 0.18),
      _Ribbon(_lerp(accent, seed, 0.5), 0.60, 90, 0.9, isDark ? 0.30 : 0.20),
      _Ribbon(accent, 0.80, 70, -0.6, isDark ? 0.28 : 0.20),
    ];
    for (var i = 0; i < ribbons.length; i++) {
      final r = ribbons[i];
      final cy = h * r.yPct;
      final amp = r.thickness * 0.6;
      final p = Path();
      p.moveTo(-50, cy);
      for (var x = -50.0; x <= w + 50; x += 8) {
        final u = x / w;
        final y = cy +
            math.sin(u * math.pi * 2.5 + phase * r.speed + i) * amp +
            math.sin(u * math.pi * 5 + phase * r.speed * 1.5) * amp * 0.3;
        p.lineTo(x, y);
      }
      // close as a thick stroked path
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r.thickness
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              r.color.withValues(alpha: 0),
              r.color.withValues(alpha: r.alpha),
              r.color.withValues(alpha: r.alpha * 0.4),
              Colors.transparent,
            ],
            stops: const [0, 0.35, 0.75, 1],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );
      // bright center line
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: isDark ? 0.25 : 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter old) => old.t != t;
}

class _Ribbon {
  _Ribbon(this.color, this.yPct, this.thickness, this.speed, this.alpha);
  final Color color;
  final double yPct;
  final double thickness;
  final double speed;
  final double alpha;
}

// ─────────────────────────── 12. Bokeh ──────────────────────────
// Defocused photo bokeh: many soft circles with bright thin edges
// (lens iris look), drifting at multiple parallax depths.

class _BokehPainter extends CustomPainter {
  _BokehPainter(this.accent, this.isDark, this.t);

  final Color accent;
  final bool isDark;
  final double t;

  static final List<_Bokeh> _circles = List.generate(28, (i) {
    final r = math.Random(i * 41 + 5);
    return _Bokeh(
      x: r.nextDouble(),
      y: r.nextDouble(),
      r: 25 + r.nextDouble() * 90,
      depth: 0.2 + r.nextDouble() * 0.8,
      speed: 0.02 + r.nextDouble() * 0.08,
      phase: r.nextDouble() * math.pi * 2,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    // moody backdrop
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: isDark
              ? [const Color(0xFF06080F), const Color(0xFF0E1422)]
              : [const Color(0xFFFFFFFF), const Color(0xFFEFF4FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
    final w = size.width;
    final h = size.height;
    // depth-sorted (back first)
    final sorted = [..._circles]..sort((a, b) => a.depth.compareTo(b.depth));
    for (final b in sorted) {
      final y = ((b.y - t * b.speed * (1 + b.depth)) % 1 + 1) % 1;
      final x =
          (b.x + math.sin(t * math.pi * 2 * b.speed + b.phase) * 0.04) % 1;
      final c = Offset(x * w, y * h);
      final r = b.r * (0.6 + b.depth);
      // soft fill (defocused light)
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 + b.depth * 10)
          ..color = accent.withValues(
            alpha: (isDark ? 0.18 : 0.10) * b.depth,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BokehPainter old) => old.t != t;
}

class _Bokeh {
  _Bokeh({
    required this.x,
    required this.y,
    required this.r,
    required this.depth,
    required this.speed,
    required this.phase,
  });
  final double x;
  final double y;
  final double r;
  final double depth;
  final double speed;
  final double phase;
}

// ─────────────────────────── utils ──────────────────────────────

Color _lerp(Color a, Color b, double t) => Color.lerp(a, b, t)!;
