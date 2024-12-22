import 'package:flutter/material.dart';
import 'document_activity.dart';

class ActivityHistorySheet extends StatelessWidget {
  final List<DocumentActivity> activities;

  const ActivityHistorySheet({Key? key, required this.activities})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Activity History',
            style: TextStyle(
              fontSize: 24, // You can adjust the font size
              fontWeight: FontWeight.bold, // You can adjust the font weight
            ),
          ),
          const SizedBox(height: 8),
          if (activities.isEmpty)
            const Text('No activities available.')
          else
            for (var activity in activities)
              ListTile(
                title: Text(activity.action),
                subtitle: Text('At: ${activity.timestamp}'),
              ),
        ],
      ),
    );
  }
}
