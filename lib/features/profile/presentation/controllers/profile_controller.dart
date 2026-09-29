import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../settings/presentation/controllers/api_key_controller.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/services/fitness_calculator.dart';

class ProfileUiState {
  const ProfileUiState({
    this.profile,
    this.isLoading = false,
  });

  final UserProfileEntity? profile;
  final bool isLoading;

  bool get hasProfile => profile != null;

  ProfileUiState copyWith({
    UserProfileEntity? profile,
    bool? isLoading,
  }) {
    return ProfileUiState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileUiState>((ref) {
  return ProfileController(ref.watch(secureStorageServiceProvider));
});

class ProfileController extends StateNotifier<ProfileUiState> {
  ProfileController(this._storage) : super(const ProfileUiState()) {
    loadProfile();
  }

  final SecureStorageService _storage;

  /// 從 Keychain 讀取保存的身材代謝檔案
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final jsonStr = await _storage.getUserProfileJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final profile = UserProfileEntity.fromJson(map);
        state = state.copyWith(profile: profile, isLoading: false);
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  /// 計算並持久化保存個人身材檔案
  Future<UserProfileEntity> saveAndCalculateProfile({
    required BiologicalSex biologicalSex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    required FitnessGoal goal,
  }) async {
    state = state.copyWith(isLoading: true);

    // 1. 計算年齡
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    age = age.clamp(10, 100);

    // 2. 調用科學計算引擎 (含 LGBTQ+ 友善中性常數)
    final bmr = FitnessCalculator.calculateBmr(
      sex: biologicalSex,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
    );

    final tdee = FitnessCalculator.calculateTdee(
      bmr: bmr,
      activityLevel: activityLevel,
    );

    final bmi = FitnessCalculator.calculateBmi(
      weightKg: weightKg,
      heightCm: heightCm,
    );

    final budget = FitnessCalculator.calculateNutritionBudget(
      tdee: tdee,
      weightKg: weightKg,
      goal: goal,
    );

    // 3. 建立完整領域實體
    final profile = UserProfileEntity(
      birthDate: birthDate,
      biologicalSex: biologicalSex,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      goal: goal,
      bmr: bmr,
      tdee: tdee,
      targetCalories: budget.targetCalories,
      proteinGrams: budget.proteinGrams,
      carbsGrams: budget.carbsGrams,
      fatGrams: budget.fatGrams,
      bmi: bmi,
    );

    // 4. 加密儲存至 Keychain
    final jsonStr = jsonEncode(profile.toJson());
    await _storage.saveUserProfileJson(jsonStr);

    state = state.copyWith(profile: profile, isLoading: false);
    return profile;
  }
}
