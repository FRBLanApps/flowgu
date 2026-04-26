enum AppCornerRadius {
  sharp,
  standard,
  rounded,
  pill,
}

extension AppCornerRadiusValue on AppCornerRadius {
  double get value {
    switch (this) {
      case AppCornerRadius.sharp:
        return 4.0;
      case AppCornerRadius.standard:
        return 12.0;
      case AppCornerRadius.rounded:
        return 24.0;
      case AppCornerRadius.pill:
        return 40.0;
    }
  }

  String get i18nKey {
    switch (this) {
      case AppCornerRadius.sharp:
        return 'settings.cornerRadius.sharp';
      case AppCornerRadius.standard:
        return 'settings.cornerRadius.standard';
      case AppCornerRadius.rounded:
        return 'settings.cornerRadius.rounded';
      case AppCornerRadius.pill:
        return 'settings.cornerRadius.pill';
    }
  }
}
