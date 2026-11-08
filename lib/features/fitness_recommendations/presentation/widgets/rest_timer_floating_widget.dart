import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/rest_timer_controller.dart';

/// 組間休息懸浮計時面板 (支援展開卡片與最小化氣泡雙模式)
class RestTimerFloatingWidget extends ConsumerWidget {
  const RestTimerFloatingWidget({
    super.key,
    this.onFinishedDismissed,
  });

  final VoidCallback? onFinishedDismissed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerControllerProvider);
    final timerNotifier = ref.read(restTimerControllerProvider.notifier);

    if (!timerState.isVisible) {
      return const SizedBox.shrink();
    }

    if (timerState.isMinimized) {
      return _buildMinimizedBubble(context, timerState, timerNotifier);
    }

    return _buildExpandedCard(context, timerState, timerNotifier);
  }

  /// 最小化懸浮氣泡 (置於右下角，尺寸嚴格為 64x64，不遮擋主要操作)
  Widget _buildMinimizedBubble(
    BuildContext context,
    RestTimerState state,
    RestTimerNotifier notifier,
  ) {
    final isFinished = state.isFinished;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('rest_timer_minimized_bubble'),
        onTap: notifier.toggleMinimized,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isFinished
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isFinished
                      ? const Color(0xFF34D399)
                      : const Color(0xFF14B8A6).withValues(alpha: 0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isFinished
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : const Color(0xFF0F172A).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!isFinished)
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(
                        value: state.progress,
                        strokeWidth: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2DD4BF),
                        ),
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isFinished)
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 24,
                        )
                      else ...[
                        Text(
                          '${state.remainingSeconds}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          state.isRunning ? '休息' : '暫停',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
  }

  /// 現代毛玻璃展開卡片
  Widget _buildExpandedCard(
    BuildContext context,
    RestTimerState state,
    RestTimerNotifier notifier,
  ) {
    final isFinished = state.isFinished;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        key: const Key('rest_timer_expanded_card'),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isFinished
                ? const Color(0xFF10B981)
                : const Color(0xFF14B8A6).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isFinished
                  ? const Color(0xFF10B981).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 標題與操作按鈕行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isFinished
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : const Color(0xFF14B8A6).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFinished ? Icons.notifications_active : Icons.timer_outlined,
                    color: isFinished
                        ? const Color(0xFF34D399)
                        : const Color(0xFF2DD4BF),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isFinished
                        ? '🔔 休息結束！準備下一組！'
                        : (state.currentExerciseName != null
                            ? '組間休息：${state.currentExerciseName}'
                            : '組間休息計時'),
                    style: TextStyle(
                      color: isFinished
                          ? const Color(0xFF34D399)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 最小化按鈕
                IconButton(
                  key: const Key('rest_timer_minimize_btn'),
                  icon: const Icon(Icons.unfold_less, color: Colors.white70, size: 20),
                  tooltip: '最小化為氣泡',
                  onPressed: notifier.toggleMinimized,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // 關閉按鈕
                IconButton(
                  key: const Key('rest_timer_close_btn'),
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  tooltip: '關閉計時器',
                  onPressed: notifier.reset,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 倒數大數字或完成慶祝
            if (isFinished) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '休息時間已達標！深吸一口氣，繼續挑戰下一組！💪',
                        style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                      ),
                    ),
                    ElevatedButton(
                      key: const Key('rest_timer_finished_ok_btn'),
                      onPressed: notifier.dismissFinished,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('完成', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    state.formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    state.isRunning ? '倒數進行中...' : '已暫停',
                    style: TextStyle(
                      color: state.isRunning
                          ? const Color(0xFF2DD4BF)
                          : Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 平滑進度條
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF14B8A6),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 常用秒數快捷鍵
              Row(
                children: [
                  _buildPresetChip(30, state, notifier),
                  const SizedBox(width: 6),
                  _buildPresetChip(60, state, notifier),
                  const SizedBox(width: 6),
                  _buildPresetChip(90, state, notifier),
                  const SizedBox(width: 6),
                  _buildPresetChip(120, state, notifier),
                ],
              ),
              const SizedBox(height: 12),

              // 控制操作列 (-15s, 暫停/繼續, +15s, 完成)
              Row(
                children: [
                  // -15s
                  OutlinedButton(
                    key: const Key('rest_timer_minus_15_btn'),
                    onPressed: () => notifier.adjustSeconds(-15),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('-15s', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  // 暫停 / 繼續
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const Key('rest_timer_play_pause_btn'),
                      onPressed: state.isRunning
                          ? notifier.pauseTimer
                          : notifier.resumeTimer,
                      icon: Icon(
                        state.isRunning ? Icons.pause : Icons.play_arrow,
                        size: 18,
                      ),
                      label: Text(
                        state.isRunning ? '暫停' : '繼續',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isRunning
                            ? const Color(0xFF334155)
                            : const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // +15s
                  OutlinedButton(
                    key: const Key('rest_timer_plus_15_btn'),
                    onPressed: () => notifier.adjustSeconds(15),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2DD4BF),
                      side: BorderSide(color: const Color(0xFF14B8A6).withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('+15s', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  // 跳過/完成
                  TextButton(
                    key: const Key('rest_timer_skip_btn'),
                    onPressed: notifier.skipOrFinish,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white60,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Text('跳過', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    int seconds,
    RestTimerState state,
    RestTimerNotifier notifier,
  ) {
    final isCurrentTotal = state.totalSeconds == seconds && state.isActive;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('rest_timer_chip_${seconds}s'),
          onTap: () => notifier.startTimer(
            seconds,
            exerciseName: state.currentExerciseName,
          ),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isCurrentTotal
                  ? const Color(0xFF0D9488)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrentTotal
                    ? const Color(0xFF2DD4BF)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '${seconds}s',
                style: TextStyle(
                  color: isCurrentTotal ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: isCurrentTotal ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
