class NotificationItemModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final String? type;
  final String? distance;
  final String? userImage;
  final String? userName;

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.type,
    this.distance,
    this.userImage,
    this.userName,
  });

  /// Create NotificationItemModel from JSON
  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      type: json['type'],
      distance: json['distance'],
      userImage: json['userImage'],
      userName: json['userName'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'distance': distance,
      'userImage': userImage,
      'userName': userName,
    };
  }
}
