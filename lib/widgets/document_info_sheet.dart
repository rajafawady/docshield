import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/auth_service.dart';

class DocumentInfoSheet extends StatelessWidget {
  final DocumentModel document;

  const DocumentInfoSheet({Key? key, required this.document}) : super(key: key);

  Future<String> _fetchUserEmail(String userId) async {
    return await AuthService().getUserEmailById(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
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
            const Divider(),
            _buildInfoRow('Name', document.name),
            FutureBuilder<String>(
              future: _fetchUserEmail(document.ownerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildInfoRow('Owner', 'Loading...');
                } else if (snapshot.hasError) {
                  return _buildInfoRow('Owner', 'Error fetching email',
                      isError: true);
                } else {
                  return _buildInfoRow('Owner', snapshot.data!);
                }
              },
            ),
            _buildInfoRow('Status', document.status),
            _buildInfoRow('Created At', document.createdAt),
            _buildInfoRow('Document URL', document.documentUrl),
            const SizedBox(height: 16),
            Text(
              'Shared With:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            for (var user in document.sharedWith)
              FutureBuilder<String>(
                future: _fetchUserEmail(user),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildInfoRow('User', 'Loading...');
                  } else if (snapshot.hasError) {
                    return _buildInfoRow('User', 'Error fetching email',
                        isError: true);
                  } else {
                    return _buildInfoRow('User', snapshot.data!);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: isError ? Colors.red : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
