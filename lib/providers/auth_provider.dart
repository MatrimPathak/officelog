import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Single operation lock - only one auth operation at a time
  bool _isOperating = false;

  // Callback to reset other providers when user changes
  Function()? _onUserChanged;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isOperating => _isOperating;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Simple auth state listener - no complex logic
    _authService.authStateChanges.listen((User? user) {
      final previousUser = _user;
      _user = user;

      // Clear operating state when auth state changes
      if (_isOperating) {
        _isOperating = false;
        _setLoading(false);
      }

      // Reset other providers when user changes (logout or different user login)
      if (previousUser?.uid != user?.uid) {
        _onUserChanged?.call();
      }

      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    // Block if any operation is in progress
    if (_isOperating || _isLoading) {
      return false;
    }

    // Set operation lock
    _isOperating = true;
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        return true;
      }
      return false;
    } catch (e) {
      _setError('Google sign-in failed: $e');
      return false;
    } finally {
      // Don't clear _isOperating here - let auth state listener handle it
      // This prevents race conditions
    }
  }

  Future<void> signOut() async {
    // Block if any operation is in progress
    if (_isOperating || _isLoading) {
      return;
    }

    // Set operation lock
    _isOperating = true;
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
    } catch (e) {
      _setError('Sign out failed: $e');
    } finally {
      // Don't clear _isOperating here - let auth state listener handle it
      // This prevents race conditions
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set callback to reset other providers when user changes
  void setUserChangeCallback(Function() callback) {
    _onUserChanged = callback;
  }

  /// Force clear all states - emergency reset
  void forceReset() {
    _isOperating = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
