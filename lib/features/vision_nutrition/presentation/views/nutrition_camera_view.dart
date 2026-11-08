import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/controllers/api_key_controller.dart';
import '../../../settings/presentation/views/api_key_settings_view.dart';
import '../../data/datasources/gemini_vision_service.dart';
import '../../data/models/nutrition_analysis_model.dart';
import '../controllers/meal_log_controller.dart';

final geminiVisionServiceProvider = Provider<GeminiVisionService>((ref) {
  return GeminiVisionService(
    dioClient: ref.watch(dioClientProvider),
    secureStorageService: ref.watch(secureStorageServiceProvider),
  );
});

/// AI 拍照營養辨識頁面 (含未設 Key 友善引導)
class NutritionCameraView extends ConsumerStatefulWidget {
  const NutritionCameraView({super.key});

  @override
  ConsumerState<NutritionCameraView> createState() => _NutritionCameraViewState();
}

class _NutritionCameraViewState extends ConsumerState<NutritionCameraView> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  bool _isAnalyzing = false;
  NutritionAnalysisModel? _analysisResult;
  String? _errorMessage;
  bool _isSavingToLog = false;
  bool _savedToLog = false;

  /// 將目前分析結果加入今日飲食紀錄
  Future<void> _saveResultToLog() async {
    final result = _analysisResult;
    if (result == null || !result.isFood || _savedToLog || _isSavingToLog) {
      return;
    }
    setState(() => _isSavingToLog = true);
    await ref.read(mealLogControllerProvider.notifier).addFromAnalysis(result);
    if (!mounted) return;
    setState(() {
      _isSavingToLog = false;
      _savedToLog = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已將「${result.foodName}」加入今日紀錄 🍱'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 拍照或選取照片
  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    final storage = ref.read(secureStorageServiceProvider);
    final hasKey = await storage.hasGeminiApiKey();

    if (!hasKey) {
      if (!mounted) return;
      _showUnconfiguredKeyBottomSheet(context);
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        // 不讀取照片完整中繼資料 (GPS 等)，iOS 上也不需要完整相簿權限
        requestFullMetadata: false,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _selectedImageBytes = bytes;
        _isAnalyzing = true;
        _errorMessage = null;
        _analysisResult = null;
        _savedToLog = false;
      });

      final visionService = ref.read(geminiVisionServiceProvider);
      final result = await visionService.analyzeFoodImageBytes(_selectedImageBytes!);

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  /// 友善彈窗：未設 Key 引導
  void _showUnconfiguredKeyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.sparkles,
                    color: AppTheme.primaryOrange,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '需要 AI 營養師為您算熱量！',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '您目前尚未在會員中心配置 API Key。\n前往設定只需 1 分鐘，即可免費享有視覺辨識！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const ApiKeySettingsView(),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.gear_alt_fill, size: 18),
                      SizedBox(width: 8),
                      Text('前往會員中心設定 Key ➔'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    '稍後再說',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 拍照營養分析'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // 圖片展示區
              Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _selectedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.camera_fill,
                              size: 38,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '拍張美食美照，AI 幫你算營養！',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '支援便當、火鍋、早午餐、手搖飲等各式餐點',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 18),

              // 拍照與選相簿按鈕
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing
                          ? null
                          : () => _pickAndAnalyzeImage(ImageSource.camera),
                      icon: const Icon(CupertinoIcons.camera, size: 20),
                      label: const Text('開啟相機拍照'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textDark,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      onPressed: _isAnalyzing
                          ? null
                          : () => _pickAndAnalyzeImage(ImageSource.gallery),
                      icon: const Icon(CupertinoIcons.photo, size: 20),
                      label: const Text('從相簿選取'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 分析中動畫
              if (_isAnalyzing) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.primaryOrange,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        AppStrings.analyzingFood,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 錯誤訊息提示
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                          color: AppTheme.errorRed, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.errorRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 分析結果卡片
              if (_analysisResult != null) ...[
                _buildAnalysisResultCard(_analysisResult!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisResultCard(NutritionAnalysisModel result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  result.foodName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.servingSize,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 熱量標籤
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${result.calories.toInt()}',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryOrange,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'kcal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // 三大營養素
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientStat('蛋白質', '${result.protein.toStringAsFixed(1)}g', const Color(0xFF3B82F6)),
              _buildNutrientStat('碳水', '${result.carbs.toStringAsFixed(1)}g', AppTheme.primaryOrange),
              _buildNutrientStat('脂肪', '${result.fat.toStringAsFixed(1)}g', const Color(0xFFEAB308)),
            ],
          ),

          const SizedBox(height: 18),

          // 教練真心話卡片
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(CupertinoIcons.chat_bubble_2_fill,
                    color: AppTheme.primaryOrange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.coachAdvice,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textDark,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 加入今日紀錄
          if (result.isFood) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('save_meal_log_button'),
                style: _savedToLog
                    ? ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        disabledBackgroundColor:
                            AppTheme.accentGreen.withValues(alpha: 0.85),
                        disabledForegroundColor: Colors.white,
                      )
                    : null,
                onPressed:
                    (_savedToLog || _isSavingToLog) ? null : _saveResultToLog,
                icon: Icon(
                  _savedToLog
                      ? CupertinoIcons.checkmark_alt_circle_fill
                      : CupertinoIcons.plus_circle_fill,
                  size: 20,
                ),
                label: Text(_savedToLog ? '已加入今日紀錄' : '加入今日紀錄'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutrientStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
