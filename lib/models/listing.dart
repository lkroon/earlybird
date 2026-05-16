import 'package:hive/hive.dart';

part 'listing.g.dart';

@HiveType(typeId: 0)
class Listing extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String imageUrl;

  @HiveField(4)
  bool isViewed;

  @HiveField(5)
  DateTime firstSeenAt;

  @HiveField(6)
  DateTime? lastSeenAt;

  @HiveField(7)
  final String filterKey;

  Listing({
    required this.title,
    required this.content,
    required this.url,
    required this.imageUrl,
    this.isViewed = false,
    DateTime? firstSeenAt,
    this.lastSeenAt,
    this.filterKey = '',
  }) : firstSeenAt = firstSeenAt ?? DateTime.now();

  String get id => url;

  bool get hasImage => imageUrl.isNotEmpty;

  factory Listing.fromMap(Map<String, String> map, {String filterKey = ''}) {
    return Listing(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      url: map['url'] ?? '',
      imageUrl: map['image'] ?? '',
      filterKey: filterKey,
    );
  }

  Map<String, String> toMap() {
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

  void markAsViewed() {
    isViewed = true;
    lastSeenAt = DateTime.now();
  }

  void toggleViewed() {
    if (isViewed) {
      isViewed = false;
      lastSeenAt = null;
    } else {
      markAsViewed();
    }
  }

  Listing copyWith({
    String? title,
    String? content,
    String? url,
    String? imageUrl,
    bool? isViewed,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    String? filterKey,
  }) {
    return Listing(
      title: title ?? this.title,
      content: content ?? this.content,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      isViewed: isViewed ?? this.isViewed,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      filterKey: filterKey ?? this.filterKey,
    );
  }
}
