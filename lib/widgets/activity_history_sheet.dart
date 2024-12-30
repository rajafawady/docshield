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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent, // Added color
            ),
          ),
          const SizedBox(height: 16), // Increased spacing
          if (activities.isEmpty)
            const Text(
              'No activities available.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey, // Added color
              ),
            )
          else
            for (var activity in activities)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.history,
                      color: Colors.blueAccent), // Added icon
                  title: Text(
                    activity.action,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'At: ${activity.timestamp}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
