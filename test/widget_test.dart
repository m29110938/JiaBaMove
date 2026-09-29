// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/core/constants/app_strings.dart';
import 'package:jiaba_move/main.dart';

void main() {
  testWidgets('JiaBaMoveApp launches and shows LoginView', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: JiaBaMoveApp(),
      ),
    );

    // 驗證品牌標題、Apple 登入與訪客入口是否正常呈現在首頁
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text('使用 Apple 帳號登入'), findsOneWidget);
    expect(find.text('先逛逛體驗 (訪客模式)'), findsOneWidget);
  });
}
