import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/entities/user_profile_entity.dart';
import '../../domain/entities/workout_plan_entity.dart';
import '../controllers/workout_controller.dart';
import '../widgets/exercise_animation_viewer.dart';

/// 自訂健身課表建立與編輯頁面 (Otterlife 柔和簡約現代風格)
class CreateCustomPlanView extends ConsumerStatefulWidget {
  const CreateCustomPlanView({
    super.key,
    this.initialPlan,
  });

  /// 若有傳入 initialPlan 則為編輯模式，否則為新建模式
  final WorkoutPlanEntity? initialPlan;

  @override
  ConsumerState<CreateCustomPlanView> createState() => _CreateCustomPlanViewState();
}

class _CreateCustomPlanViewState extends ConsumerState<CreateCustomPlanView> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;

  late WorkoutCategory _selectedCategory;
  late TargetBodyPart _selectedBodyPart;
  late WorkoutDifficulty _selectedDifficulty;
  late int _durationMinutes;
  late int _estimatedCalories;
  late List<WorkoutExercise> _exercises;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final plan = widget.initialPlan;
    _titleController = TextEditingController(text: plan?.title ?? '');
    _subtitleController = TextEditingController(text: plan?.subtitle ?? '');
    _selectedCategory = plan?.category ?? WorkoutCategory.homeWorkout;
    _selectedBodyPart = plan?.targetBodyPart ?? TargetBodyPart.chest;
    _selectedDifficulty = plan?.difficulty ?? WorkoutDifficulty.beginner;
    _durationMinutes = plan?.durationMinutes ?? 30;
    _estimatedCalories = plan?.estimatedCalories ?? 220;
    _exercises = plan != null ? List<WorkoutExercise>.from(plan.exercises) : [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _savePlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_exercises.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('請至少為課表加入一項運動動作！'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    // 收集涵蓋肌群標籤
    final muscles = _exercises.map((e) => e.targetMuscle.split('、').first).toSet().toList();
    if (muscles.isEmpty) {
      muscles.add('全身肌群');
    }

    final newPlan = WorkoutPlanEntity(
      id: widget.initialPlan?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim().isNotEmpty
          ? _subtitleController.text.trim()
          : '個人專屬自訂日常訓練課表',
      category: _selectedCategory,
      targetBodyPart: _selectedBodyPart,
      targetGoals: [FitnessGoal.maintain, FitnessGoal.fatLoss, FitnessGoal.muscleGain],
      durationMinutes: _durationMinutes,
      estimatedCalories: _estimatedCalories,
      difficulty: _selectedDifficulty,
      muscleGroups: muscles,
      exercises: _exercises,
      accentColorHex: widget.initialPlan?.accentColorHex ?? 0xFF0D9488, // 質感青綠
      isCustom: true,
    );

    final notifier = ref.read(workoutControllerProvider.notifier);
    if (widget.initialPlan != null) {
      await notifier.updateCustomPlan(newPlan);
    } else {
      await notifier.addCustomPlan(newPlan);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.initialPlan != null ? '自訂課表已更新！' : '自訂課表建立成功！'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialPlan != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEditing ? '編輯自訂課表' : '建立自訂課表'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _savePlan,
              child: const Text(
                '儲存',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // 1. 課表基本資料設定卡片
              _buildSectionTitle('課表基本資料'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 課表名稱
                    const Text(
                      '課表名稱 *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: '例如：週三晨間核心與燃脂',
                        hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return '請輸入課表名稱';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // 課表簡介 / 備註
                    const Text(
                      '課表簡介 (選填)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _subtitleController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: '例如：喚醒早晨活力，搭配組間深呼吸',
                        hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 訓練類型膠囊選擇
                    const Text(
                      '訓練類型',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: WorkoutCategory.values.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = cat);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryOrange.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryOrange : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    cat.icon,
                                    size: 16,
                                    color: isSelected ? AppTheme.primaryOrange : AppTheme.textMuted,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? AppTheme.primaryOrange : AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // 主要訓練部位選擇
                    const Text(
                      '主要訓練部位',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: TargetBodyPart.values.map((bp) {
                          final isSelected = bp == _selectedBodyPart;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedBodyPart = bp);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      bp.icon,
                                      size: 14,
                                      color: isSelected ? Colors.white : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      bp.label,
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
                    ),

                    const SizedBox(height: 16),

                    // 難度選擇
                    const Text(
                      '訓練強度',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: WorkoutDifficulty.values.map((diff) {
                        final isSelected = diff == _selectedDifficulty;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedDifficulty = diff);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0F766E).withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                diff.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF0F766E) : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // 預估時間與預估熱量
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricStepper(
                            label: '預估時長',
                            value: '$_durationMinutes 分鐘',
                            onDecrement: () {
                              if (_durationMinutes > 5) {
                                setState(() => _durationMinutes -= 5);
                              }
                            },
                            onIncrement: () {
                              if (_durationMinutes < 120) {
                                setState(() => _durationMinutes += 5);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricStepper(
                            label: '預估燃燒',
                            value: '$_estimatedCalories kcal',
                            onDecrement: () {
                              if (_estimatedCalories > 50) {
                                setState(() => _estimatedCalories -= 25);
                              }
                            },
                            onIncrement: () {
                              if (_estimatedCalories < 1000) {
                                setState(() => _estimatedCalories += 25);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. 動作清單組裝區
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('訓練動作清單 (${_exercises.length})'),
                  if (_exercises.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _exercises.clear());
                      },
                      icon: const Icon(CupertinoIcons.trash, size: 14, color: AppTheme.errorRed),
                      label: const Text(
                        '清空',
                        style: TextStyle(fontSize: 12, color: AppTheme.errorRed, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (_exercises.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.sportscourt, size: 26, color: AppTheme.primaryOrange),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '尚未加入任何訓練動作',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '點擊下方按鈕從動作庫挑選，或手動自訂動作！',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _exercises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ex = _exercises[index];
                    return _buildSelectedExerciseCard(index, ex);
                  },
                ),

              const SizedBox(height: 16),

              // 3. 新增動作按鈕列 (從動作庫選取 / 手動自訂動作)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openExerciseLibrarySheet,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(CupertinoIcons.sparkles, size: 18, color: AppTheme.primaryOrange),
                      label: const Text(
                        '從動作庫挑選',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryOrange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openCustomExerciseDialog,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(CupertinoIcons.add_circled, size: 18, color: Color(0xFF0F766E)),
                      label: const Text(
                        '+ 自訂新動作',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 4. 底部儲存大按鈕
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _savePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    isEditing ? '儲存課表修改' : '立即建立課表',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildMetricStepper({
    required String label,
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDecrement();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(CupertinoIcons.minus, size: 14, color: AppTheme.textDark),
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onIncrement();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(CupertinoIcons.plus, size: 14, color: AppTheme.textDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 已選動作卡片 (支援調整組數、次數與刪除)
  Widget _buildSelectedExerciseCard(int index, WorkoutExercise ex) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ex.targetMuscle} • ${ex.equipment}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.trash, size: 18, color: Color(0xFF94A3B8)),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _exercises.removeAt(index));
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Lottie 動作動畫縮圖展示區 (點擊可放大)
          ExerciseAnimationViewer(
            exercise: ex,
            height: 90,
            enableEnlargeModal: true,
          ),

          const SizedBox(height: 12),

          // 組數 / 次數 / 休息 微調設定列
          Row(
            children: [
              // 組數微調
              Expanded(
                child: _buildInlineTuner(
                  label: '組數',
                  value: '${ex.sets} 組',
                  onMinus: () {
                    if (ex.sets > 1) {
                      setState(() {
                        _exercises[index] = ex.copyWith(sets: ex.sets - 1);
                      });
                    }
                  },
                  onPlus: () {
                    if (ex.sets < 10) {
                      setState(() {
                        _exercises[index] = ex.copyWith(sets: ex.sets + 1);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // 休息秒數微調
              Expanded(
                child: _buildInlineTuner(
                  label: '休息',
                  value: '${ex.restSeconds} 秒',
                  onMinus: () {
                    if (ex.restSeconds > 15) {
                      setState(() {
                        _exercises[index] = ex.copyWith(restSeconds: ex.restSeconds - 15);
                      });
                    }
                  },
                  onPlus: () {
                    if (ex.restSeconds < 180) {
                      setState(() {
                        _exercises[index] = ex.copyWith(restSeconds: ex.restSeconds + 15);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineTuner({
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onMinus();
                },
                child: const Icon(CupertinoIcons.minus_circle, size: 16, color: AppTheme.textMuted),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onPlus();
                },
                child: const Icon(CupertinoIcons.plus_circle, size: 16, color: AppTheme.primaryOrange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 打開動作庫選取工作表 (Categorized Bottom Sheet)
  void _openExerciseLibrarySheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ExerciseLibraryBottomSheet(
          alreadyAddedNames: _exercises.map((e) => e.name).toSet(),
          onSelectExercise: (ex) {
            setState(() => _exercises.add(ex));
          },
          onRemoveExercise: (exName) {
            setState(() => _exercises.removeWhere((e) => e.name == exName));
          },
        );
      },
    );
  }

  /// 打開手動自訂新動作彈窗
  void _openCustomExerciseDialog() {
    final nameCtrl = TextEditingController();
    final muscleCtrl = TextEditingController();
    final equipCtrl = TextEditingController(text: '徒手 / 自備器材');
    int sets = 3;
    String reps = '12 次';
    int rest = 45;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                '新增自訂動作',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: '動作名稱 *',
                        hintText: '如：阻力帶深蹲、引體向上',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: muscleCtrl,
                      decoration: const InputDecoration(
                        labelText: '目標肌群 *',
                        hintText: '如：臀部、下背、肩膀',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: equipCtrl,
                      decoration: const InputDecoration(
                        labelText: '所需器材',
                        hintText: '如：啞鈴、瑜珈墊、單槓',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('預設組數', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(CupertinoIcons.minus_circle, size: 20),
                              onPressed: () {
                                if (sets > 1) {
                                  setDialogState(() => sets--);
                                }
                              },
                            ),
                            Text('$sets 組', style: const TextStyle(fontWeight: FontWeight.w700)),
                            IconButton(
                              icon: const Icon(CupertinoIcons.plus_circle, size: 20, color: AppTheme.primaryOrange),
                              onPressed: () {
                                if (sets < 10) {
                                  setDialogState(() => sets++);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('取消', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final muscle = muscleCtrl.text.trim();
                    if (name.isEmpty) {
                      return;
                    }
                    final newEx = WorkoutExercise(
                      name: name,
                      targetMuscle: muscle.isNotEmpty ? muscle : '全身肌群',
                      sets: sets,
                      reps: reps,
                      restSeconds: rest,
                      tips: '自訂動作，請專注感受目標肌群發力並維持穩定呼吸節奏。',
                      equipment: equipCtrl.text.trim().isNotEmpty ? equipCtrl.text.trim() : '徒手',
                      animationAsset: 'assets/animations/workout_general.json',
                    );
                    setState(() => _exercises.add(newEx));
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('加入課表', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 動作庫挑選底部彈出抽屜 (Bottom Sheet)
class _ExerciseLibraryBottomSheet extends StatefulWidget {
  const _ExerciseLibraryBottomSheet({
    required this.alreadyAddedNames,
    required this.onSelectExercise,
    required this.onRemoveExercise,
  });

  final Set<String> alreadyAddedNames;
  final ValueChanged<WorkoutExercise> onSelectExercise;
  final ValueChanged<String> onRemoveExercise;

  @override
  State<_ExerciseLibraryBottomSheet> createState() => _ExerciseLibraryBottomSheetState();
}

class _ExerciseLibraryBottomSheetState extends State<_ExerciseLibraryBottomSheet> {
  String _selectedCategoryKey = '胸部肌群';
  late final Set<String> _currentAdded;

  @override
  void initState() {
    super.initState();
    _currentAdded = Set<String>.from(widget.alreadyAddedNames);
  }

  @override
  Widget build(BuildContext context) {
    final categories = WorkoutPlanEntity.categorizedExerciseLibrary.keys.toList();
    final currentExercises = WorkoutPlanEntity.categorizedExerciseLibrary[_selectedCategoryKey] ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // 頂部把手條
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '精選動作資料庫',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '內建動作皆附帶開源示範動畫',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '完成',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryOrange),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 肌群分類滾動標籤列
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.map((catKey) {
                final isSelected = catKey == _selectedCategoryKey;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategoryKey = catKey);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryOrange : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryOrange : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      catKey,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // 該分類下的動作列表
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              itemCount: currentExercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ex = currentExercises[index];
                final isAdded = _currentAdded.contains(ex.name);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // 動畫小縮圖
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ExerciseAnimationViewer(
                          exercise: ex,
                          height: 50,
                          enableEnlargeModal: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ex.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${ex.targetMuscle} • ${ex.equipment}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      // 加入 / 已加入 按鈕
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (isAdded) {
                              _currentAdded.remove(ex.name);
                              widget.onRemoveExercise(ex.name);
                            } else {
                              _currentAdded.add(ex.name);
                              widget.onSelectExercise(ex);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isAdded ? const Color(0xFFF1F5F9) : AppTheme.primaryOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAdded ? CupertinoIcons.checkmark_alt : CupertinoIcons.add,
                                size: 14,
                                color: isAdded ? AppTheme.accentGreen : Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAdded ? '已加入' : '加入',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isAdded ? AppTheme.accentGreen : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
