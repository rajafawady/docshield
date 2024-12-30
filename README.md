# Document Security and Verification App

This application is designed to manage, share, and verify the integrity of documents. It ensures that documents remain untampered and validates the authenticity of digital signatures, providing robust security for sensitive files.

## Features

- **Document Upload and Hashing**: Compute and store the hash of uploaded files to ensure integrity.
- **Document Signing**: Users can digitally sign documents, and the signatures are securely stored.
- **Signature Verification**: Validate the authenticity of all signatures associated with a document.
- **Integrity Check**: Verify that the document has not been tampered with by comparing file hashes.
- **Activity History**: Track changes and actions performed on documents.
- **Secure Sharing**: Share documents securely with other users.
- **Dropbox Integration**: Download and preview documents stored in Dropbox.
- **PDF Preview**: View documents directly within the app.

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend Services**: Custom APIs for document and user management
- **Cryptography**: RSA for signing and verifying, SHA-256 for hashing
- **Cloud Storage**: Dropbox API for file storage and retrieval

## Installation

### Prerequisites

- Flutter SDK installed ([installation guide](https://flutter.dev/docs/get-started/install))
- A valid Dropbox API token

### Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/document-security-app.git
   cd document-security-app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure the Dropbox API token in `DropboxService`:
   ```dart
   final DropboxService _dropboxService = DropboxService(
       accessToken: 'your-dropbox-access-token');
   ```

4. Run the application:
   ```bash
   flutter run
   ```

## Usage

1. **Upload Document**:
   - Users can upload a document, which will be hashed and stored securely.

2. **Sign Document**:
   - Sign a document using your private key. The signature will be stored alongside the document.

3. **Verify Document**:
   - Ensure the document has not been tampered with by comparing its hash.
   - Validate the authenticity of all associated signatures.

4. **Share Document**:
   - Share the document with other users securely. Shared users can verify and sign the document.

## Folder Structure

```
lib/
|-- models/          # Data models (e.g., DocumentModel, UserModel)
|-- screens/         # UI screens (e.g., DocumentViewScreen)
|-- services/        # Logic for document handling, cryptography, and Dropbox integration
|-- widgets/         # Reusable UI components (e.g., DocumentInfoSheet, SignaturesSheet)
```

## Key Components

### Document Signing
- Uses RSA cryptography to sign documents.
- Signatures are stored securely and associated with the document.

### Document Verification
- Ensures the file hash matches the stored hash.
- Validates the authenticity of signatures using public keys.

### Dropbox Integration
- Downloads files securely from Dropbox.
- Allows previewing PDF documents within the app.

## Security Measures

- **SHA-256 Hashing**: Ensures document integrity by computing and storing a unique hash for each file.
- **RSA Digital Signatures**: Provides a mechanism for users to sign and verify documents.
- **Public-Key Infrastructure**: Uses public keys to validate signatures.
- **Secure Sharing**: Protects shared documents from unauthorized access.

## Future Enhancements

- **Multi-Factor Authentication (MFA)** for enhanced user security.
- **Role-Based Access Control (RBAC)** for document sharing.
- **Blockchain Integration** for tamper-proof activity logs.
- **Offline Mode** for viewing and signing documents without an internet connection.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bugfix:
   ```bash
   git checkout -b feature-name
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add new feature"
   ```
4. Push to your branch:
   ```bash
   git push origin feature-name
   ```
5. Submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions or support, please contact:

- **Email**: your-email@example.com
- **GitHub**: [your-username](https://github.com/your-username)

---

Thank you for using the Document Security and Verification App!

