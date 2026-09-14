import 'package:flutter/material.dart';
import 'screens/emergency_history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/nearby_care_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CareLinkApp());
}

class CareLinkApp extends StatelessWidget {
  const CareLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareLink AI',
      theme: AppTheme.lightTheme,
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/nearby-care': (context) => const NearbyCareScreen(),
        '/emergency-history': (context) => const EmergencyHistoryScreen(),
      },
      onGenerateRoute: (settings) {
        // Safe graceful route generator for teammate modules (auth, profile, triage)
        // when navigated before parallel branches are merged into main/develop
        if (settings.name == '/home') {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
        if (settings.name == '/nearby-care') {
          return MaterialPageRoute(builder: (_) => const NearbyCareScreen());
        }
        if (settings.name == '/emergency-history') {
          return MaterialPageRoute(
            builder: (_) => const EmergencyHistoryScreen(),
          );
        }
        // Fallback to HomeScreen for undefined routes
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      },
      home: const HomeScreen(),
    );
  }
}

/// Backward compatibility alias for teammate modules expecting `CareLinkHomePage`
typedef CareLinkHomePage = HomeScreen;