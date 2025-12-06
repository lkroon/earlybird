/// Represents search filters for real estate listings
class SearchFilter {
  final String area;
  final String objectType;
  final String publicationDate;
  final String sortOrder;

  SearchFilter({
    this.area = 'utrecht',
    this.objectType = 'house',
    this.publicationDate = '30',
    this.sortOrder = 'date_down',
  });

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
}
