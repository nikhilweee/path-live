import 'package:intl/intl.dart';

class LatLong {
  final double latitude;
  final double longitude;

  const LatLong(this.latitude, this.longitude);
}

class Alert {
  final String subject;
  final String preMessage;
  final String createdDate;
  final String modifiedDate;

  const Alert({
    required this.subject,
    required this.preMessage,
    required this.createdDate,
    required this.modifiedDate,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    final incidentMessage = json['incidentMessage'] ?? {};
    return Alert(
      subject: incidentMessage['subject'] ?? '',
      preMessage: incidentMessage['preMessage'] ?? '',
      createdDate: json['CreatedDate'] ?? '',
      modifiedDate: json['ModifiedDate'] ?? '',
    );
  }

  DateTime get modifiedDateTime {
    return DateTime.fromMillisecondsSinceEpoch(int.parse(modifiedDate));
  }
}

class Station {
  final String consideredStation;
  final List<Train> trains;
  final String consideredStationFullName;

  static const Map<String, String> stationNames = {
    "NWK": "Newark",
    "HAR": "Harrison",
    "JSQ": "Journal Square",
    "GRV": "Grove Street",
    "NEW": "Newport",
    "EXP": "Exchange Place",
    "HOB": "Hoboken",
    "WTC": "World Trade Center",
    "CHR": "Christopher Street",
    "09S": "9th Street",
    "14S": "14th Street",
    "23S": "23rd Street",
    "33S": "33rd Street"
  };

  const Station({
    required this.consideredStation,
    required this.trains,
    required this.consideredStationFullName,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    String stationCode = json['consideredStation'];
    String consideredStationFullName = stationNames[stationCode] ?? stationCode;

    // Flatten all trains from all destinations
    List<Train> allTrains = [];
    if (json['destinations'] != null) {
      for (var destinationJson in json['destinations'] as List) {
        if (destinationJson['messages'] != null) {
          for (var trainJson in destinationJson['messages'] as List) {
            allTrains.add(Train.fromJson(trainJson));
          }
        }
      }
    }

    return Station(
      consideredStation: json['consideredStation'],
      consideredStationFullName: consideredStationFullName,
      trains: allTrains,
    );
  }
}

class Train {
  final String target;
  final String secondsToArrival;
  final String arrivalTimeMessage;
  final List<String> lineColor;
  final String headSign;
  final String lastUpdated;

  const Train({
    required this.target,
    required this.secondsToArrival,
    required this.arrivalTimeMessage,
    required this.lineColor,
    required this.headSign,
    required this.lastUpdated,
  });

  factory Train.fromJson(Map<String, dynamic> json) {
    return Train(
      target: json['target'],
      secondsToArrival: json['secondsToArrival'],
      arrivalTimeMessage: json['arrivalTimeMessage'],
      lineColor: json['lineColor'].split(","),
      headSign: json['headSign'],
      lastUpdated: json['lastUpdated'],
    );
  }
}

class Trip {
  final String tripId;
  final String departureTime;
  final String tripHeadsign;
  final String routeNameShort;
  final String routeColor;
  final String? routeSecondaryRouteColor;
  final DateTime departureDate;

  Trip({
    required this.tripId,
    required this.departureTime,
    required this.tripHeadsign,
    required this.routeNameShort,
    required this.routeColor,
    this.routeSecondaryRouteColor,
    required this.departureDate,
  });

  DateTime get departureDateTime {
    // Parse just the time part using intl
    final timeOnly = DateFormat('HH:mm:ss').parse(departureTime);
    return DateTime(
      departureDate.year,
      departureDate.month,
      departureDate.day,
      timeOnly.hour,
      timeOnly.minute,
      timeOnly.second,
    );
  }

  factory Trip.fromMap(Map<String, dynamic> map, {required DateTime date}) {
    return Trip(
      tripId: map['trip_id'] as String,
      departureTime: map['departure_time'] as String,
      tripHeadsign: map['trip_headsign'] as String,
      routeNameShort: map['route_name_short'] as String,
      routeColor: map['route_color'] as String,
      routeSecondaryRouteColor: map['route_secondary_route_color'] as String?,
      departureDate: date,
    );
  }
}

class Stop {
  final String stopName;
  final String departureTime;
  final int stopSequence;
  final String routeColor;
  final String? routeSecondaryRouteColor;

  Stop({
    required this.stopName,
    required this.departureTime,
    required this.stopSequence,
    required this.routeColor,
    this.routeSecondaryRouteColor,
  });

  factory Stop.fromMap(Map<String, dynamic> map) {
    return Stop(
      stopName: map['stop_name'] as String,
      departureTime: map['departure_time'] as String,
      stopSequence: int.parse(map['stop_sequence'].toString()),
      routeColor: map['route_color'] as String,
      routeSecondaryRouteColor: map['route_secondary_route_color'] as String?,
    );
  }
}
