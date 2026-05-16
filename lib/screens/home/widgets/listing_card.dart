import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../models/listing.dart';
import '../../../providers/listings_provider.dart';

const ColorFilter _greyscaleFilter = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

class ListingCard extends StatelessWidget {
  final Listing listing;

  const ListingCard({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    if (!listing.hasImage) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => _openUrl(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColorFiltered(
              colorFilter: listing.isViewed ? _greyscaleFilter : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
              child: Image.network(
                listing.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 50),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (listing.title.isNotEmpty)
                    Text(
                      listing.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: listing.isViewed ? Colors.grey : null,
                      ),
                    ),
                  if (listing.content.isNotEmpty)
                    Text(
                      listing.content,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  if (listing.url.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        listing.url,
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              listing.isViewed ? Colors.grey[400] : Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    if (listing.url.isEmpty) return;

    final url = Uri.parse(listing.url);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (context.mounted) {
        context.read<ListingsProvider>().markAsViewed(listing);
      }
    }
  }
}
