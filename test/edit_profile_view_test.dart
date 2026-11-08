import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/core/theme/app_theme.dart';
import 'package:jiaba_move/features/auth/domain/entities/user_entity.dart';
import 'package:jiaba_move/features/auth/presentation/controllers/auth_controller.dart';
import 'package:jiaba_move/features/profile/presentation/views/edit_profile_view.dart';
import 'package:jiaba_move/features/profile/presentation/views/profile_view.dart';

void main() {
  group('EditProfileView & ProfileView Refinement Tests (CI/CD-First)', () {
    testWidgets(
        'ProfileView displays "修改會員資料" and does not display removed Keychain or duplicate body data tiles',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => AuthNotifierMock(
                const AuthState.authenticated(
                  UserEntity(
                    id: 'test_user',
                    email: 'test@jiabamove.tw',
                    displayName: '教練小王',
                    isGuest: false,
                  ),
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify "修改會員資料" exists
      expect(find.text('修改會員資料'), findsOneWidget);
      expect(find.text('編輯稱呼、帳號與個人檔案'), findsOneWidget);

      // Verify removed tiles are NOT present
      expect(find.text('iOS Keychain 資安防護說明'), findsNothing);
      expect(find.text('身體數據與代謝目標'), findsNothing);

      // 不再有登出，改為清除本機資料
      expect(find.text('登出帳號'), findsNothing);
      expect(find.text('清除本機所有資料'), findsOneWidget);
    });

    testWidgets(
        'EditProfileView renders user info and updates display name successfully',
        (tester) async {
      final mockAuth = AuthNotifierMock(
        const AuthState.authenticated(
          UserEntity(
            id: 'test_user_2',
            email: 'dee@jiabamove.tw',
            displayName: 'Dee',
            isGuest: false,
          ),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => mockAuth),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const EditProfileView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check fields exist
      expect(find.text('修改會員資料'), findsOneWidget);
      expect(find.text('僅此裝置 (iOS Keychain)'), findsOneWidget);

      // Find TextFormField and enter new name
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, '超神健美Dee');
      await tester.pumpAndSettle();

      // Tap 儲存
      await tester.tap(find.text('儲存'));
      await tester.pumpAndSettle();

      // Verify updated display name
      expect(mockAuth.updatedName, equals('超神健美Dee'));
    });
  });
}

class AuthNotifierMock extends AuthNotifier {
  AuthNotifierMock(AuthState initialState) {
    state = initialState;
  }

  String? updatedName;

  @override
  Future<void> updateDisplayName(String newName) async {
    updatedName = newName;
    if (state.user != null) {
      state = state.copyWith(user: state.user!.copyWith(displayName: newName));
    }
  }
}
