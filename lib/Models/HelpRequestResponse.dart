  class HelpRequestResponse {
    final HelpRequestData data;
    final NearbyStats nearbyStats;

    HelpRequestResponse({
      required this.data,
      required this.nearbyStats,
    });

    factory HelpRequestResponse.fromJson(Map<String, dynamic> json) {
      return HelpRequestResponse(
        data: HelpRequestData.fromJson(json['data']),
        nearbyStats: NearbyStats.fromJson(json['nearbyStats']),
      );
    }

    Map<String, dynamic> toJson() => {
      'data': data.toJson(),
      'nearbyStats': nearbyStats.toJson(),
    };
  }

  class HelpRequestData {
    final String seeker;
    final String status;
    final Location location;
    final String id;
    final DateTime createdAt;
    final DateTime updatedAt;
    final int v;

    HelpRequestData({
      required this.seeker,
      required this.status,
      required this.location,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      required this.v,
    });

    factory HelpRequestData.fromJson(Map<String, dynamic> json) {
      return HelpRequestData(
        seeker: json['seeker']?.toString() ?? '', // ensures a String
        status: json['status']?.toString() ?? '',
        location: Location.fromJson(Map<String, dynamic>.from(json['location'])),
        id: json['_id']?.toString() ?? '',
        createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
        v: (json['__v'] ?? 0) is int ? json['__v'] : int.parse(json['__v'].toString()),
      );
    }


    Map<String, dynamic> toJson() => {
      'seeker': seeker,
      'status': status,
      'location': location.toJson(),
      '_id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }

  class Location {
    final String type;
    final List<double> coordinates;

    Location({required this.type, required this.coordinates});

    factory Location.fromJson(Map<String, dynamic> json) {
      return Location(
        type: json['type'],
        coordinates: List<double>.from(json['coordinates'].map((x) => x.toDouble())),
      );
    }

    Map<String, dynamic> toJson() => {
      'type': type,
      'coordinates': coordinates,
    };
  }

  class NearbyStats {
    final int km1;
    final int km2;
    final int km3;

    NearbyStats({required this.km1, required this.km2, required this.km3 });

    factory NearbyStats.fromJson(Map<String, dynamic> json) {
      return NearbyStats(
        km1: json['1km'],
        km2: json['2km'],
        km3: json['3km'],
      );
    }

    Map<String, dynamic> toJson() => {
      '1km': km1,
      '2km': km2,
      //'3km': km3,
    };

  }
