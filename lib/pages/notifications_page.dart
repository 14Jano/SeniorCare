import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    if (currentUser == null) return;

    try {
      QuerySnapshot unreadNotifications = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      
      print("Oznaczono ${unreadNotifications.docs.length} powiadomień jako przeczytane.");

    } catch (e) {
      print("Błąd podczas oznaczania powiadomień jako przeczytane: $e");
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    var date = timestamp.toDate();
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(body: Center(child: Text("Błąd: Brak użytkownika.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Powiadomienia"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Wystąpił błąd: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Brak powiadomień.",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];
              var data = notification.data() as Map<String, dynamic>;

              bool isRead = data['isRead'] ?? true;
              Timestamp createdAt = data['createdAt'] ?? Timestamp.now();

              return ListTile(
                leading: Icon(
                  isRead ? Icons.notifications_none : Icons.notifications_active,
                  color: isRead ? Colors.grey : Theme.of(context).primaryColor,
                ),
                title: Text(
                  data['title'] ?? 'Brak tytułu',
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "${data['body'] ?? ''}\n${_formatTimestamp(createdAt)}",
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}