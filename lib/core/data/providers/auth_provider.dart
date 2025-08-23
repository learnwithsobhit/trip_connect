import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../repositories/auth_repository.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState.initial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = const AuthState.loading();
    
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          state = AuthState.authenticated(user: user);
        } else {
          state = const AuthState.unauthenticated();
        }
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> signIn(String email, String password) async {
    print('AuthNotifier signIn started for email: $email');
    state = const AuthState.loading();
    
    try {
      final result = await _authRepository.signIn(email, password);
      print('AuthRepository signIn result: success=${result.isSuccess}, user=${result.user?.displayName}, error=${result.error}');
      
      if (result.isSuccess && result.user != null) {
        state = AuthState.authenticated(user: result.user!);
        print('Auth state set to authenticated for user: ${result.user!.displayName}');
      } else {
        state = AuthState.error(message: result.error ?? 'Sign in failed');
        print('Auth state set to error: ${result.error ?? 'Sign in failed'}');
      }
    } catch (e) {
      state = AuthState.error(message: e.toString());
      print('Auth signIn exception: $e');
    }
  }

  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
    String? phone,
    String language = 'en',
  }) async {
    state = const AuthState.loading();
    
    try {
      final result = await _authRepository.signUp(
        displayName: displayName,
        email: email,
        password: password,
        phone: phone,
        language: language,
      );
      
      if (result.isSuccess && result.user != null) {
        state = AuthState.authenticated(user: result.user!);
      } else {
        state = AuthState.error(message: result.error ?? 'Sign up failed');
      }
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> signInAsGuest({String? displayName}) async {
    state = const AuthState.loading();
    
    try {
      final result = await _authRepository.signInAsGuest(displayName: displayName);
      
      if (result.isSuccess && result.user != null) {
        state = AuthState.guest(guestUser: result.user!);
      } else {
        state = AuthState.error(message: result.error ?? 'Guest sign in failed');
      }
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> refreshAuth() async {
    try {
      final result = await _authRepository.refreshToken();
      
      if (result.isSuccess && result.user != null) {
        state = AuthState.authenticated(user: result.user!);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }
}

// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    authenticated: (user) => user,
    guest: (guestUser) => guestUser,
    orElse: () => null,
  );
});

// Authentication status provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    authenticated: (_) => true,
    guest: (_) => true, // Guests are considered "authenticated" for access purposes
    orElse: () => false,
  );
});

// Guest status provider
final isGuestUserProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    guest: (_) => true,
    orElse: () => false,
  );
});

// Auth state classes
abstract class AuthState {
  const AuthState();

  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated({required User user}) = _Authenticated;
  const factory AuthState.guest({required User guestUser}) = _Guest;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error({required String message}) = _Error;

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(User user) authenticated,
    required T Function(User guestUser) guest,
    required T Function() unauthenticated,
    required T Function(String message) error,
  }) {
    if (this is _Initial) return initial();
    if (this is _Loading) return loading();
    if (this is _Authenticated) return authenticated((this as _Authenticated).user);
    if (this is _Guest) return guest((this as _Guest).guestUser);
    if (this is _Unauthenticated) return unauthenticated();
    if (this is _Error) return error((this as _Error).message);
    throw Exception('Unknown AuthState');
  }

  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(User user)? authenticated,
    T Function(User guestUser)? guest,
    T Function()? unauthenticated,
    T Function(String message)? error,
  }) {
    if (this is _Initial) return initial?.call();
    if (this is _Loading) return loading?.call();
    if (this is _Authenticated) return authenticated?.call((this as _Authenticated).user);
    if (this is _Guest) return guest?.call((this as _Guest).guestUser);
    if (this is _Unauthenticated) return unauthenticated?.call();
    if (this is _Error) return error?.call((this as _Error).message);
    return null;
  }

  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(User user)? authenticated,
    T Function(User guestUser)? guest,
    T Function()? unauthenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    if (this is _Initial && initial != null) return initial();
    if (this is _Loading && loading != null) return loading();
    if (this is _Authenticated && authenticated != null) return authenticated((this as _Authenticated).user);
    if (this is _Guest && guest != null) return guest((this as _Guest).guestUser);
    if (this is _Unauthenticated && unauthenticated != null) return unauthenticated();
    if (this is _Error && error != null) return error((this as _Error).message);
    return orElse();
  }
}

class _Initial extends AuthState {
  const _Initial();
}

class _Loading extends AuthState {
  const _Loading();
}

class _Authenticated extends AuthState {
  final User user;
  const _Authenticated({required this.user});
}

class _Guest extends AuthState {
  final User guestUser;
  const _Guest({required this.guestUser});
}

class _Unauthenticated extends AuthState {
  const _Unauthenticated();
}

class _Error extends AuthState {
  final String message;
  const _Error({required this.message});
}

