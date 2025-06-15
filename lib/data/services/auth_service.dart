import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn(
    clientId: '807405084469-lekdvlugk81mrf4saml2mvdccq44morf.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
    ],
  );
  final _storage = const FlutterSecureStorage();
  static const _isLoggedInKey = 'is_logged_in';
  static const _userEmailKey = 'user_email';

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign In was canceled by user');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Failed to get Google auth tokens');
        return null;
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        print('Failed to sign in to Firebase');
        return null;
      }

      // Store login state and user email
      await _storage.write(key: _isLoggedInKey, value: 'true');
      await _storage.write(key: _userEmailKey, value: userCredential.user?.email);

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      await _storage.delete(key: _isLoggedInKey);
      await _storage.delete(key: _userEmailKey);
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  String? get currentUserEmail => _auth.currentUser?.email;

  Future<String?> getIdToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }
} 