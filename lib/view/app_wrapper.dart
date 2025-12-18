import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glamify/controller/remote_config_service.dart';
import 'package:glamify/view/admin_dashboard/admin_bottom_nav_ui.dart';
import 'package:glamify/view/bottomNavUi.dart';
import 'package:glamify/view/auth_Ui/login_ui.dart';
import 'package:glamify/view/onboardingUi.dart';
import 'package:glamify/view/maintenance_page.dart';
import '../utils/logger.dart';

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
    // Only check for updates in debug mode to avoid unnecessary network calls in production
    if (kDebugMode) {
      // Check for updates every 30 seconds in debug mode only
      Stream.periodic(const Duration(seconds: 30)).listen((_) async {
        AppLogger.debug('Checking Remote Config (Debug Mode)', tag: 'APP_WRAPPER');
        await widget.remoteConfigService.fetchConfig();
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAppEnabled = widget.remoteConfigService.isAppEnabled;
    AppLogger.debug('Building AppWrapper', tag: 'APP_WRAPPER', data: {'appEnabled': isAppEnabled});
    
    if (!isAppEnabled) {
      AppLogger.info('Showing maintenance page', tag: 'APP_WRAPPER');
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
