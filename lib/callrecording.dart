import 'dart:io';

import 'package:callrecord/audioListing.dart';
import 'package:callrecord/voskApp.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class CallRecordingPage extends StatefulWidget {
  const CallRecordingPage({super.key});

  @override
  _CallRecordingPageState createState() => _CallRecordingPageState();
}

class _CallRecordingPageState extends State<CallRecordingPage> {
  static const platform = MethodChannel('com.yourapp/callrecording');

  @override
  void initState() {
    super.initState();
    requestPermissions(); // Request permissions when the widget is first initialized
  
  }

  // Future<void> requestPermissions() async {
  //   await Permission.microphone.request();
  //   await Permission.phone.request();
  //   await Permission.storage.request();

  //   if (await Permission.microphone.isDenied || await Permission.storage.isDenied) {
  //     // If permissions are denied, you can show a dialog or an alert to the user
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text('Permissions Required'),
  //         content: Text(
  //             'Microphone and storage permissions are required to record calls. Please grant them in settings.'),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text('OK'),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }


  Future<void> requestPermissions() async {
  await [
    Permission.microphone,
    Permission.phone,
    Permission.storage,
  ].request();
  }
  Future<void> startRecording() async {
    try {
      await platform.invokeMethod('startRecording');
    } on PlatformException catch (e) {
      print("Failed to start recording: ${e.message}");
    }
  }

  Future<void> stopRecording() async {
    try {
      await platform.invokeMethod('stopRecording');
    } on PlatformException catch (e) {
      print("Failed to stop recording: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Call Recording")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Call Transcriber",style: TextStyle(fontSize: 20),),
            // ElevatedButton(
            //   onPressed: startRecording,
            //   child: Text("Start Recording"),
            // ),
            // ElevatedButton(
            //   onPressed: stopRecording,
            //   child: Text("Stop Recording"),
            // ),
               ElevatedButton(
              onPressed: (){
           Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AudioListing()));
              },
              child: const Text("All Audio Listing"),
            ),
             ElevatedButton(
              onPressed: (){
                // fetchTranscriptions();
           Navigator.of(context).push(MaterialPageRoute(builder: (context) => UploadAndTranscribe()));
              },
              child: const Text("All Audio Listing Text"),
            ),
          ],
        ),
      ),
    );
  
  }

// Future<void> fetchTranscriptions() async {
//   final response = await http.get(Uri.parse('http://localhost:5000/transcribe_all?cache_dir=/data/data/com.example.callrecord/cache/'));

//   if (response.statusCode == 200) {
//     final Map<String, dynamic> transcripts = json.decode(response.body);
//     // Process the transcripts
//     print(transcripts);
//   } else {
//     print('Failed to load transcriptions');
//   }
// }

}
