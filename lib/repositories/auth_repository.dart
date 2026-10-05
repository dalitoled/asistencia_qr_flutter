import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  Future<UserModel?> signInWithEmail(String email, String password);
  Future<void> signOut();
  Future<UserModel?> getCurrentUserData();
}

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserModel?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      return getCurrentUserData();
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Use a try-catch for cases where the user document might not exist yet
    try {
      // Assuming user data is stored in 'usuarios' collection
      return await _firestoreService.collectionStream<UserModel>(
        path: 'usuarios',
        builder: (data, id) => UserModel.fromMap(data, id),
        queryBuilder: (query) => query.where(FieldPath.documentId, isEqualTo: user.uid),
      ).first.then((list) => list.isNotEmpty ? list.first : null);
    } catch (e) {
      return null;
    }
  }
}
