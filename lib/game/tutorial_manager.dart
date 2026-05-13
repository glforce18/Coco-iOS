/// Each step of the brief on-boarding shown during levels 1-3. Steps are
/// non-blocking — the overlay sits at the top of the screen, the board
/// stays fully interactive, and a single tap on the panel dismisses /
/// advances the step.
enum TutorialStep {
  welcome(
    level: 1,
    title: 'Hoş Geldin!',
    message: 'Coco dünyasına hoş geldin. Aynı renkten 3 kuşu kaydır.',
  ),
  teachSwap(
    level: 1,
    title: 'Kaydır',
    message: 'İki bitişik kuşu kaydır. 3 veya daha fazla aynı renk → patlar.',
  ),
  teachGoals(
    level: 1,
    title: 'Hedefler',
    message: 'Üst paneldeki sayılara dikkat — o kadar kuş topla.',
  ),
  teachSpecial4(
    level: 2,
    title: 'Roket',
    message: '4 kuşu sıralarsan ROKET oluşur. Tüm satırı / sütunu siler.',
  ),
  teachCombo(
    level: 2,
    title: 'Kombo',
    message: 'Zincirleme eşleşmeler ekstra puan getirir!',
  ),
  teachSpecialBomb(
    level: 3,
    title: 'Bomba',
    message: 'T veya L şeklinde eşleşme → BOMBA! Geniş alanı patlatır.',
  ),
  teachBooster(
    level: 3,
    title: 'Güçlendiriciler',
    message: 'Alttaki çekiç, renk patlatma ve +3 hamleyi kullan.',
  );

  final int level;
  final String title;
  final String message;

  const TutorialStep({
    required this.level,
    required this.title,
    required this.message,
  });
}

/// Tracks which on-boarding step to show on each level. Always non-blocking
/// — the panel sits at the top of the screen, the board is fully usable
/// while it is visible, and a tap on the panel advances to the next step.
class TutorialManager {
  int _currentIndex = 0;
  bool _completed = false;

  TutorialManager({bool startCompleted = false})
      : _completed = startCompleted;

  bool get isCompleted => _completed;

  bool get isVisible => !_completed && _currentIndex < TutorialStep.values.length;

  TutorialStep? get currentStep {
    if (_completed || _currentIndex >= TutorialStep.values.length) return null;
    return TutorialStep.values[_currentIndex];
  }

  /// True when the player is on [level] and there's still a step queued
  /// for a level <= [level].
  bool shouldShowForLevel(int level) {
    if (_completed) return false;
    final step = currentStep;
    if (step == null) return false;
    return step.level <= level;
  }

  /// Advance to the next step. Marks complete when the queue is empty.
  void advance() {
    _currentIndex++;
    if (_currentIndex >= TutorialStep.values.length) {
      _completed = true;
    }
  }

  /// Skip all remaining steps.
  void skip() {
    _completed = true;
  }
}
