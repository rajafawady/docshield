import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../models/user_model.dart';
import '../services/document_service.dart';
import '../widgets/document_info_sheet.dart';
import '../widgets/activity_history_sheet.dart';
import 'signatures_sheet.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class DocumentViewScreen extends StatefulWidget {
  final DocumentModel document;
  final UserModel currentUser;

  const DocumentViewScreen({
    Key? key,
    required this.document,
    required this.currentUser,
  }) : super(key: key);

  @override
  _DocumentViewScreenState createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends State<DocumentViewScreen> {
  final DocumentService _documentService = DocumentService();
  bool _isLoading = false;
  String _errorMessage = '';
  final TextEditingController _signatureController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();

  Future<void> _signDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final signature = _signatureController.text;
    final publicKeyUsed = _publicKeyController.text;

    if (signature.isEmpty || publicKeyUsed.isEmpty) {
      setState(() {
        _errorMessage = 'Signature and public key are required.';
        _isLoading = false;
      });
      return;
    }

    try {
      await _documentService.signDocument(
        documentId: widget.document.id,
        userId: widget.currentUser.id,
        signature: signature,
        publicKeyUsed: publicKeyUsed,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document signed successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign document: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => _showDocumentInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.document.documentUrl.isNotEmpty
                ? PDFView(
                    filePath: widget.document.documentUrl,
                    onError: (error) {
                      setState(() {
                        _errorMessage = 'Error loading document: $error';
                      });
                    },
                    onRender: (pages) {
                      debugPrint('Document rendered with $pages pages.');
                    },
                  )
                : const Center(
                    child: Text('Document URL is invalid or empty.'),
                  ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Activity'),
            onPressed: () => _showActivityHistory(context),
          ),
          TextButton.icon(
            icon: const Icon(Icons.people),
            label: const Text('Signatures'),
            onPressed: () => _showSignatures(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.draw),
            label: const Text('Sign Document'),
            onPressed: _isLoading ? null : _signDocument,
          ),
        ],
      ),
    );
  }

  void _showDocumentInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DocumentInfoSheet(document: widget.document),
    );
  }

  void _showActivityHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          ActivityHistorySheet(activities: widget.document.activities),
    );
  }

  void _showSignatures(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          SignaturesSheet(signatures: widget.document.signatures),
    );
  }
}
