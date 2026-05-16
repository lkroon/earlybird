/// Represents a supported scraping site
enum Site {
  funda,
  marktplaats,
  indeed,
  autoscout24,
}

extension SiteExtension on Site {
  /// Display name of the site
  String get displayName {
    switch (this) {
      case Site.funda:
        return 'Funda';
      case Site.marktplaats:
        return 'Marktplaats';
      case Site.indeed:
        return 'Indeed';
      case Site.autoscout24:
        return 'AutoScout24';
    }
  }

  /// Logo asset path for the site
  String get logoPath {
    switch (this) {
      case Site.funda:
        return 'assets/funda-logo-blue.svg';
      case Site.marktplaats:
        return 'assets/marktplaats.png';
      case Site.indeed:
        return 'assets/indeed.png';
      case Site.autoscout24:
        return 'assets/autoscout24.svg';
    }
  }

  /// Background color for the site
  int get backgroundColor {
    switch (this) {
      case Site.funda:
        return 0xFFF7A100; // Funda orange (matches AppTheme.fundaOrange)
      case Site.marktplaats:
        return 0xFFE87E00; // Marktplaats orange
      case Site.indeed:
        return 0xFFFFFFFF; // Indeed white
      case Site.autoscout24:
        return 0xFF1B1C1E; // AutoScout24 dark gray
    }
  }

  /// Whether the site is implemented
  bool get isImplemented {
    switch (this) {
      case Site.funda:
        return true;
      case Site.marktplaats:
      case Site.indeed:
      case Site.autoscout24:
        return false;
    }
  }

  /// Logo file extension (for determining how to load it)
  bool get isSvg {
    return logoPath.endsWith('.svg');
  }
}
