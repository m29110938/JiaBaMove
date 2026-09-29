import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/workout_plan_entity.dart';

/// Otterlife 現代簡約運動動作動畫播放組件
/// 支援 exercises-dataset GIF 示範動畫與 Lottie 向量動畫雙解碼
/// 內建流暢循環播放、載入容錯以及點擊全屏/彈窗放大檢視動作要領
class ExerciseAnimationViewer extends StatelessWidget {
  const ExerciseAnimationViewer({
    super.key,
    required this.exercise,
    this.height = 130,
    this.enableEnlargeModal = true,
    this.animate,
  });

  final WorkoutExercise exercise;
  final double height;
  final bool enableEnlargeModal;
  final bool? animate;

  bool get _shouldAnimate {
    if (animate != null) return animate!;
    return !WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  Widget _buildMediaContent(String path, double displayHeight) {
    final cleanPath = path.trim();
    final isNetwork = cleanPath.startsWith('http://') || cleanPath.startsWith('https://');
    final isGifOrImage = cleanPath.endsWith('.gif') ||
        cleanPath.endsWith('.png') ||
        cleanPath.endsWith('.jpg') ||
        cleanPath.endsWith('.jpeg') ||
        cleanPath.endsWith('.webp');

    if (isNetwork) {
      return Image.network(
        cleanPath,
        height: displayHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorFallback(displayHeight),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: displayHeight,
            child: const Center(
              child: CupertinoActivityIndicator(),
            ),
          );
        },
      );
    }

    if (isGifOrImage) {
      return Image.asset(
        cleanPath,
        height: displayHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorFallback(displayHeight),
      );
    }

    // 預設為 Lottie 向量格式
    return Lottie.asset(
      cleanPath,
      fit: BoxFit.contain,
      height: displayHeight,
      animate: _shouldAnimate,
      errorBuilder: (context, error, stackTrace) => _buildErrorFallback(displayHeight),
    );
  }

  Widget _buildErrorFallback(double h) {
    return Container(
      height: h,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.sportscourt,
            size: 32,
            color: AppTheme.textMuted,
          ),
          SizedBox(height: 4),
          Text(
            '動作示意',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = exercise.effectiveAnimationAsset;

    Widget content = Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景微弱呼吸裝飾
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryOrange.withValues(alpha: 0.05),
              ),
            ),
          ),

          // 動畫核心 (GIF / Lottie)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _buildMediaContent(assetPath, height - 16),
            ),
          ),

          // 右上角放大預覽提示標籤
          if (enableEnlargeModal)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_up_left_arrow_down_right,
                      size: 11,
                      color: AppTheme.textMuted,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '放大演示',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (!enableEnlargeModal) {
      return content;
    }

    return GestureDetector(
      onTap: () => _showEnlargedDialog(context),
      child: content,
    );
  }

  /// 彈出放大動態教學示範與動作解說視窗
  void _showEnlargedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 標題與關閉按鈕
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${exercise.targetMuscle} • ${exercise.equipment}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 26, color: Color(0xFFCBD5E1)),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 大尺寸動作動畫展示
                  Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildMediaContent(exercise.effectiveAnimationAsset, 174),
                      ),
                    ),
                  ),

                  // 資料集授權標示
                  const Padding(
                    padding: EdgeInsets.only(top: 6, bottom: 4),
                    child: Text(
                      '動作示範：© Gym visual (exercises-dataset)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 建議配置 (組數 / 次數 / 休息)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniInfo('組數', '${exercise.sets} 組'),
                        Container(width: 1, height: 20, color: const Color(0xFFCBD5E1)),
                        _buildMiniInfo('次數', exercise.reps),
                        Container(width: 1, height: 20, color: const Color(0xFFCBD5E1)),
                        _buildMiniInfo('組間休息', '${exercise.restSeconds} 秒'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 動作要領叮嚀
                  if (exercise.tips.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFEF3C7)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            CupertinoIcons.lightbulb_fill,
                            size: 16,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exercise.tips,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF92400E),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 18),

                  // 了解並關閉按鈕
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '了解動作要領',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
