import '../widgets/document_activity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String name;
  final String ownerId;
  final String documentHash;
  final Map<String, DocumentSignature> signatures;
  final DateTime createdAt;
  final String status;
  final List<String> sharedWith;
  final String documentUrl;
  final List<DocumentActivity> activities;

  DocumentModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.documentHash,
    required this.signatures,
    required this.createdAt,
    required this.status,
    required this.sharedWith,
    required this.documentUrl,
    required this.activities,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      name: json['name'],
      ownerId: json['ownerId'],
      documentHash: json['documentHash'],
      signatures: (json['signatures'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              DocumentSignature.fromJson(value),
            ),
          ) ??
          {},
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      status: json['status'],
      sharedWith: List<String>.from(json['sharedWith']),
      documentUrl: json['documentUrl'],
      activities: (json['activities'] as List<dynamic>)
          .map((activity) => DocumentActivity.fromJson(activity))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'documentHash': documentHash,
      'signatures':
          signatures.map((key, value) => MapEntry(key, value.toJson())),
      'createdAt': createdAt,
      'status': status,
      'sharedWith': sharedWith,
      'documentUrl': documentUrl,
      'activities': activities.map((activity) => activity.toJson()).toList(),
    };
  }
}

class DocumentSignature {
  final String userId;
  final String signature;
  final DateTime timestamp;
  final String publicKeyUsed;

  DocumentSignature({
    required this.userId,
    required this.signature,
    required this.timestamp,
    required this.publicKeyUsed,
  });

  factory DocumentSignature.fromJson(Map<String, dynamic> json) {
    return DocumentSignature(
      userId: json['userId'],
      signature: json['signature'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      publicKeyUsed: json['publicKeyUsed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'signature': signature,
      'timestamp': timestamp,
      'publicKeyUsed': publicKeyUsed,
    };
  }
}
