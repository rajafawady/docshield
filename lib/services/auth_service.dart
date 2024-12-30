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
    print('signing in with $email and $password');
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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
      print('*****PVT KEY******: ${keyPair.privateKey.toString()}');
      final user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        publicKey: _cryptoService.encodePublicKey(keyPair.publicKey),
        createdAt: DateTime.now().toString(),
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

  Stream<List<UserModel>> getAllUsers() {
    try {
      final users = _firestore.collection('users').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return UserModel.fromJson(doc.data());
        }).toList();
      });
      return users;
    } catch (e) {
      print('Error fetching users: $e');
      throw AuthException('Error fetching users: $e');
    }
  }

  Future<String> getUserEmailById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final user = UserModel.fromJson(userDoc.data()!);
        return user.email;
      } else {
        throw AuthException('User not found');
      }
    } catch (e) {
      print('Error fetching user email: $e');
      throw AuthException('Error fetching user email: $e');
    }
  }
}
