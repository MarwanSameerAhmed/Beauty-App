import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_pro/model/userAccount.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // For FCM Token
import 'package:google_sign_in/google_sign_in.dart';

// A special class to indicate a new user from Google sign-in
class NewGoogleUser {
  final User user;
  NewGoogleUser(this.user);
}

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
      // Ensure the user is signed out from any previous session to allow account switching.
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return 'تم إلغاء تسجيل الدخول.';
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
      
    }
  }

  
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
            'user'; 
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
