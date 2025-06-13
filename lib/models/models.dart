class LatLong {
  final double latitude;
  final double longitude;

  const LatLong(this.latitude, this.longitude);
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

class Destination {
  final String label;
  final List<Train> trains;

  const Destination({
    required this.label,
    required this.trains,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      label: json['label'],
      trains: (json['messages'] as List)
          .map((trainJson) => Train.fromJson(trainJson))
          .toList(),
    );
  }
}

class Station {
  final String consideredStation;
  final List<Destination> destinations;
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
    required this.destinations,
    required this.consideredStationFullName,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    String stationCode = json['consideredStation'];
    String consideredStationFullName = stationNames[stationCode] ?? stationCode;

    return Station(
      consideredStation: json['consideredStation'],
      consideredStationFullName: consideredStationFullName,
      destinations: (json['destinations'] as List)
          .map((destinationJson) => Destination.fromJson(destinationJson))
          .toList(),
    );
  }
}

class Incident {
  final String subject;
  final String preMessage;
  final String createdDate;
  final String modifiedDate;

  const Incident({
    required this.subject,
    required this.preMessage,
    required this.createdDate,
    required this.modifiedDate,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    final incidentMessage = json['incidentMessage'] ?? {};
    return Incident(
      subject: incidentMessage['subject'] ?? '',
      preMessage: incidentMessage['preMessage'] ?? '',
      createdDate: json['CreatedDate'] ?? '',
      modifiedDate: json['ModifiedDate'] ?? '',
    );
  }

  DateTime get createdDateTime {
    try {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(createdDate));
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime get modifiedDateTime {
    try {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(modifiedDate));
    } catch (e) {
      return DateTime.now();
    }
  }

  String get formattedCreatedDate {
    final date = createdDateTime;

    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');

    return '${date.month}/${date.day} $hour:$minute';
  }

  String get formattedModifiedDate {
    final date = modifiedDateTime;

    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');

    return '${date.month}/${date.day} $hour:$minute';
  }
}

class TrainSchedule {
  final String departureTime;
  final String tripHeadsign;
  final String routeNameShort;
  final String routeColor;
  final String? routeSecondaryRouteColor;
  final DateTime date;

  TrainSchedule({
    required this.departureTime,
    required this.tripHeadsign,
    required this.routeNameShort,
    required this.routeColor,
    this.routeSecondaryRouteColor,
    required this.date,
  });

  factory TrainSchedule.fromMap(Map<String, dynamic> map, {required DateTime date}) {
    return TrainSchedule(
      departureTime: map['departure_time'] as String,
      tripHeadsign: map['trip_headsign'] as String,
      routeNameShort: map['route_name_short'] as String,
      routeColor: map['route_color'] as String,
      routeSecondaryRouteColor: map['route_secondary_route_color'] as String?,
      date: date,
    );
  }
}
