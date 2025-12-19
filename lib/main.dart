import 'package:firebase_app_check/firebase_app_check.dart';
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
import 'package:connectivity_plus/connectivity_plus.dart';
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
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('your-recaptcha-v3-site-key'),
    );
  } else {
    // For production use
    if (kDebugMode) {
      // Debug mode - for development only
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } else {
      // Production mode - for App Store release
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  await LocalNotificationService.initialize();

  // Set up Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      LocalNotificationService.display(message);
    }
  });

  // Handle notification taps when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // Handle navigation based on message data
  });

  // Listen for token refresh and update Firestore
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    // FCM Token refreshed
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Error updating token
    }
  });

  // Handle notification tap when app was completely terminated
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    // App opened from terminated state via notification
    // Handle navigation based on notification data
  }

  await initializeDateFormatting('ar', null);

  // Initialize Remote Config
  final remoteConfigService = RemoteConfigService();
  await remoteConfigService.initialize();

  // Initialize AppConfig for secure API keys
  await AppConfig.instance.initialize();

  final connectivityService = ConnectivityService();
  final initialConnectivity = await connectivityService.hasInternetConnection();

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
            child: SafeArea(
              child: NoInternetCard(),
            ),
          ),
      ],
    );
  }
}
