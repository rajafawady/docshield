class DocumentActivity {
  final String action;
  final String timestamp;

  DocumentActivity({
    required this.action,
    required this.timestamp,
  });

  factory DocumentActivity.fromJson(Map<String, dynamic> json) {
    return DocumentActivity(
      action: json['action'],
      timestamp: json['timestamp'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'timestamp': timestamp,
    };
  }
}
