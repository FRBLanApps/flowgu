enum AppVisualEffect {
  aurora,
  mesh,
  glass,
  cyberGrid,
  particles,
  waves,
  noise,
  minimal,
  orthogonalGrid,
  constellation,
  ribbon,
  bokeh,
  customImage,
}

extension AppVisualEffectMeta on AppVisualEffect {
  String get id => name;

  /// i18n key prefix for the effect's display label.
  String get i18nKey => 'effects.$name';

  /// i18n key for a short description.
  String get descKey => 'effects.$name.desc';
}

const List<AppVisualEffect> kAllVisualEffects = AppVisualEffect.values;

const List<AppVisualEffect> kLightVisualEffects = [
  AppVisualEffect.mesh,
  AppVisualEffect.glass,
  AppVisualEffect.waves,
  AppVisualEffect.minimal,
  AppVisualEffect.ribbon,
  AppVisualEffect.bokeh,
];

const List<AppVisualEffect> kDarkVisualEffects = [
  AppVisualEffect.aurora,
  AppVisualEffect.cyberGrid,
  AppVisualEffect.particles,
  AppVisualEffect.noise,
  AppVisualEffect.constellation,
  AppVisualEffect.orthogonalGrid,
];

const List<AppVisualEffect> kStandardVisualEffects = [
  ...kLightVisualEffects,
  ...kDarkVisualEffects,
];
