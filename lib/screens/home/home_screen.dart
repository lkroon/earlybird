import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/site.dart';
import '../../providers/listings_provider.dart';
import 'widgets/captcha_webview.dart';
import 'widgets/listing_card.dart';
import 'widgets/filter_dialog.dart';
import 'widgets/site_selector.dart';

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

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final viewportDimension = _scrollController.position.viewportDimension;
    final totalScrollable = maxScroll + viewportDimension;

    if (totalScrollable > 0) {
      final approximateIndex =
          (currentScroll / totalScrollable * provider.listings.length).floor();

      if (provider.shouldLoadMore(approximateIndex)) {
        provider.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ListingsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Color(provider.selectedSite.backgroundColor),
            title: SiteSelector(
              selectedSite: provider.selectedSite,
              onSiteChanged: provider.selectSite,
            ),
            centerTitle: true,
          ),
          body: _buildBody(provider),
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
      },
    );
  }

  Widget _buildBody(ListingsProvider provider) {
    if (provider.needsCaptcha) {
      return CaptchaWebView(
        url: provider.searchUrl,
        botProtectionPageTitle: provider.scraperService.botProtectionPageTitle,
        onDataExtracted: (headings) =>
            provider.onWebViewDataExtracted(headings),
        onError: () => provider.onWebViewError(),
      );
    }

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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
      itemCount: provider.listings.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
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
  }
}
