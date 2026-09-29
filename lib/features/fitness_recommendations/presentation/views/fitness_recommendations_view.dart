import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/workout_controller.dart';
import '../views/workout_plan_detail_view.dart';
import '../views/create_custom_plan_view.dart';
import '../widgets/body_part_guidance_card.dart';
import '../../domain/entities/workout_plan_entity.dart';

/// 健身建議主頁面 (Otterlife 柔和簡約現代風格)
class FitnessRecommendationsView extends ConsumerWidget {
  const FitnessRecommendationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutControllerProvider);
    final workoutNotifier = ref.read(workoutControllerProvider.notifier);
    final profile = ref.watch(profileControllerProvider).profile;
    final userGoal = profile?.goal;

    final filteredPlans = workoutState.filteredPlans;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('健身建議'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add, size: 22),
            tooltip: '自訂健身計劃',
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const CreateCustomPlanView(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 頂部 Otterlife 風格柔和溫暖推薦看板
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '今日專屬推薦',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (userGoal != null)
                          Text(
                            '目標：${userGoal.label}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC2410C),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '吃飽飽來運動，身心更有勁！',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userGoal != null
                          ? '依據您的個人身形與代謝目標，為您推薦最適合的訓練模式。'
                          : '不論是健身房器械、自由重量或客廳徒手，今天就動起來吧！',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF78350F),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // 打卡累計狀態
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.flame_fill, size: 14, color: AppTheme.primaryOrange),
                          const SizedBox(width: 6),
                          Text(
                            '今日已打卡 ${workoutState.completedWorkoutIds.length} 套課表 • 燃燒 ${workoutState.totalCaloriesBurned} kcal',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. 第一層：訓練型態標籤列 (全部 / 器材機器 / 自由重量 / 居家徒手 / 我的自訂)
              _buildCategorySelector(
                selectedCategory: workoutState.selectedCategory,
                isCustomOnly: workoutState.isCustomOnly,
                onSelectCategory: (cat) {
                  HapticFeedback.selectionClick();
                  workoutNotifier.setCategory(cat);
                },
                onSelectCustomOnly: () {
                  HapticFeedback.selectionClick();
                  workoutNotifier.setCustomFilter(true);
                },
              ),

              const SizedBox(height: 10),

              // 3. 第二層：訓練部位標籤列 (全部部位 / 胸部 / 背部 / 臀腿 / 肩臂 / 核心 / 全身心肺)
              _buildBodyPartSelector(
                selectedBodyPart: workoutState.selectedBodyPart,
                onSelectBodyPart: (bp) {
                  HapticFeedback.selectionClick();
                  workoutNotifier.setBodyPart(bp);
                },
              ),

              // 4. 部位專屬教練指引卡 (當使用者選擇特定部位時展開)
              if (workoutState.selectedBodyPart != null) ...[
                const SizedBox(height: 12),
                BodyPartGuidanceCard(
                  guidance: WorkoutPlanEntity.bodyPartGuidanceMap[workoutState.selectedBodyPart]!,
                ),
              ],

              const SizedBox(height: 16),

              // 5. 課表卡片清單標題
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _buildHeaderTitle(workoutState),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Text(
                    '${filteredPlans.length} 個訓練方案',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. 清單或無課表空狀態
              if (filteredPlans.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.bookmark, size: 28, color: Color(0xFF0D9488)),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '尚未建立任何自訂課表',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '您可以挑選喜愛的動作，自由配置專屬訓練課表！',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => const CreateCustomPlanView(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(CupertinoIcons.add, size: 16),
                        label: const Text(
                          '建立自訂課表',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredPlans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final plan = filteredPlans[index];
                    final isCompleted = workoutState.isCompleted(plan.id);
                    final isRecommendedForUser =
                        userGoal != null && plan.targetGoals.contains(userGoal);

                    return _buildWorkoutPlanCard(
                      context,
                      ref: ref,
                      plan: plan,
                      isCompleted: isCompleted,
                      isRecommended: isRecommendedForUser,
                    );
                  },
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 現代 iOS 膠囊分段標籤列 (支援「我的自訂」標籤)
  Widget _buildCategorySelector({
    required WorkoutCategory? selectedCategory,
    required bool isCustomOnly,
    required ValueChanged<WorkoutCategory?> onSelectCategory,
    required VoidCallback onSelectCustomOnly,
  }) {
    final categories = <WorkoutCategory?>[
      null, // 全部
      WorkoutCategory.machines,
      WorkoutCategory.freeWeights,
      WorkoutCategory.homeWorkout,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ...categories.map((cat) {
              final isSelected = !isCustomOnly && cat == selectedCategory;
              final label = cat == null ? '全部推薦' : cat.label;
              final icon = cat == null ? CupertinoIcons.sparkles : cat.icon;

              return GestureDetector(
                onTap: () => onSelectCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: isSelected ? AppTheme.primaryOrange : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.textDark : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // 「我的自訂」專屬膠囊標籤
            GestureDetector(
              onTap: onSelectCustomOnly,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isCustomOnly ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isCustomOnly
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.bookmark_fill,
                      size: 14,
                      color: isCustomOnly ? const Color(0xFF0D9488) : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '我的自訂',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCustomOnly ? FontWeight.w700 : FontWeight.w500,
                        color: isCustomOnly ? AppTheme.textDark : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 標題文字依據型態與部位智慧組裝
  String _buildHeaderTitle(WorkoutState state) {
    if (state.isCustomOnly) {
      if (state.selectedBodyPart != null) {
        return '我的自訂 • ${state.selectedBodyPart!.label}課表';
      }
      return '我的自訂課表';
    }
    final catLabel = state.selectedCategory == null ? '精選課表' : state.selectedCategory!.label;
    if (state.selectedBodyPart != null) {
      return '$catLabel • ${state.selectedBodyPart!.label}訓練';
    }
    return state.selectedCategory == null ? '全部精選課表' : state.selectedCategory!.label;
  }

  /// 第二層：訓練部位膠囊標籤列
  Widget _buildBodyPartSelector({
    required TargetBodyPart? selectedBodyPart,
    required ValueChanged<TargetBodyPart?> onSelectBodyPart,
  }) {
    final bodyParts = <TargetBodyPart?>[
      null, // 全部部位
      TargetBodyPart.chest,
      TargetBodyPart.back,
      TargetBodyPart.legs,
      TargetBodyPart.shouldersAndArms,
      TargetBodyPart.core,
      TargetBodyPart.fullBody,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: bodyParts.map((bp) {
          final isSelected = bp == selectedBodyPart;
          final label = bp == null ? '全部部位' : bp.label;
          final icon = bp == null ? CupertinoIcons.square_grid_2x2_fill : bp.icon;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelectBodyPart(bp),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 單一課表展示卡片 (支援自訂課表徽章與管理選單)
  Widget _buildWorkoutPlanCard(
    BuildContext context, {
    required WidgetRef ref,
    required WorkoutPlanEntity plan,
    required bool isCompleted,
    required bool isRecommended,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => WorkoutPlanDetailView(plan: plan),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRecommended
                ? AppTheme.primaryOrange.withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
            width: isRecommended ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頂部標籤列
            Row(
              children: [
                // 分類標籤
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: plan.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    plan.category.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: plan.accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 強度標籤
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    plan.difficulty.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),

                // 自訂課表專屬徽章
                if (plan.isCustom) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.bookmark_fill, size: 10, color: Color(0xFF0D9488)),
                        SizedBox(width: 3),
                        Text(
                          '自訂',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (isRecommended && !plan.isCustom) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.star_fill, size: 10, color: AppTheme.primaryOrange),
                        SizedBox(width: 3),
                        Text(
                          '目標首選',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // 已打卡狀態或自訂課表更多選單
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.checkmark_alt, size: 12, color: AppTheme.accentGreen),
                        SizedBox(width: 4),
                        Text(
                          '已完成',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (plan.isCustom)
                  PopupMenuButton<String>(
                    icon: const Icon(CupertinoIcons.ellipsis, size: 18, color: AppTheme.textMuted),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => CreateCustomPlanView(initialPlan: plan),
                          ),
                        );
                      } else if (value == 'delete') {
                        _confirmDeletePlan(context, ref, plan);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.pencil, size: 16, color: AppTheme.textDark),
                            SizedBox(width: 8),
                            Text('編輯課表', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.trash, size: 16, color: AppTheme.errorRed),
                            SizedBox(width: 8),
                            Text('刪除課表', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.errorRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              plan.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            // 底部指標與肌群
            Row(
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.flame_fill, size: 14, color: Color(0xFFF97316)),
                    const SizedBox(width: 4),
                    Text(
                      '${plan.estimatedCalories} kcal',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Row(
                  children: [
                    const Icon(CupertinoIcons.stopwatch, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      '${plan.durationMinutes} 分鐘',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Row(
                  children: [
                    const Icon(CupertinoIcons.list_bullet, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      '${plan.exercises.length} 項動作',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 刪除自訂課表確認對話框
  void _confirmDeletePlan(BuildContext context, WidgetRef ref, WorkoutPlanEntity plan) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '刪除自訂課表',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          content: Text(
            '確定要刪除「${plan.title}」嗎？此操作無法還原。',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await ref.read(workoutControllerProvider.notifier).deleteCustomPlan(plan.id);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('確定刪除', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }
}
