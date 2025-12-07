import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../models/listing.dart';
import '../../../providers/listings_provider.dart';

/// A card widget that displays a single listing
class ListingCard extends StatelessWidget {
  final Listing listing;

  const ListingCard({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    // Don't display listings without images
    if (!listing.hasImage) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Listing image with badge overlay
          Stack(
            children: [
              ColorFiltered(
                colorFilter: listing.isViewed
                    ? const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0, // Red channel
                        0.2126, 0.7152, 0.0722, 0, 0, // Green channel
                        0.2126, 0.7152, 0.0722, 0, 0, // Blue channel
                        0, 0, 0, 1, 0, // Alpha channel
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: Opacity(
                  opacity: listing.isViewed ? 0.6 : 1.0,
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
              ),
              // Badge overlay
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () async {
                    final provider = Provider.of<ListingsProvider>(
                      context,
                      listen: false,
                    );
                    await provider.toggleListingViewed(listing.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: listing.isViewed
                          ? Colors.grey.withOpacity(0.9)
                          : Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      listing.isViewed ? Icons.visibility : Icons.priority_high,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Listing details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                if (listing.title.isNotEmpty)
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: listing.isViewed ? Colors.grey : Colors.black,
                    ),
                  ),

                // Content/description
                if (listing.content.isNotEmpty)
                  Text(
                    listing.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: listing.isViewed ? Colors.grey[400] : Colors.grey,
                    ),
                  ),

                // URL link
                if (listing.url.isNotEmpty)
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse(listing.url);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Padding(
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
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
