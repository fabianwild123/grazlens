import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FlutterVision vision;
  bool isModelLoaded = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
    _loadYoloModel();
  }

  Future<void> _loadYoloModel() async {
    try {
      await vision.loadYoloModel(
        modelPath: 'assets/yolov8n.tflite',
        labels: 'assets/labels.txt',
        modelVersion: 'yolov8',
        numThreads: 2,
        useGpu: false,
      );
      setState(() {
        isModelLoaded = true;
      });
    } catch (e) {
      debugPrint("Fehler beim Laden des Modells: $e");
    }
  }

  @override
  void dispose() {
    vision.closeYoloModel();
    super.dispose();
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    if (!isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modell lädt noch... Bitte kurz warten.')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? bild = await picker.pickImage(source: source);
    if (bild == null) return;

    setState(() => isProcessing = true);

    try {
      final Uint8List bytes = await bild.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);

      // Hier: bytesList statt bytes
      final results = await vision.yoloOnImage(
        bytesList: bytes,
        imageHeight: decodedImage.height,
        imageWidth: decodedImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5,
      );

      if (!mounted) return;
      setState(() => isProcessing = false);

      _showResults(bytes, results);
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Erkennung: $e')),
      );
    }
  }

  // Korrigierter Methodenkopf
void _showResults(Uint8List imageBytes, dynamic results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Erkannte Objekte (${results.length})",
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(imageBytes, height: 180, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text("Keine Objekte erkannt."))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        final tag = item['tag'] ?? 'Unbekannt';
                        final conf = ((item['box'][4] ?? 0) * 100).toStringAsFixed(1);
                        return ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.blueAccent),
                          title: Text(tag, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Text('$conf %', style: const TextStyle(color: Colors.grey)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.black,
      minimumSize: const Size(220, 50),
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("GrazLens", style: GoogleFonts.playfairDisplay(fontSize: 50)),
            const SizedBox(height: 20),

            if (isProcessing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              const Text("YOLO analysiert Bild..."),
              const SizedBox(height: 20),
            ],

            ElevatedButton(
              style: buttonStyle,
              onPressed: isProcessing ? null : () => _pickAndAnalyze(ImageSource.camera),
              child: const Text("FOTO AUFNEHMEN"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: buttonStyle,
              onPressed: isProcessing ? null : () => _pickAndAnalyze(ImageSource.gallery),
              child: const Text("FOTO HOCHLADEN"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: buttonStyle,
              onPressed: () {},
              child: const Text("VERLAUF"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: buttonStyle,
              onPressed: () {},
              child: const Text("FAVORITEN"),
            ),
          ],
        ),
      ),
    );
  }
}