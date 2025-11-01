import 'package:flutter/material.dart';
import 'auth_page.dart';

class FlashCardsScreen extends StatefulWidget {
  const FlashCardsScreen({super.key});

  @override
  State<FlashCardsScreen> createState() => _FlashCardsScreenState();
}

class _FlashCardsScreenState extends State<FlashCardsScreen> {
  final _controller = PageController();
  int _index = 0;

  // Palette
  static const Color kDeepGreen = Color(0xFF27463A);
  static const Color kCardIvory = Color(0xFFEDE7E3);
  static const Color kTextGreen = Color(0xFF2F503F);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final size = MediaQuery.of(context).size;

    // Where to place the dots so they don’t collide with panels/CTA
    double dotsBottom = 24 + padding.bottom; // default (page 1)
    if (_index == 1) {
      // page 2: panel comes from bottom; lift dots above it
      dotsBottom = (size.height * 0.30) + 16;
    } else if (_index == 2) {
      // page 3: keep above the CTA button
      dotsBottom = 24 + padding.bottom + 64;
    }

    return Scaffold(
      backgroundColor: kDeepGreen,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              physics: const BouncingScrollPhysics(),
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                // 1) Text on top (ivory), image below
                _cardTextOnTopImageBelow(
                  title: 'Greetings!',
                  subtitle:
                  'Join a global community\nturning small steps\ninto real change',
                  imageAsset: 'assets/illustrations/growth.png',
                ),

                // 2) Image on top, text on bottom (ivory) — with extra top padding
                _cardImageOnTopTextBottom(
                  title: 'Learn, Track, Compete!',
                  subtitle:
                  'Track your eco actions\nand earn points for every\neffort',
                  imageAsset: 'assets/illustrations/learn.png',
                  topPadding: 48, // Added padding gap on top
                ),

                // 3) Text on top (ivory), image below
                _cardTextOnTopImageBelow(
                  title: 'Grow Your Impact.',
                  subtitle:
                  'Level up, challenge\nfriends, and grow your\ngreen streak',
                  imageAsset: 'assets/illustrations/impact.png',
                ),
              ],
            ),

            // Page dots (position varies per page)
            Positioned(
              left: 0,
              right: 0,
              bottom: dotsBottom,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: active ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white70,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ),

            // Get Started CTA (only on last page)
            if (_index == 2)
              Positioned(
                left: 20,
                right: 20,
                bottom: 16 + padding.bottom,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kDeepGreen,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthPage()),
                    );
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Layout A: top ivory card (~28–32% height), image fills the rest.
  Widget _cardTextOnTopImageBelow({
    required String title,
    required String subtitle,
    required String imageAsset,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final topH = (c.maxHeight * 0.30).clamp(180.0, 240.0);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: SizedBox(
                height: topH,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
                  child: ClipPath(
                    clipper: _WaveBottomClipper(),
                    child: Container(
                      color: kCardIvory,
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: kTextGreen,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            subtitle,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.4,
                              color: kTextGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: double.infinity,
                  color: kDeepGreen,
                  alignment: Alignment.center,
                  child: Image.asset(
                    imageAsset,
                    height: (c.maxHeight * 0.34).clamp(240.0, 340.0),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Layout B: image on top, bottom ivory card (~28–32% height).
  Widget _cardImageOnTopTextBottom({
    required String title,
    required String subtitle,
    required String imageAsset,
    double topPadding = 28, // New optional parameter
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final bottomH =
        (c.maxHeight * 0.30).clamp(190.0, 250.0); // a touch taller
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  color: kDeepGreen,
                  child: Image.asset(
                    imageAsset,
                    height: (c.maxHeight * 0.34).clamp(240.0, 340.0),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: SizedBox(
                height: bottomH,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(26),
                    bottomRight: Radius.circular(26),
                  ),
                  child: ClipPath(
                    clipper: _WaveTopClipper(),
                    child: Container(
                      color: kCardIvory,
                      padding: EdgeInsets.fromLTRB(22, topPadding, 22, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: kTextGreen,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            subtitle,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 16.5,
                              height: 1.45,
                              color: kTextGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/* ------------------ clippers ------------------ */

class _WaveBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 52);
    p.quadraticBezierTo(
        size.width * 0.25, size.height - 10, size.width * 0.55, size.height - 26);
    p.quadraticBezierTo(
        size.width * 0.80, size.height - 42, size.width, size.height - 26);
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _WaveTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(0, 28);
    p.quadraticBezierTo(size.width * 0.18, 12, size.width * 0.50, 26);
    p.quadraticBezierTo(size.width * 0.82, 42, size.width, 26);
    p.lineTo(size.width, size.height);
    p.lineTo(0, size.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}