import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../fitness_recommendations/presentation/controllers/workout_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../vision_nutrition/domain/entities/meal_log_entity.dart';
import '../../../vision_nutrition/presentation/controllers/meal_log_controller.dart';
import '../../../vision_nutrition/presentation/widgets/meal_entry_sheet.dart';

/// 今日總覽與飲食打卡首頁
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final profile = ref.watch(profileControllerProvider).profile;
    final workoutState = ref.watch(workoutControllerProvider);
    final targetCalories = profile?.targetCalories ?? 2200;
    final proteinTarget = profile?.proteinGrams ?? 140;
    final carbsTarget = profile?.carbsGrams ?? 250;
    final fatTarget = profile?.fatGrams ?? 65;
    final mealState = ref.watch(mealLogControllerProvider);
    final todayMeals = mealState.todayLogs;
    final consumedCalories = mealState.todayCalories.round();
    final remainingCalories = targetCalories - consumedCalories;
    final isOverTarget = remainingCalories < 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日飲食與訓練'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.bell),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 親切打招呼卡片
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryOrange, Color(0xFFFF9E80)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '呷飽未，${user?.displayName ?? '巨巨'}！',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '今天蛋白質吃夠了嗎？點選下方拍照讓 AI 幫你算熱量！',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.flame_fill,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. 熱量進度卡片
              Text(
                profile != null
                    ? '今日熱量與營養目標 (目標: $targetCalories kcal · ${profile.goal.label})'
                    : '今日熱量與營養目標 (預設: 2,200 kcal)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '已攝取 $consumedCalories kcal',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isOverTarget
                              ? '超過 ${-remainingCalories} kcal'
                              : '還可吃 $remainingCalories kcal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isOverTarget
                                ? AppTheme.errorRed
                                : AppTheme.accentGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (consumedCalories / targetCalories).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverTarget
                              ? AppTheme.errorRed
                              : AppTheme.primaryOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroItem(
                          '蛋白質',
                          mealState.todayProtein,
                          proteinTarget,
                          const Color(0xFF3B82F6),
                        ),
                        _buildMacroItem(
                          '碳水',
                          mealState.todayCarbs,
                          carbsTarget,
                          AppTheme.primaryOrange,
                        ),
                        _buildMacroItem(
                          '脂肪',
                          mealState.todayFat,
                          fatTarget,
                          const Color(0xFFEAB308),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. 今日餐點紀錄清單
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '今日餐點動態',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${todayMeals.length} 餐已紀錄',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        key: const Key('manual_add_meal_button'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryOrange,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: () => _addManually(context, ref),
                        icon: const Icon(CupertinoIcons.plus_circle, size: 18),
                        label: const Text('手動新增'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (todayMeals.isEmpty)
                _buildEmptyMealsHint()
              else
                for (final meal in todayMeals) ...[
                  Dismissible(
                    key: ValueKey(meal.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(CupertinoIcons.trash,
                          color: AppTheme.errorRed),
                    ),
                    onDismissed: (_) {
                      ref
                          .read(mealLogControllerProvider.notifier)
                          .remove(meal.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已刪除「${meal.foodName}」'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: _buildMealTile(
                      onTap: () => _editMeal(context, ref, meal),
                      title: '${meal.mealType.label}：${meal.foodName}',
                      subtitle:
                          '蛋白質 ${meal.protein.round()}g • 碳水 ${meal.carbs.round()}g • 脂肪 ${meal.fat.round()}g',
                      calories: '${meal.calories.round()} kcal',
                      time: _formatTime(meal.loggedAt),
                      icon: _iconFor(meal.mealType),
                      iconColor: _colorFor(meal.mealType),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

              // 4. 今日運動成果卡片 (當有打卡運動時呈現)
              if (workoutState.completedWorkoutIds.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '今日運動成就',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      '已打卡 ${workoutState.completedWorkoutIds.length} 套課表',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.flame_fill,
                          color: Color(0xFFF97316),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '持續累積力量與肌力！',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '今日已順利完成訓練打卡，持之以恆最有力！',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addManually(BuildContext context, WidgetRef ref) async {
    final result = await showMealEntrySheet(context);
    if (result == null) return;
    final notifier = ref.read(mealLogControllerProvider.notifier);
    if (result.saveAsFavorite) await notifier.addFavorite(result.draft);
    await notifier.addDraft(result.draft);
  }

  Future<void> _editMeal(
      BuildContext context, WidgetRef ref, MealLogEntity meal) async {
    final result = await showMealEntrySheet(
      context,
      initial: MealDraft.fromLog(meal),
      title: '修改餐點',
      submitLabel: '儲存修改',
      showFavorites: false,
    );
    if (result == null) return;
    final notifier = ref.read(mealLogControllerProvider.notifier);
    if (result.saveAsFavorite) await notifier.addFavorite(result.draft);
    await notifier.update(meal.id, result.draft);
  }

  Widget _buildEmptyMealsHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(CupertinoIcons.camera, color: AppTheme.textMuted, size: 26),
          SizedBox(height: 8),
          Text(
            '今天還沒有紀錄任何一餐',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '到「拍照分析」拍下餐點，或按右上「手動新增」',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $period';
  }

  static IconData _iconFor(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return CupertinoIcons.sunrise_fill;
      case MealType.lunch:
        return CupertinoIcons.sun_max_fill;
      case MealType.afternoonSnack:
        return CupertinoIcons.drop_fill;
      case MealType.dinner:
        return CupertinoIcons.moon_fill;
      case MealType.lateNight:
        return CupertinoIcons.moon_stars_fill;
    }
  }

  static Color _colorFor(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return const Color(0xFFF59E0B);
      case MealType.lunch:
        return AppTheme.primaryOrange;
      case MealType.afternoonSnack:
        return const Color(0xFF3B82F6);
      case MealType.dinner:
        return const Color(0xFF8B5CF6);
      case MealType.lateNight:
        return const Color(0xFF475569);
    }
  }

  Widget _buildMacroItem(
      String label, double current, num target, Color color) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            text: '${current.round()}g',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
            children: [
              TextSpan(
                text: '/ ${target.round()}g',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealTile({
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required String calories,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                calories,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
