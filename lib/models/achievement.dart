/// All achievements available in PatPat.
///
/// Each achievement has a Turkish title, description, emoji icon, and coin reward.
/// The [id] is a stable string key used for storage.
enum Achievement {
  firstMatch('first_match', 'İlk Eşleşme', 'İlk eşleşmeni yap', '\u2728', 10),
  combo5('combo_5', '5 Kombo', '5 zincirleme kombo yap', '\uD83D\uDD25', 25),
  combo10('combo_10', '10 Kombo', '10 zincirleme kombo yap', '\uD83D\uDD25', 50),
  stars50('stars_50', '50 Yıldız', '50 yıldız topla', '\u2B50', 50),
  stars100('stars_100', '100 Yıldız', '100 yıldız topla', '\u2B50', 100),
  stars200('stars_200', '200 Yıldız', '200 yıldız topla', '\u2B50', 200),
  level10('level_10', 'Seviye 10', 'Seviye 10\'a ulaş', '\uD83C\uDFC6', 30),
  level30('level_30', 'Seviye 30', 'Seviye 30\'a ulaş', '\uD83C\uDFC6', 75),
  level60('level_60', 'Seviye 60', 'Seviye 60\'a ulaş', '\uD83C\uDFC6', 150),
  level100('level_100', 'Seviye 100', 'Seviye 100\'e ulaş', '\uD83C\uDFC6', 300),
  level240('level_240', 'Son Seviye', 'Tüm seviyeleri tamamla', '\uD83C\uDFC6', 1000),
  coins1000('coins_1000', '1000 Coin', '1000 coin biriktir', '\uD83E\uDE99', 50),
  coins5000('coins_5000', '5000 Coin', '5000 coin biriktir', '\uD83E\uDE99', 100),
  daily7('daily_7', '7 Gün Seri', '7 gün üst üste oyna', '\uD83D\uDCC5', 100),
  daily30('daily_30', '30 Gün Seri', '30 gün üst üste oyna', '\uD83D\uDCC5', 300),
  perfectLevel('perfect_level', 'Mükemmel', 'Bir seviyeyi 3 yıldızla bitir', '\uD83C\uDF1F', 25),
  perfect10('perfect_10', '10 Mükemmel', '10 seviyeyi 3 yıldızla bitir', '\uD83C\uDF1F', 100),
  boosterUser('booster_user', 'Destek Uzmanı', '10 booster kullan', '\uD83D\uDE80', 25),
  shopVisitor('shop_visitor', 'Alıcılık', 'Marketi ziyaret et', '\uD83D\uDED2', 10),
  spinWheel('spin_wheel', 'Şanslı Çark', 'Çarkı çevir', '\uD83C\uDFA1', 15),
  firstSpecial('first_special', 'İlk Özel', 'İlk özel jöleyi oluştur', '\uD83C\uDF08', 15),
  iceBreaker('ice_breaker', 'Buz Kırıcı', '50 buz parçala', '\u2744\uFE0F', 50),
  chocolateLover('chocolate_lover', 'Çikolata Ustası', '50 çikolata temizle', '\uD83C\uDF6B', 50),
  speedRunner('speed_runner', 'Hızlı Koşucu', 'Bir seviyeyi 30 saniyede bitir', '\u26A1', 75),
  collector('collector', 'Koleksiyoncu', 'Tüm başarımları topla', '\uD83C\uDFC5', 500);

  final String id;
  final String title;
  final String description;
  final String emoji;
  final int coinReward;

  const Achievement(this.id, this.title, this.description, this.emoji, this.coinReward);

  /// Look up an achievement by its storage ID.
  static Achievement? fromId(String id) {
    for (final a in values) {
      if (a.id == id) return a;
    }
    return null;
  }
}
