/// Represents a real estate listing
class Listing {
  final String title;
  final String content;
  final String url;
  final String imageUrl;

  Listing({
    required this.title,
    required this.content,
    required this.url,
    required this.imageUrl,
  });

  /// Creates a Listing from a map
  factory Listing.fromMap(Map<String, String> map) {
    return Listing(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      url: map['url'] ?? '',
      imageUrl: map['image'] ?? '',
    );
  }

  /// Converts Listing to a map
  Map<String, String> toMap() {
    return {
      'title': title,
      'content': content,
      'url': url,
      'image': imageUrl,
    };
  }

  /// Returns true if the listing has a valid image URL
  bool get hasImage => imageUrl.isNotEmpty;
}
