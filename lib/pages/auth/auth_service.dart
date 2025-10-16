import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
      return await _auth.signInWithCredential(credential);
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

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      FlutterExceptionHandler(e.code);
    }
    catch (e) {
      print('Coś poszło nie tak');
    }
    return null;
  }

  Future<User?> loginUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      FlutterExceptionHandler(e.code);
    } catch (e) {
      print('Nieprawidłowe dane logowania');
    }
    return null;
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Coś poszło nie tak');
    }
  }
}

FlutterExceptionHandler(String code) {
  switch(code) {
    case "invalid-credential":
      print("Nieprawidłowe dane logowania");
    case "user-not-found":
      print("Nie znaleziono użytkownika");
    case "weak-password":
      print("Hasło jest zbyt słabe, musi mieć conajmniej 8 znaków");
    case "email-already-in-use":
      print("Konto z podanym adresem email już istnieje");
    default:
      print("Wystąpił nieznany błąd");
  }
}