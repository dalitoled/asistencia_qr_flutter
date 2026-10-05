enum UserRole { admin, operator }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, [String? id]) {
    final String uid = id ?? map['uid'] ?? '';
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? map['nombre'] ?? '',
      role: (map['role'] == 'admin' || map['rol'] == 'admin') 
          ? UserRole.admin 
          : UserRole.operator,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is DateTime 
              ? map['createdAt'] 
              : DateTime.tryParse(map['createdAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nombre': name,
      'rol': role == UserRole.admin ? 'admin' : 'operator',
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}