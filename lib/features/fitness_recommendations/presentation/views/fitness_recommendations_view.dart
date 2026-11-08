import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../domain/entities/daily_workout_item_entity.dart';
import '../../domain/entities/workout_plan_entity.dart';
import '../controllers/workout_controller.dart';
import '../controllers/rest_timer_controller.dart';
import '../views/create_custom_plan_view.dart';
import '../views/workout_plan_detail_view.dart';
import '../widgets/body_part_guidance_card.dart';
import '../widgets/rest_timer_floating_widget.dart';

/// 健身菜單主頁面 (含今日日期、今日自訂菜單打卡、拖曳排序、卡片編輯、雙模輸入與靈感課表推薦)
class FitnessRecommendationsView extends ConsumerWidget {
  const FitnessRecommendationsView({super.key});

  /// 各部位常見熱門經典運動清單
  static const Map<TargetBodyPart, List<String>> _presetExercisesByBodyPart = {
    TargetBodyPart.chest: ['槓鈴平胸臥推', '啞鈴上斜臥推', '坐姿胸推機', '標準俯臥撐', '雙槓臂屈伸'],
    TargetBodyPart.back: ['高位滑輪下拉', '槓鈴俯身划船', '寬握引體向上', '坐姿滑輪划船', '啞鈴單臂划船'],
    TargetBodyPart.legs: ['槓鈴深蹲', '腿推機 (Leg Press)', '羅馬尼亞硬舉', '保加利亞分腿蹲', '大腿後彎舉機'],
    TargetBodyPart.shouldersAndArms: ['坐姿啞鈴肩推', '啞鈴側平舉', '面拉 (Face Pull)', '三頭肌滑輪下壓', '啞鈴二頭彎舉'],
    TargetBodyPart.core: ['平板支撐 (棒式)', '懸垂舉腿', '地面捲腹', '俄羅斯轉體', '健腹輪推伸'],
    TargetBodyPart.fullBody: ['壺鈴擺盪', '波比跳 (Burpees)', '槓鈴高翻', '戰繩雙甩', '划船機間歇'],
  };

  /// 經典動作對應之開源示範動畫 GIF 資源字典
  static const Map<String, String> _presetExerciseGifs = {
    // 胸部
    '槓鈴平胸臥推': 'assets/exercises/bench_press.gif',
    '啞鈴上斜臥推': 'assets/exercises/incline_press.gif',
    '坐姿胸推機': 'assets/exercises/machine_chest_press.gif',
    '標準俯臥撐': 'assets/exercises/push_up.gif',
    '雙槓臂屈伸': 'assets/exercises/pec_deck_fly.gif',
    // 背部
    '高位滑輪下拉': 'assets/exercises/lat_pulldown.gif',
    '槓鈴俯身划船': 'assets/exercises/bent_over_row.gif',
    '寬握引體向上': 'assets/exercises/pull_up.gif',
    '坐姿滑輪划船': 'assets/exercises/seated_cable_row.gif',
    '啞鈴單臂划船': 'assets/exercises/one_arm_row.gif',
    // 臀腿
    '槓鈴深蹲': 'assets/exercises/barbell_squat.gif',
    '腿推機 (Leg Press)': 'assets/exercises/leg_press.gif',
    '羅馬尼亞硬舉': 'assets/exercises/romanian_deadlift.gif',
    '保加利亞分腿蹲': 'assets/exercises/walking_lunge.gif',
    '大腿後彎舉機': 'assets/exercises/leg_curl.gif',
    // 肩臂
    '坐姿啞鈴肩推': 'assets/exercises/shoulder_press.gif',
    '啞鈴側平舉': 'assets/exercises/lateral_raise.gif',
    '面拉 (Face Pull)': 'assets/exercises/rear_delt_fly.gif',
    '三頭肌滑輪下壓': 'assets/exercises/tricep_pushdown.gif',
    '啞鈴二頭彎舉': 'assets/exercises/bicep_curl.gif',
    // 核心
    '平板支撐 (棒式)': 'assets/exercises/plank.gif',
    '懸垂舉腿': 'assets/exercises/hanging_leg_raise.gif',
    '地面捲腹': 'assets/exercises/crunch.gif',
    '俄羅斯轉體': 'assets/exercises/russian_twist.gif',
    '健腹輪推伸': 'assets/exercises/dead_bug.gif',
    // 全身
    '壺鈴擺盪': 'assets/exercises/kettlebell_swing.gif',
    '波比跳 (Burpees)': 'assets/exercises/burpees.gif',
    '槓鈴高翻': 'assets/exercises/jumping_jacks.gif',
    '戰繩雙甩': 'assets/exercises/mountain_climber.gif',
    '划船機間歇': 'assets/exercises/straight_arm_pulldown.gif',
  };

  /// 格式化中文日期：yyyy 年 M 月 d 日 星期X
  String _formatChineseDate(DateTime date) {
    const weekDays = ['一', '二', '三', '四', '五', '六', '日'];
    final weekDay = weekDays[date.weekday - 1];
    return '${date.year} 年 ${date.month} 月 ${date.day} 日 星期$weekDay';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutControllerProvider);
    final workoutNotifier = ref.read(workoutControllerProvider.notifier);
    final profile = ref.watch(profileControllerProvider).profile;
    final userWeightKg = profile?.weightKg ?? 70.0;
    final filteredPlans = workoutState.filteredPlans;
    final restTimer = ref.watch(restTimerControllerProvider);

    // 監聽休息計時器結束事件，彈出綠色橫幅通知與震動
    ref.listen<RestTimerState>(restTimerControllerProvider, (previous, next) {
      if (previous?.status != RestTimerStatus.finished &&
          next.status == RestTimerStatus.finished) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      next.currentExerciseName != null
                          ? '🔔「${next.currentExerciseName}」組間休息結束！準備下一組！'
                          : '🔔 組間休息結束！準備下一組！',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('健身菜單'),
        centerTitle: false,
        actions: [
          // 組間休息計時器捷徑
          IconButton(
            key: const Key('appbar_rest_timer_btn'),
            icon: Icon(
              restTimer.isActive ? CupertinoIcons.timer_fill : CupertinoIcons.timer,
              size: 22,
              color: restTimer.isActive ? const Color(0xFF0F766E) : null,
            ),
            tooltip: restTimer.isActive ? '檢視休息計時器' : '開啟組間休息計時',
            onPressed: () {
              HapticFeedback.selectionClick();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!restTimer.isVisible) {
                  ref.read(restTimerControllerProvider.notifier).startTimer(60);
                } else if (restTimer.isMinimized) {
                  ref.read(restTimerControllerProvider.notifier).setMinimized(false);
                }
              });
            },
          ),
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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // 1. 最上方今天日期看板 (含今日運動總消耗熱量)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(CupertinoIcons.calendar, size: 16, color: AppTheme.primaryOrange),
                            const SizedBox(width: 8),
                            Text(
                              _formatChineseDate(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            '今日專屬菜單',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '吃飽飽來運動，今日菜單練起來！',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '自由配置訓練項目與組數，汗水換肌肉！',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.bolt_fill, size: 14, color: Color(0xFFFBBF24)),
                            SizedBox(width: 4),
                            Text(
                              '持之以恆',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFBBF24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. 今日菜單標題與操作列
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '今日菜單',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${workoutState.dailyWorkoutItems.length} 項動作',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (workoutState.yesterdayWorkoutItems.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFF0284C7),
                      ),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        await workoutNotifier.copyYesterdayWorkoutItems();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已為您成功載入昨日的 ${workoutState.yesterdayWorkoutItems.length} 項訓練動作！'),
                              backgroundColor: AppTheme.accentGreen,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 14),
                      label: const Text(
                        '沿用昨日菜單',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // 3. 今日菜單項目列表或空狀態 (支援長按整張卡片拖曳排序)
              if (workoutState.dailyWorkoutItems.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF7ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.sportscourt, size: 32, color: AppTheme.primaryOrange),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '今天還沒有安排訓練動作喔！',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '點選下方「＋ 新增今日訓練動作」，安排今天的專屬重訓菜單！',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: workoutState.dailyWorkoutItems.length,
                  onReorderItem: (oldIndex, newIndex) {
                    HapticFeedback.mediumImpact();
                    workoutNotifier.reorderDailyWorkoutItems(oldIndex, newIndex);
                  },
                  itemBuilder: (ctx, index) {
                    final item = workoutState.dailyWorkoutItems[index];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(item.id),
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildDailyWorkoutItemCard(context, ref, item, userWeightKg),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 12),

              // 「＋ 新增今日訓練動作」大按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _showDailyWorkoutItemFormBottomSheet(context, ref, userWeightKg);
                  },
                  icon: const Icon(CupertinoIcons.add_circled_solid, size: 18),
                  label: const Text(
                    '＋ 新增今日訓練動作',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 4. 靈感課表推薦與部位指引區塊 (保留既有完整推薦體系)
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '靈感推薦課表與教練指引',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
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

              // 第一層：型態標籤列 (全部 / 器材機器 / 自由重量 / 居家徒手 / 我的自訂)
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

              // 第二層：部位標籤列 (全部部位 / 胸部 / 背部 / 臀腿 / 肩臂 / 核心 / 全身心肺)
              _buildBodyPartSelector(
                selectedBodyPart: workoutState.selectedBodyPart,
                onSelectBodyPart: (bp) {
                  HapticFeedback.selectionClick();
                  workoutNotifier.setBodyPart(bp);
                },
              ),

              // 部位專屬教練指引卡 (當選擇特定部位時展開)
              if (workoutState.selectedBodyPart != null) ...[
                const SizedBox(height: 12),
                BodyPartGuidanceCard(
                  guidance: WorkoutPlanEntity.bodyPartGuidanceMap[workoutState.selectedBodyPart]!,
                ),
              ],

              const SizedBox(height: 14),

              // 推薦課表清單
              if (filteredPlans.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(CupertinoIcons.search, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        '此分類目前沒有符合的課表',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () {
                          workoutNotifier.setCategory(null);
                          workoutNotifier.setBodyPart(null);
                        },
                        icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 14),
                        label: const Text('重設篩選條件'),
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
                  itemBuilder: (ctx, index) {
                    final plan = filteredPlans[index];
                    return _buildWorkoutPlanCard(context, ref, plan);
                  },
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
            // 底部懸浮組間休息計時面板 / 右下角氣泡 (只有在可見時才掛載到渲染樹，避免零高度 RenderBox 造成 MouseTracker 異常)
            if (restTimer.isVisible)
              Positioned(
                left: restTimer.isMinimized ? null : 0,
                right: restTimer.isMinimized ? 16 : 0,
                bottom: restTimer.isMinimized ? 20 : 0,
                child: const RestTimerFloatingWidget(),
              ),
          ],
        ),
      ),
    );
  }

  /// 建立今日自訂動作卡片 (支援點擊/筆型按鈕編輯，支援長按拖曳移動位置)
  Widget _buildDailyWorkoutItemCard(
    BuildContext context,
    WidgetRef ref,
    DailyWorkoutItemEntity item,
    double userWeightKg,
  ) {
    final notifier = ref.read(workoutControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isCompleted
              ? AppTheme.accentGreen.withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 勾選完成打卡鈕
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final wasCompleted = item.isCompleted;
              notifier.toggleDailyWorkoutItemCompleted(item.id);
              // 若先前為未完成、現在勾選為完成，且開啟自動觸發，排入下一幀自動開啟 60 秒休息計時
              // 透過 addPostFrameCallback 避免在 Pointer/Mouse 處置階段變更渲染樹結構
              if (!wasCompleted) {
                final timerState = ref.read(restTimerControllerProvider);
                if (timerState.autoTriggerOnCheck && !timerState.isRunning) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(restTimerControllerProvider.notifier).startTimer(
                          60,
                          exerciseName: item.exerciseName,
                        );
                  });
                }
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.isCompleted ? AppTheme.accentGreen : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.isCompleted ? AppTheme.accentGreen : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(CupertinoIcons.checkmark, size: 18, color: Colors.white)
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // 動作名稱與規格 (點擊可開啟編輯抽屜)
          Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _showDailyWorkoutItemFormBottomSheet(
                  context,
                  ref,
                  userWeightKg,
                  existingItem: item,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.targetBodyPart.label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.exerciseName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: item.isCompleted ? AppTheme.textMuted : AppTheme.textDark,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.animationAsset != null) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showExerciseAnimationDialog(context, item);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.play_circle_fill, size: 11, color: Color(0xFF2563EB)),
                                SizedBox(width: 3),
                                Text(
                                  '示範動畫',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.weightKg > 0
                            ? '${item.weightKg.toStringAsFixed(item.weightKg.truncateToDouble() == item.weightKg ? 0 : 1)} kg'
                            : '自重徒手',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1))),
                      Text(
                        '${item.reps} 下',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1))),
                      Text(
                        '${item.sets} 組',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 編輯按鈕 (鉛筆圖示)
          IconButton(
            icon: const Icon(CupertinoIcons.pencil, size: 18, color: Color(0xFF0284C7)),
            visualDensity: VisualDensity.compact,
            tooltip: '編輯動作',
            onPressed: () {
              HapticFeedback.selectionClick();
              _showDailyWorkoutItemFormBottomSheet(
                context,
                ref,
                userWeightKg,
                existingItem: item,
              );
            },
          ),

          // 刪除按鈕
          IconButton(
            icon: const Icon(CupertinoIcons.trash, size: 18, color: Color(0xFF94A3B8)),
            visualDensity: VisualDensity.compact,
            tooltip: '刪除動作',
            onPressed: () {
              HapticFeedback.lightImpact();
              notifier.deleteDailyWorkoutItem(item.id);
            },
          ),
        ],
      ),
    );
  }

  /// 彈出動作示範動畫大圖播放視窗 (Dialog)
  void _showExerciseAnimationDialog(
    BuildContext context,
    DailyWorkoutItemEntity item,
  ) {
    if (item.animationAsset == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.targetBodyPart.label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.exerciseName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 24, color: Color(0xFFCBD5E1)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 220,
                    color: const Color(0xFFF8FAFC),
                    child: Image.asset(
                      item.animationAsset!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(CupertinoIcons.sportscourt, size: 48, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.sportscourt, size: 14, color: AppTheme.primaryOrange),
                      const SizedBox(width: 6),
                      Text(
                        '今日安排：${item.weightKg > 0 ? "${item.weightKg.toStringAsFixed(item.weightKg.truncateToDouble() == item.weightKg ? 0 : 1)} kg" : "自重徒手"} • ${item.reps} 下 • ${item.sets} 組',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 彈出「新增或編輯今日訓練動作」底部抽屜 (Modal Bottom Sheet)
  void _showDailyWorkoutItemFormBottomSheet(
    BuildContext context,
    WidgetRef ref,
    double userWeightKg, {
    DailyWorkoutItemEntity? existingItem,
  }) {
    final isEditing = existingItem != null;
    TargetBodyPart selectedBodyPart = existingItem?.targetBodyPart ?? TargetBodyPart.chest;
    String selectedExerciseName = existingItem?.exerciseName ?? _presetExercisesByBodyPart[TargetBodyPart.chest]!.first;
    bool isCustom = existingItem?.isCustom ?? false;
    final weightController = TextEditingController(
      text: existingItem != null
          ? (existingItem.weightKg.truncateToDouble() == existingItem.weightKg
              ? existingItem.weightKg.toInt().toString()
              : existingItem.weightKg.toString())
          : '40',
    );
    final repsController = TextEditingController(
      text: existingItem != null ? '${existingItem.reps}' : '10',
    );
    final setsController = TextEditingController(
      text: existingItem != null ? '${existingItem.sets}' : '4',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double parseWeight() => double.tryParse(weightController.text.trim()) ?? 0.0;
            int parseReps() => int.tryParse(repsController.text.trim()) ?? 10;
            int parseSets() => int.tryParse(setsController.text.trim()) ?? 4;

            final currentWorkoutState = ref.watch(workoutControllerProvider);
            final customList = currentWorkoutState.customExercisesByBodyPart[selectedBodyPart] ?? [];
            final presets = _presetExercisesByBodyPart[selectedBodyPart] ?? [];

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 抓手
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? '編輯訓練動作' : '新增今日訓練動作',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22, color: Color(0xFFCBD5E1)),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 步驟一：選擇訓練部位
                    const Text(
                      '1. 選擇部位',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: TargetBodyPart.values.map((part) {
                          final isSelected = part == selectedBodyPart;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(part.label),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryOrange,
                              backgroundColor: const Color(0xFFF1F5F9),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppTheme.textDark,
                              ),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setModalState(() {
                                  selectedBodyPart = part;
                                  final newPresets = _presetExercisesByBodyPart[part] ?? [];
                                  final newCustoms = currentWorkoutState.customExercisesByBodyPart[part] ?? [];
                                  if (!newPresets.contains(selectedExerciseName) && !newCustoms.contains(selectedExerciseName)) {
                                    if (newPresets.isNotEmpty) {
                                      selectedExerciseName = newPresets.first;
                                      isCustom = false;
                                    }
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 步驟二：選擇或自填動作
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '2. 選擇或自填動作',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                        Text(
                          '${presets.length + customList.length} 個動作可選',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // 1. 內建經典動作
                        ...presets.map((exercise) {
                          final isSelected = !isCustom && selectedExerciseName == exercise;
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                selectedExerciseName = exercise;
                                isCustom = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryOrange : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                exercise,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppTheme.primaryOrange : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        }),

                        // 2. 使用者新增之自訂動作 (帶 ⭐ 與 ✕ 刪除鍵)
                        ...customList.map((exercise) {
                          final isSelected = isCustom && selectedExerciseName == exercise;
                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryOrange : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setModalState(() {
                                      selectedExerciseName = exercise;
                                      isCustom = true;
                                    });
                                  },
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(CupertinoIcons.star_fill, size: 10, color: Color(0xFFF59E0B)),
                                        const SizedBox(width: 4),
                                        Text(
                                          exercise,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? AppTheme.primaryOrange : const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    HapticFeedback.lightImpact();
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dCtx) => AlertDialog(
                                        title: const Text('刪除自訂動作', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                        content: Text('確定要刪除自訂動作「$exercise」嗎？'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(dCtx).pop(false),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(dCtx).pop(true),
                                            child: const Text('確定刪除', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(workoutControllerProvider.notifier).deleteCustomExercise(selectedBodyPart, exercise);
                                      setModalState(() {
                                        if (selectedExerciseName == exercise) {
                                          selectedExerciseName = presets.isNotEmpty ? presets.first : '';
                                          isCustom = false;
                                        }
                                      });
                                    }
                                  },
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                  child: const Padding(
                                    padding: EdgeInsets.fromLTRB(2, 6, 8, 6),
                                    child: Icon(CupertinoIcons.clear_circled_solid, size: 14, color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // 3. ＋ 新增自訂動作 按鈕
                        InkWell(
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            final textCtrl = TextEditingController();
                            final newName = await showDialog<String>(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                title: Text('新增【${selectedBodyPart.label}】自訂動作', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                content: TextField(
                                  controller: textCtrl,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: '例如：阿嬤牌深蹲、單臂啞鈴側舉',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dCtx).pop(),
                                    child: const Text('取消', style: TextStyle(color: Color(0xFF64748B))),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryOrange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      final val = textCtrl.text.trim();
                                      if (val.isNotEmpty) {
                                        Navigator.of(dCtx).pop(val);
                                      }
                                    },
                                    child: const Text('新增並選取', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            );
                            if (newName != null && newName.isNotEmpty) {
                              await ref.read(workoutControllerProvider.notifier).addCustomExercise(selectedBodyPart, newName);
                              setModalState(() {
                                selectedExerciseName = newName;
                                isCustom = true;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFDBA74),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.plus, size: 13, color: AppTheme.primaryOrange),
                                SizedBox(width: 4),
                                Text(
                                  '新增自訂動作',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 示範動畫預覽或自訂動作提示
                    Builder(builder: (_) {
                      final currentGif = isCustom ? null : _presetExerciseGifs[selectedExerciseName];
                      if (!isCustom && currentGif != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    color: Colors.white,
                                    child: Image.asset(
                                      currentGif,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        CupertinoIcons.sportscourt,
                                        size: 20,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '🎬 內建示範動畫',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '加入菜單後，可直接在卡片點擊查看完整動態示範',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(CupertinoIcons.pencil_ellipsis_rectangle, size: 18, color: Color(0xFF64748B)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '✏️ 自訂專屬動作（無示範動畫）',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }),

                    const SizedBox(height: 16),

                    // 步驟三：設定 重量、次數、組數 (支援手打鍵盤直接輸入與 +- 快速微調)
                    const Text(
                      '3. 設定重量與組數 (可直接點擊數字手打，或按 +- 微調)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // 重量 (kg)
                        Expanded(
                          child: _buildNumberAdjuster(
                            label: '重量 (kg)',
                            controller: weightController,
                            suffix: 'kg',
                            isDecimal: true,
                            onMinus: () {
                              final cur = parseWeight();
                              if (cur > 0) {
                                final next = (cur - 2.5).clamp(0.0, 500.0);
                                weightController.text = next.truncateToDouble() == next ? next.toInt().toString() : next.toString();
                                setModalState(() {});
                              }
                            },
                            onPlus: () {
                              final cur = parseWeight();
                              final next = (cur + 2.5).clamp(0.0, 500.0);
                              weightController.text = next.truncateToDouble() == next ? next.toInt().toString() : next.toString();
                              setModalState(() {});
                            },
                            onChanged: (val) {
                              setModalState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 次數 (reps)
                        Expanded(
                          child: _buildNumberAdjuster(
                            label: '每組下數',
                            controller: repsController,
                            suffix: '下',
                            onMinus: () {
                              final cur = parseReps();
                              if (cur > 1) {
                                repsController.text = '${cur - 1}';
                                setModalState(() {});
                              }
                            },
                            onPlus: () {
                              final cur = parseReps();
                              repsController.text = '${cur + 1}';
                              setModalState(() {});
                            },
                            onChanged: (val) {
                              setModalState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 組數 (sets)
                        Expanded(
                          child: _buildNumberAdjuster(
                            label: '訓練組數',
                            controller: setsController,
                            suffix: '組',
                            onMinus: () {
                              final cur = parseSets();
                              if (cur > 1) {
                                setsController.text = '${cur - 1}';
                                setModalState(() {});
                              }
                            },
                            onPlus: () {
                              final cur = parseSets();
                              setsController.text = '${cur + 1}';
                              setModalState(() {});
                            },
                            onChanged: (val) {
                              setModalState(() {});
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 加入/儲存按鈕
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final name = selectedExerciseName.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('請選擇或新增動作名稱！')),
                            );
                            return;
                          }

                          HapticFeedback.mediumImpact();

                          final assignedAnimationAsset = isCustom ? null : _presetExerciseGifs[name];

                          if (isEditing) {
                            final updated = existingItem.copyWith(
                              exerciseName: name,
                              targetBodyPart: selectedBodyPart,
                              weightKg: parseWeight(),
                              reps: parseReps(),
                              sets: parseSets(),
                              estimatedCalories: 0,
                              animationAsset: assignedAnimationAsset,
                              isCustom: isCustom,
                            );
                            await ref.read(workoutControllerProvider.notifier).updateDailyWorkoutItem(updated);
                          } else {
                            final newItem = DailyWorkoutItemEntity(
                              id: 'daily_${DateTime.now().microsecondsSinceEpoch}',
                              dateString: ref.read(workoutControllerProvider).currentDateString,
                              exerciseName: name,
                              targetBodyPart: selectedBodyPart,
                              weightKg: parseWeight(),
                              reps: parseReps(),
                              sets: parseSets(),
                              estimatedCalories: 0,
                              isCompleted: false,
                              animationAsset: assignedAnimationAsset,
                              isCustom: isCustom,
                              createdAt: DateTime.now(),
                            );
                            await ref.read(workoutControllerProvider.notifier).addDailyWorkoutItem(newItem);
                          }

                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                        child: Text(
                          isEditing ? '儲存修改' : '加入今日菜單',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 數值微調器元件 (組數、次數、重量：支援鍵盤手動輸入數字與兩側 +- 快速微調)
  Widget _buildNumberAdjuster({
    required String label,
    required TextEditingController controller,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required ValueChanged<String> onChanged,
    String? suffix,
    bool isDecimal = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              InkWell(
                onTap: onMinus,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Icon(CupertinoIcons.minus, size: 12, color: Color(0xFF334155)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: TextFormField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      border: InputBorder.none,
                      suffixText: suffix,
                      suffixStyle: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                    onChanged: onChanged,
                  ),
                ),
              ),
              InkWell(
                onTap: onPlus,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Icon(CupertinoIcons.plus, size: 12, color: Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 第一層：型態選擇橫向膠囊
  Widget _buildCategorySelector({
    required WorkoutCategory? selectedCategory,
    required bool isCustomOnly,
    required ValueChanged<WorkoutCategory?> onSelectCategory,
    required VoidCallback onSelectCustomOnly,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill(
            label: '全部推薦',
            icon: CupertinoIcons.sparkles,
            isSelected: selectedCategory == null && !isCustomOnly,
            onTap: () => onSelectCategory(null),
          ),
          const SizedBox(width: 8),
          ...WorkoutCategory.values.map((cat) {
            final isSelected = selectedCategory == cat && !isCustomOnly;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildPill(
                label: cat.label,
                icon: cat.icon,
                isSelected: isSelected,
                onTap: () => onSelectCategory(cat),
              ),
            );
          }),
          _buildPill(
            label: '我的自訂',
            icon: CupertinoIcons.person_crop_circle_badge_checkmark,
            isSelected: isCustomOnly,
            onTap: onSelectCustomOnly,
          ),
        ],
      ),
    );
  }

  /// 第二層：部位細分選擇橫向膠囊
  Widget _buildBodyPartSelector({
    required TargetBodyPart? selectedBodyPart,
    required ValueChanged<TargetBodyPart?> onSelectBodyPart,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSmallPill(
            label: '全部部位',
            isSelected: selectedBodyPart == null,
            onTap: () => onSelectBodyPart(null),
          ),
          const SizedBox(width: 6),
          ...TargetBodyPart.values.map((bp) {
            final isSelected = selectedBodyPart == bp;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildSmallPill(
                label: bp.label,
                isSelected: isSelected,
                onTap: () => onSelectBodyPart(bp),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryOrange : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  /// 課表卡片
  Widget _buildWorkoutPlanCard(
    BuildContext context,
    WidgetRef ref,
    WorkoutPlanEntity plan,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => WorkoutPlanDetailView(plan: plan),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(plan.category.icon, size: 12, color: AppTheme.primaryOrange),
                      const SizedBox(width: 4),
                      Text(
                        plan.category.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (plan.targetBodyPart != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      plan.targetBodyPart!.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              plan.title,
              style: const TextStyle(
                fontSize: 16,
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
            const SizedBox(height: 12),
            Row(
              children: [
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
}
