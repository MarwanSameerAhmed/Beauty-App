import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_pro/model/userAccount.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // For FCM Token
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
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
      await _saveDeviceToken(user.uid); // Save FCM token
      return null; // Success
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
      // Fetch user data from Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      await _saveDeviceToken(userCredential.user!.uid); // Save FCM token
      await _subscribeToTopics(userCredential.user!.uid); // Subscribe to topics
      return UserAccount.fromJson(
        doc.data() as Map<String, dynamic>,
      ); // Success, return user data
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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return 'تم إلغاء تسجيل الدخول.'; // User cancelled the sign-in
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
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
          // New user, create a document in Firestore
          final newUserAccount = UserAccount(
            uid: user.uid,
            name: user.displayName ?? 'مستخدم جوجل',
            email: user.email!,
            password: '', // Not needed for Google Sign-In
            confirmPassword: '', // Not needed for Google Sign-In
            accountType: 'فرد', // Default account type
            role: 'user', // Default role
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUserAccount.toJson());
          await _saveDeviceToken(user.uid);
          await _subscribeToTopics(user.uid);
          return newUserAccount;
        } else {
          // Existing user, just update token and return data
          await _saveDeviceToken(user.uid);
          await _subscribeToTopics(user.uid);
          return UserAccount.fromJson(doc.data() as Map<String, dynamic>);
        }
      }
      return 'حدث خطأ غير متوقع.';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'فشل تسجيل الدخول باستخدام جوجل.';
    } catch (e) {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Helper method to get and save the FCM token
  Future<void> _saveDeviceToken(String uid) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': fcmToken,
        });
      }
    } catch (e) {
      print('Error saving device token: $e');
      // Handle error appropriately
    }
  }

  // Subscribes the user to relevant topics based on their role
  static Future<void> _subscribeToTopics(String userId) async {
    print('Checking user role for topic subscription for user: $userId');
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        String role =
            userDoc.get('role') ??
            'user'; // Default to 'user' if role is not set
        print('User role is: $role');
        if (role == 'admin') {
          print('User is an admin. Subscribing to new_orders topic...');
          await FirebaseMessaging.instance.subscribeToTopic('new_orders');
          print('>>> SUCCESS: Admin user subscribed to new_orders topic.');
        } else {
          print('User is not an admin, no topic subscription needed.');
        }
      } else {
        print('User document not found. Cannot check role.');
      }
    } catch (e) {
      print('!!! CRITICAL ERROR subscribing to topics: $e');
    }
  }
}
