import 'dart:ui';
import 'package:flutter/material.dart';
import 'loginpage.dart';

// TL;DR: shows the logo, fades it in, chills for ~4s, then brigns you to LoginPage.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // wait a blink, then start the fade-in
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return; // guard: if we already left this screen, do nothing
      setState(() => _opacity = 1.0);
    });

    // give the splash a moment to vibe, then hop to LoginPage
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  // lil helper: draws a big blurry circle (“blob”) wherever you tell it to
  Widget _blob({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 60,
          sigmaY: 60,
        ), // extra soft edges
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.55), // make it see-through so it blends
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // background = gentle diagonal gradient; easy on the eyes
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0F7FA), Color(0xFFF1F8E9)],
              ),
            ),
          ),

          // sprinkle a few soft blobs to add depth, like bokeh lights
          _blob(top: -60, left: -40, size: 200, color: const Color(0xFF81D4FA)),
          _blob(
            bottom: -50,
            right: -30,
            size: 180,
            color: const Color(0xFFA5D6A7),
          ),
          _blob(
            top: 150,
            right: -50,
            size: 160,
            color: const Color(0xFFFFF59D),
          ),

          // the main show: logo + app name + tiny loading bar
          Center(
            child: AnimatedOpacity(
              // this does the smooth “fade in” once _opacity flips to 1.0
              duration: const Duration(seconds: 2),
              opacity: _opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // glassy card for the logo; rounded + a soft drop shadow
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 12),
                          blurRadius: 30,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/logo.png', // toss logo here
                        width: 250,
                        height: 250,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // app name—bold so it feels “brand-y”
                  Text(
                    'PhysioCare',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // skinny progress bar: purely to signal “loading…”
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: theme.colorScheme.onSurface
                            .withOpacity(0.08),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
