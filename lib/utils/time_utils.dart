class TimeUtils {
  /// Formats seconds to arrival into MM:SS format with optional negative sign
  static String formatSecondsToArrival(
      String secondsToArrival, String lastUpdated) {
    DateTime lastUpdatedTime = DateTime.parse(lastUpdated);
    Duration timePassed = DateTime.now().difference(lastUpdatedTime);

    int totalSeconds = int.parse(secondsToArrival) - timePassed.inSeconds;

    int minutes = totalSeconds.abs() ~/ 60;
    int seconds = totalSeconds.abs() % 60;

    String formattedMinutes = minutes.abs().toString().padLeft(2, '0');
    String formattedSeconds = seconds.abs().toString().padLeft(2, '0');

    // Add a negative sign if the totalSeconds is negative
    String sign = totalSeconds < 0 ? "-" : "";

    return '$sign$formattedMinutes:$formattedSeconds';
  }
}
