import 'package:hive/hive.dart';

part 'listing.g.dart';

/// Represents a real estate listing
@HiveType(typeId: 0)
class Listing extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final List<String> imageUrls;

  @HiveField(4)
  final DateTime firstSeenAt;

  @HiveField(5)
  DateTime? lastSeenAt;

  @HiveField(6)
  bool isViewed;

  @HiveField(7)
  final String filterKey;

  Listing({
    required this.title,
    required this.content,
    required this.url,
    required this.imageUrls,
    DateTime? firstSeenAt,
    this.lastSeenAt,
    this.isViewed = false,
    this.filterKey = '',
  }) : firstSeenAt = firstSeenAt ?? DateTime.now();

  /// Unique identifier based on URL
  String get id => url;

  /// Returns the first image URL (thumbnail)
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  /// Creates a Listing from a map
  factory Listing.fromMap(Map<String, dynamic> map, {String filterKey = ''}) {
    final imageUrlsRaw = map['imageUrls'];
    List<String> imageUrls = [];

    if (imageUrlsRaw is List) {
      imageUrls = imageUrlsRaw.map((e) => e.toString()).toList();
    } else if (imageUrlsRaw is String && imageUrlsRaw.isNotEmpty) {
      imageUrls = [imageUrlsRaw];
    } else if (map['image'] != null && map['image'].toString().isNotEmpty) {
      imageUrls = [map['image'].toString()];
    }

    return Listing(
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      imageUrls: imageUrls,
      firstSeenAt: map['firstSeenAt'] is DateTime
          ? map['firstSeenAt']
          : (map['firstSeenAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['firstSeenAt'])
              : DateTime.now()),
      lastSeenAt: map['lastSeenAt'] is DateTime
          ? map['lastSeenAt']
          : (map['lastSeenAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['lastSeenAt'])
              : null),
      isViewed: map['isViewed'] as bool? ?? false,
      filterKey: map['filterKey']?.toString() ?? filterKey,
    );
  }

  /// Converts Listing to a map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'url': url,
      'imageUrls': imageUrls,
      'firstSeenAt': firstSeenAt.millisecondsSinceEpoch,
      'lastSeenAt': lastSeenAt?.millisecondsSinceEpoch,
      'isViewed': isViewed,
      'filterKey': filterKey,
    };
  }

  /// Returns true if the listing has a valid image URL
  bool get hasImage => imageUrls.isNotEmpty && imageUrls.first.isNotEmpty;

  /// Returns true if the listing is new (first seen within last 24 hours)
  bool get isNew =>
      !isViewed && DateTime.now().difference(firstSeenAt).inHours < 24;

  /// Marks the listing as viewed
  void markAsViewed() {
    isViewed = true;
    lastSeenAt = DateTime.now();
  }

  /// Toggles the viewed status
  void toggleViewed() {
    isViewed = !isViewed;
    lastSeenAt = isViewed ? DateTime.now() : null;
  }

  /// Creates a copy of the listing with updated fields
  Listing copyWith({
    String? title,
    String? content,
    String? url,
    List<String>? imageUrls,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    bool? isViewed,
    String? filterKey,
  }) {
    return Listing(
      title: title ?? this.title,
      content: content ?? this.content,
      url: url ?? this.url,
      imageUrls: imageUrls ?? this.imageUrls,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isViewed: isViewed ?? this.isViewed,
      filterKey: filterKey ?? this.filterKey,
    );
  }
}
