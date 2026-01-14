import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // ✅ المكتبة
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  final String? username;
  final bool isAdmin;

  const SplashScreen({
    super.key, 
    required this.isLoggedIn, 
    this.username, 
    required this.isAdmin
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // ✅ هنا كنتسناو 5 ثواني (باش الأنيماسيون تكمل على خاطرها)
    Timer(const Duration(seconds: 5), _navigateNext);
  }

  void _navigateNext() {
    // اللوجيك: واش نمشيو للدار ولا للدخول
    if (widget.isLoggedIn && widget.username != null) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => HomeScreen(username: widget.username!, isAdmin: widget.isAdmin))
      );
    } else {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const LoginScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ درنا البيض باش تبان الأنيماسيون مزيان (تقدر تردها موف إلا بغيتي)
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔥🔥 هنا فين كنعرضو الملف ديالك 🔥🔥
            Lottie.asset(
              'assets/splash.json', 
              width: 300, 
              height: 300,
              fit: BoxFit.contain,
            ),
            
            const SizedBox(height: 20),
            
            Text(
              "Chat Ben Msik",
              style: GoogleFonts.cairo(
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                color: Colors.purple[800]
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Loading...",
              style: TextStyle(color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }
}