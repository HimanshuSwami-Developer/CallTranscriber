import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioListing extends StatefulWidget {
  const AudioListing({super.key});

  @override
  State<AudioListing> createState() => _AudioListingState();
}

class _AudioListingState extends State<AudioListing> {
  List<FileSystemEntity> audioFiles = [];
   final AudioPlayer audioPlayer = AudioPlayer();



Future<void> requestStoragePermission() async {
  if (await Permission.storage.request().isGranted) {
    // Permission is granted
    print("success");  } else {
    // Handle if permission is denied
  }
}

 void playAudio(String filePath) async {
     try {
      await audioPlayer.setSourceDeviceFile(filePath); // Updated method to set the source
      await audioPlayer.resume(); // Start playback
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose(); // Dispose the audio player when not in use
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    requestStoragePermission().then((_) {
      loadAudioFiles();
    });
  }

  Future<String> getDirectoryPath() async {
     List<Directory>? cacheDirs = await getExternalCacheDirectories();
    if (cacheDirs != null && cacheDirs.isNotEmpty) {
      return cacheDirs.first.path; // Use the first cache directory available
    } else {
      throw Exception("External cache directory not found");
    }
    // Directory? externalDir = await getExternalStorageDirectory();
    // return '${externalDir!.path}/Android/data/com.example.callrecord/cache';
  }

  void loadAudioFiles() async {
    String path = await getDirectoryPath();
    Directory directory = Directory(path);

    if (await directory.exists()) {
      List<FileSystemEntity> files = directory.listSync();

      setState(() {
        // Filter for audio files (e.g., .mp3)
        audioFiles = files.where((file) {
          final extension = file.path.split('.').last.toLowerCase();
          return extension == 'mp3' || extension == 'wav';
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Audio Files'),
        
      ),
      body: audioFiles.isEmpty
          ? const Center(child: Text('No audio files found'))
          : ListView.builder(
              itemCount: audioFiles.length,
              itemBuilder: (context, index) {
                FileSystemEntity file = audioFiles[index];
                return ListTile(
                  title: Text(file.path.split('/').last),
                  onTap: () {
                       playAudio(file.path); // Play audio when tapped
                  },
                );
              },
            ),
    );
  }
}