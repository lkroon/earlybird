import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/listing.dart';

/// Full-screen image gallery with swipe functionality
class ImageGalleryScreen extends StatefulWidget {
  final Listing listing;
  final int initialIndex;

  const ImageGalleryScreen({
    super.key,
    required this.listing,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late List<String> _imageUrls;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _imageUrls = widget.listing.imageUrl.isNotEmpty
        ? [widget.listing.imageUrl]
        : [];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${_imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (widget.listing.url.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open listing',
              onPressed: () async {
                final url = Uri.parse(widget.listing.url);
                if (await canLaunchUrl(url)) {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Image viewer with swipe
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                final isFirstImage = index == 0;
                return Center(
                  child: Hero(
                    tag: isFirstImage
                        ? 'listing-image-${widget.listing.id}'
                        : 'listing-image-${widget.listing.id}-$index',
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Image.network(
                        _imageUrls[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Listing details
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.listing.title.isNotEmpty)
                  Text(
                    widget.listing.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (widget.listing.content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.listing.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
