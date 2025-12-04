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
      final approximateIndex = (currentScroll / totalScrollable * provider.listings.length).floor();
      
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
      ),
      body: Consumer<ListingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.listings.isEmpty && !provider.isLoadingMore) {
            return const Center(child: Text('No listings found'));
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.listings.length + (provider.isLoadingMore ? 1 : 0),
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
