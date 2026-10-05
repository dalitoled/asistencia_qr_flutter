import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../core/errors/exceptions.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _uidKey = 'user_uid';
  static const String _userDataKey = 'user_data';

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserModel?> getStoredUser() async {
    try {
      final userData = await _secureStorage.read(key: _userDataKey);
      if (userData != null) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(
          Uri.splitQueryString(userData).map(
            (key, value) => MapEntry(key, value),
          ),
        );
        return UserModel.fromMap(map);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw AuthException('Usuario no encontrado');
      }

      final user = await _getUserData(credential);
      await _saveUserSession(user);
      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw AuthException('Usuario no encontrado', code: e.code);
        case 'wrong-password':
          throw AuthException('Contraseña incorrecta', code: e.code);
        case 'invalid-email':
          throw AuthException('Correo electrónico inválido', code: e.code);
        case 'user-disabled':
          throw AuthException('Usuario deshabilitado', code: e.code);
        default:
          throw AuthException('Error al iniciar sesión', code: e.code, originalError: e);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Error de conexión', originalError: e);
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _secureStorage.delete(key: _uidKey);
    await _secureStorage.delete(key: _userDataKey);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException('Error al enviar correo de recuperación', code: e.code);
    }
  }

  Future<UserModel> register(String email, String password, String nombre, String rol) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw AuthException('Error al crear usuario');
      }

      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        name: nombre,
        role: rol == 'admin' ? UserRole.admin : UserRole.operator,
        createdAt: DateTime.now(),
      );

      await _saveUserSession(user);
      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw AuthException('El correo ya está registrado', code: e.code);
        case 'weak-password':
          throw AuthException('La contraseña es muy débil', code: e.code);
        case 'invalid-email':
          throw AuthException('Correo electrónico inválido', code: e.code);
        default:
          throw AuthException('Error al registrar usuario', code: e.code, originalError: e);
      }
    }
  }

  Future<UserModel> _getUserData(UserCredential credential) async {
    final firebaseUser = credential.user;
    return UserModel(
      uid: firebaseUser!.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? 'Usuario',
      role: UserRole.admin,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _saveUserSession(UserModel user) async {
    await _secureStorage.write(key: _uidKey, value: user.uid);
    final queryString = Uri(queryParameters: user.toMap()).query;
    await _secureStorage.write(key: _userDataKey, value: queryString);
  }

  Future<bool> isLoggedIn() async {
    final uid = await _secureStorage.read(key: _uidKey);
    return uid != null;
  }
}