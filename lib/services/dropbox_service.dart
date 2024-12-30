import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DropboxService {
  final String accessToken;

  DropboxService({required this.accessToken});

  Future<String> uploadFile({
    required File file,
    required String dropboxPath,
  }) async {
    final url = Uri.parse('https://content.dropboxapi.com/2/files/upload');
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Dropbox-API-Arg': jsonEncode({
        'path': dropboxPath,
        'mode': 'add',
        'autorename': true,
        'mute': false,
        'strict_conflict': false,
      }),
      'Content-Type': 'application/octet-stream',
    };

    final fileBytes = await file.readAsBytes();

    final response = await http.post(url, headers: headers, body: fileBytes);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['content_hash'];
    } else {
      throw Exception('Error uploading file: ${response.reasonPhrase}');
    }
  }

  Future<Map<String, String>> downloadFile(
      {required String dropboxPath}) async {
    final url = Uri.parse('https://content.dropboxapi.com/2/files/download');
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Dropbox-API-Arg': jsonEncode({
        'path': dropboxPath,
      }),
    };
    final fileName = dropboxPath.split('/').last;
    final response = await http.post(url, headers: headers);
    if (response.statusCode == 200) {
      final responseHeaders = response.headers;
      final dropboxApiResult =
          jsonDecode(responseHeaders['dropbox-api-result']!);
      final documentHash = dropboxApiResult['content_hash'];
      return {
        'hash': documentHash,
        'path':
            await _saveFileToTemporaryDirectory(fileName, response.bodyBytes)
      };
    } else {
      print('Failed to download file: ${response.body}');
      throw Exception('Error downloading file: ${response.reasonPhrase}');
    }
  }

  Future<void> deleteFile({required String dropboxPath}) async {
    final url = Uri.parse('https://api.dropboxapi.com/2/files/delete_v2');
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'path': dropboxPath,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Error deleting file: ${response.reasonPhrase}');
    }
  }

  Future<String> _saveFileToTemporaryDirectory(
      String fileName, List<int> fileBytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/$fileName';
    final file = File(tempFilePath);
    await file.writeAsBytes(fileBytes);
    return tempFilePath;
  }

  // Future<String> _getFileFromTemporaryDirectory(String fileName) async {
  //   final tempDir = await getTemporaryDirectory();
  //   final tempFilePath = '${tempDir.path}/$fileName';
  //   final file = File(tempFilePath);
  //   if (await file.exists()) {
  //     return tempFilePath;
  //   } else {
  //     return 'not_found';
  //   }
  // }
}
