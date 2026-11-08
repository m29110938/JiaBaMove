import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/meal_log_entity.dart';
import '../../domain/entities/nutrition_analysis_entity.dart';

/// 飲食紀錄狀態
class MealLogState {
  const MealLogState({
    required this.logs,
    required this.todayString,
    this.favorites = const [],
    this.isLoaded = false,
  });

  /// 所有保留中的紀錄 (依時間由舊到新)
  final List<MealLogEntity> logs;
  final String todayString;

  /// 常吃食物清單 (最新加入的在前)
  final List<MealDraft> favorites;
  final bool isLoaded;

  /// 今日紀錄 (依時間由舊到新)
  List<MealLogEntity> get todayLogs =>
      logs.where((m) => m.dateString == todayString).toList();

  double get todayCalories => _sum((m) => m.calories);
  double get todayProtein => _sum((m) => m.protein);
  double get todayCarbs => _sum((m) => m.carbs);
  double get todayFat => _sum((m) => m.fat);

  double _sum(double Function(MealLogEntity) pick) =>
      todayLogs.fold(0.0, (acc, m) => acc + pick(m));

  MealLogState copyWith({
    List<MealLogEntity>? logs,
    String? todayString,
    List<MealDraft>? favorites,
    bool? isLoaded,
  }) {
    return MealLogState(
      logs: logs ?? this.logs,
      todayString: todayString ?? this.todayString,
      favorites: favorites ?? this.favorites,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

final mealLogControllerProvider =
    StateNotifierProvider<MealLogNotifier, MealLogState>((ref) {
  return MealLogNotifier();
});

class MealLogNotifier extends StateNotifier<MealLogState> {
  MealLogNotifier({
    SecureStorageService? storageService,
    DateTime Function()? clock,
  })  : _storage = storageService ?? SecureStorageService(),
        _clock = clock ?? DateTime.now,
        super(MealLogState(
          logs: const [],
          todayString: MealLogEntity.formatDate((clock ?? DateTime.now)()),
        )) {
    _loadFuture = _load();
  }

  /// 紀錄保留天數 (避免存儲無限成長)
  static const int retentionDays = 90;

  final SecureStorageService _storage;
  final DateTime Function() _clock;
  late final Future<void> _loadFuture;

  /// 等待初次載入完成 (測試與寫入前使用)
  Future<void> get ready => _loadFuture;

  Future<void> _load() async {
    List<MealLogEntity> loaded = const [];
    try {
      final jsonStr = await _storage.getMealLogsJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final raw = jsonDecode(jsonStr) as List<dynamic>;
        loaded = raw
            .whereType<Map<String, dynamic>>()
            .map(MealLogEntity.fromJson)
            .toList();
      }
    } catch (_) {
      // 資料損毀時以空清單起步，不讓 App 崩潰
    }
    List<MealDraft> favorites = const [];
    try {
      final jsonStr = await _storage.getFavoriteFoodsJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        favorites = (jsonDecode(jsonStr) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(MealDraft.fromJson)
            .where((f) => f.foodName.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // 同上，損毀時忽略
    }
    if (!mounted) return;
    state = state.copyWith(
      logs: _prune(loaded),
      favorites: favorites,
      todayString: MealLogEntity.formatDate(_clock()),
      isLoaded: true,
    );
  }

  /// 跨日時更新今日日期 (App 長時間開著時)
  void refreshToday() {
    final today = MealLogEntity.formatDate(_clock());
    if (today != state.todayString) {
      state = state.copyWith(todayString: today);
    }
  }

  /// 將 AI 分析結果加入今日紀錄
  Future<MealLogEntity> addFromAnalysis(NutritionAnalysisEntity analysis) =>
      addDraft(MealDraft.fromAnalysis(analysis));

  /// 加入一筆紀錄 (手動輸入或修改過的 AI 結果)
  Future<MealLogEntity> addDraft(MealDraft draft) async {
    await _loadFuture;
    final entry = draft.toLog(loggedAt: _clock());
    state = state.copyWith(
      logs: _prune([...state.logs, entry]),
      todayString: entry.dateString,
    );
    await _persist();
    return entry;
  }

  /// 修改既有紀錄的內容 (保留原本的記錄時間)
  Future<void> update(String id, MealDraft draft) async {
    await _loadFuture;
    state = state.copyWith(
      logs: [
        for (final m in state.logs)
          if (m.id == id) draft.toLog(loggedAt: m.loggedAt, id: m.id) else m,
      ],
    );
    await _persist();
  }

  /// 常吃清單上限
  static const int maxFavorites = 30;

  /// 加入常吃清單 (同名同份量會更新並移到最前面)
  Future<void> addFavorite(MealDraft draft) async {
    await _loadFuture;
    final d = draft.sanitized();
    if (d.foodName.isEmpty) return;
    final rest = state.favorites.where((f) => !f.sameFoodAs(d));
    state = state.copyWith(
      favorites: [MealDraft.fromJson(d.toJson()), ...rest]
          .take(maxFavorites)
          .toList(),
    );
    await _persistFavorites();
  }

  /// 從常吃清單移除
  Future<void> removeFavorite(MealDraft draft) async {
    await _loadFuture;
    state = state.copyWith(
      favorites: state.favorites.where((f) => !f.sameFoodAs(draft)).toList(),
    );
    await _persistFavorites();
  }

  Future<void> _persistFavorites() async {
    try {
      await _storage.saveFavoriteFoodsJson(
        jsonEncode(state.favorites.map((f) => f.toJson()).toList()),
      );
    } catch (_) {
      // 寫入失敗時保留記憶體狀態
    }
  }

  /// 刪除一筆紀錄
  Future<void> remove(String id) async {
    await _loadFuture;
    state = state.copyWith(
      logs: state.logs.where((m) => m.id != id).toList(),
    );
    await _persist();
  }

  List<MealLogEntity> _prune(List<MealLogEntity> logs) {
    final cutoff = _clock().subtract(const Duration(days: retentionDays));
    final kept = logs.where((m) => m.loggedAt.isAfter(cutoff)).toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    return kept;
  }

  Future<void> _persist() async {
    try {
      await _storage.saveMealLogsJson(
        jsonEncode(state.logs.map((m) => m.toJson()).toList()),
      );
    } catch (_) {
      // 寫入失敗時保留記憶體狀態，下次寫入再嘗試
    }
  }
}
