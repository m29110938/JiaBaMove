import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../fitness_recommendations/presentation/views/fitness_recommendations_view.dart';
import '../../../home/presentation/views/home_view.dart';
import '../../../profile/presentation/views/profile_view.dart';
import '../../../vision_nutrition/presentation/views/nutrition_camera_view.dart';

/// 主應用四標籤頁導航外框
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeView(),
    FitnessRecommendationsView(),
    NutritionCameraView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryOrange,
          unselectedItemColor: AppTheme.textMuted,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house),
              activeIcon: Icon(CupertinoIcons.house_fill),
              label: '今日紀錄',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.flame),
              activeIcon: Icon(CupertinoIcons.flame_fill),
              label: '健身菜單',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.camera),
              activeIcon: Icon(CupertinoIcons.camera_fill),
              label: '拍照分析',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              activeIcon: Icon(CupertinoIcons.person_fill),
              label: '會員中心',
            ),
          ],
        ),
      ),
    );
  }
}
