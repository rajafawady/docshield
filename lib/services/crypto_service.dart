import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../constants/app_constants.dart';

class CryptoService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Generate RSA key pair
  Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>>
      generateKeyPair() async {
    final secureRandom = FortunaRandom();
    // You need to provide some entropy to initialize FortunaRandom
    secureRandom
        .seed(KeyParameter(Uint8List.fromList(List.generate(32, (i) => i))));

    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(
            BigInt.parse('65537'),
            AppConstants.rsaKeySize,
            64,
          ),
          secureRandom,
        ),
      );

    final pair = keyGen.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  // Store private key in secure storage
  Future<void> storePrivateKey({
    required String userId,
    required RSAPrivateKey privateKey,
  }) async {
    final encodedKey = encodePrivateKey(privateKey);
    await _secureStorage.write(
      key: 'private_key_$userId',
      value: encodedKey,
    );
  }

  // Encode public key to base64
  String encodePublicKey(RSAPublicKey publicKey) {
    return base64Encode(
      _bigIntToBytes(publicKey.modulus!) +
          _bigIntToBytes(publicKey.publicExponent!),
    );
  }

  // Encode private key to base64
  String encodePrivateKey(RSAPrivateKey privateKey) {
    return base64Encode(
      _bigIntToBytes(privateKey.modulus!) +
          _bigIntToBytes(privateKey.privateExponent!),
    );
  }

  // Sign data using the private key
  Future<String> signData(String data, String userId) async {
    final privateKeyStr = await _secureStorage.read(key: 'private_key_$userId');
    if (privateKeyStr == null) throw Exception('Private key not found');

    final privateKey = decodePrivateKey(privateKeyStr);
    final signer = RSASigner(SHA256Digest(), AppConstants.signingAlgorithm);
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final signature = signer.generateSignature(
      Uint8List.fromList(utf8.encode(data)),
    );

    return base64Encode(signature.bytes);
  }

  // Verify signature using the public key
  bool verifySignature({
    required String data,
    required String signature,
    required String publicKeyStr,
  }) {
    try {
      final publicKey = decodePublicKey(publicKeyStr);
      final signer = RSASigner(SHA256Digest(), AppConstants.signingAlgorithm);
      signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

      return signer.verifySignature(
        Uint8List.fromList(utf8.encode(data)),
        RSASignature(base64Decode(signature)),
      );
    } catch (e) {
      return false;
    }
  }

  // Decode private key from base64
  RSAPrivateKey decodePrivateKey(String encodedKey) {
    final bytes = base64Decode(encodedKey);
    final modulus = _bytesToBigInt(bytes.sublist(0, 256));
    final privateExponent = _bytesToBigInt(bytes.sublist(256));
    return RSAPrivateKey(modulus, privateExponent, BigInt.zero, BigInt.zero);
  }

  // Decode public key from base64
  RSAPublicKey decodePublicKey(String encodedKey) {
    final bytes = base64Decode(encodedKey);
    final modulus = _bytesToBigInt(bytes.sublist(0, 256));
    final exponent = _bytesToBigInt(bytes.sublist(256));
    return RSAPublicKey(modulus, exponent);
  }

  // Convert BigInt to byte array
  List<int> _bigIntToBytes(BigInt bigInt) {
    final hexString =
        bigInt.toRadixString(16).padLeft(bigInt.bitLength ~/ 4, '0');
    final byteList = <int>[];
    for (var i = 0; i < hexString.length; i += 2) {
      byteList.add(int.parse(hexString.substring(i, i + 2), radix: 16));
    }
    return byteList;
  }

  // Convert byte array to BigInt
  BigInt _bytesToBigInt(List<int> bytes) {
    return BigInt.parse(
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16);
  }
}
