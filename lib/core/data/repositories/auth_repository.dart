import '../models/models.dart';
import '../../services/mock_server.dart';

class AuthRepository {
  final MockServer _mockServer = MockServer();

  Future<AuthResult> signIn(String email, String password) async {
    try {
      final result = await _mockServer.signIn(email, password);
      
      if (result['success'] == true) {
        final user = User.fromJson(result['user']);
        return AuthResult.success(user: user, token: result['token']);
      } else {
        return AuthResult.failure(error: result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      return AuthResult.failure(error: 'Network error: $e');
    }
  }

  Future<AuthResult> signUp({
    required String displayName,
    required String email,
    required String password,
    String? phone,
    String language = 'en',
  }) async {
    try {
      final userData = {
        'displayName': displayName,
        'email': email,
        'phone': phone,
        'language': language,
      };
      
      final result = await _mockServer.signUp(userData);
      
      if (result['success'] == true) {
        final user = User.fromJson(result['user']);
        return AuthResult.success(user: user, token: result['token']);
      } else {
        return AuthResult.failure(error: result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      return AuthResult.failure(error: 'Network error: $e');
    }
  }

  Future<AuthResult> signInAsGuest({String? displayName}) async {
    try {
      final result = await _mockServer.signInAsGuest(displayName: displayName);
      
      if (result['success'] == true) {
        final user = User.fromJson(result['user']);
        return AuthResult.success(user: user, token: result['token']);
      } else {
        return AuthResult.failure(error: result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      return AuthResult.failure(error: 'Network error: $e');
    }
  }

  Future<void> signOut() async {
    // Clear any stored tokens/session data
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<User?> getCurrentUser() async {
    // In a real app, this would validate stored token and return user
    final userId = _mockServer.currentUserId;
    if (userId != null) {
      try {
        return _mockServer.users.firstWhere((user) => user.id == userId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }

  Future<AuthResult> refreshToken() async {
    // Mock token refresh
    await Future.delayed(const Duration(milliseconds: 300));
    final user = await getCurrentUser();
    
    if (user != null) {
      return AuthResult.success(user: user, token: 'refreshed_token_${user.id}');
    }
    
    return AuthResult.failure(error: 'Session expired');
  }
}

// Result classes
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? token;
  final String? error;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.token,
    this.error,
  });

  factory AuthResult.success({required User user, required String token}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      token: token,
    );
  }

  factory AuthResult.failure({required String error}) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }
}

