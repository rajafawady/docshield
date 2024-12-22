import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/document_model.dart';
import '../widgets/document_activity.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  Stream<List<DocumentModel>> getDocuments(String userId) {
    return _firestore
        .collection('documents')
        .where('sharedWith', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DocumentModel.fromJson(doc.data());
      }).toList();
    });
  }

  Future<void> uploadDocument({
    required String ownerId,
    required String filePath,
    required String fileName,
    required String documentHash,
  }) async {
    final documentId = _uuid.v4();

    // Upload file to Firebase Storage
    final storageRef = _storage.ref('documents/$documentId/$fileName');
    await storageRef.putFile(File(filePath));
    final documentUrl = await storageRef.getDownloadURL();

    // Save metadata to Firestore
    final document = DocumentModel(
      id: documentId,
      name: fileName,
      ownerId: ownerId,
      documentHash: documentHash,
      signatures: {},
      createdAt: DateTime.now(),
      status: 'Pending',
      sharedWith: [ownerId],
      documentUrl: documentUrl,
      activities: [],
    );

    await _firestore
        .collection('documents')
        .doc(documentId)
        .set(document.toJson());
  }

  Future<void> signDocument({
    required String documentId,
    required String userId,
    required String signature,
    required String publicKeyUsed,
  }) async {
    final documentRef = _firestore.collection('documents').doc(documentId);
    final docSnapshot = await documentRef.get();

    if (!docSnapshot.exists) {
      throw Exception('Document not found');
    }

    final document = DocumentModel.fromJson(docSnapshot.data()!);

    // Add the signature for the user
    document.signatures[userId] = DocumentSignature(
      userId: userId,
      signature: signature,
      timestamp: DateTime.now(),
      publicKeyUsed: publicKeyUsed,
    );

    // Add activity to the document
    final activity = DocumentActivity(
      action: 'Document signed by $userId',
      timestamp: DateTime.now(),
    );
    document.activities.add(activity);

    // Update the document in Firestore
    await documentRef.update({
      'signatures': document.signatures
          .map((key, value) => MapEntry(key, value.toJson())),
      'activities':
          document.activities.map((activity) => activity.toJson()).toList(),
    });
  }
}
