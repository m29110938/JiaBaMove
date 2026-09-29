import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../controllers/profile_controller.dart';
import '../widgets/ruler_picker_widget.dart';

/// 身高與體重單位
enum HeightUnit { cm, inch }
enum WeightUnit { kg, lb }

/// 全螢幕分步沉浸式純動畫設定流程
class ProfileSetupFlowView extends ConsumerStatefulWidget {
  const ProfileSetupFlowView({super.key});

  @override
  ConsumerState<ProfileSetupFlowView> createState() =>
      _ProfileSetupFlowViewState();
}

class _ProfileSetupFlowViewState extends ConsumerState<ProfileSetupFlowView>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 暫存的表單數據 (全部免打字，由動畫與滾輪驅動)
  BiologicalSex _selectedSex = BiologicalSex.male;
  DateTime _selectedBirthDate = DateTime(2000, 1, 1);
  double _selectedHeight = 170.0;
  double _selectedWeight = 65.0;
  HeightUnit _heightUnit = HeightUnit.cm;
  WeightUnit _weightUnit = WeightUnit.kg;
  ActivityLevel _selectedActivity = ActivityLevel.moderate;
  FitnessGoal _selectedGoal = FitnessGoal.maintain;

  // 結算畫面 Count-up 動畫控制
  late final AnimationController _countUpController;
  late final Animation<double> _countUpAnimation;
  UserProfileEntity? _calculatedResult;

  // BMI 即時反應監聽器 (避免滑動體重時觸發全頁面 setState 重建)
  late final ValueNotifier<double> _weightNotifier;

  @override
  void initState() {
    super.initState();
    _countUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _countUpAnimation = CurvedAnimation(
      parent: _countUpController,
      curve: Curves.easeOutCubic,
    );

    // 若先前已有資料，預先載入作為初始值
    final existing = ref.read(profileControllerProvider).profile;
    if (existing != null) {
      _selectedSex = existing.biologicalSex;
      _selectedBirthDate = existing.birthDate;
      _selectedHeight = existing.heightCm;
      _selectedWeight = existing.weightKg;
      _selectedActivity = existing.activityLevel;
      _selectedGoal = existing.goal;
    }

    _weightNotifier = ValueNotifier<double>(_selectedWeight);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _countUpController.dispose();
    _weightNotifier.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 5) {
      if (_currentPage == 4) {
        // 從第 5 步進到第 6 步 (結算) 時，觸發計算與數字飛入動畫
        _triggerCalculation();
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // 完成結算，關閉視窗
      Navigator.of(context).pop();
    }
  }

  void _prevPage() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _triggerCalculation() async {
    final result = await ref
        .read(profileControllerProvider.notifier)
        .saveAndCalculateProfile(
          biologicalSex: _selectedSex,
          birthDate: _selectedBirthDate,
          heightCm: _selectedHeight,
          weightKg: _selectedWeight,
          activityLevel: _selectedActivity,
          goal: _selectedGoal,
        );

    setState(() {
      _calculatedResult = result;
    });

    _countUpController.reset();
    _countUpController.forward();
  }

  @override
  Widget build(BuildContext context) {
    const totalSteps = 6;
    final progress = (_currentPage + 1) / totalSteps;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 頂部導航與進度條
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.chevron_back, size: 24),
                    color: AppTheme.textDark,
                    onPressed: _prevPage,
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        tween: Tween<double>(begin: 0, end: progress),
                        builder: (context, val, _) {
                          return LinearProgressIndicator(
                            value: val,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryOrange,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentPage + 1}/$totalSteps',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // 分步主內容區
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // 透過按鈕與動畫前進
                onPageChanged: (idx) {
                  setState(() => _currentPage = idx);
                },
                children: [
                  _buildSexStep(),
                  _buildBirthDateStep(),
                  _buildHeightStep(),
                  _buildWeightStep(),
                  _buildActivityAndGoalStep(),
                  _buildResultStep(),
                ],
              ),
            ),

            // 底部前進按鈕
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppTheme.primaryOrange.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == 5 ? '完成設定並開始體驗' : '下一步',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: 生理性別 ---
  Widget _buildSexStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '請問您的生理性別？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.heart_fill, size: 16, color: Color(0xFFEC4899)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '呷飽來動尊重每位夥伴的多元認同！此項資料純粹依據醫學營養學推算基礎代謝率，絕不對外公開。',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: BiologicalSex.values.map((sex) {
                final isSelected = _selectedSex == sex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSex = sex);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryOrange : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sex.label,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? AppTheme.primaryOrange : AppTheme.textDark,
                                  ),
                                ),
                                if (sex == BiologicalSex.undisclosed)
                                  const Text(
                                    '採用醫學平衡中性常數推算，兼顧隱私與客觀性',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              color: AppTheme.primaryOrange,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: 出生年月日 ---
  Widget _buildBirthDateStep() {
    final calculatedAge = DateTime.now().year - _selectedBirthDate.year;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '您的出生年月日？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '年齡會直接影響人體代謝速率，讓我們為您估算最合適的熱量預算。',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '目前約 $calculatedAge 歲',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedBirthDate,
                  minimumDate: DateTime(1930),
                  maximumDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                  onDateTimeChanged: (date) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedBirthDate = date);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 現代簡約 iOS 膠囊分段標籤元件
  Widget _buildUnitToggle<T>({
    required T current,
    required Map<T, String> options,
    required ValueChanged<T> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.entries.map((entry) {
          final isSelected = entry.key == current;
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                HapticFeedback.selectionClick();
                onSelected(entry.key);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryOrange : AppTheme.textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Step 3: 身高刻度尺 (支援 cm / in 單位切換) ---
  Widget _buildHeightStep() {
    final double displayHeight;
    final double minHeight;
    final double maxHeight;
    final String unitStr;

    if (_heightUnit == HeightUnit.cm) {
      displayHeight = _selectedHeight;
      minHeight = 120.0;
      maxHeight = 230.0;
      unitStr = 'cm';
    } else {
      displayHeight = double.parse((_selectedHeight / 2.54).toStringAsFixed(1));
      minHeight = 48.0;
      maxHeight = 90.0;
      unitStr = 'in';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '您的身高是多少？',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              _buildUnitToggle<HeightUnit>(
                current: _heightUnit,
                options: const {
                  HeightUnit.cm: 'cm',
                  HeightUnit.inch: 'in',
                },
                onSelected: (unit) {
                  setState(() => _heightUnit = unit);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '滑動下方刻度尺以選取您的身高。',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const Spacer(),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: RulerPickerWidget(
                key: ValueKey('height_$_heightUnit'),
                minValue: minHeight,
                maxValue: maxHeight,
                initialValue: displayHeight,
                unit: unitStr,
                accentColor: AppTheme.primaryOrange,
                onValueChanged: (val) {
                  if (_heightUnit == HeightUnit.cm) {
                    _selectedHeight = val;
                  } else {
                    _selectedHeight = double.parse((val * 2.54).toStringAsFixed(1));
                  }
                  // 不調用 setState，尺規自己渲染數值，達到最高 120fps 順暢體驗
                },
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // --- Step 4: 體重刻度尺 + 即時 BMI (支援 kg / lb 單位切換) ---
  Widget _buildWeightStep() {
    final double displayWeight;
    final double minWeight;
    final double maxWeight;
    final String unitStr;

    if (_weightUnit == WeightUnit.kg) {
      displayWeight = _selectedWeight;
      minWeight = 35.0;
      maxWeight = 180.0;
      unitStr = 'kg';
    } else {
      displayWeight = double.parse((_selectedWeight * 2.20462).toStringAsFixed(1));
      minWeight = 75.0;
      maxWeight = 400.0;
      unitStr = 'lb';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '您的體重是多少？',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              _buildUnitToggle<WeightUnit>(
                current: _weightUnit,
                options: const {
                  WeightUnit.kg: 'kg',
                  WeightUnit.lb: 'lb',
                },
                onSelected: (unit) {
                  setState(() {
                    _weightUnit = unit;
                    _weightNotifier.value = _selectedWeight;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '滑動刻度尺選取體重，系統將即時計算當前 BMI 狀態。',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          // BMI 即時卡片 (僅局部重構此元件，零掉幀)
          ValueListenableBuilder<double>(
            valueListenable: _weightNotifier,
            builder: (context, currentWeight, _) {
              final bmi = currentWeight / ((_selectedHeight / 100) * (_selectedHeight / 100));
              final bmiStr = bmi.toStringAsFixed(1);

              String bmiLabel;
              Color bmiColor;
              if (bmi < 18.5) {
                bmiLabel = '體重偏輕';
                bmiColor = const Color(0xFF3B82F6);
              } else if (bmi < 24.0) {
                bmiLabel = '體態健康標準';
                bmiColor = AppTheme.accentGreen;
              } else if (bmi < 27.0) {
                bmiLabel = '稍微過重';
                bmiColor = AppTheme.primaryOrange;
              } else {
                bmiLabel = '肥胖注意';
                bmiColor = AppTheme.errorRed;
              }

              return Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: bmiColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: bmiColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.speedometer, size: 18, color: bmiColor),
                      const SizedBox(width: 8),
                      Text(
                        '即時預估 BMI: $bmiStr ($bmiLabel)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: bmiColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: RulerPickerWidget(
                key: ValueKey('weight_$_weightUnit'),
                minValue: minWeight,
                maxValue: maxWeight,
                initialValue: displayWeight,
                unit: unitStr,
                accentColor: AppTheme.accentGreen,
                onValueChanged: (val) {
                  if (_weightUnit == WeightUnit.kg) {
                    _selectedWeight = val;
                  } else {
                    _selectedWeight = double.parse((val / 2.20462).toStringAsFixed(1));
                  }
                  _weightNotifier.value = _selectedWeight;
                },
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // --- Step 5: 活動量與健身目標 ---
  Widget _buildActivityAndGoalStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '日常生活與健身目標？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '結合您的運動習慣與期望體態，打造精準的卡路里與宏量營養素。',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. 日常活動量',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...ActivityLevel.values.map((act) {
                    final isSelected = _selectedActivity == act;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedActivity = act);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryOrange : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      act.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? AppTheme.primaryOrange : AppTheme.textDark,
                                      ),
                                    ),
                                    Text(
                                      act.description,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  CupertinoIcons.checkmark_circle_fill,
                                  color: AppTheme.primaryOrange,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text(
                    '2. 您的健身目標',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: FitnessGoal.values.map((g) {
                      final isSelected = _selectedGoal == g;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedGoal = g);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppTheme.accentGreen : const Color(0xFFE2E8F0),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(g.emoji, style: const TextStyle(fontSize: 24)),
                                  const SizedBox(height: 4),
                                  Text(
                                    g.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? AppTheme.accentGreen : AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 6: 結算揭曉儀表板 (Count-up 動畫) ---
  Widget _buildResultStep() {
    final result = _calculatedResult;
    if (result == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const Text(
            '🎉 專屬飲食與代謝預算已出爐！',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '已為您自動同步至「今日紀錄」首頁與拍照辨識引擎。',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),

          // TDEE 主卡片
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryOrange, Color(0xFFFF9E80)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '每日目標攝取熱量 (含目標增減)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _countUpAnimation,
                  builder: (context, _) {
                    final animatedCal =
                        (_countUpAnimation.value * result.targetCalories).round();
                    return Text(
                      '$animatedCal kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '基礎代謝 BMR: ${result.bmr} kcal | 每日總消耗 TDEE: ${result.tdee} kcal',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 三大營養素克數卡片
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroRow(
                    label: '蛋白質 (修復長肉)',
                    grams: result.proteinGrams,
                    color: AppTheme.primaryOrange,
                    icon: CupertinoIcons.flame_fill,
                  ),
                  const Divider(height: 1),
                  _buildMacroRow(
                    label: '碳水化合物 (運動動能)',
                    grams: result.carbsGrams,
                    color: AppTheme.accentGreen,
                    icon: CupertinoIcons.bolt_fill,
                  ),
                  const Divider(height: 1),
                  _buildMacroRow(
                    label: '優質脂肪 (荷爾蒙平衡)',
                    grams: result.fatGrams,
                    color: const Color(0xFFF59E0B),
                    icon: CupertinoIcons.drop_fill,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow({
    required String label,
    required int grams,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _countUpAnimation,
          builder: (context, _) {
            final animatedGrams = (_countUpAnimation.value * grams).round();
            return Text(
              '$animatedGrams g',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            );
          },
        ),
      ],
    );
  }
}
