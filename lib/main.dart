import 'package:flutter/material.dart';

void main() {
  runApp(const CozysessionApp());
}

class CozysessionApp extends StatelessWidget {
  const CozysessionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cozy Session',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        backgroundColor: Color(0xFF1A1410),
        body: Center(
          child: Text(
            'Cozy Session',
            style: TextStyle(color: Color(0xFFF5E6C8), fontSize: 24),
          ),
        ),
      ),
    );
  }
}
