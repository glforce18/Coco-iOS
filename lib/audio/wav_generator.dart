import 'dart:math';
import 'dart:typed_data';

/// Generates a complete WAV file (header + PCM data) from raw samples.
///
/// [sampleRate] — samples per second (e.g. 22050).
/// [samples]   — normalised audio samples in the range [-1.0, 1.0].
Uint8List generateWav({required int sampleRate, required List<double> samples}) {
  final numSamples = samples.length;
  final byteRate = sampleRate * 2; // 16-bit mono
  final dataSize = numSamples * 2;
  final fileSize = 36 + dataSize;

  final buffer = ByteData(44 + dataSize);

  // RIFF header
  buffer.setUint32(0, 0x52494646, Endian.big); // "RIFF"
  buffer.setUint32(4, fileSize, Endian.little);
  buffer.setUint32(8, 0x57415645, Endian.big); // "WAVE"

  // fmt chunk
  buffer.setUint32(12, 0x666D7420, Endian.big); // "fmt "
  buffer.setUint32(16, 16, Endian.little); // chunk size
  buffer.setUint16(20, 1, Endian.little); // PCM format
  buffer.setUint16(22, 1, Endian.little); // mono
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, byteRate, Endian.little);
  buffer.setUint16(32, 2, Endian.little); // block align
  buffer.setUint16(34, 16, Endian.little); // bits per sample

  // data chunk
  buffer.setUint32(36, 0x64617461, Endian.big); // "data"
  buffer.setUint32(40, dataSize, Endian.little);

  for (int i = 0; i < numSamples; i++) {
    final sample = (samples[i] * 32767).clamp(-32768, 32767).toInt();
    buffer.setInt16(44 + i * 2, sample, Endian.little);
  }

  return buffer.buffer.asUint8List();
}

/// Generates a single tone with exponential decay.
List<double> generateTone(
  double freq,
  double durationSec,
  int sampleRate, {
  double decay = 3.0,
}) {
  final numSamples = (sampleRate * durationSec).toInt();
  return List<double>.generate(numSamples, (i) {
    final t = i / sampleRate;
    final envelope = exp(-decay * t);
    return sin(2 * pi * freq * t) * envelope * 0.5;
  });
}

/// Generates a frequency sweep from [freqStart] to [freqEnd].
List<double> generateSweep(
  double freqStart,
  double freqEnd,
  double durationSec,
  int sampleRate,
) {
  final numSamples = (sampleRate * durationSec).toInt();
  return List<double>.generate(numSamples, (i) {
    final t = i / sampleRate;
    final progress = t / durationSec;
    final freq = freqStart + (freqEnd - freqStart) * progress;
    final envelope = exp(-2.5 * t);
    return sin(2 * pi * freq * t) * envelope * 0.5;
  });
}

/// Generates a chord — multiple simultaneous tones mixed together.
List<double> generateChord(
  List<double> freqs,
  double durationSec,
  int sampleRate,
) {
  final numSamples = (sampleRate * durationSec).toInt();
  return List<double>.generate(numSamples, (i) {
    final t = i / sampleRate;
    final envelope = exp(-3.0 * t);
    double sum = 0;
    for (final freq in freqs) {
      sum += sin(2 * pi * freq * t);
    }
    return (sum / freqs.length) * envelope * 0.5;
  });
}

/// Generates a note sequence — notes played one after another.
List<double> generateSequence(
  List<double> freqs,
  double noteDurationSec,
  int sampleRate, {
  double decay = 4.0,
}) {
  final samples = <double>[];
  for (final freq in freqs) {
    samples.addAll(generateTone(freq, noteDurationSec, sampleRate, decay: decay));
  }
  return samples;
}
