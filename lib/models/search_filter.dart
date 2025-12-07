/// Represents search filters for real estate listings
class SearchFilter {
  final String area;
  final String objectType;
  final String publicationDate;
  final String sortOrder;

  SearchFilter({
    String area = 'utrecht',
    this.objectType = 'house',
    this.publicationDate = '30',
    this.sortOrder = 'date_down',
  }) : area = _normalizeArea(area);

  /// Normalizes area input: lowercase, trim whitespace, replace spaces with dashes
  static String _normalizeArea(String area) {
    return area.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  }

  /// Creates a copy of this filter with updated values
  SearchFilter copyWith({
    String? area,
    String? objectType,
    String? publicationDate,
    String? sortOrder,
  }) {
    return SearchFilter(
      area: area ?? this.area,
      objectType: objectType ?? this.objectType,
      publicationDate: publicationDate ?? this.publicationDate,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Converts filter to query parameters map
  Map<String, String> toQueryParams() {
    return {
      'selected_area': '["$area"]',
      'object_type': '["$objectType"]',
      'publication_date': '"$publicationDate"',
      'sort': '"$sortOrder"',
    };
  }

  /// Generates a unique key for this filter combination
  String toKey() {
    return '$area-$objectType-$publicationDate-$sortOrder';
  }
}
