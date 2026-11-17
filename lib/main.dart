import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

void main() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              'Fehler aufgetreten:\n\n${details.exceptionAsString()}\n\nStacktrace:\n${details.stack}',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  };

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
  late Interpreter interpreter;
  bool isModelLoaded = false;
  List labels = [];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/yolov8n.tflite');
      final rawLabels = await rootBundle.loadString('assets/labels.txt');
      labels = rawLabels.split('\n');

      setState(() {
        isModelLoaded = true;
      });
    } catch (e) {
      debugPrint("Modell-Ladefehler: $e");
    }
  }

  @override
  void dispose() {
    interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "GrazLens",
              style: GoogleFonts.playfairDisplay(fontSize: 50),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(220, 50),
              ),
              onPressed: () async {
                ImagePicker picker = ImagePicker();
                XFile? bild = await picker.pickImage(source: ImageSource.camera);
              },
              child: const Text("FOTO AUFNEHMEN"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(220, 50),
              ),
              onPressed: isModelLoaded
                  ? () async {
                      ImagePicker picker = ImagePicker();
                      XFile? bild = await picker.pickImage(source: ImageSource.gallery);

                      if (bild != null) {
                        Uint8List imageBytes = await bild.readAsBytes();
                        final img.Image? decodedImage = img.decodeImage(imageBytes);

                        if (decodedImage == null) return;

                        final img.Image resizedImage = img.copyResize(
                          decodedImage,
                          width: 640,
                          height: 640,
                        );

                        var input = List.generate(
                          1,
                          (b) => List.generate(
                            640,
                            (y) => List.generate(
                              640,
                              (x) {
                                final pixel = resizedImage.getPixel(x, y);
                                return [
                                  pixel.r / 255.0,
                                  pixel.g / 255.0,
                                  pixel.b / 255.0,
                                ];
                              },
                            ),
                          ),
                        );

                        var output = List.generate(
                          1,
                          (_) => List.generate(
                            84,
                            (_) => List.filled(8400, 0.0),
                          ),
                        );

                        interpreter.run(input, output);

                        List ergebnisse = [];
                        double confThreshold = 0.4;

                        for (int c = 0; c < 8400; c++) {
                          double maxScore = 0.0;
                          int bestClassId = -1;

                          for (int i = 0; i < 80; i++) {
                            final double score = output[0][i + 4][c];
                            if (score > maxScore) {
                              maxScore = score;
                              bestClassId = i;
                            }
                          }

                          if (maxScore > confThreshold) {
                            final double x = output[0][0][c];
                            final double y = output[0][1][c];
                            final double w = output[0][2][c];
                            final double h = output[0][3][c];

                            ergebnisse.add({
                              'label': labels[bestClassId].trim(),
                              'xMin': x - w / 2,
                              'yMin': y - h / 2,
                              'w': w,
                              'h': h,
                              'classId': bestClassId,
                              'score': maxScore,
                            });
                          }
                        }

                        // NEU: Wechselt nach der Berechnung auf den Ergebnis-Bildschirm
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ErgebnisScreen(ergebnisse: ergebnisse),
                          ),
                        );
                      }
                    }
                  : null,
              child: const Text("FOTO HOCHLADEN"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(220, 50),
              ),
              onPressed: () {},
              child: const Text("VERLAUF"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(220, 50),
              ),
              onPressed: () {},
              child: const Text("FAVORITEN"),
            ),
          ],
        ),
      ),
    );
  }
}

class ErgebnisScreen extends StatelessWidget {
  final List ergebnisse;

  const ErgebnisScreen({super.key, required this.ergebnisse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Erkannte Objekte")),
      body: ListView.builder(
        itemCount: ergebnisse.length,
        itemBuilder: (context, index) {
          final item = ergebnisse[index];

          // NEU: Zeigt Name und Wahrscheinlichkeit als einfache Textzeile an
          return ListTile(
            title: Text(item['label'].toString()),
            subtitle: Text("Sicherheit: ${item['score']}"),
          );
        },
      ),
    );
  }
}