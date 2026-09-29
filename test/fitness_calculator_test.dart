import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/features/profile/domain/entities/user_profile_entity.dart';
import 'package:jiaba_move/features/profile/domain/services/fitness_calculator.dart';

void main() {
  group('FitnessCalculator Unit Tests (CI/CD-First)', () {
    test('Calculates male BMR correctly (Mifflin-St Jeor)', () {
      // 70kg, 175cm, 25 years old
      // BMR = 10 * 70 + 6.25 * 175 - 5 * 25 + 5 = 700 + 1093.75 - 125 + 5 = 1673.75 => 1674
      final bmr = FitnessCalculator.calculateBmr(
        sex: BiologicalSex.male,
        weightKg: 70,
        heightCm: 175,
        age: 25,
      );
      expect(bmr, equals(1674));
    });

    test('Calculates female BMR correctly (Mifflin-St Jeor)', () {
      // 55kg, 160cm, 25 years old
      // BMR = 10 * 55 + 6.25 * 160 - 5 * 25 - 161 = 550 + 1000 - 125 - 161 = 1264
      final bmr = FitnessCalculator.calculateBmr(
        sex: BiologicalSex.female,
        weightKg: 55,
        heightCm: 160,
        age: 25,
      );
      expect(bmr, equals(1264));
    });

    test('Calculates undisclosed biological sex BMR correctly (LGBTQ+ Gender-Neutral Midpoint -78)', () {
      // 65kg, 170cm, 25 years old
      // BMR = 10 * 65 + 6.25 * 170 - 5 * 25 - 78 = 650 + 1062.5 - 125 - 78 = 1509.5 => 1510
      final bmr = FitnessCalculator.calculateBmr(
        sex: BiologicalSex.undisclosed,
        weightKg: 65,
        heightCm: 170,
        age: 25,
      );
      expect(bmr, equals(1510));
    });

    test('Calculates TDEE with various activity levels', () {
      const bmr = 1600;

      final sedentary = FitnessCalculator.calculateTdee(
        bmr: bmr,
        activityLevel: ActivityLevel.sedentary,
      );
      expect(sedentary, equals((1600 * 1.2).round())); // 1920

      final moderate = FitnessCalculator.calculateTdee(
        bmr: bmr,
        activityLevel: ActivityLevel.moderate,
      );
      expect(moderate, equals((1600 * 1.55).round())); // 2480
    });

    test('Adjusts calorie budget and macros according to fitness goal', () {
      const tdee = 2400;
      const weightKg = 70.0;

      // 減脂: -350 kcal = 2050 kcal
      final fatLossBudget = FitnessCalculator.calculateNutritionBudget(
        tdee: tdee,
        weightKg: weightKg,
        goal: FitnessGoal.fatLoss,
      );
      expect(fatLossBudget.targetCalories, equals(2050));
      expect(fatLossBudget.proteinGrams, greaterThanOrEqualTo(140)); // 2.0g/kg
      expect(fatLossBudget.fatGrams, greaterThan(0));
      expect(fatLossBudget.carbsGrams, greaterThan(0));

      // 增肌: +350 kcal = 2750 kcal
      final muscleGainBudget = FitnessCalculator.calculateNutritionBudget(
        tdee: tdee,
        weightKg: weightKg,
        goal: FitnessGoal.muscleGain,
      );
      expect(muscleGainBudget.targetCalories, equals(2750));
    });

    test('Calculates BMI accurately', () {
      // 70kg, 175cm -> 70 / (1.75 * 1.75) = 22.86
      final bmi = FitnessCalculator.calculateBmi(weightKg: 70, heightCm: 175);
      expect(bmi, closeTo(22.9, 0.1));
    });
  });
}
