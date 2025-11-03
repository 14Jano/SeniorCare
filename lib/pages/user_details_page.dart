import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;
  final String userName;

  const UserDetailsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _medNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  String _selectedSchedule = "Rano";

  Future<void> _addMedication() async {
    if (_medNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Proszę podać nazwę leku.")),
      );
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('medications')
          .add({
        'name': _medNameController.text,
        'dosage': _dosageController.text,
        'scheduleTime': _selectedSchedule,
        'isTaken': false,
        'createdAt': Timestamp.now(),
      });

      Navigator.pop(context);
      _medNameController.clear();
      _dosageController.clear();
      
    } catch (e) {
      print("Błąd dodawania leku: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Wystąpił błąd podczas dodawania leku.")),
      );
    }
  }

  void _showAddMedDialog() {
    _selectedSchedule = "Rano"; 
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dodaj nowy lek", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  TextField(
                    controller: _medNameController,
                    decoration: InputDecoration(
                      labelText: "Nazwa leku",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: _dosageController,
                    decoration: InputDecoration(
                      labelText: "Dawkowanie (np. 1 tabletka, 100 mg)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _selectedSchedule,
                    decoration: InputDecoration(
                      labelText: "Pora dnia",
                      border: OutlineInputBorder(),
                    ),
                    items: ["Rano", "Południe", "Wieczór", "W razie potrzeby"]
                        .map((label) => DropdownMenuItem(
                              child: Text(label),
                              value: label,
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setModalState(() {
                          _selectedSchedule = newValue;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addMedication,
                    child: Text("Dodaj lek"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _medNameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Leki dla: ${widget.userName}"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('medications')
            .orderBy('createdAt', descending: true)
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
                "Ten podopieczny nie ma jeszcze żadnych leków.\nNaciśnij + aby dodać pierwszy lek.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            );
          }

          final medications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) {
              var med = medications[index];
              var medData = med.data() as Map<String, dynamic>;

              bool isTaken = medData['isTaken'] ?? false; 
              
              return ListTile(
                title: Text(medData['name'] ?? 'Brak nazwy'),
                subtitle: Text("${medData['dosage'] ?? ''} - ${medData['scheduleTime'] ?? ''}"),
                trailing: Icon(
                  isTaken ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isTaken ? Colors.green : Colors.grey,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedDialog,
        child: Icon(Icons.add),
        tooltip: "Dodaj lek",
      ),
    );
  }
}