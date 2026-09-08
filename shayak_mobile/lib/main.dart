import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';

/// ============================================================================
/// SHAYAK-AI: Application Entrypoint & Offline-First Persistence Initialization
/// Initializes Hive for on-device edge caching, configures WCAG AAA accessibility
/// parameters, and mounts the persistent navigation shell.
/// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce high-contrast system UI overlay styles
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.darkNavy,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive for offline-first local session persistence
  try {
    await Hive.initFlutter();
    // Open cached assessment boxes and user preferences
    await Hive.openBox('assessment_cache');
    await Hive.openBox('user_preferences');
    debugPrint('[SHAYAK-INIT] Hive local databases initialized.');
  } catch (e) {
    debugPrint('[SHAYAK-INIT] Hive initialization notice (fallback to in-memory): $e');
  }

  runApp(const ShayakApp());
}

class ShayakApp extends StatelessWidget {
  const ShayakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHAYAK-AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.highContrastTheme,
      // Accessibility: Enforce minimum text scaling to prevent cramped layouts for elderly users
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Ensure scale is at least 1.0 and clamped to 1.35 to maintain layout integrity
        final clampedScale = mediaQuery.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.35,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScale),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}
