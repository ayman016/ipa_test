import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'admin_screen.dart';

class ChatScreen extends StatefulWidget {
  final String username;
  final String collectionId;
  final bool isAdmin;

  const ChatScreen({super.key, required this.username, required this.collectionId, required this.isAdmin});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin {
  // ✅ زدنا هاد Mixin باش فاش تقلب الصفحة وترجع، الشات يبقى فبلاصتو ما يتعاودش يتحمل
  @override
  bool get wantKeepAlive => true;

  final _msgController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription? _blockListener;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (!widget.isAdmin) _listenToBlockStatus();
  }

  void _listenToBlockStatus() {
    _blockListener = _firestore.collection('users').doc(widget.username).snapshots().listen((snapshot) async {
      if (snapshot.exists && snapshot.data()?['isBlocked'] == true) {
        _blockListener?.cancel();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
        }
      }
    });
  }

  @override
  void dispose() {
    _blockListener?.cancel();
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 30);
      if (pickedFile != null) {
        setState(() => _isUploading = true);
        File imageFile = File(pickedFile.path);
        Uint8List imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        _sendMessage(imageBase64: base64Image);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Wrap(children: [
        ListTile(leading: const Icon(Icons.photo_library, color: Colors.purple), title: Text('المعرض', style: GoogleFonts.cairo()), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
        ListTile(leading: const Icon(Icons.camera_alt, color: Colors.purple), title: Text('الكاميرا', style: GoogleFonts.cairo()), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); })
      ])),
    );
  }

  void _sendMessage({String? imageBase64}) async {
    if (_msgController.text.trim().isEmpty && imageBase64 == null) return;
    try {
      await _firestore.collection(widget.collectionId).add({
        'text': _msgController.text,
        'imageBase64': imageBase64,
        'sender': widget.username,
        'createdAt': FieldValue.serverTimestamp(),
        'isOfficial': widget.isAdmin,
      });
      _msgController.clear();
    } catch (_) {}
  }

  void _deleteMessage(String docId) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("حذف"), content: const Text("مسح هاد الميساج؟"), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("لا")), TextButton(onPressed: (){_firestore.collection(widget.collectionId).doc(docId).delete(); Navigator.pop(ctx);}, child: const Text("نعم"))]));
  }

  void _viewImageFullScreen(String base64String) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)), body: Center(child: InteractiveViewer(child: Image.memory(base64Decode(base64String)))))));
  }

  Color _getAvatarColor(String username) {
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    return colors[username.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ضروري لـ KeepAlive
    bool isRatt = widget.collectionId.contains('ratt');
    Color themeColor = isRatt ? Colors.grey[800]! : (widget.isAdmin ? const Color(0xFFB71C1C) : const Color(0xFF6A11CB));
    Color bgColor = isRatt ? const Color(0xFF121212) : const Color(0xFFF0F2F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // شريط الآدمين
          if (widget.isAdmin) 
            InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8), color: Colors.red[50], child: Center(child: Text("🔐 الدخول إلى لوحة التحكم", style: GoogleFonts.cairo(color: Colors.red[900], fontWeight: FontWeight.bold))))),
          
          if (_isUploading) const LinearProgressIndicator(color: Colors.purple),

          // ✅ هنا الإصلاح: Expanded كتضمن أن الشات ياخد المساحة كاملة
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection(widget.collectionId).orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("وقع خطأ: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final messages = snapshot.data!.docs;
                if (messages.isEmpty) return Center(child: Text("ما كاين حتى ميساج، بدا نتا اللول!", style: GoogleFonts.cairo(color: Colors.grey)));

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final data = msg.data() as Map<String, dynamic>;
                    final isMe = data['sender'] == widget.username;
                    final isOfficial = data['isOfficial'] ?? false;
                    Timestamp? ts = data['createdAt'];
                    String time = ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : "..";

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[CircleAvatar(radius: 14, backgroundColor: _getAvatarColor(data['sender']), child: Text(data['sender'][0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))), const SizedBox(width: 5)],
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!isMe) Padding(padding: const EdgeInsets.only(left: 12, bottom: 2), child: Text(data['sender'], style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                                GestureDetector(
                                  onLongPress: widget.isAdmin ? () => _deleteMessage(msg.id) : null,
                                  child: data['imageBase64'] != null
                                      ? GestureDetector(onTap: () => _viewImageFullScreen(data['imageBase64']), child: Container(margin: const EdgeInsets.only(bottom: 5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: isOfficial ? Border.all(color: Colors.red, width: 2) : null), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.memory(base64Decode(data['imageBase64']), height: 200, width: 200, fit: BoxFit.cover))))
                                      : BubbleSpecialThree(text: data['text'] ?? "", color: isMe ? (isOfficial ? Colors.red[800]! : const Color(0xFF6A11CB)) : (isRatt ? Colors.grey[800]! : Colors.white), tail: true, textStyle: GoogleFonts.cairo(color: isMe ? Colors.white : (isRatt ? Colors.white : Colors.black87), fontSize: 16), isSender: isMe),
                                ),
                                Padding(padding: const EdgeInsets.only(top: 2, left: 10, right: 10), child: Text(time, style: TextStyle(fontSize: 9, color: isRatt ? Colors.grey[600] : Colors.grey[500]))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ✅ خانة الكتابة (بقات لتحت حيت خرجناها من Expanded)
          Container(
            padding: const EdgeInsets.all(10),
            color: isRatt ? Colors.black : Colors.white,
            child: Row(children: [
              IconButton(icon: Icon(Icons.add_a_photo, color: themeColor), onPressed: _showImageSourceActionSheet),
              Expanded(child: TextField(controller: _msgController, style: GoogleFonts.cairo(color: isRatt ? Colors.white : Colors.black), decoration: InputDecoration(hintText: "...", hintStyle: TextStyle(color: Colors.grey), filled: true, fillColor: isRatt ? Colors.grey[900] : Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)))),
              const SizedBox(width: 5),
              CircleAvatar(backgroundColor: themeColor, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: () => _sendMessage()))
            ]),
          ),
        ],
      ),
    );
  }
}