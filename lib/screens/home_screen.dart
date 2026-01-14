import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final bool isAdmin;
  const HomeScreen({super.key, required this.username, required this.isAdmin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const LoginScreen()), 
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // لون التاب بار حسب واش آدمين ولا لا
    Color accentColor = widget.isAdmin ? const Color(0xFFB71C1C) : const Color(0xFF6A11CB);

    return DefaultTabController(
      length: 2, // عدد الغرف
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            "Chat Ben Msik 🔥", 
            style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)
          ),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.logout, color: Colors.black), onPressed: _logout)
          ],
          // ✅ التاب بار العصري (Tabs)
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: accentColor, // اللون المختار
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "🌍 العامة"),
                  Tab(text: "☠️ Ratt"),
                ],
              ),
            ),
          ),
        ),
        
        // ✅ هنا فين كاين الـ Scroll (Swipe)
        body: TabBarView(
          children: [
            // الغرفة 1
            ChatScreen(
              key: const PageStorageKey('general'),
              username: widget.username, 
              collectionId: 'messages_general', 
              isAdmin: widget.isAdmin
            ),
            // الغرفة 2
            ChatScreen(
              key: const PageStorageKey('ratt'),
              username: widget.username, 
              collectionId: 'messages_ratt', 
              isAdmin: widget.isAdmin
            ),
          ],
        ),
      ),
    );
  }
}