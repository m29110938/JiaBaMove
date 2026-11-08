import 'workout_plan_entity.dart';

/// 今日自訂訓練動作實體 (Daily Workout Item)
class DailyWorkoutItemEntity {
  const DailyWorkoutItemEntity({
    required this.id,
    required this.dateString,
    required this.exerciseName,
    required this.targetBodyPart,
    required this.weightKg,
    required this.reps,
    required this.sets,
    this.estimatedCalories = 0,
    this.isCompleted = false,
    this.animationAsset,
    this.isCustom = false,
    this.createdAt,
  });

  final String id;                    // 唯一識別碼
  final String dateString;            // 日期格式 yyyy-MM-dd
  final String exerciseName;          // 動作名稱 (如：槓鈴深蹲、平板啞鈴臥推)
  final TargetBodyPart targetBodyPart;// 訓練部位
  final double weightKg;              // 訓練重量 (kg，0 代表徒手/自重)
  final int reps;                     // 每組次數 (如：10)
  final int sets;                     // 訓練組數 (如：4)
  final int estimatedCalories;        // 預估消耗大卡 (kcal)
  final bool isCompleted;             // 是否打卡完成
  final String? animationAsset;       // 開源示範動畫 GIF 檔案路徑 (若為使用者自訂動作則為 null)
  final bool isCustom;                // 是否為使用者手打自訂動作
  final DateTime? createdAt;          // 建立時間

  DailyWorkoutItemEntity copyWith({
    String? id,
    String? dateString,
    String? exerciseName,
    TargetBodyPart? targetBodyPart,
    double? weightKg,
    int? reps,
    int? sets,
    int? estimatedCalories,
    bool? isCompleted,
    String? animationAsset,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return DailyWorkoutItemEntity(
      id: id ?? this.id,
      dateString: dateString ?? this.dateString,
      exerciseName: exerciseName ?? this.exerciseName,
      targetBodyPart: targetBodyPart ?? this.targetBodyPart,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      isCompleted: isCompleted ?? this.isCompleted,
      animationAsset: animationAsset ?? this.animationAsset,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateString': dateString,
        'exerciseName': exerciseName,
        'targetBodyPart': targetBodyPart.name,
        'weightKg': weightKg,
        'reps': reps,
        'sets': sets,
        'estimatedCalories': estimatedCalories,
        'isCompleted': isCompleted,
        'animationAsset': animationAsset,
        'isCustom': isCustom,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory DailyWorkoutItemEntity.fromJson(Map<String, dynamic> json) {
    TargetBodyPart bodyPart = TargetBodyPart.chest;
    final bodyPartStr = json['targetBodyPart'] as String?;
    if (bodyPartStr != null) {
      for (final p in TargetBodyPart.values) {
        if (p.name == bodyPartStr) {
          bodyPart = p;
          break;
        }
      }
    }

    return DailyWorkoutItemEntity(
      id: json['id'] as String? ?? '',
      dateString: json['dateString'] as String? ?? '',
      exerciseName: json['exerciseName'] as String? ?? '',
      targetBodyPart: bodyPart,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      reps: json['reps'] as int? ?? 10,
      sets: json['sets'] as int? ?? 3,
      estimatedCalories: json['estimatedCalories'] as int? ?? 50,
      isCompleted: json['isCompleted'] as bool? ?? false,
      animationAsset: json['animationAsset'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  /// 科學卡路里計算公式：
  /// 綜合考量：
  /// 1. 肌群大小基礎代謝消耗 (腿/全身 > 背/胸 > 肩臂/核心)
  /// 2. 機械功負重係數 (每組做功：重量 × 次數)
  /// 3. 使用者體重校正 (預設 70kg)
  static int calculateWorkoutCalories({
    required TargetBodyPart bodyPart,
    required double weightKg,
    required int reps,
    required int sets,
    double userWeightKg = 70.0,
  }) {
    if (sets <= 0 || reps <= 0) return 0;

    // 各肌群每組基礎熱量 (kcal / set，含組間間歇心率提升代謝)
    double baseKcalPerSet;
    switch (bodyPart) {
      case TargetBodyPart.legs:
      case TargetBodyPart.fullBody:
        baseKcalPerSet = 8.5; // 大腿、臀部、全身復合動作耗能最高
        break;
      case TargetBodyPart.back:
        baseKcalPerSet = 7.5; // 大肌群背部
        break;
      case TargetBodyPart.chest:
        baseKcalPerSet = 7.0; // 胸肌
        break;
      case TargetBodyPart.shouldersAndArms:
        baseKcalPerSet = 5.0; // 中小型肌群
        break;
      case TargetBodyPart.core:
        baseKcalPerSet = 4.5; // 核心腹肌
        break;
    }

    // 負重機械做功功耗加成 (每 1000 kg*rep 做功約消耗額外 12~18 kcal)
    final totalWorkVolume = weightKg * reps; // 單組做功量
    final workVolumeKcalPerSet = (totalWorkVolume / 1000.0) * 15.0;

    // 體重修正係數 (以 70kg 為標準基準，體重愈重單位耗能愈高)
    final weightFactor = (userWeightKg / 70.0).clamp(0.6, 1.8);

    // 總消耗大卡
    final totalCalories = (baseKcalPerSet + workVolumeKcalPerSet) * sets * weightFactor;

    return totalCalories.round().clamp(10, 800);
  }
}
