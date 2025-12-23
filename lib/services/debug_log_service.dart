import 'package:intl/intl.dart';

class DebugLogService {
  static final DebugLogService _instance = DebugLogService._internal();
  factory DebugLogService() => _instance;
  DebugLogService._internal();

  final List<String> _logs = [];
  final int _maxLogs = 50;

  void addLog(String message) {
    final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
    final formattedLog = "[$timestamp] $message";
    
    _logs.add(formattedLog);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    print(formattedLog); // Keep console logging too
  }

  String getLogs() {
    return _logs.join('\n');
  }

  void clearLogs() {
    _logs.clear();
  }
}
