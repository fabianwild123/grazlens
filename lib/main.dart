import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FlutterVision vision;
  bool isModelLoaded = false;

  @override

  void initState() {
    super.initState();
    vision = FlutterVision();
    _loadModel(); 
  }

  Future<void> _loadModel() async {
    await vision.loadYoloModel(
      modelPath: 'assets/models/yolov8n.tflite',
      labels: 'assets/models/labels.txt',
      modelVersion: 'yolov8',
      numThreads: 2,
      useGpu: true,
    );
    setState(() {
      isModelLoaded = true; 
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body:Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("GrazLens", style: GoogleFonts.playfairDisplay(fontSize: 50, ),),

            SizedBox(height: 20),

            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.black, minimumSize: Size(220, 50)), onPressed: () async {
              ImagePicker picker=ImagePicker();
              XFile? bild=await picker.pickImage(source: ImageSource.camera);},
              child: Text("FOTO AUFNEHMEN")),

            SizedBox(height:20),

            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.black, minimumSize: Size(220, 50)),onPressed: isModelLoaded ? () async {
              ImagePicker picker = ImagePicker(); 
              XFile? bild=await picker.pickImage(source: ImageSource.gallery);
              if (bild != null) {
                Uint8List imageBytes = await bild.readAsBytes();

                var results = await vision.yoloOnImage(
                  bytesList: imageBytes,
                  imageHeight: 640,
                  imageWidth: 640,
                  iouThreshold: 0.4,
                  confThreshold: 0.4,
                  classThreshold: 0.5,
                );

                print(results); }} : null,
              child: Text("FOTO HOCHLADEN")),

            SizedBox(height:20),

            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.black, minimumSize: Size(220, 50)),onPressed: () {
              },
              child: Text("VERLAUF")),

            SizedBox(height:20),
            
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.black, minimumSize: Size(220, 50)),onPressed: () {}, child: Text("FAVORITEN")),
          ],
        ),
      )
    );
  }
}