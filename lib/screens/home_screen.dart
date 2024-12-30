import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/document_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/document_service.dart';
import 'auth_screen.dart';
import 'upload_document_screen.dart';
import 'document_view_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DocumentService _documentService = DocumentService();
  List<DocumentModel> _userDocuments = [];
  List<DocumentModel> _otherDocuments = [];
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(user: widget.user),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<DocumentModel>>(
            stream: _documentService.getDocuments(widget.user.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.red)));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final documents = snapshot.data!;
              _userDocuments = documents
                  .where((doc) => doc.ownerId == widget.user.id)
                  .toList();
              _otherDocuments = documents
                  .where((doc) => doc.ownerId != widget.user.id)
                  .toList();

              if (documents.isEmpty) {
                return const Center(
                    child: Text('No documents found.',
                        style: TextStyle(color: Colors.grey)));
              }

              return ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  if (_userDocuments.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('My Documents',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                    ),
                    ..._userDocuments
                        .map((document) => _buildDocumentCard(document))
                        .toList(),
                  ],
                  if (_otherDocuments.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Shared Documents',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                    ),
                    ..._otherDocuments
                        .map((document) => _buildDocumentCard(document))
                        .toList(),
                  ],
                ],
              );
            },
          ),
          if (_isDeleting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadDocumentScreen(user: widget.user),
            ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    final isOwner = document.ownerId == widget.user.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      child: ListTile(
        title: Text(document.name, style: TextStyle(color: Colors.black)),
        subtitle: Text(
          'Status: ${document.status}',
          style: TextStyle(
            color:
                document.status == 'Completed' ? Colors.green : Colors.orange,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentViewScreen(
                      document: document,
                      currentUser: widget.user,
                    ),
                  ),
                );
              },
            ),
            if (isOwner)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Document'),
                      content: const Text(
                          'Are you sure you want to delete this document?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    setState(() {
                      _isDeleting = true;
                    });
                    try {
                      await _documentService.deleteDocument(
                          document.id, document.documentUrl);
                      setState(() {
                        _userDocuments.remove(document);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Document deleted successfully.'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                        ),
                      );
                    } finally {
                      setState(() {
                        _isDeleting = false;
                      });
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
