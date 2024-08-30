import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UploadAndTranscribe extends StatefulWidget {
  @override
  _UploadAndTranscribeState createState() => _UploadAndTranscribeState();
}

class _UploadAndTranscribeState extends State<UploadAndTranscribe> {
  String _transcription = 'No transcription available';
Future<void> uploadFile(File file) async {
  var uri = Uri.parse('http://192.168.154.202:5000/upload'); // Replace with your server address
  var request = http.MultipartRequest('POST', uri)
    ..files.add(await http.MultipartFile.fromPath('file', file.path));

  var response = await request.send();
  if (response.statusCode == 200) {
    print('File uploaded successfully');
  } else {
    print('File upload failed with status: ${response.statusCode}');
  }
}

  Future<void> requestTranscription(String cacheDir) async {
    var uri = Uri.parse('http://192.168.154.202:5000/transcribe_all?cache_dir=$cacheDir'); // Replace with your server address
    var response = await http.get(uri);

    if (response.statusCode == 200) {
      setState(() {
        _transcription = response.body;
      });
    } else {
      setState(() {
        _transcription = 'Failed to get transcription: ${response.reasonPhrase}';
      });
    }
  }

  Future<void> handleUploadAndTranscription() async {
    Directory tempDir = await getTemporaryDirectory();
    String cacheDir = "/storage/emulated/0/Android/data/com.example.callrecord/cache/";
    // tempDir.path; // Use the cache directory path

    // Assume you have a method to get the latest audio file in the cache directory
    File latestFile = await getLatestRecordingFile(cacheDir);

    // await uploadFile(latestFile);
    if (await latestFile.exists()) {
    await uploadFile(latestFile);
  } else {
    print('File not found');
  }

    await requestTranscription(cacheDir);
  }

  Future<File> getLatestRecordingFile(String dirPath) async {
    Directory dir = Directory(dirPath);
    List<FileSystemEntity> files = dir.listSync();
    if (files.isNotEmpty) {
      // Sort by modification date and get the latest file
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return File(files.first.path);
    } else {
      throw Exception('No audio files found in cache');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload and Transcribe'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _transcription,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleUploadAndTranscription,
              child: Text('Upload and Transcribe'),
            ),
          ],
        ),
      ),
    );
  }
}

