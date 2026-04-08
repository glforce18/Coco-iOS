import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'wav_generator.dart';

/// Types of sound effects available in the game.
enum SoundType {
  buttonClick,
  swap,
  match,
  destroy,
  combo,
  levelComplete,
  gameOver,
}

/// Singleton that generates procedural WAV sounds at startup and plays them
/// on demand via [audioplayers].
///
/// All sounds are synthesised from sine waves — no asset files needed.
class SoundManager {
  static final SoundManager _instance = SoundManager._();
  static SoundManager get instance => _instance;
  SoundManager._();

  bool _initialized = false;
  bool _enabled = true;
  final Map<SoundType, String> _soundPaths = {};
  final _rng = Random();

  // Debouncing — prevent the same sound from stacking within 50 ms.
  final Map<SoundType, int> _lastPlayTime = {};
  static const _debounceMs = 50;

  bool get isEnabled => _enabled;
  set enabled(bool value) => _enabled = value;

  /// Generate all WAV files into a temp directory. Call once at app start.
  Future<void> init() async {
    if (_initialized) return;

    final dir = await getTemporaryDirectory();
    final soundDir = Directory('${dir.path}/patpat_sounds');
    if (!soundDir.existsSync()) {
      soundDir.createSync(recursive: true);
    }

    const sr = 22050;

    _soundPaths[SoundType.buttonClick] = await _generateAndSave(
      soundDir, 'click', generateTone(800, 0.035, sr),
    );
    _soundPaths[SoundType.swap] = await _generateAndSave(
      soundDir, 'swap', generateSweep(350, 650, 0.09, sr),
    );
    _soundPaths[SoundType.match] = await _generateAndSave(
      soundDir, 'match', generateChord([523, 659, 784], 0.13, sr),
    );
    _soundPaths[SoundType.destroy] = await _generateAndSave(
      soundDir, 'destroy', generateSweep(900, 250, 0.16, sr),
    );
    _soundPaths[SoundType.combo] = await _generateAndSave(
      soundDir, 'combo', generateSequence([523, 659, 784, 1047], 0.055, sr),
    );
    _soundPaths[SoundType.levelComplete] = await _generateAndSave(
      soundDir, 'win', generateSequence([523, 659, 784, 1047, 1319], 0.11, sr),
    );
    _soundPaths[SoundType.gameOver] = await _generateAndSave(
      soundDir, 'lose', generateSequence([392, 330, 262], 0.17, sr, decay: 2.5),
    );

    _initialized = true;
  }

  Future<String> _generateAndSave(
    Directory dir,
    String name,
    List<double> samples,
  ) async {
    final path = '${dir.path}/$name.wav';
    final file = File(path);
    if (!file.existsSync()) {
      final wav = generateWav(sampleRate: 22050, samples: samples);
      await file.writeAsBytes(wav);
    }
    return path;
  }

  /// Play a sound effect with optional volume (0.0 – 1.0).
  ///
  /// Adds slight random pitch/volume jitter so repeated sounds feel organic.
  Future<void> play(SoundType type, {double volume = 0.7}) async {
    if (!_enabled || !_initialized) return;

    // Debounce identical sounds.
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastPlayTime[type] ?? 0;
    if (now - last < _debounceMs) return;
    _lastPlayTime[type] = now;

    final path = _soundPaths[type];
    if (path == null) return;

    // Subtle jitter for variation.
    final rate = 1.0 + (_rng.nextDouble() - 0.5) * 0.06; // +/- 3 %
    final vol = (volume + (_rng.nextDouble() - 0.5) * 0.16).clamp(0.0, 1.0);

    try {
      final player = AudioPlayer();
      await player.setVolume(vol);
      await player.setPlaybackRate(rate);
      await player.play(DeviceFileSource(path));
      // Dispose after the clip finishes so we don't leak players.
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (_) {
      // Audio must never crash the game — swallow errors silently.
    }
  }
}
