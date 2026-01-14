import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _logUserIp(String username) async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        await FirebaseFirestore.instance.collection('access_logs').add({
          'user': username, 'ip': response.body, 'time': FieldValue.serverTimestamp(), 'status': 'Login Success'
        });
      }
    } catch (_) {}
  }

  void _login() async {
    String username = _usernameController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ المرجو ملء جميع الخانات")));
        return;
    }
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(username).get();
      if (!doc.exists) throw "اسم المستخدم غير موجود ❌";
      
      final data = doc.data() as Map<String, dynamic>;
      if (data['password'] != password) throw "كلمة السر خاطئة 🔑";
      if (data['isBlocked'] == true) throw "⛔ حسابك محظور!";
      if ((data['status'] ?? 'pending') == 'pending') throw "⏳ حسابك قيد المراجعة";

      bool isAdminUser = (data['status'] == 'admin');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);
      await prefs.setBool('isAdmin', isAdminUser);
      _logUserIp(username);

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(username: username, isAdmin: isAdminUser)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)), child: const Icon(Icons.chat_bubble_rounded, size: 60, color: Colors.white)),
                    const SizedBox(height: 20),
                    const Text("مرحباً بك مجدداً!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                      child: Column(
                        children: [
                          TextField(controller: _usernameController, decoration: InputDecoration(prefixIcon: const Icon(Icons.person, color: Color(0xFF6A11CB)), hintText: "اسم المستخدم", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                          const SizedBox(height: 16),
                          TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(prefixIcon: const Icon(Icons.lock, color: Color(0xFF6A11CB)), hintText: "كلمة السر", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                          const SizedBox(height: 24),
                          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("تسجيل الدخول", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("ما عندكش حساب؟ ", style: TextStyle(color: Colors.white)), GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text("أنشئ حساباً الآن", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)))]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}