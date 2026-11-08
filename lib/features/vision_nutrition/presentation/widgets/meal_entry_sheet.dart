import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/meal_log_entity.dart';
import '../controllers/meal_log_controller.dart';

/// 餐點表單送出結果
class MealEntryResult {
  const MealEntryResult(this.draft, {this.saveAsFavorite = false});
  final MealDraft draft;
  final bool saveAsFavorite;
}

/// 開啟餐點編輯表單
///
/// - [initial] 為 null 時是手動新增，會顯示常吃清單供快速帶入
/// - 有 [initial] 時是修改 (AI 結果或既有紀錄)
Future<MealEntryResult?> showMealEntrySheet(
  BuildContext context, {
  MealDraft? initial,
  String title = '手動新增餐點',
  String submitLabel = '加入今日紀錄',
  bool showFavorites = true,
}) {
  return showModalBottomSheet<MealEntryResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => MealEntrySheet(
      initial: initial,
      title: title,
      submitLabel: submitLabel,
      showFavorites: showFavorites,
    ),
  );
}

class MealEntrySheet extends ConsumerStatefulWidget {
  const MealEntrySheet({
    super.key,
    this.initial,
    required this.title,
    required this.submitLabel,
    this.showFavorites = true,
  });

  final MealDraft? initial;
  final String title;
  final String submitLabel;
  final bool showFavorites;

  @override
  ConsumerState<MealEntrySheet> createState() => _MealEntrySheetState();
}

class _MealEntrySheetState extends ConsumerState<MealEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _serving;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late MealType _mealType;
  bool _saveAsFavorite = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _name = TextEditingController(text: d?.foodName ?? '');
    _serving = TextEditingController(text: d?.servingSize ?? '');
    _calories = TextEditingController(text: _fmt(d?.calories));
    _protein = TextEditingController(text: _fmt(d?.protein));
    _carbs = TextEditingController(text: _fmt(d?.carbs));
    _fat = TextEditingController(text: _fmt(d?.fat));
    _mealType = d?.mealType ?? MealType.fromTime(DateTime.now());
  }

  @override
  void dispose() {
    for (final c in [_name, _serving, _calories, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _fmt(double? v) {
    if (v == null) return '';
    final r = (v * 10).round() / 10;
    return r == r.roundToDouble() ? r.toInt().toString() : r.toString();
  }

  static double _parse(String s) => double.tryParse(s.trim()) ?? 0;

  /// 依倍數縮放熱量與營養素 (AI 估錯份量時用)
  void _scale(double factor) {
    setState(() {
      for (final c in [_calories, _protein, _carbs, _fat]) {
        if (c.text.trim().isEmpty) continue;
        c.text = _fmt(_parse(c.text) * factor);
      }
    });
  }

  void _fillFrom(MealDraft f) {
    setState(() {
      _name.text = f.foodName;
      _serving.text = f.servingSize;
      _calories.text = _fmt(f.calories);
      _protein.text = _fmt(f.protein);
      _carbs.text = _fmt(f.carbs);
      _fat.text = _fmt(f.fat);
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = MealDraft(
      foodName: _name.text,
      servingSize: _serving.text,
      calories: _parse(_calories.text),
      protein: _parse(_protein.text),
      carbs: _parse(_carbs.text),
      fat: _parse(_fat.text),
      mealType: _mealType,
    ).sanitized();
    Navigator.of(context)
        .pop(MealEntryResult(draft, saveAsFavorite: _saveAsFavorite));
  }

  String? _validateNumber(String? v, double max, {bool required = false}) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return required ? '必填' : null;
    final n = double.tryParse(s);
    if (n == null) return '請輸入數字';
    if (n < 0) return '不可為負數';
    if (n > max) return '最多 ${max.toInt()}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final favorites = widget.showFavorites
        ? ref.watch(mealLogControllerProvider.select((s) => s.favorites))
        : const <MealDraft>[];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),

                if (favorites.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    '常吃清單 (點一下帶入，按 × 移除)',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in favorites)
                        InputChip(
                          key: ValueKey('favorite_${f.foodName}_${f.servingSize}'),
                          avatar: const Icon(CupertinoIcons.star_fill,
                              size: 14, color: Color(0xFFF59E0B)),
                          label: Text('${f.foodName} · ${f.calories.round()}'),
                          onPressed: () => _fillFrom(f),
                          deleteIcon: const Icon(CupertinoIcons.xmark, size: 14),
                          onDeleted: () => ref
                              .read(mealLogControllerProvider.notifier)
                              .removeFavorite(f),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in MealType.values)
                      ChoiceChip(
                        label: Text(t.label),
                        selected: _mealType == t,
                        onSelected: (_) => setState(() => _mealType = t),
                        selectedColor:
                            AppTheme.primaryOrange.withValues(alpha: 0.18),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('meal_name_field'),
                  controller: _name,
                  decoration: const InputDecoration(labelText: '餐點名稱'),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '請輸入餐點名稱' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _serving,
                  decoration: const InputDecoration(
                    labelText: '份量 (選填)',
                    hintText: '例如：1 碗、約 300g',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 10),
                _numberField(
                  const Key('meal_calories_field'),
                  _calories,
                  '熱量 (kcal)',
                  MealDraft.maxCalories,
                  required: true,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _numberField(const Key('meal_protein_field'),
                          _protein, '蛋白質 g', MealDraft.maxMacroGrams),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numberField(const Key('meal_carbs_field'),
                          _carbs, '碳水 g', MealDraft.maxMacroGrams),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numberField(const Key('meal_fat_field'), _fat,
                          '脂肪 g', MealDraft.maxMacroGrams),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      '份量調整',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 8),
                    for (final entry in const [
                      ('×½', 0.5),
                      ('×1.5', 1.5),
                      ('×2', 2.0),
                    ]) ...[
                      OutlinedButton(
                        key: Key('scale_${entry.$2}'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(52, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          foregroundColor: AppTheme.textDark,
                        ),
                        onPressed: () => _scale(entry.$2),
                        child: Text(entry.$1),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
                CheckboxListTile(
                  key: const Key('save_favorite_checkbox'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _saveAsFavorite,
                  onChanged: (v) => setState(() => _saveAsFavorite = v ?? false),
                  title: const Text('同時加入常吃清單',
                      style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('meal_entry_submit'),
                    onPressed: _submit,
                    child: Text(widget.submitLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField(
    Key key,
    TextEditingController c,
    String label,
    double max, {
    bool required = false,
  }) {
    return TextFormField(
      key: key,
      controller: c,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      textInputAction: TextInputAction.next,
      validator: (v) => _validateNumber(v, max, required: required),
    );
  }
}
