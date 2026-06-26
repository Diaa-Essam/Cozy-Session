import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/database_helper.dart';
import '../utils/formatters.dart';

/// Displays the user's past study sessions in chronological order.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _todayCount = 0;

  /// Holds the future that fetches all sessions from the database

  /// Loads the number of sessions completed today
  Future<void> _loadTodayCount() async {
    final count = await DatabaseHelper.instance.getTodaySessionCount();
    setState(() => _todayCount = count);
  }

  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = DatabaseHelper.instance.getAllSessions();
    _loadTodayCount(); // ← add this
  }

  void _reload() {
    setState(() {
      _sessionsFuture = DatabaseHelper.instance.getAllSessions();
    });
    _loadTodayCount(); // ← add this
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Row(
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
              const SizedBox(height: 4),
              const Text(
                'Your journey through focus and calm.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                _todayCount == 0
                    ? 'No sessions today yet.'
                    : _todayCount == 1
                    ? '1 session today'
                    : '$_todayCount sessions today',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _sessionsFuture,
                  builder: (context, snapshot) {
                    // Still loading
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      );
                    }

                    // No sessions yet
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No sessions yet.\nStart a session and press to save it.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            height: 2,
                          ),
                        ),
                      );
                    }
                    // Sessions exist — show the list
                    final sessions = snapshot.data!;
                    return ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        // Session number counts from most recent downward
                        final sessionNumber = sessions.length - index;
                        return Dismissible(
                          // Ask for confirmation before deleting
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppTheme.card,
                                title: const Text(
                                  'Delete session?',
                                  style: TextStyle(color: AppTheme.textPrimary),
                                ),
                                content: const Text(
                                  'This cannot be undone.',
                                  style: TextStyle(color: AppTheme.textMuted),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },

                          //Unique key for each session
                          key: Key(session['id'].toString()),
                          direction: DismissDirection.endToStart,
                          // Red background shown while swiping
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade900,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          // Called when swipe is completed
                          onDismissed: (direction) async {
                            await DatabaseHelper.instance.deleteSession(
                              session['id'],
                            );
                            _reload();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.card,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                // Session number badge
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#$sessionNumber',
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Habit name and date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Habit name
                                      Text(
                                        session['habit'] ?? 'Unknown',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatDate(session['date']),
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 13,
                                        ),
                                      ),

                                      // I want to put when exactly in the day this session happend
                                    ],
                                  ),
                                ),
                                // Duration
                                Text(
                                  formatDuration(session['duration']),
                                  style: const TextStyle(
                                    color: AppTheme.accent,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
