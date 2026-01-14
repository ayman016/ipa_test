import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _confirmToggleBlock(BuildContext context, DocumentSnapshot userDoc) {
    bool currentStatus = userDoc['isBlocked'] ?? false;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(currentStatus ? "فك الحظر" : "تأكيد الحظر ⛔"),
        content: Text("واش متأكد باغي ${currentStatus ? 'تفك الحظر على' : 'تبلوكي'} المستخدم ${userDoc.id}؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: currentStatus ? Colors.green : Colors.red),
            onPressed: () {
              userDoc.reference.update({'isBlocked': !currentStatus});
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(currentStatus ? "✅ تم فك الحظر" : "⛔ تم الحظر بنجاح")));
            },
            child: Text(currentStatus ? "فك الحظر" : "بلوكي"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إدارة الأعضاء"), backgroundColor: Colors.red[900], foregroundColor: Colors.white),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs;
          final pendingUsers = users.where((u) => u['status'] == 'pending').toList();
          final activeUsers = users.where((u) => u['status'] == 'approved').toList();

          return ListView(
            padding: const EdgeInsets.all(10),
            children: [
              if (pendingUsers.isNotEmpty) ...[
                const Padding(padding: EdgeInsets.all(8.0), child: Text("⏳ طلبات الانتظار", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange))),
                ...pendingUsers.map((user) => Card(elevation: 3, child: ListTile(leading: const Icon(Icons.person_add_alt_1, color: Colors.orange), title: Text(user.id, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("تاريخ الطلب: ${user['createdAt']?.toDate().toString().substring(0, 16) ?? 'N/A'}"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(tooltip: "قبول", icon: const Icon(Icons.check_circle, color: Colors.green, size: 30), onPressed: () => user.reference.update({'status': 'approved'})), IconButton(tooltip: "رفض وحذف", icon: const Icon(Icons.cancel, color: Colors.red, size: 30), onPressed: () => user.reference.delete())])))),
                const Divider(height: 30, thickness: 2),
              ],
              const Padding(padding: EdgeInsets.all(8.0), child: Text("👥 الأعضاء المسجلون", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple))),
              ...activeUsers.map((user) {
                 bool isBlocked = user['isBlocked'] ?? false;
                 return Card(color: isBlocked ? Colors.red[50] : Colors.white, child: ListTile(leading: Icon(Icons.person, color: isBlocked ? Colors.red : Colors.purple), title: Text(user.id, style: TextStyle(fontWeight: FontWeight.bold, decoration: isBlocked ? TextDecoration.lineThrough : null)), subtitle: Text(isBlocked ? "⛔ محظور" : "✅ نشيط", style: TextStyle(color: isBlocked ? Colors.red : Colors.green)), trailing: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: isBlocked ? Colors.green : Colors.red, foregroundColor: Colors.white), icon: Icon(isBlocked ? Icons.lock_open : Icons.block), label: Text(isBlocked ? "فك الحظر" : "حظر"), onPressed: () => _confirmToggleBlock(context, user))));
              }),
            ],
          );
        },
      ),
    );
  }
}