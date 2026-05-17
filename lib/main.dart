import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'models/listing.dart';
import 'providers/listings_provider.dart';
import 'services/funda_scraper_service.dart';
import 'services/listing_storage_service.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    Hive.registerAdapter(ListingAdapter());

    final storageService = ListingStorageService();
    await storageService.init();

    runApp(MyApp(storageService: storageService));
  } catch (e, stack) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Startup error:\n\n$e\n\n$stack',
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final ListingStorageService storageService;

  const MyApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ListingsProvider(
        scraperService: FundaScraperService(),
        storageService: storageService,
      ),
      child: MaterialApp(
        title: 'EarlyBird',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
