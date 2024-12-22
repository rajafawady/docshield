import 'package:flutter/material.dart';
import '../models/document_model.dart';

class SignaturesSheet extends StatelessWidget {
  final Map<String, DocumentSignature> signatures;

  const SignaturesSheet({Key? key, required this.signatures}) : super(key: key);

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
            ),
          ),
          const SizedBox(height: 8),
          if (signatures.isEmpty)
            const Text('No signatures yet.')
          else
            for (var signature in signatures.values)
              ListTile(
                title: Text('Signed by: ${signature.userId}'),
                subtitle: Text('At: ${signature.timestamp}'),
              ),
        ],
      ),
    );
  }
}
