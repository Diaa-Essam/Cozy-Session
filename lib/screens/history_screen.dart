import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'History',
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 24),
      ),
    );
  }
}
