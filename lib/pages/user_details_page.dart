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

int _getScheduleOrder(String schedule) {
    switch (schedule) {
      case "Rano":
        return 1;
      case "Południe":
        return 2;
      case "Wieczór":
        return 3;
      default:
        return 4;
    }
  }

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
        'scheduleOrder': _getScheduleOrder(_selectedSchedule),
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

  Future<void> _updateMedication(String medId) async {
    if (_medNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Proszę podać nazwę leku.")),
      );
      return;
    }

    try {
      int order = _getScheduleOrder(_selectedSchedule);

      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('medications')
          .doc(medId)
          .update({
        'name': _medNameController.text,
        'dosage': _dosageController.text,
        'scheduleTime': _selectedSchedule,
        'scheduleOrder': order,
      });

      Navigator.pop(context);
      
    } catch (e) {
      print("Błąd aktualizacji leku: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Wystąpił błąd podczas aktualizacji leku.")),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(String medId) async {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text("Potwierdzenie"),
          content: Text("Czy na pewno chcesz usunąć ten lek? Tej akcji nie można cofnąć."),
          actions: [
            TextButton(
              child: Text("Anuluj"),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: Text("Usuń", style: TextStyle(color: Colors.red)),
              onPressed: () {
                _firestore
                    .collection('users')
                    .doc(widget.userId)
                    .collection('medications')
                    .doc(medId)
                    .delete();

                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddMedDialog({DocumentSnapshot? medToEdit}) {
    final bool isEditing = medToEdit != null;
    if (isEditing) {
      _medNameController.text = medToEdit['name'];
      _dosageController.text = medToEdit['dosage'];
      _selectedSchedule = medToEdit['scheduleTime'];
    } else {
      _medNameController.clear();
      _dosageController.clear();
      _selectedSchedule = "Rano";
    }
    
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
                    onPressed: () {
                      if (isEditing) {
                        _updateMedication(medToEdit.id);
                      } else {
                        _addMedication();
                      }
                    },
                    child: Text(isEditing ? "Zaktualizuj lek" : "Dodaj lek"),
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
            .orderBy('scheduleOrder')
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
          Widget _buildSectionHeader(String title) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).primaryColor, // Użyj koloru motywu
                  ),
                ),
              );
            }
          Widget _buildMedListTile(DocumentSnapshot med) {
            var medData = med.data() as Map<String, dynamic>;
            bool isTaken = medData['isTaken'] ?? false;

            return ListTile(
              title: Text(medData['name'] ?? 'Brak nazwy'),
              subtitle: Text("${medData['dosage'] ?? ''} - ${medData['scheduleTime'] ?? ''}"),
              trailing: Icon(
                isTaken ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isTaken ? Colors.green : Colors.grey,
              ),
              // Funkcje edycji i usuwania, które dodaliśmy wcześniej
              onLongPress: () {
                _showDeleteConfirmationDialog(med.id);
              },
              onTap: () {
                _showAddMedDialog(medToEdit: med);
              },
            );
          }

          int _getScheduleOrder(String schedule) {
          switch (schedule) {
            case "Rano": return 1;
            case "Południe": return 2;
            case "Wieczór": return 3;
            default: return 4;
            }
          }

          final medications = snapshot.data!.docs;

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
              // --- SEKCJA RANO ---
              if (morningMeds.isNotEmpty)
                _buildSectionHeader('Rano'), // Nasza funkcja pomocnicza
              ...morningMeds.map((med) => _buildMedListTile(med)).toList(), // Nasza druga funkcja pomocnicza

              // --- SEKCJA POŁUDNIE ---
              if (afternoonMeds.isNotEmpty)
                _buildSectionHeader('Południe'),
              ...afternoonMeds.map((med) => _buildMedListTile(med)).toList(),
              
              // --- SEKCJA WIECZÓR ---
              if (eveningMeds.isNotEmpty)
                _buildSectionHeader('Wieczór'),
              ...eveningMeds.map((med) => _buildMedListTile(med)).toList(),

              // --- SEKCJA INNE ---
              if (otherMeds.isNotEmpty)
                _buildSectionHeader('W razie potrzeby'),
              ...otherMeds.map((med) => _buildMedListTile(med)).toList(),
                
              SizedBox(height: 80), // Dodatkowy padding na dole, aby FAB nie zasłaniał
            ],
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