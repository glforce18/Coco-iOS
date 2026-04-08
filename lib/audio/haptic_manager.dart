import 'package:vibration/vibration.dart';

/// Singleton for haptic feedback — varies intensity by game event.
class HapticManager {
  static final HapticManager _instance = HapticManager._();
  static HapticManager get instance => _instance;
  HapticManager._();

  bool _enabled = true;
  bool _hasVibrator = false;

  bool get isEnabled => _enabled;
  set enabled(bool value) => _enabled = value;

  /// Probe device vibration support. Call once at app start.
  Future<void> init() async {
    _hasVibrator = await Vibration.hasVibrator();
  }

  /// Light tap — menu buttons, tile selection.
  void tapLight() {
    if (!_enabled || !_hasVibrator) return;
    Vibration.vibrate(duration: 20, amplitude: 80);
  }

  /// Medium tap — match found.
  void tapMatch() {
    if (!_enabled || !_hasVibrator) return;
    Vibration.vibrate(duration: 30, amplitude: 120);
  }

  /// Strong tap — combo chain.
  void tapCombo() {
    if (!_enabled || !_hasVibrator) return;
    Vibration.vibrate(duration: 50, amplitude: 200);
  }

  /// Heavy tap — level complete / game over.
  void tapHeavy() {
    if (!_enabled || !_hasVibrator) return;
    Vibration.vibrate(duration: 80, amplitude: 255);
  }

  /// Double-pulse pattern — obstacle destroyed.
  void doubleTap() {
    if (!_enabled || !_hasVibrator) return;
    Vibration.vibrate(pattern: [0, 40, 60, 40], intensities: [0, 180, 0, 120]);
  }
}
