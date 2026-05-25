import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Stats',
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 24),
      ),
    );
  }
}
