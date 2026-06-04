import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../data/database_helper.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_TimerTaskHandler());
}

class _TimerTaskHandler extends TaskHandler {
  int _seconds = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _seconds = await FlutterForegroundTask.getData<int>(key: 'seconds') ?? 0;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _seconds++;
    FlutterForegroundTask.saveData(key: 'seconds', value: _seconds);
    FlutterForegroundTask.sendDataToMain(_seconds);
    FlutterForegroundTask.updateService(
      notificationTitle: 'Cozy Session',
      notificationText: _formatTime(_seconds),
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  bool _isStopwatch = true;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  final int _countdownSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;

  List<String> _habits = [];
  String _selectedHabit = '';

  Timer? _uiTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initForegroundTask();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveData);
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('habits');
    setState(() {
      _habits = saved ?? ['Leetcode'];
      _selectedHabit = _habits.first;
    });
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('habits', _habits);
  }

  Future<void> _saveSession() async {
    if (_elapsedSeconds < 5) return; // ignore accidental taps
    await DatabaseHelper.instance.insertSession({
      'habit': _selectedHabit,
      'duration': _elapsedSeconds,
      'date': DateTime.now().toIso8601String(),
      'notes': '',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Session saved — ${_formatTime(_elapsedSeconds)}',
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          backgroundColor: AppTheme.card,
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning) {
      FlutterForegroundTask.getData<int>(key: 'seconds').then((value) {
        if (value != null && mounted) {
          setState(() => _elapsedSeconds = value);
        }
        _startUiTimer();
      });
    } else if (state == AppLifecycleState.paused) {
      _uiTimer?.cancel();
    }
  }

  void _onReceiveData(Object data) {
    if (data is int && mounted) {
      if (_uiTimer == null || !_uiTimer!.isActive) {
        setState(() {
          if (_isStopwatch) {
            _elapsedSeconds = data;
          } else {
            _remainingSeconds = (_countdownSeconds - data).clamp(
              0,
              _countdownSeconds,
            );
          }
        });
      }
    }
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_isStopwatch) {
          _elapsedSeconds++;
        } else {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _stopAll();
          }
        }
      });
      FlutterForegroundTask.saveData(key: 'seconds', value: _elapsedSeconds);
    });
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'cozy_session_timer',
        channelName: 'Cozy Session Timer',
        channelDescription: 'Shows your active study session',
        onlyAlertOnce: true,
        playSound: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
      ),
    );
  }

  Future<void> _startAll() async {
    await FlutterForegroundTask.saveData(
      key: 'seconds',
      value: _elapsedSeconds,
    );
    await FlutterForegroundTask.saveData(key: 'habit', value: _selectedHabit);
    await FlutterForegroundTask.requestNotificationPermission();
    await FlutterForegroundTask.startService(
      notificationTitle: 'Cozy Session',
      notificationText: '$_selectedHabit • ${_formatTime(_elapsedSeconds)}',
      callback: startCallback,
    );
    _startUiTimer();
    setState(() => _isRunning = true);
  }

  Future<void> _stopAll() async {
    _uiTimer?.cancel();
    await FlutterForegroundTask.stopService();
    setState(() => _isRunning = false);
  }

  Future<void> _stopAndSave() async {
    await _saveSession();
    await _stopAll();
    setState(() {
      _elapsedSeconds = 0;
      _remainingSeconds = _countdownSeconds;
    });
  }

  void _startStop() {
    if (_isRunning) {
      _stopAll();
    } else {
      _startAll();
    }
  }

  void _reset() {
    _stopAll();
    setState(() {
      _elapsedSeconds = 0;
      _remainingSeconds = _countdownSeconds;
      _isRunning = false;
    });
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  String get _displayTime {
    if (_isStopwatch) return _formatTime(_elapsedSeconds);
    return _formatTime(_remainingSeconds);
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveData);
    super.dispose();
  }

  void _showHabitPicker() {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      constraints: BoxConstraints(
        // Use 90% of screen height — works on both portrait and landscape
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Select Habit',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(color: AppTheme.textMuted),
                ..._habits.map(
                  (h) => ListTile(
                    title: Text(
                      h,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _habits.remove(h);
                          if (_selectedHabit == h && _habits.isNotEmpty) {
                            _selectedHabit = _habits.first;
                          }
                        });
                        _saveHabits();
                        setModalState(() {});
                      },
                    ),
                    onTap: () {
                      setState(() => _selectedHabit = h);
                      Navigator.pop(context);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Add new habit...',
                            hintStyle: const TextStyle(
                              color: AppTheme.textMuted,
                            ),
                            filled: true,
                            fillColor: AppTheme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final name = controller.text.trim();
                          if (name.isNotEmpty && !_habits.contains(name)) {
                            setState(() {
                              _habits.add(name);
                              _selectedHabit = name;
                            });
                            _saveHabits();
                            setModalState(() {});
                            controller.clear();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mode toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 80),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _modeButton('Stopwatch', true),
                  _modeButton('Timer', false),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Habit selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: _showHabitPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedHabit.isEmpty ? 'Add a habit' : _selectedHabit,
                        style: TextStyle(
                          color: _selectedHabit.isEmpty
                              ? AppTheme.textMuted
                              : AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(Icons.expand_more, color: AppTheme.accent),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Time display
            Text(
              _displayTime,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 72,
                fontWeight: FontWeight.w200,
                letterSpacing: 4,
              ),
            ),

            const SizedBox(height: 60),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  color: AppTheme.textMuted,
                  iconSize: 32,
                ),

                const SizedBox(width: 24),

                GestureDetector(
                  onTap: _startStop,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Stop and save
                IconButton(
                  onPressed: _stopAndSave,
                  icon: const Icon(Icons.stop_circle_outlined),
                  color: AppTheme.accent,
                  iconSize: 32,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'tap ⏹ to save session',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String label, bool isStopwatch) {
    final selected = _isStopwatch == isStopwatch;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!_isRunning) {
            setState(() {
              _isStopwatch = isStopwatch;
              _reset();
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
