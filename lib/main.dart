import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/main/presentation/views/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: JiaBaMoveApp(),
    ),
  );
}

class JiaBaMoveApp extends StatelessWidget {
  const JiaBaMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'),
        Locale('zh', 'CN'),
        Locale('zh'),
        Locale('en', 'US'),
        Locale('en'),
        Locale('ja', 'JP'),
        Locale('ja'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return const Locale('zh', 'TW');
      },
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            // 在大螢幕 (如桌面網頁版寬度 > 600px) 時，以優雅置中的手機畫布模式展示
            if (constraints.maxWidth > 600) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 460,
                    height: constraints.maxHeight.clamp(600.0, 960.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 36,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(460, constraints.maxHeight.clamp(600.0, 960.0)),
                      ),
                      child: child,
                    ),
                  ),
                ),
              );
            }
            return child;
          },
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}
