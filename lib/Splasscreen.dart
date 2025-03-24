import 'package:flutter/material.dart';
import 'package:guide_me/home.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  bool _moveLogo = false;
  bool _showText = false;
  bool _hideSplash = false; // Menyembunyikan SplashScreen saat transisi mulai

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _moveLogo = true;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _showText = true;
        });
      });
    });

    // Navigasi ke Home setelah 3 detik
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _hideSplash = true; // Langsung hilangkan tampilan SplashScreen
        });

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0), // Mulai dari kanan
                  end: Offset.zero, // Masuk ke tengah
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut, // Gerakan lebih halus
                )),
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  Widget buildSplashScreenContent() {
    return Opacity(
      opacity: _hideSplash ? 0.0 : 1.0, 
      child: Stack(
        children: [
         
          Positioned.fill(
            child: Container(
              color: Colors.green,
              height: MediaQuery.of(context).size.height * 0.2,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            left: _moveLogo
                ? MediaQuery.of(context).size.width * 0.3
                : MediaQuery.of(context).size.width * 0.5 - 40,
            top: MediaQuery.of(context).size.height * 0.25,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo5.png',
                  width: 80,
                  height: 80,
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _showText ? 1.0 : 0.0,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      'Guide ME',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Awan mulai dari setengah layar dan naik bertahap seperti anak tangga
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: double.infinity,
              child: CustomPaint(
                painter: CloudPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildSplashScreenContent(),
    );
  }
}

class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.white;
    Path path = Path();

    double width = size.width;
    double height = size.height;
    double baseHeight = height * 0.8; // Awal awan di setengah layar
    double stepWidth = width / 5; // 5 bagian untuk efek naik bertahap
    double stepHeight = height * 0.1; // Setiap langkah naik bertahap

    path.moveTo(0, baseHeight);

    for (int i = 0; i < 5; i++) {
      double startX = i * stepWidth;
      double currentHeight = baseHeight - (i * stepHeight);
      
      path.quadraticBezierTo(
        startX + stepWidth / 2, currentHeight - stepHeight / 2, 
        startX + stepWidth, currentHeight
      );
    }

    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
