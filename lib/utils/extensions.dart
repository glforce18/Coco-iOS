import 'dart:ui';

import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Display helpers for [JellyType].
extension JellyTypeDisplay on JellyType {
  Color get lightColor {
    switch (this) {
      case JellyType.purple:
        return GameColors.purpleLight;
      case JellyType.yellow:
        return GameColors.yellowLight;
      case JellyType.blue:
        return GameColors.blueLight;
      case JellyType.green:
        return GameColors.greenLight;
      case JellyType.pink:
        return GameColors.pinkLight;
      case JellyType.orange:
        return GameColors.orangeLight;
    }
  }

  Color get darkColor {
    switch (this) {
      case JellyType.purple:
        return GameColors.purpleDark;
      case JellyType.yellow:
        return GameColors.yellowDark;
      case JellyType.blue:
        return GameColors.blueDark;
      case JellyType.green:
        return GameColors.greenDark;
      case JellyType.pink:
        return GameColors.pinkDark;
      case JellyType.orange:
        return GameColors.orangeDark;
    }
  }
}
