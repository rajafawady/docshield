import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/auth_service.dart'; // Import your auth service

class SignaturesSheet extends StatelessWidget {
  final Map<String, DocumentSignature> signatures;

  const SignaturesSheet({Key? key, required this.signatures}) : super(key: key);

  Future<String> _fetchUserEmail(String userId) async {
    // Replace this with your actual method to fetch user email
    return await AuthService().getUserEmailById(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Signatures',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 16),
          if (signatures.isEmpty)
            const Text(
              'No signatures yet.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            )
          else
            for (var signature in signatures.values)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FutureBuilder<String>(
                    future: _fetchUserEmail(signature.userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          leading: CircularProgressIndicator(),
                          title: Text('Signed by: Loading...'),
                          subtitle: Text('At: ${signature.timestamp}'),
                        );
                      } else if (snapshot.hasError) {
                        return ListTile(
                          leading: Icon(Icons.error, color: Colors.red),
                          title: Text('Signed by: Error'),
                          subtitle: Text('At: ${signature.timestamp}'),
                        );
                      } else {
                        return ListTile(
                          leading:
                              Icon(Icons.check_circle, color: Colors.green),
                          title: Text('Signed by: ${snapshot.data}'),
                          subtitle: Text('At: ${signature.timestamp}'),
                        );
                      }
                    },
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
