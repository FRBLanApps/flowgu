enum AppCardStyle {
  flat,
  frosted,
  liquid,
}

extension AppCardStyleName on AppCardStyle {
  String get i18nKey {
    switch (this) {
      case AppCardStyle.flat:
        return 'settings.cardStyle.flat';
      case AppCardStyle.frosted:
        return 'settings.cardStyle.frosted';
      case AppCardStyle.liquid:
        return 'settings.cardStyle.liquid';
    }
  }
}
