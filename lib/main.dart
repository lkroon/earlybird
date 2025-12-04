import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EarlyBird',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'EarlyBird Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, String>> _listings = [];
  List<Map<String, String>> _allHeadings = []; // Store all headings
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // Calculate approximate current index based on scroll position
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final approximateIndex = (currentScroll / (maxScroll + _scrollController.position.viewportDimension) * _listings.length).floor();
      
      // Trigger load more when viewing item at index (listings.length - 5) or beyond
      if (approximateIndex >= _listings.length - 5) {
        if (!_isLoadingMore && _currentIndex < _allHeadings.length) {
          _loadMore();
        }
      }
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _listings = [];
      _allHeadings = [];
      _currentIndex = 0;
    });

    try {
      final fundaUrl = 'https://www.funda.nl/zoeken/koop?selected_area=[%22soest%22]&object_type=[%22house%22]&publication_date="30"&sort="date_down"';
      final url = 'https://corsproxy.io/?${Uri.encodeComponent(fundaUrl)}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
        },
      );

      if (response.statusCode == 200) {
        // Parse HTML for Funda
        final document = html_parser.parse(response.body);

        // Get all headings with their following content
        final allHeadings = document.querySelectorAll('h1, h2, h3, h4');

        // Extract heading data without fetching images yet
        for (var heading in allHeadings) {
          final headingText = heading.text.trim();
          if (headingText.isEmpty) continue;

          // Extract href from innerHtml
          final innerHtml = heading.innerHtml;
          final hrefMatch = RegExp(r'href="([^"]+)"').firstMatch(innerHtml);
          var detailUrl = '';

          if (hrefMatch != null) {
            final href = hrefMatch.group(1) ?? '';
            detailUrl = href.startsWith('http') ? href : 'https://www.funda.nl$href';
          } else {
            continue;
          }

          // Try to get the next sibling text or parent's next content
          var nextContent = '';
          var nextElement = heading.nextElementSibling;
          if (nextElement != null) {
            nextContent = nextElement.text.trim();
            if (nextContent.length > 200) {
              nextContent = nextContent.substring(0, 200);
            }
          }

          if (detailUrl.contains('/detail/')) {
            _allHeadings.add({
              'title': headingText,
              'content': nextContent,
              'url': detailUrl,
              'image': '', // Will be loaded later
            });
          }
        }

        setState(() {
          _isLoading = false;
        });

        // Load first batch
        await _loadMore();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching data: $e');
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentIndex >= _allHeadings.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final batchSize = _currentIndex == 0 ? 10 : 5;
      final endIndex = (_currentIndex + batchSize).clamp(0, _allHeadings.length);
      final newListings = <Map<String, String>>[];

      for (var i = _currentIndex; i < endIndex; i++) {
        final heading = _allHeadings[i];
        final detailUrl = heading['url'] ?? '';
        var imageUrl = '';

        // Fetch the detail page to get the image
        if (detailUrl.isNotEmpty) {
          try {
            final detailResponse = await http.get(
              Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(detailUrl)}'),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              },
            );

            if (detailResponse.statusCode == 200) {
              final detailDoc = html_parser.parse(detailResponse.body);
              final detailImages = detailDoc.querySelectorAll('img');

              // Get the second image (skip the logo)
              if (detailImages.length > 1) {
                final img = detailImages.elementAt(1);
                imageUrl = img.attributes['src'] ?? img.attributes['data-src'] ?? img.attributes['data-lazy-src'] ?? '';
              }
            }
          } catch (e) {
            print('Error fetching detail page: $e');
          }
        }

        newListings.add({
          'title': heading['title'] ?? '',
          'content': heading['content'] ?? '',
          'url': detailUrl,
          'image': imageUrl,
        });
      }

      setState(() {
        _listings.addAll(newListings);
        _currentIndex = endIndex;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7A100),
        title: SvgPicture.asset(
          'assets/funda-logo-blue.svg',
          height: 30,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listings.isEmpty && !_isLoadingMore
              ? const Center(child: Text('No listings found'))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _listings.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _listings.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final listing = _listings[index];
                    if (listing['image']?.isEmpty ?? true) return const SizedBox.shrink();
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.network(
                            listing['image']!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.broken_image, size: 50)),
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (listing['title']?.isNotEmpty ?? false)
                                  Text(listing['title']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                if (listing['content']?.isNotEmpty ?? false)
                                  Text(listing['content']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (listing['url']?.isNotEmpty ?? false)
                                  InkWell(
                                    onTap: () async {
                                      final url = Uri.parse(listing['url']!);
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Text(
                                        listing['url']!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue,
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
                  },
                ),

      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
