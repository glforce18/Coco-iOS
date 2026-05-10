/// One incubating egg slot. Cracks and opens at preset level milestones
/// (see EggSlot.crackLevels / openLevels), not based on accumulated heat.
class EggSlot {
  /// Whether the player has already tapped to hatch this slot (so it shows
  /// the hatched bird instead of the ready-to-tap egg).
  bool hatched;
  EggSlot({this.hatched = false});

  /// Level at which each egg starts to crack (slot 1 / 2 / 3).
  static const List<int> crackLevels = [10, 50, 150];

  /// Level at which each egg is fully ready to hatch (player taps to open).
  static const List<int> openLevels = [25, 75, 175];

  Map<String, dynamic> toMap() => {'hatched': hatched};
  static EggSlot fromMap(Map<String, dynamic> m) =>
      EggSlot(hatched: (m['hatched'] as bool?) ?? false);
}

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

  // ─── Egg incubator (Yuva) ────────────────────────────────────────────
  /// 3 incubating egg slots. Each level completion adds heat.
  List<EggSlot> eggSlots;
  /// IDs of all hatched birds (e.g. 'jelly_purple', 'rare_gold').
  Set<String> hatchedBirds;

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

  // ─── Notifications ────────────────────────────────────────────────
  /// Master toggle. False = no notifs at all, regardless of sub-prefs.
  bool notifsEnabled;
  bool notifsLifeFull;
  bool notifsDaily;
  bool notifsEgg;
  bool notifsDailyReward;
  bool notifsCampaign;
  /// Epoch ms when we first showed the OS permission popup. 0 = never asked.
  int notifsAskedAt;
  /// Last FCM token POSTed to backend (so we don't re-send unchanged).
  String fcmToken;

  // ─── Premium promo (auto-popup pacing) ────────────────────────────
  /// Epoch ms when the auto premium popup was last shown to the user.
  int lastPremiumPromoShownAt;

  // ─── Update banner (in-app version check) ─────────────────────────
  /// The latest version string we already nudged the user about. Used
  /// to suppress the "new version" banner for repeated launches with
  /// the same target version.
  String lastSeenUpdateVersion;

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
    List<EggSlot>? eggSlots,
    Set<String>? hatchedBirds,
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
    this.notifsEnabled = true,
    this.notifsLifeFull = true,
    this.notifsDaily = true,
    this.notifsEgg = true,
    this.notifsDailyReward = true,
    this.notifsCampaign = true,
    this.notifsAskedAt = 0,
    this.fcmToken = '',
    this.lastPremiumPromoShownAt = 0,
    this.lastSeenUpdateVersion = '',
  })  : stars = stars ?? {},
        highScores = highScores ?? {},
        achievements = achievements ?? {},
        decorations = decorations ?? {},
        eventProgress = eventProgress ?? {},
        eggSlots = eggSlots ?? [EggSlot(), EggSlot(), EggSlot()],
        hatchedBirds = hatchedBirds ?? {};

  int get totalStars => stars.values.fold(0, (a, b) => a + b);

  int get perfectLevelCount => stars.values.where((s) => s >= 3).length;

  int starsForLevel(int level) => stars[level] ?? 0;

  bool isLevelUnlocked(int level) {
    // PRODUCTION GATING — level 1 always open; each subsequent level needs
    // the previous one to have earned at least 1 star.
    if (level < 1 || level > 240) return false;
    if (level == 1) return true;
    return starsForLevel(level - 1) > 0;
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
