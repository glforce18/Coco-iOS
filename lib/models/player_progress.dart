class PlayerProgress {
  int currentLevel;
  Map<int, int> stars; // level -> stars (0-3)
  Map<int, int> highScores; // level -> best score
  int totalScore;
  int lives;
  int lastLifeLostTime; // milliseconds epoch
  int coins;
  int hammerCount;
  int colorBlastCount;
  int extraMovesCount;
  bool soundEnabled;
  bool musicEnabled;
  bool vibrationEnabled;
  int dailyRewardStreak;
  int lastDailyRewardDay;
  int piggyBankCoins;
  Set<String> achievements;
  bool tutorialCompleted;

  PlayerProgress({
    this.currentLevel = 1,
    Map<int, int>? stars,
    Map<int, int>? highScores,
    this.totalScore = 0,
    this.lives = 5,
    this.lastLifeLostTime = 0,
    this.coins = 500,
    this.hammerCount = 3,
    this.colorBlastCount = 2,
    this.extraMovesCount = 3,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.dailyRewardStreak = 0,
    this.lastDailyRewardDay = 0,
    this.piggyBankCoins = 0,
    Set<String>? achievements,
    this.tutorialCompleted = false,
  })  : stars = stars ?? {},
        highScores = highScores ?? {},
        achievements = achievements ?? {};

  int get totalStars => stars.values.fold(0, (a, b) => a + b);

  int starsForLevel(int level) => stars[level] ?? 0;

  bool isLevelUnlocked(int level) {
    if (level <= 1) return true;
    return starsForLevel(level - 1) > 0; // Previous level completed
  }

  void completeLevel(int level, int newStars, int score, int coinsEarned) {
    final prevStars = stars[level] ?? 0;
    if (newStars > prevStars) stars[level] = newStars;
    final prevScore = highScores[level] ?? 0;
    if (score > prevScore) highScores[level] = score;
    if (level >= currentLevel) currentLevel = level + 1;
    totalScore += score;
    coins += coinsEarned;
  }

  // Life regeneration: 1 life every 30 minutes, max 5
  void regenerateLives() {
    if (lives >= 5 || lastLifeLostTime == 0) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - lastLifeLostTime;
    const regenInterval = 30 * 60 * 1000; // 30 minutes
    final regenerated = elapsed ~/ regenInterval;
    if (regenerated > 0) {
      lives = (lives + regenerated).clamp(0, 5);
      if (lives >= 5) {
        lastLifeLostTime = 0;
      } else {
        lastLifeLostTime += regenerated * regenInterval;
      }
    }
  }

  void useLife() {
    if (lives > 0) {
      lives--;
      if (lastLifeLostTime == 0) {
        lastLifeLostTime = DateTime.now().millisecondsSinceEpoch;
      }
    }
  }
}
