import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patpat_game/auth/auth_manager.dart';

class AuthState {
  final bool isLoggedIn;
  final String? userName;
  final String? userEmail;
  final String? photoUrl;
  final bool isLoading;

  /// Most recent provider-level error from a failed sign-in attempt. Cleared
  /// at the start of each new attempt. Used by main_menu to surface the
  /// real Apple/Firebase error code (instead of a generic "Giriş başarısız").
  final String? lastError;

  const AuthState({
    this.isLoggedIn = false,
    this.userName,
    this.userEmail,
    this.photoUrl,
    this.isLoading = false,
    this.lastError,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userName,
    String? userEmail,
    String? photoUrl,
    bool? isLoading,
    String? lastError,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        userName: userName ?? this.userName,
        userEmail: userEmail ?? this.userEmail,
        photoUrl: photoUrl ?? this.photoUrl,
        isLoading: isLoading ?? this.isLoading,
        lastError: lastError,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void checkCurrentUser() {
    final auth = AuthManager.instance;
    state = AuthState(
      isLoggedIn: auth.isLoggedIn,
      userName: auth.userName,
      userEmail: auth.userEmail,
      photoUrl: auth.userPhotoUrl,
    );
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, lastError: null);
    final result = await AuthManager.instance.signInWithGoogle();
    if (result.success) {
      state = AuthState(
        isLoggedIn: true,
        userName: result.displayName,
        userEmail: result.email,
        photoUrl: result.photoUrl,
      );
    } else {
      state = state.copyWith(isLoading: false, lastError: result.error);
    }
    return result.success;
  }

  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, lastError: null);
    final result = await AuthManager.instance.signInWithApple();
    if (result.success) {
      state = AuthState(
        isLoggedIn: true,
        userName: result.displayName,
        userEmail: result.email,
      );
    } else {
      state = state.copyWith(isLoading: false, lastError: result.error);
    }
    return result.success;
  }

  Future<void> signOut() async {
    await AuthManager.instance.signOut();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
