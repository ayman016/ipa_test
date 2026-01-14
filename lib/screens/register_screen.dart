import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    String username = _usernameController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty || password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ تأكد من ملء البيانات (كلمة السر +4 حروف)")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(username);
      final doc = await userRef.get();
      if (doc.exists) throw "❌ هذا الاسم مستخدم بالفعل";

      await userRef.set({
        'password': password,
        'status': 'pending',
        'isBlocked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم إرسال طلبك! انتظر الموافقة."), backgroundColor: Colors.green));
        Navigator.pop(context);
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context))),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity, height: double.infinity,
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF2575FC), Color(0xFF6A11CB)])),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Icon(Icons.person_add_rounded, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text("إنشاء حساب جديد", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: Column(
                      children: [
                        TextField(controller: _usernameController, decoration: InputDecoration(prefixIcon: const Icon(Icons.account_circle, color: Color(0xFF2575FC)), hintText: "اختر اسم مستخدم", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                        const SizedBox(height: 16),
                        TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFF2575FC)), hintText: "كلمة السر", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                        const SizedBox(height: 24),
                        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _register, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2575FC), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("إرسال الطلب", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                      ],
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