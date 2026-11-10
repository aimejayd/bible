import 'package:flutter/material.dart';

import 'theme.dart';

/// Branded start screen. The mark sits exactly where the Android splash draws
/// it, so the hand-over from the system splash is seamless; the name and
/// tagline then fade in underneath.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final Animation<double> _mark = CurvedAnimation(parent: _controller, curve: const Interval(0, .55, curve: Curves.easeOutBack));
  late final Animation<double> _words = CurvedAnimation(parent: _controller, curve: const Interval(.35, 1, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Brand.green,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(colors: [Color(0xFF285F52), Brand.green, Brand.greenDeep], stops: [0, .55, 1], radius: 1.1),
                ),
              ),
            ),
            ScaleTransition(
              scale: Tween<double>(begin: .92, end: 1).animate(_mark),
              child: Image.asset('assets/brand/mark.png', width: 128, height: 128),
            ),
            Transform.translate(
              offset: const Offset(0, 118),
              child: FadeTransition(
                opacity: _words,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, .4), end: Offset.zero).animate(_words),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('IJAMBO', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 9, decoration: TextDecoration.none)),
                      SizedBox(height: 10),
                      SizedBox(width: 36, child: Divider(color: Brand.gold, thickness: 2, height: 2)),
                      SizedBox(height: 12),
                      Text('Holy Bible  ·  La Bible  ·  Bibiliya Yera',
                          style: TextStyle(color: Color(0xFFE6D5AE), fontSize: 13, letterSpacing: .6, fontWeight: FontWeight.w500, decoration: TextDecoration.none)),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: 40,
              child: Text('Ijambo ry’Imana',
                  style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13, fontStyle: FontStyle.italic, fontFamily: scriptureFont, decoration: TextDecoration.none)),
            ),
          ],
        ),
      );
}
