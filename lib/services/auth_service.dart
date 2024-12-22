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
    print('signing in');
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('userCredential: ${userCredential.user?.uid}');
      final user = await _getOrCreateUser(userCredential.user!);
      return user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code}, ${e.message}');
      throw AuthException(e.message ?? 'Sign in failed');
    } catch (e) {
      print('Unexpected error: $e');
      throw AuthException('Unexpected error: $e');
    }
  }

  Future<UserModel> _getOrCreateUser(User firebaseUser) async {
    final userDoc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();
    print('userDoc: $userDoc');
    if (!userDoc.exists) {
      final keyPair = await _cryptoService.generateKeyPair();
      print('keypair: $keyPair');
      final user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        publicKey: _cryptoService.encodePublicKey(keyPair.publicKey),
        createdAt: DateTime.now(),
        roles: ['user'],
      );
      print("user: $user");
      await _firestore.collection('users').doc(user.id).set(user.toJson());
      print('firestore success!');
      // Store private key securely
      await _cryptoService.storePrivateKey(
        userId: user.id,
        privateKey: keyPair.privateKey,
      );
      print('private key stored!');
      return user;
    }

    return UserModel.fromJson(userDoc.data()!);
  }
}
