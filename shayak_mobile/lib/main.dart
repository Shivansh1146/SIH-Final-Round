import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';

/// ============================================================================
/// SHAYAK-AI: Application Entrypoint & Theme Configuration
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
  } catch (e) {
    debugPrint('[SHAYAK-INIT] Hive local cache notice: $e');
  }

  runApp(const ShayakApp());
}

class ShayakApp extends StatelessWidget {
  const ShayakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHAYAK-AI: Cognitive & Memory Support',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const MainNavigationScreen(),
    );
  }
}
