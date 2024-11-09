// lib/main.dart
import 'package:flutter/material.dart';
import 'package:pdf_manager/main_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  // Initialize FFI for sqflite
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('he', 'IL'),
        Locale('ar', 'AE'),
      ],
      home: MainScreen(),
    );
  }
}
