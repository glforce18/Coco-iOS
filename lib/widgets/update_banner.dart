import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/services/update_checker.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

/// Mounted at the MaterialApp `builder` level so it shows on top of
/// every screen. Polls [UpdateChecker] once on first build and surfaces:
///   • Soft update → dismissable top banner sliding in from above.
///   • Force update → modal blocking the entire UI.
class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({super.key});

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner>
    with SingleTickerProviderStateMixin {
  UpdateCheckResult? _result;
  bool _dismissed = false;
  late final AnimationController _slide;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _runCheck();
  }

  Future<void> _runCheck() async {
    // Tiny delay so the splash screen + initial routes settle.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final result = await UpdateChecker.instance.check();
    if (!mounted || !result.hasUpdate) return;

    // Suppress soft-update banner if we already nudged the user about
    // this exact version and they tapped "Sonra" on it.
    final progress = ref.read(playerProgressProvider);
    if (result.kind == UpdateKind.softUpdate &&
        progress.lastSeenUpdateVersion == result.latestVersion) {
      return;
    }

    setState(() => _result = result);
    _slide.forward();
  }

  Future<void> _openStore() async {
    final url = _result?.storeUrl ?? '';
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _dismiss() async {
    final r = _result;
    if (r == null) return;
    await ref
        .read(playerProgressProvider.notifier)
        .markUpdateBannerSeen(r.latestVersion);
    await _slide.reverse();
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    if (r == null || _dismissed) return const SizedBox.shrink();
    if (r.isForced) return _ForceModal(result: r, onUpdate: _openStore);

    // Soft update — slide-in banner anchored to the top safe-area.
    return SafeArea(
      child: AnimatedBuilder(
        animation: _slide,
        builder: (_, __) {
          final t = Curves.easeOutCubic.transform(_slide.value);
          return Transform.translate(
            offset: Offset(0, (1 - t) * -120),
            child: Opacity(
              opacity: t,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _SoftBanner(
                  result: r,
                  onUpdate: _openStore,
                  onDismiss: _dismiss,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SoftBanner extends StatelessWidget {
  final UpdateCheckResult result;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  const _SoftBanner({
    required this.result,
    required this.onUpdate,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.goldShine, TT.gold, TT.goldDeep],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(170), blurRadius: 14, offset: const Offset(0, 4)),
          BoxShadow(color: TT.gold.withAlpha(160), blurRadius: 18, spreadRadius: -2),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TT.driftWoodDark, Color(0xFF3D2712)],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TT.coralLight, TT.coral, TT.coralDark],
                ),
                boxShadow: [
                  BoxShadow(color: TT.coral.withAlpha(180), blurRadius: 10, spreadRadius: -1),
                ],
              ),
              child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Yeni sürüm var: ${result.latestVersion}',
                    style: TT.titleSmall.copyWith(
                      color: TT.goldShine,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.black.withAlpha(220), blurRadius: 3, offset: const Offset(0, 1)),
                      ],
                    ),
                  ),
                  if (result.notes.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      result.notes,
                      style: TT.bodySmall.copyWith(color: TT.sandLight.withAlpha(220), fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                backgroundColor: TT.palm,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onUpdate,
              child: const Text(
                'GÜNCELLE',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.6, fontSize: 12),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
              onPressed: onDismiss,
              splashRadius: 18,
              tooltip: 'Kapat',
            ),
          ],
        ),
      ),
    );
  }
}

class _ForceModal extends StatelessWidget {
  final UpdateCheckResult result;
  final VoidCallback onUpdate;

  const _ForceModal({required this.result, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(220),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [TT.goldShine, TT.gold, TT.goldDeep],
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(220), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TT.driftWoodDark, Color(0xFF3D2712)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [TT.coralLight, TT.coral, TT.coralDark],
                      ),
                      boxShadow: [
                        BoxShadow(color: TT.coral.withAlpha(180), blurRadius: 18, spreadRadius: 1),
                      ],
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Güncelleme Gerekli',
                    style: TT.titleLarge.copyWith(
                      color: TT.goldShine,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Eski sürümü kullanıyorsun. Devam etmek için yeni sürümü indir.',
                    textAlign: TextAlign.center,
                    style: TT.bodyMedium.copyWith(color: TT.sandLight.withAlpha(220)),
                  ),
                  if (result.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black.withAlpha(120),
                      ),
                      child: Text(
                        result.notes,
                        textAlign: TextAlign.center,
                        style: TT.bodySmall.copyWith(color: TT.goldShine.withAlpha(230)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withAlpha(120),
                    ),
                    child: Text(
                      'Sürümün: ${result.currentVersion} • Yeni: ${result.latestVersion}',
                      style: TT.bodySmall.copyWith(color: TT.sandLight.withAlpha(180), fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: TT.palm,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: onUpdate,
                      child: const Text(
                        'ŞIMDI GÜNCELLE',
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
