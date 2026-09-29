import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/workout_plan_entity.dart';

/// 專屬部位科學訓練教練指引卡片 (Otterlife 溫暖專業手帳質感)
class BodyPartGuidanceCard extends StatelessWidget {
  const BodyPartGuidanceCard({
    super.key,
    required this.guidance,
  });

  final BodyPartGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(guidance.accentColorHex);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頂部部位標題與涵蓋肌群
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  guidance.bodyPart.icon,
                  size: 22,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${guidance.bodyPart.label}專屬教練指引',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guidance.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      guidance.targetMuscles,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 1. 發力感受要領
          _buildGuidanceSection(
            icon: CupertinoIcons.sparkles,
            iconColor: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFEF3C7),
            title: '發力感受要領',
            content: guidance.mindMuscleTip,
          ),

          const SizedBox(height: 10),

          // 2. 建議頻率與組數
          _buildGuidanceSection(
            icon: CupertinoIcons.chart_bar_alt_fill,
            iconColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFDBEAFE),
            title: '建議頻率與組數',
            content: guidance.recommendedVolume,
          ),

          const SizedBox(height: 10),

          // 3. 常見代償與防傷提醒
          _buildGuidanceSection(
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            iconColor: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFEE2E2),
            title: '避坑指南（防代償）',
            content: guidance.commonMistakes,
          ),

          const SizedBox(height: 10),

          // 4. 練後伸展指引
          _buildGuidanceSection(
            icon: CupertinoIcons.heart_fill,
            iconColor: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFFD1FAE5),
            title: '練後伸展與恢復',
            content: guidance.recoveryTip,
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceSection({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, height: 1.45, color: AppTheme.textDark),
                children: [
                  TextSpan(
                    text: '$title：',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                    ),
                  ),
                  TextSpan(
                    text: content,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
