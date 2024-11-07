import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'detect_text.dart';
import 'image_processing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(CameraApp(cameras));
}

class CameraApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  CameraApp(this.cameras);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: CameraScreen(cameras),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  CameraScreen(this.cameras);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool isCameraOn = true;
  XFile? capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(widget.cameras[0], ResolutionPreset.high);
    await _controller?.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleCamera() async {
    if (isCameraOn) {
      await _controller?.dispose();
      _controller = null;
    } else {
      _initializeCamera();
    }
    isCameraOn = !isCameraOn;
    setState(() {});
  }

  Future<void> _captureImage() async {
    if (_controller != null && _controller!.value.isInitialized) {
      capturedImage = await _controller!.takePicture();
      if (capturedImage != null) {
        final processedImage = await preprocessImage(capturedImage!.path);
        final recognizedText = await detectTextFromImage(capturedImage!.path); // Get text

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('saved_image', base64Encode(processedImage));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageDisplayScreen(
              processedImage: processedImage,
              recognizedText: recognizedText, // Pass text to screen
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: _controller == null || !_controller!.value.isInitialized
                  ? Center(
                child: Text(
                  isCameraOn ? 'Initializing Camera...' : 'Camera is Off',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              )
                  : CameraPreview(_controller!),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _toggleCamera,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(isCameraOn ? 'Turn Off' : 'Turn On', style: const TextStyle(fontSize: 24)),
                  ),
                  ElevatedButton(
                    onPressed: _captureImage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.camera_alt, size: 48),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Text(
              '!Click photo to try OCR!',
              style: GoogleFonts.nunito(
                textStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImageDisplayScreen extends StatelessWidget {
  final List<int> processedImage;
  final String recognizedText;

  const ImageDisplayScreen({
    super.key,
    required this.processedImage,
    required this.recognizedText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Processed Image")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display the processed image
          Image.memory(
            Uint8List.fromList(processedImage),
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 20),
          // Display recognized text below the image
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              recognizedText,
              style: const TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
