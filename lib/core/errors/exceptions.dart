class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => originalError != null ? '$message: $originalError' : message;
}

class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalError});
}

class FirestoreException extends AppException {
  FirestoreException(super.message, {super.code, super.originalError});
}

class StorageException extends AppException {
  StorageException(super.message, {super.code, super.originalError});
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.code});
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}