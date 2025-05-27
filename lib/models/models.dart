class LatLong {
  final double latitude;
  final double longitude;

  const LatLong(this.latitude, this.longitude);
}

class Message {
  final String target;
  final String secondsToArrival;
  final String arrivalTimeMessage;
  final List<String> lineColor;
  final String headSign;
  final String lastUpdated;

  const Message({
    required this.target,
    required this.secondsToArrival,
    required this.arrivalTimeMessage,
    required this.lineColor,
    required this.headSign,
    required this.lastUpdated,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
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
  final List<Message> messages;

  const Destination({
    required this.label,
    required this.messages,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      label: json['label'],
      messages: (json['messages'] as List)
          .map((messageJson) => Message.fromJson(messageJson))
          .toList(),
    );
  }
}

class Result {
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

  const Result({
    required this.consideredStation,
    required this.destinations,
    required this.consideredStationFullName,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    String stationCode = json['consideredStation'];
    String consideredStationFullName = stationNames[stationCode] ?? stationCode;

    return Result(
      consideredStation: json['consideredStation'],
      consideredStationFullName: consideredStationFullName,
      destinations: (json['destinations'] as List)
          .map((destinationJson) => Destination.fromJson(destinationJson))
          .toList(),
    );
  }
}
