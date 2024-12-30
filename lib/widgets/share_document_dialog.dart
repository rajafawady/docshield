import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/document_service.dart';
import '../services/auth_service.dart';

class ShareDocumentDialog extends StatefulWidget {
  final String documentId;
  final UserModel currentUser;

  const ShareDocumentDialog(
      {Key? key, required this.documentId, required this.currentUser})
      : super(key: key);

  @override
  _ShareDocumentDialogState createState() => _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends State<ShareDocumentDialog> {
  final TextEditingController _searchController = TextEditingController();
  late Stream<List<UserModel>> _usersStream;
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String? _errorMessage; // Variable to hold error message

  @override
  void initState() {
    super.initState();
    _usersStream = AuthService().getAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredUsers = _filteredUsers
          .where(
              (user) => user.email.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _shareDocumentWithUser(UserModel user) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Reset error message
    });

    try {
      // Call your function to share the document with this user
      await DocumentService().shareDocument(
        documentId: widget.documentId,
        ownerId: widget.currentUser.id,
        userIdToShareWith: user.id,
        ownerName: widget.currentUser.email,
        inviteeName: user.email,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document shared with ${user.email}')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        final errorMessage = e is Exception ? e.toString() : 'Unknown error';
        _isLoading = false;
        if (errorMessage.contains('alr_invited')) {
          _errorMessage = 'Document already shared with this user!';
        } else {
          _errorMessage = 'Failed to share document, try again!';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Document'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search User',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 10),
            // Display error message inside the dialog if exists
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<UserModel>>(
                    stream: _usersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No users found'));
                      }

                      // Filter users based on search query
                      _filteredUsers = snapshot.data!
                          .where((user) => user.email
                              .toLowerCase()
                              .contains(_searchController.text.toLowerCase()))
                          .toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return ListTile(
                            title: Text(user.email),
                            subtitle: Text(user.email),
                            onTap: () => _shareDocumentWithUser(user),
                          );
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
