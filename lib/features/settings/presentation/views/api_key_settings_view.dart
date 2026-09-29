import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/api_key_controller.dart';

/// Gemini API Key 安全設定畫面
class ApiKeySettingsView extends ConsumerStatefulWidget {
  const ApiKeySettingsView({super.key});

  @override
  ConsumerState<ApiKeySettingsView> createState() => _ApiKeySettingsViewState();
}

class _ApiKeySettingsViewState extends ConsumerState<ApiKeySettingsView> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(apiKeyControllerProvider);
    final controller = ref.read(apiKeyControllerProvider.notifier);

    // 當載入已存金鑰且輸入框為空時自動同步
    ref.listen<ApiKeyUiState>(apiKeyControllerProvider, (previous, next) {
      if (next.hasExistingKey && _textController.text.isEmpty) {
        _textController.text = next.keyText;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.apiKeyTitle),
        actions: [
          if (uiState.hasExistingKey)
            IconButton(
              icon: const Icon(CupertinoIcons.trash, color: AppTheme.errorRed),
              tooltip: AppStrings.clearKeyBtn,
              onPressed: () => _confirmClearKey(context, controller),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 頂部資訊卡片：強調 iOS Keychain 資安
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.lock_shield_fill,
                        color: AppTheme.primaryOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.appName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            AppStrings.apiKeySubtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // AI 模型選擇器與官方同步
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '作用中 AI 視覺模型',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (uiState.hasExistingKey)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: uiState.isFetchingModels
                          ? null
                          : () => controller.fetchModels(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (uiState.isFetchingModels)
                              const CupertinoActivityIndicator(radius: 6)
                            else
                              const Icon(
                                CupertinoIcons.arrow_2_circlepath,
                                size: 13,
                                color: AppTheme.primaryOrange,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              uiState.availableModels.isNotEmpty
                                  ? '已同步官方模型 (${uiState.availableModels.length})'
                                  : '同步最新模型',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: Builder(
                    builder: (context) {
                      // 建立模型選項字典，確保 value 唯一且具備親切繁中標籤
                      final modelItems = <String, String>{
                        'gemini-2.5-flash': 'Google Gemini 2.5 Flash (預設推薦・極速)',
                        'gemini-2.5-pro': 'Google Gemini 2.5 Pro (進階・深度分析)',
                        'gemini-3.5-flash': 'Google Gemini 3.5 Flash (次世代旗艦)',
                        'gpt-4o-mini': 'OpenAI GPT-4o-mini',
                        'gpt-4o': 'OpenAI GPT-4o',
                        'claude-3-5-sonnet': 'Anthropic Claude 3.5 Sonnet',
                      };

                      // 將 Google 伺服器動態抓取之新模型加入
                      for (final m in uiState.availableModels) {
                        if (!modelItems.containsKey(m)) {
                          modelItems[m] = 'Google $m (官方同步)';
                        }
                      }

                      // 容錯防呆：若當前選取的模型不在列表中，動態補入避免 DropdownButton 崩潰
                      final effectiveSelected = modelItems.containsKey(uiState.selectedModel)
                          ? uiState.selectedModel
                          : 'gemini-2.5-flash';

                      return DropdownButton<String>(
                        value: effectiveSelected,
                        isExpanded: true,
                        icon: const Icon(CupertinoIcons.chevron_down, size: 18),
                        items: modelItems.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.setSelectedModel(val);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // API Key 標籤與提示
              const Text(
                AppStrings.apiKeyInputLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),

              // 輸入框 (支援密碼遮罩切換)
              TextField(
                controller: _textController,
                obscureText: uiState.isObscured,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: AppStrings.apiKeyInputHint,
                  prefixIcon: const Icon(
                    CupertinoIcons.lock_fill,
                    size: 20,
                    color: AppTheme.textMuted,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      uiState.isObscured
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: controller.toggleObscure,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 狀態提示橫幅 (成功 / 錯誤 / 連線中)
              if (uiState.isTesting) ...[
                _buildStatusBanner(
                  icon: CupertinoIcons.arrow_2_circlepath,
                  message: AppStrings.testingConnection,
                  color: AppTheme.primaryOrange,
                  isLoading: true,
                ),
                const SizedBox(height: 16),
              ] else if (uiState.errorMessage != null) ...[
                _buildStatusBanner(
                  icon: CupertinoIcons.exclamationmark_circle_fill,
                  message: uiState.errorMessage!,
                  color: AppTheme.errorRed,
                ),
                const SizedBox(height: 16),
              ] else if (uiState.successMessage != null) ...[
                _buildStatusBanner(
                  icon: CupertinoIcons.checkmark_seal_fill,
                  message: uiState.successMessage!,
                  color: AppTheme.successGreen,
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 12),

              // 測試連線並儲存按鈕
              ElevatedButton(
                onPressed: uiState.isTesting
                    ? null
                    : () async {
                        FocusScope.of(context).unfocus();
                        await controller.testAndSaveKey(_textController.text);
                      },
                child: uiState.isTesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.bolt_horizontal_circle_fill, size: 20),
                          SizedBox(width: 8),
                          Text(AppStrings.testConnectionBtn),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required String message,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearKey(BuildContext context, ApiKeyNotifier controller) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(AppStrings.clearKeyDialogTitle),
        content: const Text(AppStrings.clearKeyDialogMessage),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.clearKeyConfirmBtn),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.clearKeyCancelBtn),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _textController.clear();
      await controller.clearKey();
    }
  }
}
