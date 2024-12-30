import 'package:flutter/material.dart';
import '../models/document_model.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final Function() onSign;
  final Function() onView;
  final Function() onShare;

  const DocumentCard({
    Key? key,
    required this.document,
    required this.onSign,
    required this.onView,
    required this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.description, size: 40),
            title: Text(
              document.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Created: ${document.createdAt}',
            ),
            trailing: _buildStatusChip(document.status),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${document.signatures.length} signature(s)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                onPressed: onShare,
              ),
              TextButton.icon(
                icon: const Icon(Icons.remove_red_eye),
                label: const Text('View'),
                onPressed: onView,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.draw),
                label: const Text('Sign'),
                onPressed: document.status == 'pending' ? onSign : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }
}
