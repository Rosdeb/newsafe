class HistoryModel {
  final String id;
  final String status;
  final String title;
  final String details;
  final String distance;
  final String date;
  final String time;
  final String createdAt;

  HistoryModel({
    required this.id,
    required this.status,
    required this.title,
    required this.details,
    required this.distance,
    required this.date,
    required this.time,
    required this.createdAt,
  });

  // Convert JSON → Model
  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['id'] ?? "",
      status: json['status'] ?? "",
      title: json['title'] ?? "",
      details: json['details'] ?? "",
      distance: json['distance'] ?? "",
      date: json['date'] ?? "",
      time: json['time'] ?? "",
      createdAt: json['createdAt'] ?? "",
    );
  }

  // Convert Model → JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "status": status,
      "title": title,
      "details": details,
      "distance": distance,
      "date": date,
      "time": time,
      "createdAt": createdAt,
    };
  }
}
