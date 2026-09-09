import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'services/local_database_service.dart';
import 'services/notification_service.dart';

/// ============================================================================
/// SAHAYAK—AI: Application Entrypoint & Theme Configuration
/// Serene Sage & Forest Green Elderly Cognitive Health Interface
/// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure high-contrast system UI overlay styles
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Hive.initFlutter();
    await Hive.openBox('assessment_cache');
    await Hive.openBox('user_preferences');
    await LocalDatabaseService.init();
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('[SAHAYAK-INIT] Local database notice: $e');
  }

  runApp(const SahayakApp());
}

class SahayakApp extends StatelessWidget {
  const SahayakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAHAYAK—AI: Cognitive & Memory Support',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const MainNavigationScreen(),
    );
  }
}
