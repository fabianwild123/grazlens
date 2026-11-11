import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
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
              foregroundColor: Colors.black, minimumSize: Size(220, 50)),onPressed: () async {
              ImagePicker picker = ImagePicker(); picker = ImagePicker();
              XFile? bild=await picker.pickImage(source: ImageSource.gallery);},
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