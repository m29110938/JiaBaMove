import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/features/auth/domain/entities/user_entity.dart';
import 'package:jiaba_move/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  group('Auth Flow Unit Tests (CI/CD-First)', () {
    test('UserEntity guest creation works correctly', () {
      final guestUser = UserEntity.guest();

      expect(guestUser.isGuest, isTrue);
      expect(guestUser.displayName, equals('熱血健身訪客'));
      expect(guestUser.id, startsWith('guest_'));
      expect(guestUser.email, isNull);
    });

    test('UserEntity authenticated user creation works correctly', () {
      const user = UserEntity(
        id: 'user_12345',
        email: 'coach@jiabamove.tw',
        displayName: '健美大師',
        isGuest: false,
      );

      expect(user.isGuest, isFalse);
      expect(user.email, equals('coach@jiabamove.tw'));
      expect(user.displayName, equals('健美大師'));
    });

    test('Initial AuthState is unauthenticated', () {
      const initialState = AuthState.unauthenticated();

      expect(initialState.isAuthenticated, isFalse);
      expect(initialState.user, isNull);
      expect(initialState.isLoading, isFalse);
    });

    test('UserEntity copyWith correctly updates displayName', () {
      const user = UserEntity(
        id: 'user_999',
        email: 'test@jiaba.tw',
        displayName: '舊暱稱',
        isGuest: false,
      );

      final updated = user.copyWith(displayName: '深蹲狂魔大巨巨');

      expect(updated.displayName, equals('深蹲狂魔大巨巨'));
      expect(updated.id, equals(user.id));
      expect(updated.email, equals(user.email));
      expect(updated.isGuest, equals(user.isGuest));
    });
  });
}
