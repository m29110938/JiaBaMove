import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';

enum AuthStatus {
  unauthenticated,
  loading,
  authenticated,
  error,
}

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = null;

  const AuthState.authenticated(this.user)
      : status = AuthStatus.authenticated,
        errorMessage = null;

  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier([SecureStorageService? storageService])
      : _storage = storageService ?? SecureStorageService(),
        super(const AuthState.unauthenticated());

  final SecureStorageService _storage;

  /// 訪客模式快速登入
  Future<void> continueAsGuest() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 300));
    var guest = UserEntity.guest();
    final savedName = await _storage.getUserDisplayName();
    if (savedName != null && savedName.isNotEmpty) {
      guest = guest.copyWith(displayName: savedName);
    }
    state = AuthState.authenticated(guest);
  }

  /// Apple Sign-In 登入
  Future<bool> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600));
    // 模擬或整合 Apple 授權流程
    var appleUser = const UserEntity(
      id: 'apple_user_demo',
      email: 'apple_user@icloud.com',
      displayName: 'Apple 尊榮會員',
      isGuest: false,
    );
    final savedName = await _storage.getUserDisplayName();
    if (savedName != null && savedName.isNotEmpty) {
      appleUser = appleUser.copyWith(displayName: savedName);
    }
    state = AuthState.authenticated(appleUser);
    return true;
  }

  /// Google 登入
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600));
    // 模擬或整合 Google 授權流程
    var googleUser = const UserEntity(
      id: 'google_user_demo',
      email: 'gemini_lover@gmail.com',
      displayName: 'Google 健身夥伴',
      isGuest: false,
    );
    final savedName = await _storage.getUserDisplayName();
    if (savedName != null && savedName.isNotEmpty) {
      googleUser = googleUser.copyWith(displayName: savedName);
    }
    state = AuthState.authenticated(googleUser);
    return true;
  }

  /// 電子信箱登入
  Future<bool> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: '請填寫完整的電子信箱與密碼喔！',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600));

    final user = UserEntity(
      id: 'email_${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      displayName: cleanEmail.split('@').first,
      isGuest: false,
    );
    state = AuthState.authenticated(user);
    return true;
  }

  /// 電子信箱註冊
  Future<bool> registerWithEmail(
    String email,
    String password,
    String nickname,
  ) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.length < 6) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: '密碼至少需要 6 碼以上喔！',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 700));

    final user = UserEntity(
      id: 'email_${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      displayName: nickname.trim().isEmpty ? '健美巨巨' : nickname.trim(),
      isGuest: false,
    );
    state = AuthState.authenticated(user);
    return true;
  }

  /// 更新會員名稱 (暱稱) 並安全儲存於本機
  Future<void> updateDisplayName(String newName) async {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) return;

    if (state.user != null) {
      final updatedUser = state.user!.copyWith(displayName: cleanName);
      state = state.copyWith(user: updatedUser);
      await _storage.saveUserDisplayName(cleanName);
    }
  }

  /// 登出
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    await Future.delayed(const Duration(milliseconds: 200));
    state = const AuthState.unauthenticated();
  }
}
