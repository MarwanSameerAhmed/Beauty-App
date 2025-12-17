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
import 'package:test_pro/controller/cart_service.dart';
import 'package:test_pro/firebase_options.dart';
import 'package:test_pro/view/app_wrapper.dart';
import 'package:test_pro/controller/local_notification_service.dart'; // For foreground notifications
import 'package:test_pro/controller/remote_config_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test_pro/controller/connectivity_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تخصيص شريط الحالة للتطبيق بالكامل
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 249, 237, 237), // لون خلفية التطبيق
      statusBarIconBrightness: Brightness.dark, // أيقونات داكنة
      statusBarBrightness: Brightness.light, // للـ iOS
      systemNavigationBarColor: Color.fromARGB(255, 249, 237, 237),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Request notification permissions with better handling
  final NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Log permission status
  print('🔔 Notification Permission Status: ${settings.authorizationStatus}');
  
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ User granted notification permissions');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('⚠️ User granted provisional notification permissions');
  } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print('❌ User denied notification permissions');
  } else {
    print('⚠️ Notification permission status: ${settings.authorizationStatus}');
  }

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
    print('Message clicked: ${message.messageId}');
    // Handle navigation based on message data
  });

  // Listen for token refresh and update Firestore
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        print('📝 Updating token in Firestore for user: ${user.uid}');
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('✅ Token updated successfully in Firestore');
      } else {
        print('⚠️ No authenticated user or anonymous user, skipping token update');
      }
    } catch (e) {
      print('❌ Error updating token: $e');
    }
  });

  // Handle notification tap when app was completely terminated
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('🚀 App opened from terminated state via notification');
    print('📬 Message ID: ${initialMessage.messageId}');
    print('📋 Data: ${initialMessage.data}');
    // Handle navigation based on notification data
    // You can store this message and handle it after app initialization
  }

  await initializeDateFormatting('ar', null);

  // Initialize Remote Config
  final remoteConfigService = RemoteConfigService();
  await remoteConfigService.initialize();

  final connectivityService = ConnectivityService();
  final initialConnectivity = await connectivityService.checkConnectivity();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartService()),
        StreamProvider<ConnectivityResult>(
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
      title: 'تطبيق ميك أب',
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
    final connectivityResult = Provider.of<ConnectivityResult?>(context);

    return Stack(
      children: [
        child,
        if (connectivityResult == ConnectivityResult.none)
          const NoInternetPopup(),
      ],
    );
  }
}

class NoInternetPopup extends StatefulWidget {
  const NoInternetPopup({super.key});

  @override
  State<NoInternetPopup> createState() => _NoInternetPopupState();
}

class _NoInternetPopupState extends State<NoInternetPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(40.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFF9D5D3).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'انقطع الاتصال',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                        fontFamily: 'Tajawal',

                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'يرجى التحقق من اتصالك بالإنترنت',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.8),
                        decoration: TextDecoration.none,
                        fontFamily: 'Tajawal',
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
