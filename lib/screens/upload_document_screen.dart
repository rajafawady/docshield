import 'package:flutter/material.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_model.dart';
import '../services/document_service.dart';

class UploadDocumentScreen extends StatefulWidget {
  final UserModel user;

  const UploadDocumentScreen({Key? key, required this.user}) : super(key: key);

  @override
  _UploadDocumentScreenState createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final DocumentService _documentService = DocumentService();
  File? _selectedFile;
  bool _isLoading = false;
  String _errorMessage = '';
  double _uploadProgress = 0.0;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        // Restrict file size to 5 MB
        if (fileSize > 5 * 1024 * 1024) {
          setState(() {
            _errorMessage =
                'File size exceeds 5 MB. Please select a smaller file.';
          });
          return;
        }

        setState(() {
          _selectedFile = file;
          _nameController.text = result.files.single.name;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  String _calculateFileHash(File file) {
    final bytes = file.readAsBytesSync();
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) return;

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _errorMessage = '';
    });

    try {
      final fileHash = _calculateFileHash(_selectedFile!);

      await _documentService.uploadDocument(
        filePath: _selectedFile!.path,
        fileName: _nameController.text,
        documentHash: fileHash,
        ownerId: widget.user.id,
      );

      Navigator.pop(context, 'Document uploaded successfully!');
    } catch (e) {
      setState(() {
        _errorMessage = 'Upload failed: $e';
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
      appBar: AppBar(title: const Text('Upload Document')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedFile != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(_selectedFile!.path.split('/').last),
                    subtitle: FutureBuilder<int>(
                      future: _selectedFile!.length(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final kb = snapshot.data! / 1024;
                        return Text('${kb.toStringAsFixed(1)} KB');
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
                          _nameController.clear();
                        });
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Document Name',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a document name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_selectedFile == null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select PDF'),
                  onPressed: _pickFile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              if (_selectedFile != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(_isLoading ? 'Uploading...' : 'Upload Document'),
                  onPressed: _isLoading ? null : _uploadDocument,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(value: _uploadProgress),
                ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
