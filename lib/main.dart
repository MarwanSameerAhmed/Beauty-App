import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pro/controller/cart_service.dart';
import 'package:test_pro/firebase_options.dart';
import 'package:test_pro/view/admin_dashboard/admin_bottom_nav_ui.dart';
import 'package:test_pro/view/bottomNavUi.dart';
import 'package:test_pro/view/loginUi.dart';
import 'package:test_pro/view/onboardingUi.dart';
import 'package:test_pro/controller/local_notification_service.dart'; // For foreground notifications
import 'package:intl/date_symbol_data_local.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('your-recaptcha-v3-site-key'),
    );
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  LocalNotificationService.initialize();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      LocalNotificationService.display(message);
    }
  });

  await initializeDateFormatting('ar', null);

  runApp(
    ChangeNotifierProvider(
      create: (context) => CartService(),
      child: MyApp(onboardingComplete: onboardingComplete, prefs: prefs),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.onboardingComplete,
    required this.prefs,
  });

  final bool onboardingComplete;
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تطبيق ميك أب',
      theme: ThemeData(fontFamily: 'Tajawal'),
      home: onboardingComplete ? _getInitialScreen() : const OnboardingScreen(),
    );
  }

  Widget _getInitialScreen() {
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      final String userRole = prefs.getString('role') ?? 'user';
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
