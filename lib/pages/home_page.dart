import 'package:flutter/material.dart';
import 'package:senior_care/pages/auth/auth_service.dart';
import 'package:senior_care/pages/auth/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senior_care/pages/user_details_page.dart';

final AuthService _auth = AuthService();

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

@override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();

  Future<void> _sendInvitation() async {
    if (_emailController.text.isEmpty) return;
    if (currentUser == null) return;

    final String userEmail = _emailController.text.trim();

    try {
      var userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .where('role', isEqualTo: 'User')
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Nie znaleziono użytkownika o tym adresie e-mail.")),
        );
        return;
      }

      var userData = userQuery.docs.first.data();
      if (userData['linkedAdminId'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ten użytkownik jest już połączony z innym opiekunem.")),
          );
          return;
      }

      DocumentSnapshot adminData =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      String adminName = (adminData.data() as Map<String, dynamic>)['name'] ?? 'Opiekun';

      await _firestore.collection('invitations').add({
        'adminId': currentUser!.uid,
        'adminName': adminName,
        'userEmail': userEmail,
        'status': 'pending',
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Wysłano zaproszenie!")),
      );

    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Wystąpił błąd: $e")),
      );
    }
  }

  void _showInviteDialog() {
    _emailController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Zaproś podopiecznego"),
          content: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "E-mail podopiecznego",
              hintText: "jan@example.com",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Anuluj"),
            ),
            ElevatedButton(
              onPressed: _sendInvitation,
              child: Text("Wyślij"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Panel Admina"),
      ),
      body: LinkedUsersList(adminId: currentUser!.uid),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        icon: Icon(Icons.person_add),
        label: Text("Zaproś"),
      ),
    );
  }
}

class LinkedUsersList extends StatelessWidget {
  final String adminId;

  LinkedUsersList({Key? key, required this.adminId}) : super(key: key);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('linkedAdminId', isEqualTo: adminId)
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
            child: Text("Nie masz jeszcze żadnych podopiecznych."),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> userData = users[index].data() as Map<String, dynamic>;
            String userId = users[index].id;

            return ListTile(
              leading: Icon(Icons.person_outline),
              title: Text(userData['name'] ?? 'Brak nazwy'),
              subtitle: Text(userData['email'] ?? 'Brak e-maila'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:(context) => UserDetailsPage(
                      userId: userId,
                      userName: userData['name'] ?? 'Brak nazwy',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});
  @override
    State<UserScreen> createState() => _UserScreenState();
}
class _UserScreenState extends State<UserScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _acceptInvitation(String invitationId, String adminId) async {
    if (currentUser == null) return;
    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'linkedAdminId': adminId,
      });

      await _firestore.collection('invitations').doc(invitationId).update({
        'status': 'accepted',
      });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd podczas akceptacji: $e")),
      );
    }
  }

  Future<void> _declineInvitation(String invitationId) async {
    try {
      await _firestore.collection('invitations').doc(invitationId).update({
        'status': 'declined',
      });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd podczas odrzucania: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(body: Center(child: Text("Błąd logowania.")));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Mój Panel")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData) {
            return Center(child: Text("Błąd ładowania danych."));
          }

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;

          if (userData['linkedAdminId'] != null) {
            return Center(
              child: Text("Jesteś połączony! Tu będzie lista leków."),
            );
          } else {
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('invitations')
                  .where('userEmail', isEqualTo: currentUser!.email)
                  .where('status', isEqualTo: 'pending')
                  .limit(1)
                  .snapshots(),
              builder: (context, invSnapshot) {
                if (invSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!invSnapshot.hasData || invSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Nie jesteś połączony z żadnym opiekunem. Poproś opiekuna o wysłanie zaproszenia na Twój e-mail.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }

                var invitation = invSnapshot.data!.docs.first;
                String adminName = invitation.get('adminName');
                String adminId = invitation.get('adminId');
                String invitationId = invitation.id;

                return InvitationPending(
                  adminName: adminName,
                  onAccept: () => _acceptInvitation(invitationId, adminId),
                  onDecline: () => _declineInvitation(invitationId),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class InvitationPending extends StatelessWidget {
  final String adminName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const InvitationPending({
    Key? key,
    required this.adminName,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Zaproszenie", style: TextStyle(fontSize: 18, color: Colors.grey[700])),
              SizedBox(height: 15),
              Text(
                adminName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "chce się z Tobą połączyć.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 18, color: Colors.white),
                ),
                child: Text("Akceptuj"),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: onDecline,
                child: Text("Odrzuć", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        title: const Text("User Panel"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Witaj w panelu użytkownika!"),
            ElevatedButton(
              onPressed: () {
                _auth.signOut();
                print("Wylogowano pomyślnie.");
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              },
              child: const Text("Wyloguj się"),
            ),
          ],
        ),
      ),
    );
  }

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const LoginScreen();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Wystąpił błąd: ${snapshot.error}")),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Nie znaleziono danych użytkownika."),
                  ElevatedButton(
                    onPressed: () => _auth.signOut(),
                    child: Text("Wyloguj"),
                  )
                ],
              ),
            ),
          );
        }

        String role = (snapshot.data!.data() as Map<String, dynamic>)['role'];

        if (role == "Admin") {
          return const AdminScreen();
        } else {
          return const UserScreen();
        }
      },
    );
  }
}