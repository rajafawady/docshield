import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/document_model.dart';

class DocumentDetailScreen extends StatelessWidget {
  final DocumentModel document;
  final UserModel user;

  const DocumentDetailScreen({
    Key? key,
    required this.document,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Document ID: ${document.id}'),
            Text('Owner: ${document.ownerId}'),
            Text('Status: ${document.status}'),
            Text('Created At: ${document.createdAt}'),
            const SizedBox(height: 16),
            const Text('Signatures:'),
            ...document.signatures.entries.map((entry) {
              final signature = entry.value;
              return ListTile(
                title: Text('User: ${signature.userId}'),
                subtitle: Text('Signed At: ${signature.timestamp}'),
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Implement signature functionality
              },
              child: const Text('Sign Document'),
            ),
          ],
        ),
      ),
    );
  }
}
