import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _status = AuthStatus.authenticated;
        await _loadUserData();
      } else {
        _status = AuthStatus.unauthenticated;
        _userData = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;
    _userData = await _authService.getUserData(_user!.uid);

    // Retry once if Firestore returned null (race condition on new accounts)
    if (_userData == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      _userData = await _authService.getUserData(_user!.uid);
    }

    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.loginWithEmail(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      // Explicitly load user data after login
      await _loadUserData();

      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? jobTitle,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        jobTitle: jobTitle,
      );

      // Wait for Firestore to finish writing before loading
      await Future.delayed(const Duration(milliseconds: 800));
      await _loadUserData();

      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> deleteAccount(String password) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      await _authService.deleteAccount(password);
      _status = AuthStatus.unauthenticated;
      _userData = null;
      _user = null;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.authenticated;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> getSavedLoginData() {
    return _authService.getSavedLoginData();
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (_user == null) return;
    await _authService.updateUserData(_user!.uid, data);
    await _loadUserData();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}