import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart'; // تأكد أن هاد الملف عندك
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final prefs = await SharedPreferences.getInstance();
  final String? savedUsername = prefs.getString('username');
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final bool isAdmin = prefs.getBool('isAdmin') ?? false;
  runApp(MyApp(
    isLoggedIn: isLoggedIn, 
    username: savedUsername, 
    isAdmin: isAdmin
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? username;
  final bool isAdmin;

  const MyApp({super.key, required this.isLoggedIn, this.username, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat Ben Msik',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.purple,
      ),
      home: isLoggedIn && username != null 
          ? HomeScreen(username: username!, isAdmin: isAdmin) 
          : const LoginScreen(),
    );
  }
}