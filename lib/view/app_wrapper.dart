import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glamify/controller/remote_config_service.dart';
import 'package:glamify/controller/update_service.dart';
import 'package:glamify/view/admin_dashboard/admin_bottom_nav_ui.dart';
import 'package:glamify/view/bottomNavUi.dart';
import 'package:glamify/view/auth_Ui/login_ui.dart';
import 'package:glamify/view/onboardingUi.dart';
import 'package:glamify/view/maintenance_page.dart';
import 'package:glamify/view/update_dialog.dart';
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
  /// مفتاح عداد فتحات التطبيق للتحديث الاختياري
  static const String _appOpenCountKey = 'update_app_open_count';
  /// عدد الفتحات قبل إعادة إظهار الدايلوق
  static const int _showEveryNOpens = 5;

  @override
  void initState() {
    super.initState();
    // Start listening to remote config changes
    _startRemoteConfigListener();

    // Check for updates after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
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

  /// فحص التحديثات عند فتح التطبيق
  Future<void> _checkForUpdates() async {
    // لا نفحص على الويب
    if (kIsWeb) return;

    try {
      final updateService = UpdateService(widget.remoteConfigService);
      final updateInfo = await updateService.checkForUpdate();

      if (!mounted) return;

      switch (updateInfo.status) {
        case UpdateStatus.forceUpdate:
          // تحديث إجباري → dialog ما يقفل — يظهر دائماً
          AppLogger.info('Force update required', tag: 'UPDATE');
          showUpdateDialog(context, updateInfo);
          break;

        case UpdateStatus.optionalUpdate:
          // تحديث اختياري → نظام ذكي: يظهر كل 5 فتحات
          final shouldShow = await _shouldShowOptionalUpdate(updateInfo.latestVersion);
          if (shouldShow && mounted) {
            AppLogger.info('Showing optional update (periodic)', tag: 'UPDATE');
            await showUpdateDialog(context, updateInfo);
          }
          break;

        case UpdateStatus.upToDate:
          // محدث → نمسح العداد
          await _resetOpenCount();
          AppLogger.debug('App is up to date', tag: 'UPDATE');
          break;
      }
    } catch (e) {
      AppLogger.error('Error checking for updates', tag: 'UPDATE', error: e);
    }
  }

  /// هل نعرض دايلوق التحديث الاختياري؟
  /// أول مرة: نعم. بعدها كل 5 فتحات.
  Future<bool> _shouldShowOptionalUpdate(String latestVersion) async {
    final prefs = await SharedPreferences.getInstance();

    // نتحقق إذا النسخة تغيرت — نعيد العداد
    final lastKnownVersion = prefs.getString('update_last_known_version') ?? '';
    if (lastKnownVersion != latestVersion) {
      // نسخة جديدة → نعيد العداد ونعرض فوراً
      await prefs.setString('update_last_known_version', latestVersion);
      await prefs.setInt(_appOpenCountKey, 0);
      AppLogger.info('New version detected ($latestVersion), resetting counter', tag: 'UPDATE');
      return true;
    }

    // نفس النسخة → نزيد العداد
    final currentCount = (prefs.getInt(_appOpenCountKey) ?? 0) + 1;
    await prefs.setInt(_appOpenCountKey, currentCount);

    AppLogger.debug('Optional update open count: $currentCount / $_showEveryNOpens', tag: 'UPDATE');

    // نعرض عند كل مضاعف لـ 5
    if (currentCount >= _showEveryNOpens) {
      await prefs.setInt(_appOpenCountKey, 0); // نعيد العداد
      return true;
    }

    return false;
  }

  /// مسح عداد الفتحات (عند التحديث)
  Future<void> _resetOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appOpenCountKey);
    await prefs.remove('update_last_known_version');
  }

  @override
  Widget build(BuildContext context) {
    final isAppEnabled = widget.remoteConfigService.isAppEnabled;
    AppLogger.debug('Building AppWrapper', tag: 'APP_WRAPPER', data: {'appEnabled': isAppEnabled});
    
    if (!isAppEnabled) {
      AppLogger.info('Showing maintenance page', tag: 'APP_WRAPPER');
      return const MaintenancePage();
    }

    // على الويب: تخطي Onboarding دائماً — الدخول مباشرة للوحة التحكم
    if (kIsWeb) {
      return _getInitialScreen();
    }

    // على الموبايل: التدفق العادي بدون أي تغيير
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
        // على الويب: المستخدم العادي لا يدخل المتجر — يرجع للـ Login
        if (kIsWeb) {
          return const LoginUi();
        }
        return const Run();
      }
    } else {
      return const LoginUi();
    }
  }
}
