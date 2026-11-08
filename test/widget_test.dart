import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/main.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async => null);
  });

  testWidgets('App 啟動後直接進入主畫面，不顯示登入頁', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: JiaBaMoveApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('今日紀錄'), findsWidgets);
    expect(find.text('拍照分析'), findsWidgets);
    expect(find.text('使用 Apple 帳號登入'), findsNothing);
  });
}
