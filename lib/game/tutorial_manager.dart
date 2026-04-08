import 'package:patpat_game/models/position.dart';

/// Each step of the interactive tutorial shown during levels 1-3.
enum TutorialStep {
  welcome(
    level: 1,
    title: 'Hos Geldin!',
    message:
        'PatPat dunyasina hos geldin! Jelleri eslestirerek hedefleri tamamla.',
    highlightFrom: null,
    highlightTo: null,
    requiresAction: false,
  ),
  teachSwap(
    level: 1,
    title: 'Kaydir!',
    message:
        'Iki bitisik jeli kaydirarak yer degistir. Ayni renkten 3 veya daha fazla sirala!',
    highlightFrom: Position(4, 3),
    highlightTo: Position(4, 4),
    requiresAction: true,
  ),
  teachMatch(
    level: 1,
    title: 'Eslesme!',
    message: 'Harika! Eslesen jeller patladi ve puan kazandin.',
    highlightFrom: null,
    highlightTo: null,
    requiresAction: false,
  ),
  teachGoals(
    level: 1,
    title: 'Hedefler',
    message:
        'Ustteki hedef paneline bak. Belirtilen sayida jeli topla!',
    highlightFrom: null,
    highlightTo: null,
    requiresAction: false,
  ),
  teachSpecial4(
    level: 2,
    title: 'Roket!',
    message: '4 jeli siralarsan ozel bir ROKET olusur.',
    highlightFrom: null,
    highlightTo: null,
    requiresAction: false,
  ),
  teachCombo(
    level: 2,
    title: 'Kombo!',
    message: 'Zincirleme eslesmeler KOMBOdur!',
    highlightFrom: null,
    highlightTo: null,
    requiresAction: false,
  ),
  teachSpecialBomb(
    level: 3,
    title: 'Bomba!',
    message: 'T veya L seklinde eslesme → BOMBA!',
    highlightFrom: null,
    highlightTo: null,
    requiresAction: false,
  ),
  teachBooster(
    level: 3,
    title: 'Guclendiriciler',
    message: 'Alt paneldeki guclendiricileri kullan.',
    highlightFrom: null,
    highlightTo: null,
    requiresAction: false,
  );

  final int level;
  final String title;
  final String message;
  final Position? highlightFrom;
  final Position? highlightTo;
  final bool requiresAction;

  const TutorialStep({
    required this.level,
    required this.title,
    required this.message,
    required this.highlightFrom,
    required this.highlightTo,
    required this.requiresAction,
  });
}

/// Manages which tutorial step to show and when to advance.
class TutorialManager {
  int _currentIndex = 0;
  bool _completed = false;
  bool _visible = true;

  TutorialManager({bool startCompleted = false})
      : _completed = startCompleted;

  bool get isCompleted => _completed;
  bool get isVisible => _visible && !_completed && _currentIndex < TutorialStep.values.length;

  TutorialStep? get currentStep {
    if (_completed || _currentIndex >= TutorialStep.values.length) return null;
    return TutorialStep.values[_currentIndex];
  }

  /// Filter steps that belong to [level].
  bool shouldShowForLevel(int level) {
    if (_completed) return false;
    final step = currentStep;
    if (step == null) return false;
    return step.level <= level;
  }

  /// Advance to the next step (called on "Devam" or after an action).
  void advance() {
    _currentIndex++;
    _visible = true;
    if (_currentIndex >= TutorialStep.values.length) {
      _completed = true;
    }
  }

  /// Skip all remaining steps.
  void skip() {
    _completed = true;
  }

  /// Temporarily hide the overlay (e.g. during TEACH_SWAP action).
  void hideOverlay() {
    _visible = false;
  }

  /// Re-show the overlay after player action.
  void showOverlay() {
    _visible = true;
  }

  /// Check if current step is the action-required swap step.
  bool get isWaitingForAction {
    final step = currentStep;
    return step != null && step.requiresAction;
  }

  /// Get all steps for a given level that haven't been passed yet.
  List<TutorialStep> pendingStepsForLevel(int level) {
    if (_completed) return [];
    return TutorialStep.values
        .where((s) => s.level == level && s.index >= _currentIndex)
        .toList();
  }
}
