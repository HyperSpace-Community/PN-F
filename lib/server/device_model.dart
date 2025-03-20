class Device {
  final String deviceToken;
  final Map<String, dynamic> deviceInfo;
  final DateTime lastSeen;

  Device({
    required this.deviceToken,
    required this.deviceInfo,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'deviceToken': deviceToken,
        'deviceInfo': deviceInfo,
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        deviceToken: json['deviceToken'],
        deviceInfo: json['deviceInfo'],
        lastSeen: DateTime.parse(json['lastSeen']),
      );
}
