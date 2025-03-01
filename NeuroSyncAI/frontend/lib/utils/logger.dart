import 'dart:developer' as developer;

class Logger {
  // Log levels
  static const int _debugLevel = 0;
  static const int _infoLevel = 1;
  static const int _warningLevel = 2;
  static const int _errorLevel = 3;
  
  // Current log level - change this to adjust logging verbosity
  static const int _currentLogLevel = _debugLevel;
  
  // Debug log
  static void debug(String message) {
    if (_currentLogLevel <= _debugLevel) {
      _log('DEBUG', message);
    }
  }
  
  // Info log
  static void info(String message) {
    if (_currentLogLevel <= _infoLevel) {
      _log('INFO', message);
    }
  }
  
  // Warning log
  static void warning(String message) {
    if (_currentLogLevel <= _warningLevel) {
      _log('WARNING', message);
    }
  }
  
  // Error log
  static void error(String message) {
    if (_currentLogLevel <= _errorLevel) {
      _log('ERROR', message);
    }
  }
  
  // Log with timestamp and level
  static void _log(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    developer.log('[$timestamp] $level: $message');
  }
}
