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
    // Convert modulus and exponent to byte arrays and concatenate them
    final modulusBytes = _bigIntToBytes(publicKey.modulus!);
    final exponentBytes = _bigIntToBytes(publicKey.publicExponent!);
    print('Modulus length: ${modulusBytes.length}');
    // Combine the byte arrays (modulus first, then exponent)
    return base64Encode(modulusBytes + exponentBytes);
  }

  // Encode private key to base64
  String encodePrivateKey(RSAPrivateKey privateKey) {
    final modulusBytes = _bigIntToBytes(privateKey.modulus!);
    final privateExponentBytes = _bigIntToBytes(privateKey.privateExponent!);
    final pBytes = _bigIntToBytes(privateKey.p!);
    final qBytes = _bigIntToBytes(privateKey.q!);

    // Debugging: Log the lengths of the components
    print('Modulus length: ${modulusBytes.length}');
    print('Private Exponent length: ${privateExponentBytes.length}');
    print('p length: ${pBytes.length}');
    print('q length: ${qBytes.length}');

    // Concatenate the byte arrays
    final allBytes = modulusBytes + privateExponentBytes + pBytes + qBytes;

    // Encode the concatenated bytes in Base64
    return base64Encode(allBytes);
  }

  // Sign data using the private key
  Future<String> signData(String data, String userId) async {
    try {
      final privateKeyStr =
          await _secureStorage.read(key: 'private_key_$userId');
      if (privateKeyStr == null) throw Exception('Private key not found');

      final privateKey = decodePrivateKey(privateKeyStr);
      print('decoded successfully');
      final signer = RSASigner(SHA256Digest(), AppConstants.signingAlgorithm);
      print('signer assigned');
      signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
      print('signer init');
      final signature = signer.generateSignature(
        Uint8List.fromList(utf8.encode(data)),
      );
      print('signature gen');
      return base64Encode(signature.bytes);
    } catch (e) {
      throw Exception('Failed to sign data: $e');
    }
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

    // Debugging: Log the total byte length
    print('Decoded byte length: ${bytes.length}');

    // Correcting the split logic based on the known sizes of the key components
    final modulusSize = 256; // 256 bytes for modulus
    final privateExponentSize = 256; // 256 bytes for private exponent
    final pSize = 128; // 128 bytes for p
    final qSize = 128; // 128 bytes for q

    // Debugging: Log the sizes of the extracted components
    print('Modulus size: $modulusSize');
    print('Private Exponent size: $privateExponentSize');
    print('p size: $pSize');
    print('q size: $qSize');

    // Extract components based on their sizes
    final modulus = _bytesToBigInt(bytes.sublist(0, modulusSize));
    final privateExponent = _bytesToBigInt(
        bytes.sublist(modulusSize, modulusSize + privateExponentSize));
    final p = _bytesToBigInt(bytes.sublist(modulusSize + privateExponentSize,
        modulusSize + privateExponentSize + pSize));
    final q = _bytesToBigInt(
        bytes.sublist(modulusSize + privateExponentSize + pSize, bytes.length));

    return RSAPrivateKey(modulus, privateExponent, p, q);
  }

  // Decode public key from base64
  RSAPublicKey decodePublicKey(String encodedKey) {
    final bytes = base64Decode(encodedKey);

    // Calculate the length of the modulus (this will depend on the key size)
    final modulusLength = 256;

    // Extract the modulus and exponent from the byte array
    final modulus = _bytesToBigInt(bytes.sublist(0, modulusLength));
    final exponent = _bytesToBigInt(bytes.sublist(modulusLength));
    print('Modulus length: ${modulusLength}');

    return RSAPublicKey(modulus, exponent);
  }

  // Convert BigInt to byte array
  List<int> _bigIntToBytes(BigInt bigInt) {
    // Handle BigInt greater than or equal to zero
    if (bigInt.isNegative) {
      throw Exception('RSA key components should not be negative');
    }

    // Get the number of bytes required to store the BigInt
    final byteLength = (bigInt.bitLength + 7) >>
        3; // Equivalent to: (bigInt.bitLength + 7) / 8

    // Convert BigInt to byte array in big-endian order
    final byteList = List<int>.filled(byteLength, 0);

    for (int i = byteLength - 1; i >= 0; i--) {
      byteList[i] = (bigInt & BigInt.from(0xff)).toInt();
      bigInt = bigInt >> 8; // Shift by 8 bits for the next byte
    }

    return byteList;
  }

  // Convert byte array to BigInt
  BigInt _bytesToBigInt(List<int> bytes) {
    // Handle empty byte array or null input
    if (bytes.isEmpty) {
      throw Exception('Byte array cannot be empty');
    }

    // Convert byte array to BigInt in big-endian order
    BigInt bigInt = BigInt.zero;

    for (int byte in bytes) {
      bigInt = (bigInt << 8) | BigInt.from(byte);
    }

    return bigInt;
  }
}
