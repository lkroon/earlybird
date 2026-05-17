import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'models/listing.dart';
import 'providers/listings_provider.dart';
import 'services/captcha_session_service.dart';
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

    final captchaSession = CaptchaSessionService();

    runApp(
        MyApp(storageService: storageService, captchaSession: captchaSession));
  } catch (e, stack) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
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
  final CaptchaSessionService captchaSession;

  const MyApp({
    super.key,
    required this.storageService,
    required this.captchaSession,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CaptchaSessionService>.value(value: captchaSession),
        ChangeNotifierProvider(
          create: (_) => ListingsProvider(
            scraperService: FundaScraperService(captchaSession: captchaSession),
            storageService: storageService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'EarlyBird',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
