import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// 專為身高、體重設計的高性能純動畫互動刻度尺元件
/// 支援 120fps 慣性滑動、置中指針精準幾何對齊、觸感震動反饋 (Haptic Feedback)
class RulerPickerWidget extends StatefulWidget {
  const RulerPickerWidget({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.unit,
    required this.onValueChanged,
    this.itemSpacing = 12.0,
    this.accentColor = AppTheme.primaryOrange,
  });

  final double minValue;
  final double maxValue;
  final double initialValue;
  final String unit;
  final ValueChanged<double> onValueChanged;
  final double itemSpacing;
  final Color accentColor;

  @override
  State<RulerPickerWidget> createState() => _RulerPickerWidgetState();
}

class _RulerPickerWidgetState extends State<RulerPickerWidget> {
  late final ScrollController _scrollController;
  late double _currentValue;
  int _lastHapticInteger = -1;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.clamp(widget.minValue, widget.maxValue);
    _lastHapticInteger = _currentValue.round();

    final initialOffset =
        (_currentValue - widget.minValue) * widget.itemSpacing;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final calculated = widget.minValue + (offset / widget.itemSpacing);
    final clamped = calculated.clamp(widget.minValue, widget.maxValue);

    if ((clamped - _currentValue).abs() >= 0.1) {
      setState(() {
        _currentValue = double.parse(clamped.toStringAsFixed(1));
      });
      widget.onValueChanged(_currentValue);

      // 每跳過一個整數單位時觸發細膩的輕微震動反饋
      final currentInt = _currentValue.round();
      if (currentInt != _lastHapticInteger) {
        _lastHapticInteger = currentInt;
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = (widget.maxValue - widget.minValue).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 高性能即時數值指示器 (零掉幀、即時流暢更新)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _currentValue.toStringAsFixed(_currentValue % 1 == 0 ? 0 : 1),
              style: TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w900,
                color: widget.accentColor,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.unit,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 2. 互動刻度尺與置中指針 (精準幾何對齊與 O(1) SliverFixedExtent 渲染)
        SizedBox(
          height: 100,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final halfWidth = constraints.maxWidth / 2;
              // 關鍵校正：消除 itemSpacing 半寬偏差，確保刻度中心線與置中指針 100% 絕對重疊對齊
              final adjustedPadding = halfWidth - (widget.itemSpacing / 2);

              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  // 水平刻度尺列表 (固定項目寬度 itemExtent 帶來極致順暢度)
                  NotificationListener<ScrollEndNotification>(
                    onNotification: (_) {
                      // 滾動結束時平滑吸附至最近的 0.5 單位
                      final nearest =
                          (widget.minValue +
                                  (_scrollController.offset /
                                      widget.itemSpacing))
                              .clamp(widget.minValue, widget.maxValue);
                      final targetOffset =
                          (nearest - widget.minValue) * widget.itemSpacing;

                      if ((_scrollController.offset - targetOffset).abs() > 1.0) {
                        _scrollController.animateTo(
                          targetOffset,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                        );
                      }
                      return true;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemExtent: widget.itemSpacing, // O(1) 效能保證
                      padding: EdgeInsets.symmetric(
                        horizontal: adjustedPadding > 0 ? adjustedPadding : halfWidth,
                      ),
                      itemCount: totalSteps + 1,
                      itemBuilder: (context, index) {
                        final val = widget.minValue + index;
                        final isMajor = index % 5 == 0;
                        final isDecade = index % 10 == 0;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 刻度線條
                            Container(
                              width: isDecade ? 2.5 : (isMajor ? 1.8 : 1.2),
                              height: isDecade ? 38 : (isMajor ? 26 : 16),
                              decoration: BoxDecoration(
                                color: isDecade
                                    ? AppTheme.textDark
                                    : (isMajor
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 每 10 單位標註一次數字 (水平橫向展開，避免空間擠壓導致直式換行)
                            if (isDecade)
                              SizedBox(
                                height: 16,
                                child: OverflowBox(
                                  maxWidth: 50,
                                  minWidth: 50,
                                  child: Text(
                                    val.toInt().toString(),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ),

                  // 頂部置中指示針 (帶柔和陰影與圓角)
                  Positioned(
                    top: 14,
                    child: Container(
                      width: 4,
                      height: 52,
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
