import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'providers/listings_provider.dart';
import 'services/funda_scraper_service.dart';
import 'services/listing_storage_service.dart';
import 'models/listing.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ListingAdapter());

  // Initialize storage service
  final storageService = ListingStorageService();
  await storageService.init();

  runApp(MyApp(storageService: storageService));
}

class MyApp extends StatelessWidget {
  final ListingStorageService storageService;

  const MyApp({
    super.key,
    required this.storageService,
  });

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
