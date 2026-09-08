import 'package:flutter/material.dart';
import '../widgets/app_top_bar.dart';
import 'landing_screen.dart';
import 'patient_home_screen.dart';
import 'caregiver_workspace_screen.dart';
import 'patient_registration_screen.dart';
import 'doctor_dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  AppViewMode _currentMode = AppViewMode.landing;

  void _onModeChanged(AppViewMode mode) {
    setState(() {
      _currentMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentMode) {
      case AppViewMode.landing:
        return LandingScreen(onNavigate: _onModeChanged);
      case AppViewMode.patient:
        return PatientHomeScreen(onNavigate: _onModeChanged);
      case AppViewMode.caregiver:
        return CaregiverWorkspaceScreen(onNavigate: _onModeChanged);
      case AppViewMode.doctor:
        return DoctorDashboardScreen(onNavigate: _onModeChanged);
      case AppViewMode.register:
        return PatientRegistrationScreen(
          onRegistered: () => _onModeChanged(AppViewMode.patient),
          onNavigate: _onModeChanged,
        );
    }
  }
}
