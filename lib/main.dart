import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'utils/theme.dart';

void main() {
  runApp(const ActasSenaApp());
}

class ActasSenaApp extends StatelessWidget {
  const ActasSenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SENA Actas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}