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
  bool removeAdsPurchased;
  bool vipActive;
  bool starterBundleClaimed;
  bool soundEnabled;
  bool musicEnabled;
  bool vibrationEnabled;
  int dailyRewardStreak;
  int lastDailyRewardDay;
  int piggyBankCoins;
  Set<String> achievements;
  Set<String> decorations;
  bool tutorialCompleted;

  // Spin wheel
  int lastSpinTime; // milliseconds epoch (0 = never spun)

  // Weekly events
  int lastEventWeek; // ISO week number (0 = never)
  Map<String, int> eventProgress; // taskId -> current progress

  // Stats (for achievement tracking)
  int totalCombos;
  int totalBoostersUsed;
  int totalIceBroken;
  int totalChocolateCleared;
  int totalSpecialsCreated;
  bool shopVisited;
  bool wheelSpun;

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
    this.removeAdsPurchased = false,
    this.vipActive = false,
    this.starterBundleClaimed = false,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.dailyRewardStreak = 0,
    this.lastDailyRewardDay = 0,
    this.piggyBankCoins = 0,
    Set<String>? achievements,
    Set<String>? decorations,
    this.tutorialCompleted = false,
    this.lastSpinTime = 0,
    this.lastEventWeek = 0,
    Map<String, int>? eventProgress,
    this.totalCombos = 0,
    this.totalBoostersUsed = 0,
    this.totalIceBroken = 0,
    this.totalChocolateCleared = 0,
    this.totalSpecialsCreated = 0,
    this.shopVisited = false,
    this.wheelSpun = false,
  })  : stars = stars ?? {},
        highScores = highScores ?? {},
        achievements = achievements ?? {},
        decorations = decorations ?? {},
        eventProgress = eventProgress ?? {};

  int get totalStars => stars.values.fold(0, (a, b) => a + b);

  int get perfectLevelCount => stars.values.where((s) => s >= 3).length;

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

  // Life regeneration: 1 life every 30 minutes (20 for VIP), max 5
  void regenerateLives() {
    if (lives >= 5 || lastLifeLostTime == 0) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - lastLifeLostTime;
    final regenInterval = vipActive ? 20 * 60 * 1000 : 30 * 60 * 1000;
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
