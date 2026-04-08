import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'wav_generator.dart';

/// Available background music tracks.
enum MusicTrack { menu, game, boss }

/// Singleton that generates looping procedural background music and plays it.
///
/// Three tracks are synthesised once at startup:
/// - **menu** — gentle C-major arpeggio at 80 BPM
/// - **game** — bouncy G-major pentatonic at 140 BPM
/// - **boss** — tense A-minor at 160 BPM
class MusicManager {
  static final MusicManager _instance = MusicManager._();
  static MusicManager get instance => _instance;
  MusicManager._();

  bool _enabled = true;
  bool _initialized = false;
  AudioPlayer? _player;
  MusicTrack? _currentTrack;
  final Map<MusicTrack, String> _trackPaths = {};

  bool get isEnabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    if (!value) stop();
  }

  /// Generate all music WAVs. Call once at app start.
  Future<void> init() async {
    if (_initialized) return;

    final dir = await getTemporaryDirectory();
    final musicDir = Directory('${dir.path}/patpat_music');
    if (!musicDir.existsSync()) {
      musicDir.createSync(recursive: true);
    }

    _trackPaths[MusicTrack.menu] = await _generateTrack(
      musicDir, 'menu', _generateMenuTrack(),
    );
    _trackPaths[MusicTrack.game] = await _generateTrack(
      musicDir, 'game', _generateGameTrack(),
    );
    _trackPaths[MusicTrack.boss] = await _generateTrack(
      musicDir, 'boss', _generateBossTrack(),
    );

    _initialized = true;
  }

  // ── Track generators ──────────────────────────────────────────────

  /// Soft C-major arpeggio, 80 BPM.
  List<double> _generateMenuTrack() {
    const sr = 22050;
    const bpm = 80.0;
    final beatDuration = 60.0 / bpm;
    // C4 E4 G4 C5 G4 E4
    final notes = [261.63, 329.63, 392.0, 523.25, 392.0, 329.63];
    final samples = <double>[];

    for (int bar = 0; bar < 16; bar++) {
      for (final note in notes) {
        final tone = generateTone(note, beatDuration * 0.8, sr, decay: 5.0);
        // Warm pad layer at half frequency.
        for (int i = 0; i < tone.length; i++) {
          final t = i / sr;
          tone[i] =
              tone[i] * 0.6 + sin(2 * pi * note * 0.5 * t) * 0.25 * exp(-2.0 * t);
        }
        samples.addAll(tone);
        // Small silence gap between notes.
        samples.addAll(List<double>.filled((beatDuration * 0.2 * sr).toInt(), 0.0));
      }
    }

    _normalise(samples, 0.35);
    return samples;
  }

  /// Bouncy G-major pentatonic, 140 BPM.
  List<double> _generateGameTrack() {
    const sr = 22050;
    const bpm = 140.0;
    final beatDuration = 60.0 / bpm;
    // G4 A4 B4 D5 E5 D5 B4 A4
    final notes = [392.0, 440.0, 493.88, 587.33, 659.25, 587.33, 493.88, 440.0];
    final samples = <double>[];

    for (int bar = 0; bar < 16; bar++) {
      for (final note in notes) {
        final tone = generateTone(note, beatDuration * 0.7, sr, decay: 4.0);
        // Sub-bass at quarter frequency.
        for (int i = 0; i < tone.length; i++) {
          final t = i / sr;
          tone[i] =
              tone[i] * 0.5 + sin(2 * pi * note * 0.25 * t) * 0.3 * exp(-3.0 * t);
        }
        samples.addAll(tone);
        samples.addAll(List<double>.filled((beatDuration * 0.3 * sr).toInt(), 0.0));
      }
    }

    _normalise(samples, 0.35);
    return samples;
  }

  /// Tense A-minor, 160 BPM.
  List<double> _generateBossTrack() {
    const sr = 22050;
    const bpm = 160.0;
    final beatDuration = 60.0 / bpm;
    // A3 C4 E4 A4 G#3 B3 E4 G#4
    final notes = [220.0, 261.63, 329.63, 440.0, 207.65, 246.94, 329.63, 415.3];
    final samples = <double>[];

    for (int bar = 0; bar < 16; bar++) {
      for (final note in notes) {
        final tone = generateTone(note, beatDuration * 0.75, sr, decay: 3.5);
        // Dark bass at half frequency.
        for (int i = 0; i < tone.length; i++) {
          final t = i / sr;
          tone[i] =
              tone[i] * 0.5 + sin(2 * pi * note * 0.5 * t) * 0.35 * exp(-2.5 * t);
        }
        samples.addAll(tone);
        samples.addAll(List<double>.filled((beatDuration * 0.25 * sr).toInt(), 0.0));
      }
    }

    _normalise(samples, 0.35);
    return samples;
  }

  // ── Helpers ────────────────────────────────────────────────────────

  /// Peak-normalise [samples] to [target] amplitude.
  void _normalise(List<double> samples, double target) {
    double maxAmp = 0;
    for (final s in samples) {
      final a = s.abs();
      if (a > maxAmp) maxAmp = a;
    }
    if (maxAmp > 0) {
      final scale = target / maxAmp;
      for (int i = 0; i < samples.length; i++) {
        samples[i] *= scale;
      }
    }
  }

  Future<String> _generateTrack(
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

  // ── Playback ───────────────────────────────────────────────────────

  /// Start playing [track] in a loop. If the same track is already playing
  /// this is a no-op.
  Future<void> play(MusicTrack track) async {
    if (!_enabled || !_initialized) return;
    if (_currentTrack == track && _player != null) return;

    await stop();

    final path = _trackPaths[track];
    if (path == null) return;

    try {
      _player = AudioPlayer();
      await _player!.setVolume(0.35);
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.play(DeviceFileSource(path));
      _currentTrack = track;
    } catch (_) {
      // Silently ignore — music is non-critical.
    }
  }

  /// Stop and release the current music player.
  Future<void> stop() async {
    try {
      await _player?.stop();
      await _player?.dispose();
    } catch (_) {
      // ignore
    }
    _player = null;
    _currentTrack = null;
  }

  /// Pause the current music (e.g. when the game is paused).
  Future<void> pause() async {
    try {
      await _player?.pause();
    } catch (_) {
      // ignore
    }
  }

  /// Resume paused music.
  Future<void> resume() async {
    if (_enabled) {
      try {
        await _player?.resume();
      } catch (_) {
        // ignore
      }
    }
  }
}
