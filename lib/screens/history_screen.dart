import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/database_helper.dart';

/// Displays the user's past study sessions in chronological order.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// Holds the future that fetches all sessions from the database

  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    // Load sessions when the screen first opens
    _sessionsFuture = DatabaseHelper.instance.getAllSessions();
  }

  /// Reloads sessions from the database - called on manual refresh
  void _reload() {
    setState(() {
      _sessionsFuture = DatabaseHelper.instance.getAllSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'History',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
