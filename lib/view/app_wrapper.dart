import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pro/controller/remote_config_service.dart';
import 'package:test_pro/view/admin_dashboard/admin_bottom_nav_ui.dart';
import 'package:test_pro/view/bottomNavUi.dart';
import 'package:test_pro/view/auth_Ui/login_ui.dart';
import 'package:test_pro/view/onboardingUi.dart';
import 'package:test_pro/view/maintenance_page.dart';

class AppWrapper extends StatefulWidget {
  final bool onboardingComplete;
  final SharedPreferences prefs;
  final RemoteConfigService remoteConfigService;

  const AppWrapper({
    super.key,
    required this.onboardingComplete,
    required this.prefs,
    required this.remoteConfigService,
  });

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    // Start listening to remote config changes
    _startRemoteConfigListener();
  }

  void _startRemoteConfigListener() {
    // Check for updates every 5 seconds for testing
    Stream.periodic(const Duration(seconds: 5)).listen((_) async {
      print('🔍 Checking Remote Config...');
      await widget.remoteConfigService.fetchConfig();
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAppEnabled = widget.remoteConfigService.isAppEnabled;
    print('🏗️ Building AppWrapper - App enabled: $isAppEnabled');
    
    if (!isAppEnabled) {
      print('🚧 Showing maintenance page');
      return const MaintenancePage();
    }

    if (widget.onboardingComplete) {
      return _getInitialScreen();
    } else {
      return const OnboardingScreen();
    }
  }

  Widget _getInitialScreen() {
    final bool isLoggedIn = widget.prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      final String userRole = widget.prefs.getString('role') ?? 'user';
      if (userRole == 'admin') {
        return const AdminBottomNav();
      } else {
        return const Run();
      }
    } else {
      return const LoginUi();
    }
  }
}
