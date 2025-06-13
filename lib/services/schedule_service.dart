import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/models.dart';
import 'database_service.dart';

class ScheduleService {
  static Future<List<TrainSchedule>> getTrainsForDate(
      String stopName, DateTime date) async {
    tz.initializeTimeZones();
    final nyLocation = tz.getLocation('America/New_York');
    final tzDateTime =
        tz.TZDateTime(nyLocation, date.year, date.month, date.day);
    return DatabaseService.getTrainsForDay(stopName, tzDateTime);
  }

  static bool isTrainInPast(TrainSchedule train) {
    return train.departureDateTime.isBefore(DateTime.now());
  }
}
