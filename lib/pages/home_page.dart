import 'package:flutter/material.dart';
import 'package:senior_care/pages/auth/auth_service.dart';
import 'package:senior_care/pages/auth/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senior_care/pages/user_details_page.dart';
import 'package:senior_care/pages/notifications_page.dart';

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

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _runMissedMedicationCheck();
    }
  }
  
Future<void> _runMissedMedicationCheck() async {
    if (currentUser == null) return;
    print("Uruchamiam SPRAWDZANIE RETROAKTYWNE pominiętych leków...");

    try {
      DocumentSnapshot adminDoc = await _firestore.collection('users').doc(currentUser!.uid).get();
      DateTime cutoff = DateTime.now().subtract(Duration(hours: 3));

      if ((adminDoc.data() as Map<String, dynamic>).containsKey('lastMissedCheck')) {
        DateTime lastCheckTime = (adminDoc.get('lastMissedCheck') as Timestamp).toDate();
        if (lastCheckTime.isAfter(cutoff)) {
          print("Sprawdzano niedawno (mniej niż 3h temu). Pomijam.");
          return;
        }
      }

      QuerySnapshot linkedUsers = await _firestore
          .collection('users')
          .where('linkedAdminId', isEqualTo: currentUser!.uid)
          .get();
      
      if (linkedUsers.docs.isEmpty) return;

      int hour = DateTime.now().hour;
      List<String> schedulesToCheck = [];
      
      if (hour >= 10) schedulesToCheck.add("Rano");
      if (hour >= 15) schedulesToCheck.add("Południe");
      if (hour >= 21) schedulesToCheck.add("Wieczór");

      if (schedulesToCheck.isEmpty) {
        print("Za wcześnie na sprawdzanie jakichkolwiek harmonogramów.");
        return;
      }
      print("Sprawdzam zaległości dla: $schedulesToCheck");

      for (var userDoc in linkedUsers.docs) {
        String userName = userDoc.get('name');
        String userId = userDoc.id;

        for (String schedule in schedulesToCheck) {
          
          DateTime startOfToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          
          QuerySnapshot existingAlerts = await _firestore
              .collection('users')
              .doc(currentUser!.uid)
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('schedule', isEqualTo: schedule)
              .where('createdAt', isGreaterThanOrEqualTo: startOfToday)
              .get();

          if (existingAlerts.docs.isEmpty) {
            
            QuerySnapshot missedMeds = await _firestore
                .collection('users')
                .doc(userId)
                .collection('medications')
                .where('scheduleTime', isEqualTo: schedule)
                .where('isTaken', isEqualTo: false)
                .get();

            if (missedMeds.docs.isNotEmpty) {
              print("Użytkownik $userName pominął $schedule! Wysyłam alert.");
              await _createMissedNotification(
                adminId: currentUser!.uid,
                userName: userName,
                schedule: schedule,
                missedCount: missedMeds.docs.length,
                userId: userId,
              );
            }
          } else {
            print("Alert dla $userName ($schedule) został już wysłany dzisiaj. Pomijam.");
          }
        }
      }

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'lastMissedCheck': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print("Błąd podczas sprawdzania pominiętych leków: $e");
    }
  }

  Future<void> _createMissedNotification({
    required String adminId,
    required String userName,
    required String schedule,
    required int missedCount,
    required String userId,
  }) async {
    await _firestore
        .collection('users')
        .doc(adminId)
        .collection('notifications')
        .add({
          'title': "⚠️ $userName pominął leki!",
          'body': "Wykryto $missedCount pominiętych leków z harmonogramu '$schedule'.",
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'schedule': schedule,
          'userId': userId,
        });
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Panel Opiekuna"),
            if (currentUser != null)
              Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
        actions: [
        // 🔔 POWIADOMIENIA
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(currentUser!.uid)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              unreadCount = snapshot.data!.docs.length;
            }
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsPage(),
                      ),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

          // 🚪 WYLOGOWANIE
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Wyloguj się",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
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

  Future<void> _showUnlinkConfirmationDialog(BuildContext context, String userId, String userName) async {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text("Potwierdzenie"),
          content: Text("Czy na pewno chcesz usunąć podopiecznego: $userName?"),
          actions: [
            TextButton(
              child: Text("Anuluj"),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: Text("Usuń", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await _firestore
                      .collection('users')
                      .doc(userId)
                      .update({'linkedAdminId': null});
                  Navigator.of(ctx).pop();
                } catch (e) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Wystąpił błąd: $e")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

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
              onLongPress: () {
                _showUnlinkConfirmationDialog(context, userId, userData['name'] ?? 'Brak nazwy');
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
  bool _isResetting = true;

@override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _checkAndResetMeds();
    } else {
      setState(() {
        _isResetting = false;
      });
    }
  }
  Future<void> _checkAndResetMeds() async {
      try {
        DocumentReference userDocRef = _firestore.collection('users').doc(currentUser!.uid);
        DocumentSnapshot userDoc = await userDocRef.get();

        Timestamp? lastReset = (userDoc.data() as Map<String, dynamic>)['lastResetDate'];
        
        bool needsReset = false;
        if (lastReset == null) {
          needsReset = true;
        } else {
          DateTime lastResetDate = lastReset.toDate();
          DateTime now = DateTime.now();
          DateTime startOfToday = DateTime(now.year, now.month, now.day); // Dziś o północy

          if (lastResetDate.isBefore(startOfToday)) {
            needsReset = true;
          }
        }

        if (needsReset) {
          print("Wykryto potrzebę resetu. Resetuję checkboxy...");
          
          QuerySnapshot medsSnapshot = await userDocRef.collection('medications').get();
          
          WriteBatch batch = _firestore.batch();
          
          for (var doc in medsSnapshot.docs) {
            batch.update(doc.reference, {'isTaken': false});
          }

          batch.update(userDocRef, {'lastResetDate': Timestamp.now()});

          await batch.commit();
          print("Reset zakończony.");

        } else {
          print("Reset na dziś już był. Pomijam.");
        }

      } catch (e) {
        print("Błąd podczas resetowania leków: $e");
      } finally {
        setState(() {
          _isResetting = false;
        });
      }
    }  

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

  Future<void> _toggleMedStatus(String medId, bool currentStatus, String medName, String medDosage) async {
    if (currentUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('medications')
          .doc(medId)
          .update({
            'isTaken': !currentStatus
          });
      
      if (!currentStatus == true) {
         DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser!.uid).get();
        if (!userDoc.exists || userDoc.get('linkedAdminId') == null) {
          print("Błąd: User nie ma połączonego admina.");
          return;
        }
        String adminId = userDoc.get('linkedAdminId');
        String userName = userDoc.get('name');

        await _firestore
          .collection('users')
          .doc(adminId)
          .collection('notifications')
          .add({
            'title': "$userName wziął lek",
            'body': "Potwierdzono wzięcie: $medName ${medDosage ?? ''}",
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
            'userId': currentUser!.uid,
          });
      }
    } catch (e) {
      print("Błąd zmiany statusu leku: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd: Nie udało się zaktualizować leku.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(body: Center(child: Text("Błąd logowania.")));
    }
    if (_isResetting) {
      return Scaffold(
        appBar: AppBar(title: Text("Moje Leki")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Moje leki")),
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
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(currentUser!.uid)
                  .collection('medications')
                  .orderBy('scheduleOrder')
                  .snapshots(),
              builder: (context, medSnapshot) {
                if (medSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (medSnapshot.hasError) {
                  return Center(child: Text("Błąd ładowania leków."));
                }
                if (!medSnapshot.hasData || medSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Opiekun nie dodał jeszcze żadnych leków. Skontaktuj się z nim, aby uzyskać więcej informacji.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                  );
                }
                final medications = medSnapshot.data!.docs;

                final morningMeds = medications
                    .where((doc) => (doc.data() as Map<String, dynamic>)['scheduleTime'] == 'Rano')
                    .toList();
                final afternoonMeds = medications
                    .where((doc) => (doc.data() as Map<String, dynamic>)['scheduleTime'] == 'Południe')
                    .toList();
                final eveningMeds = medications
                    .where((doc) => (doc.data() as Map<String, dynamic>)['scheduleTime'] == 'Wieczór')
                    .toList();
                final otherMeds = medications
                    .where((doc) => !['Rano', 'Południe', 'Wieczór']
                        .contains((doc.data() as Map<String, dynamic>)['scheduleTime']))
                    .toList();



                return ListView(
                  children: [
                    if (morningMeds.isNotEmpty)
                      _buildSectionHeader('Rano'),
                    ...morningMeds.map((med) => _buildMedCheckboxListTile(med)).toList(),

                    if (afternoonMeds.isNotEmpty)
                      _buildSectionHeader('Południe'),
                    ...afternoonMeds.map((med) => _buildMedCheckboxListTile(med)).toList(),
                    
                    if (eveningMeds.isNotEmpty)
                      _buildSectionHeader('Wieczór'),
                    ...eveningMeds.map((med) => _buildMedCheckboxListTile(med)).toList(),

                    if (otherMeds.isNotEmpty)
                      _buildSectionHeader('W razie potrzeby'),
                    ...otherMeds.map((med) => _buildMedCheckboxListTile(med)).toList(),
                  ],
                );
              },
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

                if (invSnapshot.hasData && invSnapshot.data!.docs.isNotEmpty) {
                    var invitation = invSnapshot.data!.docs.first;
                    return InvitationPending(
                      adminName: invitation.get('adminName'),
                      onAccept: () => _acceptInvitation(invitation.id, invitation.get('adminId')),
                      onDecline: () => _declineInvitation(invitation.id),
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
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          color: Theme.of(context).primaryColorDark,
        ),
      ),
    );
  }

Widget _buildMedCheckboxListTile(DocumentSnapshot med) {
    var medData = med.data() as Map<String, dynamic>;
    String medId = med.id;
    bool isTaken = medData['isTaken'] ?? false;
    String medName = medData['name'] ?? 'Brak nazwy';
    String medDosage = medData['dosage'] ?? '';

    return CheckboxListTile(
      title: Text(
        medName,
        style: TextStyle(
          fontSize: 18,
          decoration: isTaken ? TextDecoration.lineThrough : TextDecoration.none,
          color: isTaken ? Colors.grey[600] : Colors.black,
        ),
      ),
      subtitle: Text("${medDosage} - ${medData['scheduleTime'] ?? ''}"),
      value: isTaken,
      onChanged: (bool? newValue) {
        _toggleMedStatus(medId, isTaken, medName, medDosage);
      },
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.green,
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