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

/// 本機使用者狀態
///
/// 本 App 為個人用、資料只存在本機，因此不提供登入 / 註冊。
/// 啟動即為本機使用者，僅載入使用者自訂的暱稱。
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier([SecureStorageService? storageService])
      : _storage = storageService ?? SecureStorageService(),
        super(AuthState.authenticated(UserEntity.local())) {
    _loadDisplayName();
  }

  final SecureStorageService _storage;

  Future<void> _loadDisplayName() async {
    try {
      final savedName = await _storage.getUserDisplayName();
      if (!mounted || savedName == null || savedName.trim().isEmpty) return;
      final user = state.user;
      if (user != null) {
        state = state.copyWith(user: user.copyWith(displayName: savedName));
      }
    } catch (_) {
      // 讀取失敗時沿用預設暱稱
    }
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
}
