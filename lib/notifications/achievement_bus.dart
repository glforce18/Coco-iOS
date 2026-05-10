import 'package:flutter/foundation.dart';
import 'package:patpat_game/models/achievement.dart';

/// Global stream of newly unlocked achievements so the app shell can show a
/// toast wherever the user happens to be when the unlock fires.
class AchievementBus {
  AchievementBus._();
  static final AchievementBus instance = AchievementBus._();

  /// Queue of unlocks awaiting display. The shell listens via [notifier]
  /// and pops items off as it shows each toast.
  final ValueNotifier<int> notifier = ValueNotifier(0);
  final List<Achievement> _queue = [];

  void emit(Achievement a) {
    _queue.add(a);
    notifier.value++;
  }

  Achievement? pop() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  bool get hasMore => _queue.isNotEmpty;
}
