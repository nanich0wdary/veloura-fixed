// lib/core/services/auth_service.dart
// Veloura — Real Google Sign-In + Drive API client

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _scopes = [
    drive.DriveApi.driveAppdataScope, // AppData folder — private to app
  ];

  final _googleSignIn = GoogleSignIn(scopes: _scopes);

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  bool   get isSignedIn => _currentUser != null;
  String get userEmail  => _currentUser?.email        ?? '';
  String get userName   => _currentUser?.displayName  ?? '';
  String get userPhoto  => _currentUser?.photoUrl     ?? '';

  /// Silent sign-in — restores previous session without UI
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (kDebugMode) debugPrint('Silent sign-in: ${_currentUser?.email ?? "no session"}');
      return _currentUser;
    } catch (e) {
      if (kDebugMode) debugPrint('Silent sign-in error: $e');
      return null;
    }
  }

  /// Interactive sign-in — shows Google account picker
  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (kDebugMode) debugPrint('Signed in: ${_currentUser?.email}');
      return _currentUser;
    } catch (e) {
      if (kDebugMode) debugPrint('Sign-in error: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      if (kDebugMode) debugPrint('Signed out');
    } catch (e) {
      if (kDebugMode) debugPrint('Sign-out error: $e');
    }
  }

  /// Get Drive API client — authenticated
  Future<drive.DriveApi?> getDriveApi() async {
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return null;
      return drive.DriveApi(httpClient);
    } catch (e) {
      if (kDebugMode) debugPrint('getDriveApi error: $e');
      return null;
    }
  }
}
