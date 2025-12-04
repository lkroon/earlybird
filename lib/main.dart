import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/listings_provider.dart';
import 'services/funda_scraper_service.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ListingsProvider(
        scraperService: FundaScraperService(),
      ),
      child: MaterialApp(
        title: 'EarlyBird',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
