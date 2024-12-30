import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../models/user_model.dart';
import '../services/document_service.dart';
import '../services/crypto_service.dart';
import '../widgets/document_info_sheet.dart';
import '../widgets/activity_history_sheet.dart';
import '../services/dropbox_service.dart';
import '../widgets/signatures_sheet.dart';
import '../widgets/share_document_dialog.dart'; // Add this line to import the ShareDocumentDialog widget
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../constants/app_constants.dart';

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
  final CryptoService _cryptoService = CryptoService();
  final DocumentService _documentService = DocumentService();
  bool _isLoading = false;
  bool _isSignLoading = false;
  String _errorMessage = '';
  final DropboxService _dropboxService =
      DropboxService(accessToken: AppConstants.dropboxAccessToken);
  String? _localFilePath;
  String? _documentHash;

  @override
  void initState() {
    super.initState();
    _fetchAndPreviewFile();
  }

  Future<void> _fetchAndPreviewFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _dropboxService.downloadFile(
          dropboxPath: widget.document.documentUrl);
      setState(() {
        _localFilePath = response['path'];
        _documentHash = response['hash'];
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load document: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signDocument() async {
    setState(() {
      _isSignLoading = true;
      _errorMessage = '';
    });

    try {
      final signature = await _cryptoService.signData(
          widget.document.documentHash, widget.currentUser.id);

      print('signature: $signature');
      await _documentService.signDocument(
        email: widget.currentUser.email,
        documentId: widget.document.id,
        userId: widget.currentUser.id,
        signature: signature,
        publicKeyUsed: widget.currentUser.publicKey,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document signed successfully')),
      );
    } catch (e) {
      setState(() {
        final errorMessage = e is Exception ? e.toString() : 'Unknown error';
        if (errorMessage.contains('alr_sign')) {
          _errorMessage = 'Document already signed by this user!';
        } else {
          _errorMessage = 'Failed to sign document, try again!';
        }
      });
    } finally {
      setState(() {
        _isSignLoading = false;
      });
    }
  }

  Future<void> _verifyDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final documentHash = widget.document.documentHash;
      final signatures = widget.document.signatures;
      bool allValid = true;

      if (_documentHash != widget.document.documentHash) {
        throw Exception(
            'Document integrity check failed: The file has been tampered with.');
      }

      if (signatures.isEmpty) {
        throw Exception('No signatures yet!');
      }

      for (var signatureData in signatures.values) {
        final isValid = _cryptoService.verifySignature(
          data: documentHash,
          signature: signatureData.signature,
          publicKeyStr: signatureData.publicKeyUsed,
        );

        if (!isValid) {
          allValid = false;
          break;
        }
      }

      if (allValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('All signatures are valid and document is safe!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Some signatures are invalid!')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _localFilePath != null
                    ? PDFView(
                        filePath: _localFilePath,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'verify':
                  _verifyDocument();
                  break;
                case 'activity':
                  _showActivityHistory(context);
                  break;
                case 'signatures':
                  _showSignatures(context);
                  break;
                case 'share':
                  _showShareDialog(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'verify',
                child: ListTile(
                  leading: Icon(Icons.verified),
                  title: Text('Verify Document'),
                ),
              ),
              const PopupMenuItem(
                value: 'signatures',
                child: ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Signatures'),
                ),
              ),
              if (widget.currentUser.id == widget.document.ownerId) ...[
                const PopupMenuItem(
                  value: 'activity',
                  child: ListTile(
                    leading: Icon(Icons.history),
                    title: Text('Activity'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share Document'),
                  ),
                ),
              ],
            ],
            child: const Icon(Icons.more_vert),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.draw),
            label: _isSignLoading
                ? const Text('Signing Document...')
                : const Text('Sign Document'),
            onPressed: _isSignLoading ? null : _signDocument,
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

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ShareDocumentDialog(
            documentId: widget.document.id, currentUser: widget.currentUser);
      },
    );
  }
}
