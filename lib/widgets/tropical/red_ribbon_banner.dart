import 'package:flutter/material.dart';

/// Premium red velvet ribbon banner with gold trim and dual tassels.
/// Used as section title on YUVA / ADALAR / TEBRİKLER screens — matches
/// reference SS in /root/foto/yeni/.
///
/// Renders a "carved" 3D ribbon shape with:
///   - red velvet body w/ vertical gradient
///   - top + bottom gold trim
///   - 2 hanging tassels at bottom-left and bottom-right
///   - gold-on-dark text with subtle drop shadow
class RedRibbonBanner extends StatelessWidget {
  final String text;
  final double height;
  final double fontSize;
  final double horizontalPadding;

  const RedRibbonBanner({
    super.key,
    required this.text,
    this.height = 64,
    this.fontSize = 32,
    this.horizontalPadding = 28,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + 18, // room for tassel drop
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Tassels first (so ribbon shadow can sit above them visually)
          Positioned(
            left: 4,
            top: height - 4,
            child: _Tassel(height: 22),
          ),
          Positioned(
            right: 4,
            top: height - 4,
            child: _Tassel(height: 22),
          ),
          // Main ribbon body
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE85A5A),
                  Color(0xFFC22929),
                  Color(0xFF8B0F0F),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD56F),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFFFFD56F).withValues(alpha: 0.45),
                  blurRadius: 18,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Center(
              child: _GoldText(
                text: text,
                fontSize: fontSize,
              ),
            ),
          ),
          // Left fold (small triangle behind ribbon, darker red)
          Positioned(
            left: 0,
            top: height * 0.35,
            child: ClipPath(
              clipper: _LeftFoldClipper(),
              child: Container(
                width: 24,
                height: 28,
                color: const Color(0xFF6B0B0B),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: height * 0.35,
            child: ClipPath(
              clipper: _RightFoldClipper(),
              child: Container(
                width: 24,
                height: 28,
                color: const Color(0xFF6B0B0B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold gradient text with brown outline — matches reference ribbon text.
class _GoldText extends StatelessWidget {
  final String text;
  final double fontSize;
  const _GoldText({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outline (drawn underneath via stroke)
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            height: 1.0,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = const Color(0xFF3A1A0A),
          ),
        ),
        // Gold fill
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF6B0),
              Color(0xFFFFCB3D),
              Color(0xFFC9890A),
            ],
            stops: [0.0, 0.55, 1.0],
          ).createShader(rect),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              height: 1.0,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Color(0xCC2A1810),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Tassel extends StatelessWidget {
  final double height;
  const _Tassel({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 3 hanging strings
          for (int i = 0; i < 3; i++)
            Positioned(
              left: 8 + i * 6.0,
              top: 0,
              child: Container(
                width: 2,
                height: height * 0.7,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFCB3D), Color(0xFFB8860B)],
                  ),
                ),
              ),
            ),
          // Bottom gold bell shape
          Positioned(
            bottom: 0,
            child: Container(
              width: 18,
              height: height * 0.5,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFE89C),
                    Color(0xFFE8A317),
                    Color(0xFF9E6A0A),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftFoldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_) => false;
}

class _RightFoldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height * 0.5)
      ..close();
  }

  @override
  bool shouldReclip(_) => false;
}
