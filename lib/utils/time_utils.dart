class TimeUtils {
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

  /// Formats time as "xx min" or "now" if arrival is imminent
  static String formatMinutesToArrival(
      String secondsToArrival, String lastUpdated) {
    final totalSeconds = remainingSeconds(secondsToArrival, lastUpdated);

    if (totalSeconds <= 60) {
      return "now";
    }

    final minutes = (totalSeconds / 60).floor();
    return "$minutes min";
  }
}
