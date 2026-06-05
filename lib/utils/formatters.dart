/// Utility functions for formatting data into readable strings

/// Converts seconds into readable format -->> 1h 20m or 45m 30s

String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '${h}h ${m}m ${s}s';
  if (m > 0) return '${m}m ${s}s';

  return '${s}s';
}

/// Converts ISO date String into readable format -->> Jun 4, 2026

String formatDate(String isoDate) {
  final date = DateTime.parse(isoDate);
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
