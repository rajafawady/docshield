import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/crypto_service.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CryptoService _cryptoService = CryptoService();

  Future<UserModel> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = await _getOrCreateUser(userCredential.user!);
      return user;
    } catch (e) {
      throw AuthException('Sign in failed: $e');
    }
  }

  Future<UserModel> _getOrCreateUser(User firebaseUser) async {
    final userDoc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (!userDoc.exists) {
      final keyPair = await _cryptoService.generateKeyPair();

      final user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        publicKey: _cryptoService.encodePublicKey(keyPair.publicKey),
        createdAt: DateTime.now(),
        roles: ['user'],
      );

      await _firestore.collection('users').doc(user.id).set(user.toJson());

      // Store private key securely
      await _cryptoService.storePrivateKey(
        userId: user.id,
        privateKey: keyPair.privateKey,
      );

      return user;
    }

    return UserModel.fromJson(userDoc.data()!);
  }
}
