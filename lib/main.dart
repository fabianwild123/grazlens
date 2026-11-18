import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

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
  Interpreter? interpreter;
  bool isModelLoaded = false;
  bool isWorking = false;
  String? ladeFehler;
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

      if (!mounted) return;
      setState(() {
        isModelLoaded = true;
      });
    } catch (e, st) {
      debugPrint("Modell-Ladefehler: $e\n$st");
      if (!mounted) return;
      setState(() {
        ladeFehler = e.toString();
      });
    }
  }

  Future<void> _bildAnalysieren(ImageSource quelle) async {
    try {
      setState(() {
        ladeFehler = null;
      });

      ImagePicker picker = ImagePicker();
      XFile? bild = await picker.pickImage(source: quelle, imageQuality: 90);

      if (bild == null) return;

      setState(() {
        isWorking = true;
      });

      Uint8List imageBytes = await bild.readAsBytes();
      final img.Image? decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        setState(() {
          isWorking = false;
          ladeFehler = "Bildformat konnte nicht gelesen werden.";
        });
        return;
      }

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

      // Liest die exakte Ausgabe-Form des Modells automatisch aus (z.B. [1, 84, 8400])
      final outputShape = interpreter!.getOutputTensor(0).shape;
      final int numRows = outputShape[1];
      final int numBoxes = outputShape[2];
      final int numClasses = numRows - 4;

      var output = List.generate(
        1,
        (_) => List.generate(
          numRows,
          (_) => List.filled(numBoxes, 0.0),
        ),
      );

      interpreter!.run(input, output);

      List ergebnisse = [];
      double confThreshold = 0.4;

      for (int c = 0; c < numBoxes; c++) {
        double maxScore = 0.0;
        int bestClassId = -1;

        for (int i = 0; i < numClasses; i++) {
          final double score = output[0][i + 4][c];
          if (score > maxScore) {
            maxScore = score;
            bestClassId = i;
          }
        }

        if (maxScore > confThreshold && bestClassId >= 0) {
          final double x = output[0][0][c];
          final double y = output[0][1][c];
          final double w = output[0][2][c];
          final double h = output[0][3][c];

          String labelName = bestClassId < labels.length
              ? labels[bestClassId].toString().trim()
              : "Klasse $bestClassId";

          ergebnisse.add({
            'label': labelName,
            'xMin': x - w / 2,
            'yMin': y - h / 2,
            'w': w,
            'h': h,
            'classId': bestClassId,
            'score': maxScore,
          });
        }
      }

      if (!mounted) return;
      setState(() {
        isWorking = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ErgebnisScreen(ergebnisse: ergebnisse),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isWorking = false;
        ladeFehler = e.toString();
      });
    }
  }

  @override
  void dispose() {
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "GrazLens",
                style: GoogleFonts.playfairDisplay(fontSize: 50),
              ),

              if (isWorking)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),

              if (ladeFehler != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Fehler: $ladeFehler",
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(220, 50),
                ),
                onPressed: isModelLoaded && !isWorking
                    ? () => _bildAnalysieren(ImageSource.camera)
                    : null,
                child: const Text("FOTO AUFNEHMEN"),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(220, 50),
                ),
                onPressed: isModelLoaded && !isWorking
                    ? () => _bildAnalysieren(ImageSource.gallery)
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
      body: ergebnisse.isEmpty
          ? const Center(
              child: Text("Keine Objekte erkannt (Sicherheit unter 40 %)."),
            )
          : ListView.builder(
              itemCount: ergebnisse.length,
              itemBuilder: (context, index) {
                final item = ergebnisse[index];

                return ListTile(
                  title: Text(item['label'].toString()),
                  subtitle: Text("Sicherheit: ${item['score']}"),
                );
              },
            ),
    );
  }
}