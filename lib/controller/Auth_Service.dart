import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:glamify/model/userAccount.dart';
import 'package:glamify/utils/logger.dart';
import 'package:glamify/config/web_config.dart';

// A special class to indicate a new user from Google sign-in
class NewGoogleUser {
  final User user;
  NewGoogleUser(this.user);
}

class AuthService {
  // Configure GoogleSignIn for web and mobile
  // iOS Client ID: 677899943891-3brjn65v46vplgat2u5f9g19f1shhsf4.apps.googleusercontent.com
  // Server Client ID (Web): 677899943891-5f1r21khbvsiphlelq0vs4qj82t7jc7p.apps.googleusercontent.com
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
        ? WebConfig.googleClientId // Web client ID from config
        : null, // Use GIDClientID from Info.plist for iOS
    serverClientId: '677899943891-5f1r21khbvsiphlelq0vs4qj82t7jc7p.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
    ],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerUser(UserAccount user) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );
      user.uid = cred.user!.uid;
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
      await _saveDeviceToken(user.uid); 
      return null; 
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'هذا البريد الإلكتروني مسجل بالفعل.';
        case 'weak-password':
          return 'كلمة المرور ضعيفة جدًا.';
        case 'invalid-email':
          return 'صيغة البريد الإلكتروني غير صحيحة.';
        default:
          return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
      }
    } catch (e) {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }

  Future<Object?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      await _saveDeviceToken(userCredential.user!.uid); 
      await _subscribeToTopics(userCredential.user!.uid);
      return UserAccount.fromJson(
        doc.data() as Map<String, dynamic>,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة.';
        case 'invalid-email':
          return 'صيغة البريد الإلكتروني غير صحيحة.';
        default:
          return 'فشل تسجيل الدخول. يرجى التحقق من بياناتك.';
      }
    } catch (e) {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }

  Future<Object?> signInWithGoogle() async {
    try {
      // For web, we don't need to sign out first as it causes issues
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (e) {
          // Ignore sign out errors (e.g., if no previous session exists)
          AppLogger.debug('Sign out before sign in failed (this is OK)', tag: 'AUTH');
        }
      }
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return 'تم إلغاء تسجيل الدخول.';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      
      // Check if we have the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return 'فشل في الحصول على بيانات المصادقة من جوجل.';
      }
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!doc.exists) {
          // This is a new user, return a special object to signal profile completion is needed.
          return NewGoogleUser(user);
        } else {
         
          await _saveDeviceToken(user.uid);
          await _subscribeToTopics(user.uid);
          return UserAccount.fromJson(doc.data() as Map<String, dynamic>);
        }
      }
      return 'حدث خطأ غير متوقع.';
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth Error', tag: 'AUTH', error: e);
      switch (e.code) {
        case 'popup-closed-by-user':
          return 'تم إغلاق نافذة تسجيل الدخول.';
        case 'popup-blocked':
          return 'تم حظر نافذة تسجيل الدخول. يرجى السماح بالنوافذ المنبثقة.';
        case 'network-request-failed':
          return 'فشل الاتصال بالإنترنت. يرجى المحاولة مرة أخرى.';
        default:
          return e.message ?? 'فشل تسجيل الدخول باستخدام جوجل.';
      }
    } catch (e) {
      AppLogger.error('Google Sign-In Error', tag: 'AUTH', error: e);
      if (e.toString().contains('popup_closed_by_user')) {
        return 'تم إغلاق نافذة تسجيل الدخول.';
      }
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      AppLogger.error('Error signing in anonymously', tag: 'AUTH', error: e);
      return null;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<String?> updateUserProfile(UserAccount user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson(), SetOptions(merge: true));
      await _saveDeviceToken(user.uid);
      await _subscribeToTopics(user.uid);
      return null; // Success
    } catch (e) {
      return 'حدث خطأ أثناء تحديث الملف الشخصي.';
    }
  }

  Future<UserAccount?> getCurrentUserAccount() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (doc.exists) {
          return UserAccount.fromJson(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting current user account', tag: 'AUTH', error: e);
      return null;
    }
  }

  static Future<void> _saveDeviceToken(String uid) async {
    try {
      // Skip FCM token for web as it requires different setup
      if (kIsWeb) {
        AppLogger.info('Skipping FCM token for web platform', tag: 'FCM');
        return;
      }
      
      String? fcmToken;
      
      // iOS requires APNs token before FCM token can be retrieved
      if (Platform.isIOS) {
        AppLogger.info('iOS detected, getting APNs token first...', tag: 'FCM');
        
        // Get APNs token first
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        
        // If APNs token is null, wait and retry
        if (apnsToken == null) {
          AppLogger.warning('APNs token is null, waiting 3 seconds...', tag: 'FCM');
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        }
        
        if (apnsToken != null) {
          AppLogger.info('APNs token retrieved successfully', tag: 'FCM', data: {'tokenPrefix': apnsToken.substring(0, 20)});
        } else {
          AppLogger.warning('APNs token still null after retry. Notifications may not work.', tag: 'FCM');
          // Continue anyway, FCM might still work in some cases
        }
      }
      
      // Now get FCM token
      fcmToken = await FirebaseMessaging.instance.getToken();
      
      if (fcmToken != null) {
        AppLogger.info('Saving FCM Token for user', tag: 'FCM', data: {'userId': uid, 'tokenPrefix': fcmToken.substring(0, 20)});
        
        // Use set with merge to create or update the document
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': Platform.isIOS ? 'ios' : 'android',
        }, SetOptions(merge: true));
        
        AppLogger.info('FCM Token saved successfully', tag: 'FCM');
      } else {
        AppLogger.warning('FCM Token is null, skipping save', tag: 'FCM');
      }
    } catch (e) {
      AppLogger.error('Error saving device token', tag: 'FCM', error: e);
    }
  }

  
  static Future<void> _subscribeToTopics(String userId) async {
    AppLogger.debug('Checking user role for topic subscription', tag: 'TOPICS', data: {'userId': userId});
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        String role =
            userDoc.get('role') ??
            'user'; 
        AppLogger.info('User role determined', tag: 'TOPICS', data: {'role': role});
        if (role == 'admin') {
          AppLogger.info('User is admin, subscribing to admin topics', tag: 'TOPICS');
          await FirebaseMessaging.instance.subscribeToTopic('new_orders');
          await FirebaseMessaging.instance.subscribeToTopic('admin_notifications');
          AppLogger.info('Admin user subscribed to admin topics successfully', tag: 'TOPICS');
        } else {
          AppLogger.debug('User is not admin, no topic subscription needed', tag: 'TOPICS');
        }
      } else {
        AppLogger.warning('User document not found, cannot check role', tag: 'TOPICS');
      }
    } catch (e) {
      AppLogger.error('CRITICAL ERROR subscribing to topics', tag: 'TOPICS', error: e);
    }
  }
}
