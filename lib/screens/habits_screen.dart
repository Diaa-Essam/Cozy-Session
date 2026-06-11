import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Habits',
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 24),
      ),
    );
  }
}
