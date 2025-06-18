class TimeUtils {
  /// Formats time from "HH:MM:SS" to "HH:MM"
  static String formatTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeString;
  }

  /// Calculates remaining seconds until arrival based on original data and current time
  static int remainingSeconds(String secondsToArrival, String lastUpdated) {
    final lastUpdatedTime = DateTime.parse(lastUpdated);
    final timePassed = DateTime.now().difference(lastUpdatedTime);
    return int.parse(secondsToArrival) - timePassed.inSeconds;
  }

  /// Formats time as "MM:SS" with negative sign if needed
  static String formatSecondsToArrival(
      String secondsToArrival, String lastUpdated) {
    final totalSeconds = remainingSeconds(secondsToArrival, lastUpdated);
    final minutes = totalSeconds.abs() ~/ 60;
    final seconds = totalSeconds.abs() % 60;

    final formattedMinutes = minutes.toString().padLeft(2, '0');
    final formattedSeconds = seconds.toString().padLeft(2, '0');
    final sign = totalSeconds < 0 ? "-" : "";

    return '$sign$formattedMinutes:$formattedSeconds';
  }
}
