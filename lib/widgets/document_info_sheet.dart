import 'package:flutter/material.dart';
import '../models/document_model.dart';

class DocumentInfoSheet extends StatelessWidget {
  final DocumentModel document;

  const DocumentInfoSheet({Key? key, required this.document}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Document Info',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Name: ${document.name}'),
          Text('Owner: ${document.ownerId}'),
          Text('Status: ${document.status}'),
          Text('Created At: ${document.createdAt}'),
          Text('Document URL: ${document.documentUrl}'),
          const SizedBox(height: 16),
          Text('Shared With:'),
          for (var user in document.sharedWith) Text(user),
        ],
      ),
    );
  }
}
