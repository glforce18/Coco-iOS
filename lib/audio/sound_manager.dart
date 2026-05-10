import 'package:audioplayers/audioplayers.dart';

/// Lightweight sound manager — uses a pool of [AudioPlayer]s so rapid
/// match-3 pops can overlap without cutting each other off, plus a
/// dedicated [_loopPlayer] for ambient beach loop.
///
/// Uses [AudioContext] with mixWithOthers (iOS) + USAGE_GAME without
/// audio focus (Android), so user's own background music KEEPS PLAYING
/// when they enter our app instead of being paused.
class SoundManager {
  SoundManager._();
  static final SoundManager instance = SoundManager._();

  static const String pop = 'audio/pop.wav';
  static const String combo = 'audio/combo.wav';
  static const String swap = 'audio/swap.wav';
  static const String success = 'audio/success.wav';
  static const String chirp = 'audio/chirp.wav';
  static const String special = 'audio/special.wav';
  static const String fail = 'audio/fail.wav';
  static const String ambienceBeach = 'audio/ambience_beach.wav';

  bool enabled = true;
  bool ambienceEnabled = true;

  /// Audio context — ducks/mixes politely with user's external music.
  static final AudioContext _ctx = AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none, // do not steal focus
    ),
  );

  static const int _poolSize = 6;
  late final List<AudioPlayer> _pool = List.generate(_poolSize, (_) {
    final p = AudioPlayer();
    p.setAudioContext(_ctx);
    return p;
  });
  int _next = 0;

  late final AudioPlayer _loopPlayer = () {
    final p = AudioPlayer();
    p.setAudioContext(_ctx);
    // Low-latency player mode keeps the buffer warm so seeking back to start
    // on loop happens within the same audio frame — no audible gap.
    p.setPlayerMode(PlayerMode.lowLatency);
    p.setReleaseMode(ReleaseMode.loop);
    return p;
  }();
  String? _activeLoop;

  Future<void> play(String key, {double volume = 1.0}) async {
    if (!enabled) return;
    try {
      final p = _pool[_next % _poolSize];
      _next++;
      await p.stop();
      await p.setVolume(volume.clamp(0.0, 1.0));
      await p.play(AssetSource(key));
    } catch (_) {}
  }

  /// Start (or switch to) a looping ambience track. No-op if already playing.
  ///
  /// Uses setSource→resume rather than play() so we keep the same prepared
  /// buffer across loops — eliminates the ~250ms restart gap that play()
  /// introduces when audioplayers re-prepares the source.
  Future<void> playLoop(String key, {double volume = 0.3}) async {
    if (!ambienceEnabled) return;
    if (_activeLoop == key) return;
    try {
      await _loopPlayer.stop();
      await _loopPlayer.setReleaseMode(ReleaseMode.loop);
      await _loopPlayer.setVolume(volume.clamp(0.0, 1.0));
      await _loopPlayer.setSource(AssetSource(key));
      await _loopPlayer.resume();
      _activeLoop = key;
    } catch (_) {}
  }

  Future<void> stopLoop() async {
    try {
      await _loopPlayer.stop();
    } catch (_) {}
    _activeLoop = null;
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _loopPlayer.dispose();
  }
}
