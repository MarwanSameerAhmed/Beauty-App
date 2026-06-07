import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:firebase_core/firebase_core.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glamify/controller/cart_service.dart';
import 'package:glamify/firebase_options.dart';
import 'package:glamify/view/app_wrapper.dart';
import 'package:glamify/controller/local_notification_service.dart'; // For foreground notifications
import 'package:glamify/controller/remote_config_service.dart';
import 'package:glamify/config/app_config.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:glamify/controller/connectivity_service.dart';
import 'package:glamify/widgets/connectivity_card.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Handling a background message: ${message.messageId}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تخصيص شريط الحالة للتطبيق بالكامل - شفاف للسماح بامتداد الباك قراوند
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // شفاف للسماح بامتداد الباك قراوند
      statusBarIconBrightness: Brightness.dark, // أيقونات داكنة
      statusBarBrightness: Brightness.light, // للـ iOS
      systemNavigationBarColor: Color.fromARGB(255, 249, 237, 237),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // === الخطوات الأساسية فقط (لازم تكتمل قبل ما يظهر التطبيق) ===
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Crashlytics for production error tracking
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    // Disable Crashlytics in debug mode
    if (kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  await initializeDateFormatting('ar', null);

  // Remote Config - مع timeout عشان ما يعلق التطبيق
  final remoteConfigService = RemoteConfigService();
  try {
    await remoteConfigService.initialize().timeout(const Duration(seconds: 5));
  } catch (e) {
    // Remote Config timed out - continue with defaults
  }

  final connectivityService = ConnectivityService();
  final initialConnectivity = await connectivityService
      .hasInternetConnection()
      .timeout(const Duration(seconds: 3), onTimeout: () => true);

  // === شغّل التطبيق فوراً! ===
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartService()),
        StreamProvider<bool>(
          create: (context) => connectivityService.connectionStatusStream,
          initialData: initialConnectivity,
        ),
      ],
      child: MyApp(
        onboardingComplete: onboardingComplete,
        prefs: prefs,
        remoteConfigService: remoteConfigService,
      ),
    ),
  );

  // === كل الخدمات الثانوية تشتغل بالخلفية بعد ما يظهر التطبيق ===
  _initializeBackgroundServices();
}

/// الخدمات اللي مو ضرورية قبل عرض التطبيق - تشتغل بالخلفية
Future<void> _initializeBackgroundServices() async {
  try {
    // Firebase App Check
    try {
      if (kIsWeb) {
        await FirebaseAppCheck.instance
            .activate(
              webProvider: ReCaptchaV3Provider('your-recaptcha-v3-site-key'),
            )
            .timeout(const Duration(seconds: 5));
      } else {
        if (kDebugMode) {
          await FirebaseAppCheck.instance
              .activate(
                androidProvider: AndroidProvider.debug,
                appleProvider: AppleProvider.debug,
              )
              .timeout(const Duration(seconds: 5));
        } else {
          await FirebaseAppCheck.instance
              .activate(
                androidProvider: AndroidProvider.playIntegrity,
                appleProvider: AppleProvider.appAttest,
              )
              .timeout(const Duration(seconds: 5));
        }
      }
    } catch (e) {
      // App Check failed or timed out - continue without it
    }

    // Notification permissions
    try {
      await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      // Permission request failed - continue
    }

    // Local notifications
    try {
      await LocalNotificationService.initialize().timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      // Local notification init failed - continue
    }

    // Firebase Messaging handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        LocalNotificationService.display(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle navigation based on message data
    });

    // Listen for token refresh and update Firestore
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.isAnonymous) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'fcmToken': newToken,
                'lastTokenUpdate': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      } catch (e) {
        // Error updating token
      }
    });

    // Handle notification tap when app was completely terminated
    try {
      await FirebaseMessaging.instance.getInitialMessage().timeout(
        const Duration(seconds: 3),
      );
    } catch (e) {
      // Initial message check failed - continue
    }

    // Initialize AppConfig for secure API keys
    try {
      await AppConfig.instance.initialize().timeout(const Duration(seconds: 5));
    } catch (e) {
      // AppConfig timed out - continue with defaults
    }
  } catch (e) {
    // Background services initialization failed - app continues normally
  }
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.onboardingComplete,
    required this.prefs,
    required this.remoteConfigService,
  });

  final bool onboardingComplete;
  final SharedPreferences prefs;
  final RemoteConfigService remoteConfigService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glamify',
      theme: ThemeData(fontFamily: 'Tajawal'),
      home: ConnectivityWrapper(
        child: AppWrapper(
          onboardingComplete: onboardingComplete,
          prefs: prefs,
          remoteConfigService: remoteConfigService,
        ),
      ),
    );
  }
}

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isConnected = Provider.of<bool?>(context);

    return Stack(
      children: [
        child,
        if (isConnected == false)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: NoInternetCard()),
          ),
      ],
    );
  }
}
