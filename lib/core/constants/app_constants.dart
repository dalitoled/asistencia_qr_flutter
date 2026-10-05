import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xFF1E88E5); // Azul Institucional
  static const Color secondaryColor = Color(0xFF00ACC1);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFFBC02D);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Colors.white;
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);

  // Paddings
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Border Radius
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;

  // Strings
  static const String appName = 'AAP Tolata Chico';
  
  // Business Logic Constants
  static const String defaultHourLimit = '08:30';
  static const double defaultFineDelay = 10.0;
  static const double defaultFineAbsence = 30.0;
  static const String institutionName = 'AAP Tolata Chico';

  // Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Storage Keys
  static const String tokenKey = 'secure_auth_token';
  static const String userKey = 'cached_user_data';
}