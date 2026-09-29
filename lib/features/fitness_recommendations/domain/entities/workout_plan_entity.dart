import 'package:flutter/cupertino.dart';
import '../../../profile/domain/entities/user_profile_entity.dart';

/// 訓練型態分類 (第一層分類)
enum WorkoutCategory {
  machines,    // 器材機器
  freeWeights, // 自由重量
  homeWorkout; // 居家徒手

  String get label {
    switch (this) {
      case WorkoutCategory.machines:
        return '器材機器';
      case WorkoutCategory.freeWeights:
        return '自由重量';
      case WorkoutCategory.homeWorkout:
        return '居家徒手';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkoutCategory.machines:
        return CupertinoIcons.gear_alt_fill;
      case WorkoutCategory.freeWeights:
        return CupertinoIcons.bolt_horizontal_circle_fill;
      case WorkoutCategory.homeWorkout:
        return CupertinoIcons.house_alt_fill;
    }
  }
}

/// 訓練難度等級
enum WorkoutDifficulty {
  beginner,     // 新手友善
  intermediate, // 中階進階
  advanced;     // 高強度挑戰

  String get label {
    switch (this) {
      case WorkoutDifficulty.beginner:
        return '新手友善';
      case WorkoutDifficulty.intermediate:
        return '中階進階';
      case WorkoutDifficulty.advanced:
        return '高強度挑戰';
    }
  }
}

/// 訓練部位分類 (第二層細分)
enum TargetBodyPart {
  chest,             // 胸部肌群
  back,              // 背部肌群
  legs,              // 臀腿下肢
  shouldersAndArms,  // 肩膀與手臂
  core,              // 核心腹肌
  fullBody;          // 全身與心肺

  String get label {
    switch (this) {
      case TargetBodyPart.chest:
        return '胸部';
      case TargetBodyPart.back:
        return '背部';
      case TargetBodyPart.legs:
        return '臀腿';
      case TargetBodyPart.shouldersAndArms:
        return '肩臂';
      case TargetBodyPart.core:
        return '核心';
      case TargetBodyPart.fullBody:
        return '全身心肺';
    }
  }

  String get fullName {
    switch (this) {
      case TargetBodyPart.chest:
        return '胸部肌群';
      case TargetBodyPart.back:
        return '背部肌群';
      case TargetBodyPart.legs:
        return '臀腿下肢';
      case TargetBodyPart.shouldersAndArms:
        return '肩膀與手臂';
      case TargetBodyPart.core:
        return '核心腹肌';
      case TargetBodyPart.fullBody:
        return '全身與心肺';
    }
  }

  IconData get icon {
    switch (this) {
      case TargetBodyPart.chest:
        return CupertinoIcons.shield_lefthalf_fill;
      case TargetBodyPart.back:
        return CupertinoIcons.layers_alt_fill;
      case TargetBodyPart.legs:
        return CupertinoIcons.bolt_fill;
      case TargetBodyPart.shouldersAndArms:
        return CupertinoIcons.hammer_fill;
      case TargetBodyPart.core:
        return CupertinoIcons.circle_grid_hex_fill;
      case TargetBodyPart.fullBody:
        return CupertinoIcons.flame_fill;
    }
  }
}

/// 部位專屬科學訓練教練指引實體
class BodyPartGuidance {
  const BodyPartGuidance({
    required this.bodyPart,
    required this.title,
    required this.subtitle,
    required this.targetMuscles,
    required this.mindMuscleTip,
    required this.recommendedVolume,
    required this.commonMistakes,
    required this.recoveryTip,
    required this.accentColorHex,
  });

  final TargetBodyPart bodyPart;
  final String title;               // 指引主標 (如：挺拔胸膛與力量奠基)
  final String subtitle;            // 簡短副標
  final String targetMuscles;       // 涵蓋肌群 (胸大肌上中下束、前三角肌)
  final String mindMuscleTip;       // 🎯 發力感受要領
  final String recommendedVolume;   // 📊 建議訓練量與頻率
  final String commonMistakes;      // ⚠️ 常見代償錯誤防範
  final String recoveryTip;         // 🧘 練後伸展指引
  final int accentColorHex;         // 代表強調色
}

/// 單一運動動作詳細定義
class WorkoutExercise {
  const WorkoutExercise({
    required this.name,
    required this.targetMuscle,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.tips,
    required this.equipment,
    this.animationAsset,
  });

  final String name;          // 動作名稱 (如：坐姿胸推機)
  final String targetMuscle;   // 目標肌群 (如：胸大肌、三頭肌)
  final int sets;              // 建議組數 (如：4)
  final String reps;           // 建議次數或時間 (如：10~12 次、45 秒)
  final int restSeconds;       // 組間休息秒數 (如：60)
  final String tips;           // 動作要領叮嚀
  final String equipment;      // 所需器材 (如：胸推機、啞鈴、瑜珈墊)
  final String? animationAsset; // 開源示範動畫 GIF 檔案路徑

  String get effectiveAnimationAsset =>
      animationAsset ?? 'assets/exercises/bench_press.gif';

  WorkoutExercise copyWith({
    String? name,
    String? targetMuscle,
    int? sets,
    String? reps,
    int? restSeconds,
    String? tips,
    String? equipment,
    String? animationAsset,
  }) {
    return WorkoutExercise(
      name: name ?? this.name,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      tips: tips ?? this.tips,
      equipment: equipment ?? this.equipment,
      animationAsset: animationAsset ?? this.animationAsset,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'targetMuscle': targetMuscle,
        'sets': sets,
        'reps': reps,
        'restSeconds': restSeconds,
        'tips': tips,
        'equipment': equipment,
        'animationAsset': animationAsset,
      };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        name: json['name'] as String? ?? '',
        targetMuscle: json['targetMuscle'] as String? ?? '',
        sets: json['sets'] as int? ?? 3,
        reps: json['reps'] as String? ?? '10~12 次',
        restSeconds: json['restSeconds'] as int? ?? 60,
        tips: json['tips'] as String? ?? '',
        equipment: json['equipment'] as String? ?? '徒手 / 輔助道具',
        animationAsset: json['animationAsset'] as String?,
      );
}

/// 完整課表實體
class WorkoutPlanEntity {
  const WorkoutPlanEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.targetGoals,
    required this.durationMinutes,
    required this.estimatedCalories,
    required this.difficulty,
    required this.muscleGroups,
    required this.exercises,
    required this.accentColorHex,
    this.isCustom = false,
    this.targetBodyPart,
  });

  final String id;
  final String title;
  final String subtitle;
  final WorkoutCategory category;
  final List<FitnessGoal> targetGoals; // 適合的目標 (減脂/維持/增肌)
  final int durationMinutes;           // 預估時長 (分鐘)
  final int estimatedCalories;         // 預估消耗大卡
  final WorkoutDifficulty difficulty;  // 難度
  final List<String> muscleGroups;     // 主要涵蓋肌群 (如：["胸部", "背部", "手臂"])
  final List<WorkoutExercise> exercises;
  final int accentColorHex;            // Otterlife 馬卡龍柔和色彩值
  final bool isCustom;                 // 是否為使用者自訂課表
  final TargetBodyPart? targetBodyPart; // 主要訓練部位 (第二層細分)

  Color get accentColor => Color(accentColorHex);

  WorkoutPlanEntity copyWith({
    String? id,
    String? title,
    String? subtitle,
    WorkoutCategory? category,
    List<FitnessGoal>? targetGoals,
    int? durationMinutes,
    int? estimatedCalories,
    WorkoutDifficulty? difficulty,
    List<String>? muscleGroups,
    List<WorkoutExercise>? exercises,
    int? accentColorHex,
    bool? isCustom,
    TargetBodyPart? targetBodyPart,
  }) {
    return WorkoutPlanEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      targetGoals: targetGoals ?? this.targetGoals,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      difficulty: difficulty ?? this.difficulty,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      exercises: exercises ?? this.exercises,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      isCustom: isCustom ?? this.isCustom,
      targetBodyPart: targetBodyPart ?? this.targetBodyPart,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'category': category.name,
        'targetGoals': targetGoals.map((g) => g.name).toList(),
        'durationMinutes': durationMinutes,
        'estimatedCalories': estimatedCalories,
        'difficulty': difficulty.name,
        'muscleGroups': muscleGroups,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'accentColorHex': accentColorHex,
        'isCustom': isCustom,
        'targetBodyPart': targetBodyPart?.name,
      };

  factory WorkoutPlanEntity.fromJson(Map<String, dynamic> json) {
    TargetBodyPart? parsedBodyPart;
    if (json['targetBodyPart'] != null) {
      parsedBodyPart = TargetBodyPart.values.firstWhere(
        (b) => b.name == json['targetBodyPart'],
        orElse: () => TargetBodyPart.fullBody,
      );
    }

    return WorkoutPlanEntity(
      id: json['id'] as String? ??
          'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? '自訂課表',
      subtitle: json['subtitle'] as String? ?? '',
      category: WorkoutCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => WorkoutCategory.homeWorkout,
      ),
      targetGoals: (json['targetGoals'] as List<dynamic>?)
              ?.map((g) => FitnessGoal.values.firstWhere(
                    (fg) => fg.name == g,
                    orElse: () => FitnessGoal.maintain,
                  ))
              .toList() ??
          [FitnessGoal.maintain],
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      estimatedCalories: json['estimatedCalories'] as int? ?? 200,
      difficulty: WorkoutDifficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => WorkoutDifficulty.beginner,
      ),
      muscleGroups: (json['muscleGroups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['全身肌群'],
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      accentColorHex: json['accentColorHex'] as int? ?? 0xFF10B981,
      isCustom: json['isCustom'] as bool? ?? true,
      targetBodyPart: parsedBodyPart,
    );
  }

  /// 6 大部位專屬科學訓練教練指引資料庫
  static const Map<TargetBodyPart, BodyPartGuidance> bodyPartGuidanceMap = {
    TargetBodyPart.chest: BodyPartGuidance(
      bodyPart: TargetBodyPart.chest,
      title: '挺拔胸膛與厚度雕塑',
      subtitle: '注重向心夾胸與離心拉伸，打造飽滿胸大肌輪廓',
      targetMuscles: '胸大肌 (上束/中束/下束)、胸小肌、前鋸肌',
      mindMuscleTip: '沉肩後收夾緊肩胛骨，雙腳踩實，推起時想像「用兩側大臂向中間靠攏夾緊」，而非盲目伸手。',
      recommendedVolume: '每週建議刺激 1.5~2 次，每次 12~18 組，多關節臥推 6~10 下、孤立夾胸 12~15 下。',
      commonMistakes: '過度聳肩造成斜方肌與肩膀代償、臥推手肘外展超過 90 度增加旋轉肌袖受傷風險、手腕過度後折。',
      recoveryTip: '訓練後進行門框單側胸肌伸展，雙臂貼於門框前傾深呼吸，每側各維持 45~60 秒，釋放胸小肌緊繃。',
      accentColorHex: 0xFF6366F1, // 柔和靛藍
    ),
    TargetBodyPart.back: BodyPartGuidance(
      bodyPart: TargetBodyPart.back,
      title: '倒三角背肌與挺拔身姿',
      subtitle: '改善圓肩駝背，打造立體寬度與中背飽滿厚度',
      targetMuscles: '闊背肌、菱形肌、中下斜方肌、大圓肌、豎脊肌',
      mindMuscleTip: '以手肘為引導向下或向後拉，想像「手只是鉤子，背部兩側向中心折疊擠壓」，頂峰停頓收縮 1 秒。',
      recommendedVolume: '每週建議刺激 1.5~2 次，每次 14~20 組，垂直拉 (下拉/引體) 與水平划船交替搭配。',
      commonMistakes: '過度後仰藉助腰部借力晃動、二頭肌過度發力手臂先力竭、背部拱起折腰拉重物。',
      recoveryTip: '雙手抓握單槓放鬆懸掛 30 秒，或採用貓牛式與跪姿背部側向延伸伸展，放鬆背闊肌筋膜。',
      accentColorHex: 0xFF0D9488, // 翡翠青綠
    ),
    TargetBodyPart.legs: BodyPartGuidance(
      bodyPart: TargetBodyPart.legs,
      title: '下肢基石與代謝引擎',
      subtitle: '全身最大肌群驅動，加速燃脂代謝與臀腿修長緊實',
      targetMuscles: '股四頭肌、臀大肌、膕繩肌 (大腿後側)、小腿腓腸肌',
      mindMuscleTip: '深蹲著重三點支撐 (大腳趾球、小腳趾球、腳跟)，蹲下時髖膝連動、膝蓋對齊第二腳趾方向，蹬地站起。',
      recommendedVolume: '每週建議 1~2 次高質量訓練，每次 12~16 組，複合蹲推 8~12 下，單腿與提踵 15~20 下。',
      commonMistakes: '膝蓋內扣 (X型腿)、下蹲時腳後跟離地、硬舉時弓背塌腰導致椎間盤過載。',
      recoveryTip: '練後進行鴿子式伸展臀大肌 60 秒、站姿股四頭肌單腿後拉 45 秒，並搭配滾筒放鬆大腿外側髂脛束。',
      accentColorHex: 0xFF3B82F6, // 活力海洋藍
    ),
    TargetBodyPart.shouldersAndArms: BodyPartGuidance(
      bodyPart: TargetBodyPart.shouldersAndArms,
      title: '直角立體肩與緊實手臂',
      subtitle: '刻畫三角肌三束立體感，雕塑二頭肌峰與三頭肌馬蹄鐵',
      targetMuscles: '前三角肌、中三角肌、後三角肌、肱二頭肌、肱三頭肌',
      mindMuscleTip: '側平舉「手肘微屈，向兩側大範圍推開而非向上提手腕」；二頭彎舉「大臂夾緊軀幹不動，純小臂屈伸」。',
      recommendedVolume: '每週可穿插 2~3 次，中小肌群恢復快，側平舉與後束建議高次數 12~18 下累積代謝壓力。',
      commonMistakes: '側平舉聳肩用斜方肌甩起過重啞鈴、大重量推舉腰部過度反折反弓、三頭下壓手肘前後大幅晃動。',
      recoveryTip: '跨胸手臂肩部後束拉伸每側 45 秒、過頭三頭肌拉伸每側 45 秒，舒緩肩關節前側緊繃。',
      accentColorHex: 0xFFF59E0B, // 琥珀金橘
    ),
    TargetBodyPart.core: BodyPartGuidance(
      bodyPart: TargetBodyPart.core,
      title: '強韌核心與平坦馬甲線',
      subtitle: '穩固骨盆與腰椎健康，提升全身運動爆發力與平衡力',
      targetMuscles: '腹直肌 (上/下)、腹橫肌 (深層束身衣)、腹內外斜肌、豎脊肌',
      mindMuscleTip: '捲腹著重「骨盆與胸骨的距離縮短折疊」，想像吐氣肚臍貼緊脊椎；平板支撐全身夾緊如鋼板，骨盆微後傾。',
      recommendedVolume: '每週可訓練 3~4 次，每次 10~15 分鐘，靜態支撐 30~60 秒，動態捲腹轉體 15~20 下。',
      commonMistakes: '雙手雙臂死命抱頭拉扯頸椎、平板支撐塌腰或高高翹臀、憋氣造成腹內壓急遽上升。',
      recoveryTip: '腹部眼鏡蛇式溫和伸展 30 秒 (注意骨盆貼地勿擠壓腰椎)，搭配嬰兒式放鬆下背深呼吸。',
      accentColorHex: 0xFF8B5CF6, // 靜謐紫羅蘭
    ),
    TargetBodyPart.fullBody: BodyPartGuidance(
      bodyPart: TargetBodyPart.fullBody,
      title: '全身機能協調與高燃脂心肺',
      subtitle: '多關節動態串聯，激發後燃效應 (EPOC) 與全方位敏捷耐力',
      targetMuscles: '全身協同肌群、心肌、後側動力鏈、前側動力鏈',
      mindMuscleTip: '節奏重於速度，落地時保持微屈膝緩衝減少關節衝擊，呼吸均勻深長，維持在有氧至無氧臨界區間。',
      recommendedVolume: '每週建議 2~3 次 HIIT 或循環訓練，每次 20~30 分鐘，動靜穿插維持高心率。',
      commonMistakes: '波比跳落地直腿砸地傷關節、疲勞時動作變形依然硬拼速度、熱身不足即進入高強度衝刺。',
      recoveryTip: '運動後進行 5 分鐘慢走平復心率，接著完成全身大肌群靜態伸展，補充電解質與充足水分。',
      accentColorHex: 0xFFEF4444, // 爆汗珊瑚紅
    ),
  };

  /// 內建精選科學課表資料集 (涵蓋各大型態與部位)
  static const List<WorkoutPlanEntity> defaultPlans = [
    // 1. 器材機器 (Machines)
    WorkoutPlanEntity(
      id: 'plan_mach_chest',
      title: '器械胸肌專項推力爆發',
      subtitle: '固定軌跡安全孤立胸大肌，新手安全增厚胸肌首選',
      category: WorkoutCategory.machines,
      targetBodyPart: TargetBodyPart.chest,
      targetGoals: [FitnessGoal.muscleGain, FitnessGoal.maintain],
      durationMinutes: 30,
      estimatedCalories: 250,
      difficulty: WorkoutDifficulty.beginner,
      muscleGroups: ['胸大肌中束', '前三角肌', '肱三頭肌'],
      accentColorHex: 0xFF6366F1, // 柔和靛藍
      exercises: [
        WorkoutExercise(
          name: '坐姿機械胸推',
          targetMuscle: '胸大肌、前三角肌',
          sets: 4,
          reps: '10~12 次',
          restSeconds: 60,
          tips: '背部微拱緊貼靠墊，沉肩挺胸，推起時吐氣並感受胸肌發力，手肘不鎖死。',
          equipment: '胸推機 (Chest Press Machine)',
          animationAsset: 'assets/exercises/machine_chest_press.gif',
        ),
        WorkoutExercise(
          name: '蝴蝶機夾胸',
          targetMuscle: '胸肌內側中縫',
          sets: 4,
          reps: '15 次',
          restSeconds: 45,
          tips: '手肘微彎固定角度，專注感受胸肌向中央擠壓，還原時動作放慢。',
          equipment: '蝴蝶機 (Pec Deck Fly)',
          animationAsset: 'assets/exercises/pec_deck_fly.gif',
        ),
        WorkoutExercise(
          name: '滑輪繩索夾胸',
          targetMuscle: '胸肌下側與整體輪廓',
          sets: 3,
          reps: '12~15 次',
          restSeconds: 45,
          tips: '軀幹微前傾，手臂向下方弧線環抱夾緊，頂峰收縮 1 秒。',
          equipment: '龍門架滑輪',
          animationAsset: 'assets/exercises/cable_crossover.gif',
        ),
      ],
    ),
    WorkoutPlanEntity(
      id: 'plan_mach_back',
      title: '高位引體與器械背肌增厚',
      subtitle: '滑輪垂直下拉與坐姿划船，打造寬闊立體背肌',
      category: WorkoutCategory.machines,
      targetBodyPart: TargetBodyPart.back,
      targetGoals: [FitnessGoal.muscleGain, FitnessGoal.maintain],
      durationMinutes: 35,
      estimatedCalories: 290,
      difficulty: WorkoutDifficulty.intermediate,
      muscleGroups: ['闊背肌', '菱形肌', '中下斜方肌'],
      accentColorHex: 0xFF0D9488, // 翡翠青綠
      exercises: [
        WorkoutExercise(
          name: '高位機械滑輪下拉',
          targetMuscle: '闊背肌、大圓肌',
          sets: 4,
          reps: '10~12 次',
          restSeconds: 60,
          tips: '雙手略寬於肩，下拉時以手肘帶動往下夾，身體微向後傾約 15 度。',
          equipment: '高位下拉機 (Lat Pulldown)',
          animationAsset: 'assets/exercises/lat_pulldown.gif',
        ),
        WorkoutExercise(
          name: '坐姿機械划船',
          targetMuscle: '中背部、菱形肌',
          sets: 4,
          reps: '12 次',
          restSeconds: 60,
          tips: '核心收緊，挺胸拉向肚臍位置，肩胛骨往中間收夾停留一秒。',
          equipment: '划船機 (Seated Row Machine)',
          animationAsset: 'assets/exercises/seated_cable_row.gif',
        ),
        WorkoutExercise(
          name: '直臂滑輪下壓',
          targetMuscle: '闊背肌孤立強化',
          sets: 3,
          reps: '12~15 次',
          restSeconds: 45,
          tips: '手肘微彎固定不屈伸，完全以闊背肌下壓橫槓至大腿前方。',
          equipment: '高位滑輪',
          animationAsset: 'assets/exercises/straight_arm_pulldown.gif',
        ),
      ],
    ),
    WorkoutPlanEntity(
      id: 'plan_mach_legs',
      title: '下肢器械全面力量強化',
      subtitle: '大肌群高消耗訓練，加速基礎代謝並鍛鍊修長緊實下肢',
      category: WorkoutCategory.machines,
      targetBodyPart: TargetBodyPart.legs,
      targetGoals: [FitnessGoal.fatLoss, FitnessGoal.muscleGain],
      durationMinutes: 40,
      estimatedCalories: 330,
      difficulty: WorkoutDifficulty.intermediate,
      muscleGroups: ['股四頭肌', '腿後側肌群', '臀大肌'],
      accentColorHex: 0xFF3B82F6, // 晴空藍
      exercises: [
        WorkoutExercise(
          name: '45度仰臥腿推機',
          targetMuscle: '股四頭肌、臀肌',
          sets: 4,
          reps: '10~12 次',
          restSeconds: 75,
          tips: '腳掌置中與肩同寬，膝蓋對齊第二腳趾方向，下推至約 90 度後推起。',
          equipment: '斜臥腿推機 (Leg Press)',
          animationAsset: 'assets/exercises/leg_press.gif',
        ),
        WorkoutExercise(
          name: '坐姿機械腿伸展',
          targetMuscle: '股四頭肌 (大腿前側)',
          sets: 4,
          reps: '12~15 次',
          restSeconds: 60,
          tips: '背部緊貼椅背，抬起小腿至雙腿打平頂峰收縮，下落時保持阻力控制。',
          equipment: '腿伸展機 (Leg Extension)',
          animationAsset: 'assets/exercises/leg_extension.gif',
        ),
        WorkoutExercise(
          name: '俯臥機械腿彎舉',
          targetMuscle: '膕繩肌 (大腿後側)',
          sets: 4,
          reps: '12 次',
          restSeconds: 60,
          tips: '臀部貼緊墊面不懸空，勾起腳後跟朝臀部發力，緩慢有控制地下放。',
          equipment: '腿彎舉機 (Lying Leg Curl)',
          animationAsset: 'assets/exercises/leg_curl.gif',
        ),
        WorkoutExercise(
          name: '站姿或坐姿提踵機',
          targetMuscle: '小腿腓腸肌',
          sets: 3,
          reps: '15~20 次',
          restSeconds: 45,
          tips: '腳尖踩穩踏板前緣，腳後跟下壓拉伸，再全力踮起腳尖頂峰停頓。',
          equipment: '提踵機 (Calf Raise Machine)',
          animationAsset: 'assets/exercises/calf_raise.gif',
        ),
      ],
    ),
    WorkoutPlanEntity(
      id: 'plan_mach_shoulders_arms',
      title: '器械肩臂線條精雕塑形',
      subtitle: '推肩機與繩索下壓，精準刻劃三角肌與手臂線條',
      category: WorkoutCategory.machines,
      targetBodyPart: TargetBodyPart.shouldersAndArms,
      targetGoals: [FitnessGoal.muscleGain, FitnessGoal.maintain],
      durationMinutes: 30,
      estimatedCalories: 240,
      difficulty: WorkoutDifficulty.beginner,
      muscleGroups: ['三角肌前中束', '肱三頭肌', '肱二頭肌'],
      accentColorHex: 0xFFF59E0B, // 琥珀橙
      exercises: [
        WorkoutExercise(
          name: '器械過頭推舉',
          targetMuscle: '三角肌前中束',
          sets: 4,
          reps: '10~12 次',
          restSeconds: 60,
          tips: '手握手把高度與耳齊平，垂直推起吐氣，頂端手肘微屈不超伸鎖死。',
          equipment: '推肩機 (Shoulder Press Machine)',
          animationAsset: 'assets/exercises/shoulder_press.gif',
        ),
        WorkoutExercise(
          name: '滑輪繩索三頭下壓',
          targetMuscle: '肱三頭肌外側與長頭',
          sets: 4,
          reps: '12~15 次',
          restSeconds: 45,
          tips: '手肘夾緊身體兩側，下壓至底端微微向兩側分開，擠壓三頭肌。',
          equipment: '高位滑輪繩索',
          animationAsset: 'assets/exercises/tricep_pushdown.gif',
        ),
        WorkoutExercise(
          name: '牧師凳二頭彎舉',
          targetMuscle: '肱二頭肌孤立強化',
          sets: 3,
          reps: '10~12 次',
          restSeconds: 60,
          tips: '上臂緊貼斜托板，雙手平穩將槓鈴彎起，下放時有控制延展。',
          equipment: '牧師凳與曲槓',
          animationAsset: 'assets/exercises/preacher_curl.gif',
        ),
      ],
    ),

    // 2. 自由重量 (Free Weights)
    WorkoutPlanEntity(
      id: 'plan_free_chest_triceps',
      title: '啞鈴平斜推胸與三頭力量',
      subtitle: '多角度啞鈴推胸，強化胸大肌上中束與手臂伸展力量',
      category: WorkoutCategory.freeWeights,
      targetBodyPart: TargetBodyPart.chest,
      targetGoals: [FitnessGoal.muscleGain, FitnessGoal.maintain],
      durationMinutes: 40,
      estimatedCalories: 310,
      difficulty: WorkoutDifficulty.intermediate,
      muscleGroups: ['胸大肌上中側', '肱三頭肌', '前三角肌'],
      accentColorHex: 0xFF6366F1, // 柔和靛藍
      exercises: [
        WorkoutExercise(
          name: '槓鈴平版臥推 (Barbell Bench Press)',
          targetMuscle: '胸大肌整體、前三角肌',
          sets: 4,
          reps: '8~10 次',
          restSeconds: 90,
          tips: '肩胛骨後收下沉，雙腳踩實，槓鈴平穩降至胸口中下部，推起時微夾胸。',
          equipment: '槓鈴、臥推椅',
          animationAsset: 'assets/exercises/bench_press.gif',
        ),
        WorkoutExercise(
          name: '啞鈴上斜臥推 (Incline Dumbbell Press)',
          targetMuscle: '胸大肌上側、鎖骨部',
          sets: 4,
          reps: '10~12 次',
          restSeconds: 75,
          tips: '椅背調整約 30~45 度，手肘保持微向內收，推至頂點感受上胸收緊。',
          equipment: '一對啞鈴、上斜椅',
          animationAsset: 'assets/exercises/incline_press.gif',
        ),
        WorkoutExercise(
          name: '滑輪繩索三頭下壓 (Tricep Pushdown)',
          targetMuscle: '肱三頭肌外側與長頭',
          sets: 4,
          reps: '12~15 次',
          restSeconds: 45,
          tips: '手肘夾緊固定在身體兩側，手腕向下推至伸直，底端向兩側微微拉開。',
          equipment: '高位滑輪繩索',
          animationAsset: 'assets/exercises/tricep_pushdown.gif',
        ),
      ],
    ),
    WorkoutPlanEntity(
      id: 'plan_free_back_biceps',
      title: '啞鈴俯身划船與二頭雕塑',
      subtitle: '複合拉力動作，強化背闊肌厚度與手臂二頭肌峰',
      category: WorkoutCategory.freeWeights,
      targetBodyPart: TargetBodyPart.back,
      targetGoals: [FitnessGoal.muscleGain, FitnessGoal.maintain],
      durationMinutes: 40,
      estimatedCalories: 320,
      difficulty: WorkoutDifficulty.intermediate,
      muscleGroups: ['闊背肌', '菱形肌', '肱二頭肌'],
      accentColorHex: 0xFF0D9488, // 翡翠青綠
      exercises: [
        WorkoutExercise(
          name: '俯身槓鈴划船 (Barbell Bent-Over Row)',
          targetMuscle: '中背厚度、闊背肌',
          sets: 4,
          reps: '8~10 次',
          restSeconds: 75,
          tips: '折髖屈膝背脊平直，沿大腿將槓鈴平穩拉向肚臍位置。',
          equipment: '槓鈴',
          animationAsset: 'assets/exercises/bent_over_row.gif',
        ),
        WorkoutExercise(
          name: '單臂啞鈴划船 (One-arm Row)',
          targetMuscle: '闊背肌、背闊後束',
          sets: 4,
          reps: '每側 10 次',
          restSeconds: 60,
          tips: '背部與地面接近平行，將啞鈴沿弧線平穩拉向髖骨位置。',
          equipment: '單只啞鈴、長凳',
          animationAsset: 'assets/exercises/one_arm_row.gif',
        ),
        WorkoutExercise(
          name: '站姿啞鈴二頭彎舉 (Bicep Curl)',
          targetMuscle: '肱二頭肌',
          sets: 4,
          reps: '10~12 次',
          restSeconds: 45,
          tips: '大臂貼緊身體不晃動，旋後彎起頂峰收縮擠壓二頭肌。',
          equipment: '一對啞鈴',
          animationAsset: 'assets/exercises/bicep_curl.gif',
        ),
      ],
    ),
    WorkoutPlanEntity(
      id: 'plan_free_legs_glutes',
      title: '槓鈴深蹲與硬舉力量突破',
      subtitle: '經典三大項深蹲硬舉，鍛鍊強大下肢推進力與蜜桃臀',
      category: WorkoutCategory.freeWeights,
      targetBodyPart: TargetBodyPart.legs,
      targetGoals: [FitnessGoal.muscleGain, FitnessGoal.fatLoss],
      durationMinutes: 45,
      estimatedCalories: 380,
      difficulty: WorkoutDifficulty.advanced,
      muscleGroups: ['股四頭肌', '臀大肌', '大腿後側膕繩肌'],
      accentColorHex: 0xFF3B82F6, // 晴空藍
      exercises: [
        WorkoutExercise(
          name: '槓鈴深蹲 (Barbell Back Squat)',
          targetMuscle: '股四頭肌、臀大肌',
          sets: 4,
          reps: '8~10 次',
          restSeconds: 90,
          tips: '槓鈴置於斜方肌上，膝蓋順應腳尖方向蹲至大腿平行地面，蹬地挺立。',
          equipment: '槓鈴、深蹲架',
          animationAsset: 'assets/exercises/barbell_squat.gif',
        ),
        WorkoutExercise(
          name: '羅馬尼亞硬舉 (Romanian Deadlift, RDL)',
          targetMuscle: '膕繩肌、臀大肌、下背',
          sets: 4,
          reps: '10~12 次',
          restSeconds: 75,
          tips: '微曲膝蓋，將臀部向後推折髖，啞鈴貼著小腿向下至後側飽滿緊繃。',
          equipment: '啞鈴 / 槓鈴',
          animationAsset: 'assets/exercises/romanian_deadlift.gif',
        ),
        WorkoutExercise(
          name: '啞鈴弓箭步走 (Walking Lunge)',
          targetMuscle: '單腿穩定度、臀肌',
          sets: 3,
          reps: '每側 12 步',
          restSeconds: 60,
          tips: '跨步下蹲時前膝不超過腳尖，後膝微觸地面，身體重心平穩。',
          equipment: '一對啞鈴',
          animationAsset: 'assets/exercises/walking_lunge.gif',
        ),
      ],
    ),
    WorkoutPlanEntity(
      id: 'plan_free_shoulders',
      title: '立體直角肩與飛鳥精雕',
      subtitle: '多角度刺激三角肌前中後束，打造完美肩寬視覺比例',
      category: WorkoutCategory.freeWeights,
      targetBodyPart: TargetBodyPart.shouldersAndArms,
      targetGoals: [FitnessGoal.muscleGain, FitnessGoal.maintain],
      durationMinutes: 35,
      estimatedCalories: 260,
      difficulty: WorkoutDifficulty.intermediate,
      muscleGroups: ['前三角肌', '中三角肌', '後三角肌'],
      accentColorHex: 0xFFF59E0B, // 琥珀金
      exercises: [
        WorkoutExercise(
          name: '站姿過頭推舉 (Overhead Shoulder Press)',
          targetMuscle: '三角肌前中束、上胸部',
          sets: 4,
          reps: '10~12 次',
          restSeconds: 60,
          tips: '核心臀部緊縮，將啞鈴或槓鈴從肩旁垂直推過頭頂，避免腰部過度借力。',
          equipment: '啞鈴 / 槓鈴',
          animationAsset: 'assets/exercises/shoulder_press.gif',
        ),
        WorkoutExercise(
          name: '啞鈴側平舉 (Dumbbell Lateral Raise)',
          targetMuscle: '三角肌中束 (直角肩)',
          sets: 4,
          reps: '12~15 次',
          restSeconds: 45,
          tips: '手肘微曲，以手肘帶動向兩側抬起至與肩齊平，下放動作放慢。',
          equipment: '一對輕啞鈴',
          animationAsset: 'assets/exercises/lateral_raise.gif',
        ),
        WorkoutExercise(
          name: '俯身啞鈴飛鳥 (Rear Delt Fly)',
          targetMuscle: '三角肌後束、菱形肌',
          sets: 4,
          reps: '15 次',
          restSeconds: 45,
          tips: '折髖俯身，手臂向兩側展開如翅膀，專注以肩膀後側發力。',
          equipment: '一對輕啞鈴',
          animationAsset: 'assets/exercises/rear_delt_fly.gif',
        ),
      ],
    ),
    WorkoutPlanEntity(
      id: 'plan_free_dumbbell_full',
      title: '經典啞鈴全身力量核心雕塑',
      subtitle: '多關節複合動作，強化核心穩定與對稱平衡力量',
      category: WorkoutCategory.freeWeights,
      targetBodyPart: TargetBodyPart.fullBody,
      targetGoals: [FitnessGoal.muscleGain, FitnessGoal.maintain],
      durationMinutes: 45,
      estimatedCalories: 360,
      difficulty: WorkoutDifficulty.intermediate,
      muscleGroups: ['全身大肌群', '核心肌群', '三角肌'],
      accentColorHex: 0xFFF97316, // 活力活力橘
      exercises: [
        WorkoutExercise(
          name: '啞鈴高腳杯深蹲 (Goblet Squat)',
          targetMuscle: '股四頭肌、臀大肌、核心',
          sets: 4,
          reps: '10~12 次',
          restSeconds: 60,
          tips: '雙手捧住啞鈴置於胸前，膝蓋順應腳尖方向蹲下至大腿平行地面。',
          equipment: '單只中等重量啞鈴',
          animationAsset: 'assets/exercises/goblet_squat.gif',
        ),
        WorkoutExercise(
          name: '平版啞鈴臥推 (Dumbbell Press)',
          targetMuscle: '胸大肌、肱三頭肌',
          sets: 4,
          reps: '10 次',
          restSeconds: 60,
          tips: '躺在握推凳上，雙腳踩實地面，手肘微向下約 45~75 度推出。',
          equipment: '一對啞鈴、運動臥推椅',
          animationAsset: 'assets/exercises/incline_press.gif',
        ),
        WorkoutExercise(
          name: '單臂啞鈴划船 (One-arm Row)',
          targetMuscle: '闊背肌、中背菱形肌',
          sets: 4,
          reps: '每側 10 次',
          restSeconds: 60,
          tips: '單手與單膝支撐在平凳上，背脊挺直，將啞鈴沿弧線拉至髖骨旁。',
          equipment: '單只啞鈴、平凳',
          animationAsset: 'assets/exercises/one_arm_row.gif',
        ),
        WorkoutExercise(
          name: '啞鈴羅馬尼亞硬舉 (Dumbbell RDL)',
          targetMuscle: '大腿後側、臀部、下背',
          sets: 4,
          reps: '10~12 次',
          restSeconds: 75,
          tips: '膝蓋微屈固定，屁股往後推折髖，啞鈴貼著小腿向下至有拉伸感。',
          equipment: '一對啞鈴',
          animationAsset: 'assets/exercises/romanian_deadlift.gif',
        ),
      ],
    ),
    WorkoutPlanEntity(
      id: 'plan_free_kettlebell_hiit',
      title: '壺鈴與啞鈴高能燃脂循環',
      subtitle: '結合心肺與爆發力鍛鍊，高效燃燒熱量與提升後燃效應',
      category: WorkoutCategory.freeWeights,
      targetBodyPart: TargetBodyPart.fullBody,
      targetGoals: [FitnessGoal.fatLoss],
      durationMinutes: 30,
      estimatedCalories: 320,
      difficulty: WorkoutDifficulty.advanced,
      muscleGroups: ['心肺耐力', '臀腿後側鏈', '全身'],
      accentColorHex: 0xFFEF4444, // 爆汗熱情紅
      exercises: [
        WorkoutExercise(
          name: '雙手壺鈴擺盪 (Kettlebell Swing)',
          targetMuscle: '臀大肌、腿後肌、背部',
          sets: 4,
          reps: '15~20 次',
          restSeconds: 45,
          tips: '以髖關節折疊為主導，非深蹲！利用臀部瞬間夾緊推起壺鈴。',
          equipment: '壺鈴 (8kg ~ 16kg)',
          animationAsset: 'assets/exercises/kettlebell_swing.gif',
        ),
        WorkoutExercise(
          name: '波比跳 (Burpees)',
          targetMuscle: '全身爆發力、極限燃脂',
          sets: 3,
          reps: '10~12 次',
          restSeconds: 60,
          tips: '下蹲俯臥撐再迅速收腿垂直躍起，維持呼吸節奏不要憋氣。',
          equipment: '運動鞋、瑜珈墊',
          animationAsset: 'assets/exercises/burpees.gif',
        ),
        WorkoutExercise(
          name: '啞鈴站姿過頭肩推 (Overhead Press)',
          targetMuscle: '三角肌前中束、上胸',
          sets: 3,
          reps: '12 次',
          restSeconds: 60,
          tips: '核心腹肌緊收，啞鈴從肩旁平穩推過頭頂，避免腰部過度後仰借力。',
          equipment: '一對啞鈴',
          animationAsset: 'assets/exercises/shoulder_press.gif',
        ),
      ],
    ),

    // 3. 居家健身 (Home Workout)
    WorkoutPlanEntity(
      id: 'plan_home_chest_pushup',
      title: '客廳多角度俯臥撐胸肌挑戰',
      subtitle: '零器材打造飽滿胸大肌與上肢推力，安全又高效',
      category: WorkoutCategory.homeWorkout,
      targetBodyPart: TargetBodyPart.chest,
      targetGoals: [FitnessGoal.muscleGain, FitnessGoal.maintain],
      durationMinutes: 20,
      estimatedCalories: 180,
      difficulty: WorkoutDifficulty.beginner,
      muscleGroups: ['胸大肌', '核心抗伸展', '肱三頭肌'],
      accentColorHex: 0xFF6366F1, // 柔和靛藍
      exercises: [
        WorkoutExercise(
          name: '標準伏地挺身 (Push-Up)',
          targetMuscle: '胸大肌、核心抗伸展',
          sets: 4,
          reps: '12~15 次',
          restSeconds: 45,
          tips: '腹部與臀部夾緊呈直線，胸口微觸地面後全力推起。',
          equipment: '徒手 / 瑜珈墊',
          animationAsset: 'assets/exercises/push_up.gif',
        ),
        WorkoutExercise(
          name: '死蟲式核心活化 (Dead Bug)',
          targetMuscle: '深層腹橫肌骨盆穩定',
          sets: 3,
          reps: '每側 10 次',
          restSeconds: 30,
          tips: '下背部全程壓實墊面，對角線手腳緩慢向外延伸，深層發力。',
          equipment: '瑜珈墊',
          animationAsset: 'assets/exercises/dead_bug.gif',
        ),
      ],
    ),
    WorkoutPlanEntity(
      id: 'plan_home_bodyweight_hiit',
      title: '客廳徒手高效爆汗間歇',
      subtitle: '免器材、零門檻，客廳鋪張瑜珈墊即刻啟動高燃脂代謝',
      category: WorkoutCategory.homeWorkout,
      targetBodyPart: TargetBodyPart.fullBody,
      targetGoals: [FitnessGoal.fatLoss, FitnessGoal.maintain],
      durationMinutes: 25,
      estimatedCalories: 250,
      difficulty: WorkoutDifficulty.beginner,
      muscleGroups: ['全身爆汗', '心肺強化', '下肢'],
      accentColorHex: 0xFF10B981, // 翡翠翠綠
      exercises: [
        WorkoutExercise(
          name: '開合跳動態暖身 (Jumping Jacks)',
          targetMuscle: '全身熱身、喚醒心肺',
          sets: 3,
          reps: '45 秒',
          restSeconds: 20,
          tips: '落地時腳尖輕柔緩衝，膝蓋微彎保護關節，雙臂順暢大範圍伸展。',
          equipment: '瑜珈墊或舒適地毯',
          animationAsset: 'assets/exercises/jumping_jacks.gif',
        ),
        WorkoutExercise(
          name: '徒手自重深蹲 (Air Squat)',
          targetMuscle: '大腿、臀大肌',
          sets: 4,
          reps: '15 次',
          restSeconds: 40,
          tips: '重心在足跟與中足，雙手向前平衡，蹲至大腿與地面水平後站起。',
          equipment: '無',
          animationAsset: 'assets/exercises/barbell_squat.gif',
        ),
        WorkoutExercise(
          name: '標準俯臥撑 (可換跪姿伏地挺身)',
          targetMuscle: '胸肌、三頭肌、腹部核心',
          sets: 4,
          reps: '10~12 次',
          restSeconds: 45,
          tips: '全身呈一直線如棒式，手掌置於胸口兩側，下壓至胸口微觸地面。',
          equipment: '瑜珈墊',
          animationAsset: 'assets/exercises/push_up.gif',
        ),
        WorkoutExercise(
          name: '登山者式 (Mountain Climber)',
          targetMuscle: '腹直肌、心肺耐力',
          sets: 4,
          reps: '30 秒',
          restSeconds: 30,
          tips: '雙手撐地，左右膝蓋快速交替向胸口收縮提膝，臀部不抬過高。',
          equipment: '瑜珈墊',
          animationAsset: 'assets/exercises/mountain_climber.gif',
        ),
      ],
    ),
    WorkoutPlanEntity(
      id: 'plan_home_glutes_legs',
      title: '居家無跳躍靜音蜜桃臀腿',
      subtitle: '零噪音樓下不抗議，專注臀大肌與大腿內外側雕塑',
      category: WorkoutCategory.homeWorkout,
      targetBodyPart: TargetBodyPart.legs,
      targetGoals: [FitnessGoal.fatLoss, FitnessGoal.maintain],
      durationMinutes: 20,
      estimatedCalories: 170,
      difficulty: WorkoutDifficulty.beginner,
      muscleGroups: ['臀大肌', '大腿前側', '大腿後側'],
      accentColorHex: 0xFFEC4899, // 溫柔薔薇粉
      exercises: [
        WorkoutExercise(
          name: '自重深蹲 (Air Squat)',
          targetMuscle: '大腿、臀大肌',
          sets: 4,
          reps: '15 次',
          restSeconds: 40,
          tips: '重心在足跟與中足，雙手向前平衡，蹲至大腿與地面水平後站起。',
          equipment: '無',
          animationAsset: 'assets/exercises/barbell_squat.gif',
        ),
        WorkoutExercise(
          name: '原地弓箭步蹲 (Lunge)',
          targetMuscle: '單腿平衡、臀肌深度刺激',
          sets: 3,
          reps: '每側 12 次',
          restSeconds: 45,
          tips: '前膝對齊腳尖，後膝貼近地面，身體保持直立不前傾。',
          equipment: '瑜珈墊',
          animationAsset: 'assets/exercises/walking_lunge.gif',
        ),
        WorkoutExercise(
          name: '站姿提踵 (Standing Calf Raise)',
          targetMuscle: '小腿腓腸肌',
          sets: 3,
          reps: '20 次',
          restSeconds: 30,
          tips: '腳掌前緣踩地，全力踮起腳尖至最高點，感受小腿緊繃收縮。',
          equipment: '平地 / 牆壁輔助',
          animationAsset: 'assets/exercises/calf_raise.gif',
        ),
      ],
    ),
    WorkoutPlanEntity(
      id: 'plan_home_core_mobility',
      title: '核心雕塑與伸展恢復日常',
      subtitle: '緊實腹部馬甲線，舒緩久坐肩頸緊繃與下背壓力',
      category: WorkoutCategory.homeWorkout,
      targetBodyPart: TargetBodyPart.core,
      targetGoals: [FitnessGoal.maintain, FitnessGoal.fatLoss, FitnessGoal.muscleGain],
      durationMinutes: 20,
      estimatedCalories: 150,
      difficulty: WorkoutDifficulty.beginner,
      muscleGroups: ['腹橫肌', '腹直肌', '脊椎放鬆'],
      accentColorHex: 0xFF8B5CF6, // 療癒紫羅蘭
      exercises: [
        WorkoutExercise(
          name: '死蟲式核心活化 (Dead Bug)',
          targetMuscle: '深層腹橫肌、骨盆穩定',
          sets: 3,
          reps: '每側 10 次',
          restSeconds: 30,
          tips: '下背緊貼墊面不留空隙，對角線手腳緩慢向外延伸，感受腹部深層發力。',
          equipment: '瑜珈墊',
          animationAsset: 'assets/exercises/dead_bug.gif',
        ),
        WorkoutExercise(
          name: '仰臥捲腹 (Bicycle Crunch)',
          targetMuscle: '腹直肌上側、腹斜肌',
          sets: 3,
          reps: '16 次',
          restSeconds: 30,
          tips: '雙手輕托耳後，用腹肌將肩胛骨捲離地面，手肘朝對側膝蓋靠近。',
          equipment: '瑜珈墊',
          animationAsset: 'assets/exercises/crunch.gif',
        ),
        WorkoutExercise(
          name: '平板支撐 (Plank)',
          targetMuscle: '全身抗伸展核心',
          sets: 3,
          reps: '45 秒',
          restSeconds: 40,
          tips: '手肘在肩膀正下方，腹部與臀部夾緊，頭、背、腳跟維持筆直線條。',
          equipment: '瑜珈墊',
          animationAsset: 'assets/exercises/plank.gif',
        ),
        WorkoutExercise(
          name: '貓牛式與嬰兒式拉筋放鬆',
          targetMuscle: '胸椎活動度、腰背肌放鬆',
          sets: 2,
          reps: '60 秒深度呼吸',
          restSeconds: 0,
          tips: '隨吸氣胸口延展微抬頭，吐氣拱背低頭收腹，最後推至嬰兒式徹底放鬆。',
          equipment: '瑜珈墊',
          animationAsset: 'assets/exercises/cat_cow_stretch.gif',
        ),
      ],
    ),
  ];

  /// 內建分類完整動作資料庫 (整合 exercises-dataset 結構化動作與專屬動作動畫)
  static const Map<String, List<WorkoutExercise>> categorizedExerciseLibrary = {
    '胸部肌群': [
      WorkoutExercise(
        name: '槓鈴平版臥推 (Barbell Bench Press)',
        targetMuscle: '胸大肌整體、前三角肌',
        sets: 4,
        reps: '8~10 次',
        restSeconds: 90,
        tips: '肩胛骨後收下沉，雙腳踩實，槓鈴平穩降至胸口中下部，推起時微夾胸。',
        equipment: '槓鈴、臥推椅',
        animationAsset: 'assets/exercises/bench_press.gif',
      ),
      WorkoutExercise(
        name: '啞鈴上斜臥推 (Incline Dumbbell Press)',
        targetMuscle: '胸大肌上側、鎖骨部',
        sets: 4,
        reps: '10~12 次',
        restSeconds: 75,
        tips: '椅背調整約 30~45 度，手肘保持微向內收，推至頂點感受上胸收緊。',
        equipment: '一對啞鈴、上斜椅',
        animationAsset: 'assets/exercises/incline_press.gif',
      ),
      WorkoutExercise(
        name: '坐姿機械胸推 (Chest Press Machine)',
        targetMuscle: '胸大肌、三頭肌',
        sets: 4,
        reps: '10~12 次',
        restSeconds: 60,
        tips: '調整握把高度與胸口切齊，背貼靠墊，推起吐氣手肘不鎖死。',
        equipment: '胸推機',
        animationAsset: 'assets/exercises/machine_chest_press.gif',
      ),
      WorkoutExercise(
        name: '蝴蝶機夾胸 (Pec Deck Fly)',
        targetMuscle: '胸肌內側中縫',
        sets: 3,
        reps: '15 次',
        restSeconds: 45,
        tips: '手肘微曲鎖定角度，以胸肌將雙臂向胸前收攏擠壓，還原時動作放慢。',
        equipment: '蝴蝶機',
        animationAsset: 'assets/exercises/pec_deck_fly.gif',
      ),
      WorkoutExercise(
        name: '標準伏地挺身 (Push-Up)',
        targetMuscle: '胸大肌、核心抗伸展',
        sets: 3,
        reps: '12~15 次',
        restSeconds: 45,
        tips: '腹部與臀部夾緊呈直線，胸口微觸地面後全力推起。',
        equipment: '徒手 / 瑜珈墊',
        animationAsset: 'assets/exercises/push_up.gif',
      ),
      WorkoutExercise(
        name: '滑輪繩索夾胸 (Cable Crossover)',
        targetMuscle: '胸大肌下側與輪廓',
        sets: 3,
        reps: '12~15 次',
        restSeconds: 45,
        tips: '軀幹微前傾，手臂呈大弧線向下前方環抱夾緊，頂峰收縮 1 秒。',
        equipment: '龍門架滑輪',
        animationAsset: 'assets/exercises/cable_crossover.gif',
      ),
    ],
    '背部肌群': [
      WorkoutExercise(
        name: '高位機械滑輪下拉 (Lat Pulldown)',
        targetMuscle: '闊背肌、大圓肌',
        sets: 4,
        reps: '10~12 次',
        restSeconds: 60,
        tips: '挺胸下壓肩胛，用手肘向斜後下方帶動拉至鎖骨高度。',
        equipment: '高位下拉機',
        animationAsset: 'assets/exercises/lat_pulldown.gif',
      ),
      WorkoutExercise(
        name: '正手引體向上 (Pull-Up)',
        targetMuscle: '闊背肌、上背部肌群',
        sets: 4,
        reps: '6~10 次',
        restSeconds: 90,
        tips: '握距略寬於肩，沉肩啟動，將胸口朝單槓提拉，避免擺盪借力。',
        equipment: '單槓 / 引體向上架',
        animationAsset: 'assets/exercises/pull_up.gif',
      ),
      WorkoutExercise(
        name: '坐姿滑輪划船 (Seated Cable Row)',
        targetMuscle: '菱形肌、中下斜方肌',
        sets: 4,
        reps: '12 次',
        restSeconds: 60,
        tips: '保持軀幹穩定挺胸，手肘貼緊肋骨後拉，頂峰肩胛用力後夾。',
        equipment: '坐姿划船機',
        animationAsset: 'assets/exercises/seated_cable_row.gif',
      ),
      WorkoutExercise(
        name: '俯身槓鈴划船 (Barbell Bent-Over Row)',
        targetMuscle: '中背厚度、闊背肌',
        sets: 4,
        reps: '8~10 次',
        restSeconds: 75,
        tips: '折髖屈膝背脊平直，沿大腿將槓鈴平穩拉向肚臍位置。',
        equipment: '槓鈴',
        animationAsset: 'assets/exercises/bent_over_row.gif',
      ),
      WorkoutExercise(
        name: '單臂啞鈴划船 (One-arm Row)',
        targetMuscle: '闊背肌、背闊後束',
        sets: 4,
        reps: '每側 10 次',
        restSeconds: 60,
        tips: '背部與地面接近平行，將啞鈴沿弧線平穩拉向髖骨位置。',
        equipment: '單只啞鈴、長凳',
        animationAsset: 'assets/exercises/one_arm_row.gif',
      ),
      WorkoutExercise(
        name: '直臂滑輪下壓 (Straight-Arm Pulldown)',
        targetMuscle: '闊背肌孤立強化',
        sets: 3,
        reps: '12~15 次',
        restSeconds: 45,
        tips: '手肘微彎固定不屈伸，完全以闊背肌下壓橫槓至大腿前方。',
        equipment: '高位滑輪',
        animationAsset: 'assets/exercises/straight_arm_pulldown.gif',
      ),
    ],
    '臀腿下肢': [
      WorkoutExercise(
        name: '槓鈴深蹲 (Barbell Back Squat)',
        targetMuscle: '股四頭肌、臀大肌',
        sets: 4,
        reps: '8~10 次',
        restSeconds: 90,
        tips: '槓鈴置於斜方肌上，膝蓋順應腳尖方向蹲至大腿平行地面，蹬地挺立。',
        equipment: '槓鈴、深蹲架',
        animationAsset: 'assets/exercises/barbell_squat.gif',
      ),
      WorkoutExercise(
        name: '啞鈴高腳杯深蹲 (Goblet Squat)',
        targetMuscle: '股四頭肌、臀肌、核心',
        sets: 4,
        reps: '10~12 次',
        restSeconds: 60,
        tips: '雙手托住啞鈴貼於胸前，保持軀幹挺拔直立下蹲起立。',
        equipment: '單只啞鈴',
        animationAsset: 'assets/exercises/goblet_squat.gif',
      ),
      WorkoutExercise(
        name: '45度倒蹬腿推機 (Leg Press)',
        targetMuscle: '股四頭肌、臀大肌大肌群',
        sets: 4,
        reps: '10~12 次',
        restSeconds: 75,
        tips: '腳掌踩實踏板，下推深吸氣，推起吐氣，頂峰膝關節不鎖死。',
        equipment: '倒蹬腿推機',
        animationAsset: 'assets/exercises/leg_press.gif',
      ),
      WorkoutExercise(
        name: '羅馬尼亞硬舉 (Romanian Deadlift, RDL)',
        targetMuscle: '膕繩肌、臀大肌、下背',
        sets: 4,
        reps: '10~12 次',
        restSeconds: 75,
        tips: '微曲膝蓋，將臀部向後推折髖，啞鈴貼著小腿向下至後側飽滿緊繃。',
        equipment: '啞鈴 / 槓鈴',
        animationAsset: 'assets/exercises/romanian_deadlift.gif',
      ),
      WorkoutExercise(
        name: '坐姿機械腿伸展 (Leg Extension)',
        targetMuscle: '股四頭肌線條雕塑',
        sets: 4,
        reps: '12~15 次',
        restSeconds: 60,
        tips: '背部緊貼靠墊，踢起雙腿至水平打平停頓一秒，緩慢有控制地下落。',
        equipment: '腿伸展機',
        animationAsset: 'assets/exercises/leg_extension.gif',
      ),
      WorkoutExercise(
        name: '俯臥機械腿彎舉 (Lying Leg Curl)',
        targetMuscle: '大腿後側膕繩肌',
        sets: 4,
        reps: '12 次',
        restSeconds: 60,
        tips: '骨盆貼緊墊面不懸空，小腿彎起拉向臀部，頂峰停頓加強刺激。',
        equipment: '腿彎舉機',
        animationAsset: 'assets/exercises/leg_curl.gif',
      ),
      WorkoutExercise(
        name: '啞鈴弓箭步走 (Walking Lunge)',
        targetMuscle: '單腿穩定度、臀肌',
        sets: 3,
        reps: '每側 12 步',
        restSeconds: 60,
        tips: '跨步下蹲時前膝不超過腳尖，後膝微觸地面，身體重心平穩。',
        equipment: '一對啞鈴',
        animationAsset: 'assets/exercises/walking_lunge.gif',
      ),
      WorkoutExercise(
        name: '站姿提踵 (Standing Calf Raise)',
        targetMuscle: '小腿腓腸肌',
        sets: 3,
        reps: '15~20 次',
        restSeconds: 45,
        tips: '腳掌前緣踩在邊緣，後跟盡力下壓伸展，全力踮起腳尖至最高點。',
        equipment: '台階 / 提踵機',
        animationAsset: 'assets/exercises/calf_raise.gif',
      ),
    ],
    '肩部與手臂': [
      WorkoutExercise(
        name: '站姿過頭推舉 (Overhead Shoulder Press)',
        targetMuscle: '三角肌前中束、上胸部',
        sets: 4,
        reps: '10~12 次',
        restSeconds: 60,
        tips: '核心臀部緊縮，將啞鈴或槓鈴從肩旁垂直推過頭頂，避免腰部過度借力。',
        equipment: '啞鈴 / 槓鈴',
        animationAsset: 'assets/exercises/shoulder_press.gif',
      ),
      WorkoutExercise(
        name: '啞鈴側平舉 (Dumbbell Lateral Raise)',
        targetMuscle: '三角肌中束 (直角肩)',
        sets: 4,
        reps: '12~15 次',
        restSeconds: 45,
        tips: '手肘微曲，以手肘帶動向兩側抬起至與肩齊平，下放動作放慢。',
        equipment: '一對輕啞鈴',
        animationAsset: 'assets/exercises/lateral_raise.gif',
      ),
      WorkoutExercise(
        name: '站姿啞鈴二頭彎舉 (Bicep Curl)',
        targetMuscle: '肱二頭肌',
        sets: 4,
        reps: '10~12 次',
        restSeconds: 45,
        tips: '大臂貼緊身體不晃動，旋後彎起頂峰收縮擠壓二頭肌。',
        equipment: '一對啞鈴',
        animationAsset: 'assets/exercises/bicep_curl.gif',
      ),
      WorkoutExercise(
        name: '滑輪繩索三頭下壓 (Tricep Pushdown)',
        targetMuscle: '肱三頭肌外側與長頭',
        sets: 4,
        reps: '12~15 次',
        restSeconds: 45,
        tips: '手肘夾緊固定在身體兩側，手腕向下推至伸直，底端向兩側微微拉開。',
        equipment: '高位滑輪繩索',
        animationAsset: 'assets/exercises/tricep_pushdown.gif',
      ),
      WorkoutExercise(
        name: '俯身啞鈴飛鳥 (Rear Delt Fly)',
        targetMuscle: '三角肌後束、菱形肌',
        sets: 3,
        reps: '15 次',
        restSeconds: 45,
        tips: '折髖俯身，手臂向兩側展開如翅膀，專注以肩膀後側發力。',
        equipment: '一對輕啞鈴',
        animationAsset: 'assets/exercises/rear_delt_fly.gif',
      ),
      WorkoutExercise(
        name: '牧師凳二頭彎舉 (Preacher Curl)',
        targetMuscle: '二頭肌下端與短頭孤立',
        sets: 3,
        reps: '10~12 次',
        restSeconds: 60,
        tips: '大臂全程貼緊斜托墊，避免藉助身體晃動，專注手臂屈伸。',
        equipment: '牧師凳、曲柄槓鈴',
        animationAsset: 'assets/exercises/preacher_curl.gif',
      ),
    ],
    '核心腹肌': [
      WorkoutExercise(
        name: '平板支撐 (Plank)',
        targetMuscle: '腹橫肌、全身抗伸展',
        sets: 3,
        reps: '45~60 秒',
        restSeconds: 40,
        tips: '手肘位於肩正下方，骨盆微後傾夾臀收腹，身體筆直不塌腰。',
        equipment: '瑜珈墊',
        animationAsset: 'assets/exercises/plank.gif',
      ),
      WorkoutExercise(
        name: '仰臥捲腹 (Abdominal Crunch)',
        targetMuscle: '腹直肌上側',
        sets: 4,
        reps: '15~20 次',
        restSeconds: 30,
        tips: '下背貼地，用腹肌發力將上背部捲離地面吐氣，手不拉扯後頸。',
        equipment: '瑜珈墊',
        animationAsset: 'assets/exercises/crunch.gif',
      ),
      WorkoutExercise(
        name: '懸垂舉腿 (Hanging Leg Raise)',
        targetMuscle: '腹直肌下部、髂腰肌',
        sets: 3,
        reps: '12 次',
        restSeconds: 45,
        tips: '雙手懸掛單槓，避免大幅晃動，用下腹捲起雙膝或雙腿至水平以上。',
        equipment: '單槓',
        animationAsset: 'assets/exercises/hanging_leg_raise.gif',
      ),
      WorkoutExercise(
        name: '登山者式 (Mountain Climber)',
        targetMuscle: '腹直肌、全身心肺耐力',
        sets: 4,
        reps: '30 秒',
        restSeconds: 30,
        tips: '伏地姿勢雙膝快速交替向胸前提膝，核心收緊保持臀部平穩。',
        equipment: '瑜珈墊',
        animationAsset: 'assets/exercises/mountain_climber.gif',
      ),
      WorkoutExercise(
        name: '俄羅斯轉體 (Russian Twist)',
        targetMuscle: '腹內外斜肌 (人魚線)',
        sets: 3,
        reps: '每側 15 次',
        restSeconds: 30,
        tips: '屈膝懸空或著地，上半身向後傾約 45 度，帶動核心旋轉碰觸兩側。',
        equipment: '徒手 / 藥球',
        animationAsset: 'assets/exercises/russian_twist.gif',
      ),
      WorkoutExercise(
        name: '死蟲式核心活化 (Dead Bug)',
        targetMuscle: '深層腹橫肌骨盆穩定',
        sets: 3,
        reps: '每側 10 次',
        restSeconds: 30,
        tips: '下背部全程壓實墊面，對角線手腳緩慢向外延伸，深層發力。',
        equipment: '瑜珈墊',
        animationAsset: 'assets/exercises/dead_bug.gif',
      ),
    ],
    '全身心肺與伸展': [
      WorkoutExercise(
        name: '節奏開合跳 (Jumping Jacks)',
        targetMuscle: '全身爆汗、心肺熱身',
        sets: 3,
        reps: '45 秒',
        restSeconds: 20,
        tips: '前腳掌著地膝蓋微曲緩衝，雙臂與雙腿節奏同步律動開合。',
        equipment: '運動鞋、瑜珈墊',
        animationAsset: 'assets/exercises/jumping_jacks.gif',
      ),
      WorkoutExercise(
        name: '波比跳 (Burpees)',
        targetMuscle: '全身爆發力、極限燃脂',
        sets: 3,
        reps: '10~12 次',
        restSeconds: 60,
        tips: '下蹲俯臥撐再迅速收腿垂直躍起，維持呼吸節奏不要憋氣。',
        equipment: '運動鞋、瑜珈墊',
        animationAsset: 'assets/exercises/burpees.gif',
      ),
      WorkoutExercise(
        name: '雙手壺鈴擺盪 (Kettlebell Swing)',
        targetMuscle: '後側鏈、臀部爆發力',
        sets: 4,
        reps: '15~20 次',
        restSeconds: 45,
        tips: '以髖部鉸鏈爆發夾臀向前推，手臂僅作為連桿懸掛壺鈴。',
        equipment: '壺鈴',
        animationAsset: 'assets/exercises/kettlebell_swing.gif',
      ),
      WorkoutExercise(
        name: '貓牛式脊椎伸展 (Cat-Cow Stretch)',
        targetMuscle: '脊椎胸椎靈活度放鬆',
        sets: 2,
        reps: '60 秒',
        restSeconds: 0,
        tips: '隨吸氣胸口延展微抬頭塌腰，吐氣低頭拱背收腹，舒緩腰背緊繃。',
        equipment: '瑜珈墊',
        animationAsset: 'assets/exercises/cat_cow_stretch.gif',
      ),
      WorkoutExercise(
        name: '嬰兒式深度放鬆 (Child\'s Pose)',
        targetMuscle: '臀大肌伸展、身心放鬆',
        sets: 2,
        reps: '60 秒',
        restSeconds: 0,
        tips: '雙膝分開臀部坐在腳跟上，雙手向前延伸，前額輕觸地面深呼吸。',
        equipment: '瑜珈墊',
        animationAsset: 'assets/exercises/child_pose.gif',
      ),
    ],
  };
}
