import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._();
  static AuthManager get instance => _instance;
  AuthManager._();

  /// Whether Firebase was successfully initialized.
  bool firebaseReady = false;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  bool get isLoggedIn => firebaseReady && _auth.currentUser != null;
  String? get userName => firebaseReady ? _auth.currentUser?.displayName : null;
  String? get userEmail => firebaseReady ? _auth.currentUser?.email : null;
  String? get userPhotoUrl =>
      firebaseReady ? _auth.currentUser?.photoURL : null;
  String get accountId =>
      (firebaseReady ? _auth.currentUser?.uid : null) ?? 'guest';

  Future<AuthResult> signInWithGoogle() async {
    if (!firebaseReady) {
      return const AuthResult(
        success: false,
        error: 'Firebase yapilandirilmadi',
      );
    }

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return const AuthResult(success: false, error: 'Iptal edildi');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      return AuthResult(
        success: true,
        displayName: user?.displayName,
        email: user?.email,
        photoUrl: user?.photoURL,
        accountId: user?.uid,
      );
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  Future<AuthResult> signInWithApple() async {
    if (!firebaseReady) {
      return const AuthResult(
        success: false,
        error: 'Firebase yapilandirilmadi',
      );
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      // Apple only gives name on first sign-in
      if (appleCredential.givenName != null) {
        await user?.updateDisplayName(
          '${appleCredential.givenName} ${appleCredential.familyName}'.trim(),
        );
      }

      return AuthResult(
        success: true,
        displayName: user?.displayName ?? appleCredential.givenName,
        email: user?.email ?? appleCredential.email,
        accountId: user?.uid,
      );
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    if (!firebaseReady) return;
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  /// Listen to auth state changes (returns empty stream if Firebase not ready).
  Stream<User?> get authStateChanges {
    if (!firebaseReady) return const Stream.empty();
    return _auth.authStateChanges();
  }
}

class AuthResult {
  final bool success;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? accountId;
  final String? error;

  const AuthResult({
    required this.success,
    this.displayName,
    this.email,
    this.photoUrl,
    this.accountId,
    this.error,
  });
}
