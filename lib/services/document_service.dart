import 'package:cloud_firestore/cloud_firestore.dart';
import 'dropbox_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/document_model.dart';
import '../widgets/document_activity.dart';
import '../constants/app_constants.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    required File file,
    required String fileName,
  }) async {
    final documentId = _uuid.v4();
    final dropboxService =
        DropboxService(accessToken: AppConstants.dropboxAccessToken);
    // Upload file to Firebase Storage
    final dropboxPath = '/documents/$documentId/$fileName';
    print('dropboxPath: $dropboxPath');
    final documentHash =
        await dropboxService.uploadFile(file: file, dropboxPath: dropboxPath);
    print('****document Hash*****: $documentHash');

    // Save metadata to Firestore
    final document = DocumentModel(
      id: documentId,
      name: fileName,
      ownerId: ownerId,
      documentHash: documentHash,
      signatures: {},
      createdAt: DateTime.now().toString(),
      status: 'Pending',
      sharedWith: [ownerId],
      documentUrl: dropboxPath,
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
    required String email,
  }) async {
    final documentRef = _firestore.collection('documents').doc(documentId);
    final docSnapshot = await documentRef.get();

    if (!docSnapshot.exists) {
      throw Exception('Document not found');
    }

    final document = DocumentModel.fromJson(docSnapshot.data()!);

    // Check if the document is already signed by the user
    if (document.signatures.containsKey(userId)) {
      throw Exception('alr_sign');
    }

    // Add the signature for the user
    document.signatures[userId] = DocumentSignature(
      userId: userId,
      signature: signature,
      timestamp: DateTime.now().toString(),
      publicKeyUsed: publicKeyUsed,
    );

    // Add activity to the document
    final activity = DocumentActivity(
      action: 'Document signed by $email',
      timestamp: DateTime.now().toString(),
    );
    document.activities.add(activity);

    // Update the document in Firestore
    await documentRef.update({
      'signatures': document.signatures
          .map((key, value) => MapEntry(key, value.toJson())),
      'activities':
          document.activities.map((activity) => activity.toJson()).toList(),
      'status': document.signatures.length == document.sharedWith.length
          ? 'Completed'
          : 'Pending',
    });
  }

  Future<void> shareDocument({
    required String documentId,
    required String ownerName,
    required String ownerId,
    required String inviteeName,
    required String userIdToShareWith,
  }) async {
    final documentRef = _firestore.collection('documents').doc(documentId);
    final docSnapshot = await documentRef.get();

    if (!docSnapshot.exists) {
      throw Exception('Document not found');
    }

    final document = DocumentModel.fromJson(docSnapshot.data()!);

    // Check if the current user is the owner of the document
    if (document.ownerId != ownerId) {
      throw Exception('Only the owner can share this document');
    }

    // Add the userId to the sharedWith array if not already present
    if (!document.sharedWith.contains(userIdToShareWith)) {
      document.sharedWith.add(userIdToShareWith);

      // Add activity to the document
      final activity = DocumentActivity(
        action: 'Document shared with $inviteeName by $ownerName',
        timestamp: DateTime.now().toString(),
      );
      document.activities.add(activity);

      // Update the document in Firestore
      await documentRef.update({
        'sharedWith': document.sharedWith,
        'activities':
            document.activities.map((activity) => activity.toJson()).toList(),
      });
    } else {
      throw Exception('alr_invited');
    }
  }

  Future<void> deleteDocument(String documentId, String dropboxPath) async {
    final docRef =
        FirebaseFirestore.instance.collection('documents').doc(documentId);

    try {
      // Delete the file from Dropbox
      final dropboxService =
          DropboxService(accessToken: AppConstants.dropboxAccessToken);
      await dropboxService.deleteFile(dropboxPath: dropboxPath);

      // Delete the document from Firestore
      await docRef.delete();
      print('Document and file deleted successfully');
    } catch (error) {
      print('Error deleting document or file: $error');
      throw Exception('Failed to delete document!');
    }
  }
}
