class DocumentActivity {
  final String action;
  final DateTime timestamp;

  DocumentActivity({
    required this.action,
    required this.timestamp,
  });

  factory DocumentActivity.fromJson(Map<String, dynamic> json) {
    return DocumentActivity(
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'timestamp': timestamp,
    };
  }
}
