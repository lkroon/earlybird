import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/listings_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/listing_card.dart';
import 'widgets/filter_dialog.dart';

/// Home screen displaying real estate listings
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListingsProvider>().fetchListings();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final provider = context.read<ListingsProvider>();

    // Calculate approximate current index based on scroll position
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final viewportDimension = _scrollController.position.viewportDimension;
    final totalScrollable = maxScroll + viewportDimension;

    if (totalScrollable > 0) {
      final approximateIndex =
          (currentScroll / totalScrollable * provider.listings.length).floor();

      // Trigger load more when needed
      if (provider.shouldLoadMore(approximateIndex)) {
        provider.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.fundaOrange,
        title: SvgPicture.asset(
          'assets/funda-logo-blue.svg',
          height: 30,
        ),
        centerTitle: true,
        actions: [
          // Show spinner when refreshing in background
          Consumer<ListingsProvider>(
            builder: (context, provider, child) {
              if (provider.isRefreshing) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<ListingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => provider.fetchListings(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.listings.isEmpty && !provider.isLoadingMore) {
            return const Center(child: Text('No listings found'));
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            itemCount:
                provider.listings.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at the end
              if (index >= provider.listings.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final listing = provider.listings[index];
              return ListingCard(listing: listing);
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'filter',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const FilterDialog(),
              );
            },
            tooltip: 'Filters',
            child: const Icon(Icons.filter_list),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'delete',
            backgroundColor: Colors.red,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Data'),
                  content: const Text(
                    'Are you sure you want to delete all cached listings? This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final provider = context.read<ListingsProvider>();
                        await provider.clearAllCachedListings();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All cached data cleared'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Clear all cached data',
            child: const Icon(Icons.delete_forever),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'refresh',
            onPressed: () {
              context.read<ListingsProvider>().refresh();
            },
            tooltip: 'Refresh',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
