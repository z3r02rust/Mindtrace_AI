import 'package:firebase_auth/firebase_auth.dart';


class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String> ensureSignedIn() async {
    User? user = _auth.currentUser;
    user ??= (await _auth.signInAnonymously()).user;
    if (user == null) {
      throw StateError('Firebase anonim autentifikatsiya muvaffaqiyatsiz tugadi.');
    }
    return user.uid;
  }
}
