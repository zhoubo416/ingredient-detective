import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  static bool get isConfigured => ApiConfig.isSupabaseConfigured;

  User? get currentUser => isConfigured ? _auth.currentUser : null;

  Session? get currentSession => isConfigured ? _auth.currentSession : null;

  bool get isSignedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<Session?> getValidSession({bool forceRefresh = false}) async {
    if (!isConfigured) return null;

    final session = _auth.currentSession;
    if (session == null) {
      return null;
    }

    if (!forceRefresh && !session.isExpired) {
      return session;
    }

    try {
      final refreshed = await _auth.refreshSession();
      return refreshed.session;
    } catch (_) {
      await _auth.signOut();
      return null;
    }
  }

  Future<bool> hasValidSession() async {
    return await getValidSession() != null;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> resetPasswordForEmail({
    required String email,
  }) {
    return _auth.resetPasswordForEmail(email);
  }

  Future<ResendResponse> resendSignupConfirmation({
    required String email,
  }) {
    return _auth.resend(
      email: email,
      type: OtpType.signup,
    );
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
