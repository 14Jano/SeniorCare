import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final doc = _firestore.collection('users').doc(user.uid);
        final snapshot = await doc.get();

        if (!snapshot.exists) {
          await doc.set({
            'uid': user.uid,
            'name': user.displayName ?? 'Użytkownik Google',
            'email': user.email,
            'role': 'User',
            'linkedAdminId': null,
            'lastResetDate': null,
          });
        }
      }

      return userCredential;
    } catch (e) {
      print(e.toString());
    }
    return null;
  }


  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
        print(e.toString());
    }
  }

  Future<void> sendPasswordResetLink(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
        print(e.toString());
    }
  }

  Future<String?> createUserWithEmailAndPassword({required String name, required String email, required String password, required String role}) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());

      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
      };

      if (role == "User") {
        userData['linkedAdminId'] = null;
        userData['lastResetDate'] = null;
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
      return null;
    } catch (e) {
    return e.toString();
    }
  }

  Future<String?> loginUserWithEmailAndPassword({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      return userDoc['role']; 
    } catch (e) {
      return e.toString();
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Coś poszło nie tak');
    }
  }
}