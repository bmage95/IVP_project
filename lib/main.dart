import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  int selectedCameraIndex = 0;
  bool isCameraOn = true;
  XFile? capturedImage; // Holds the captured image

  @override
  void initState() {
    super.initState();
    _initializeCamera(widget.cameras[selectedCameraIndex]);
  }

  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    _controller = CameraController(cameraDescription, ResolutionPreset.high);
    try {
      await _controller?.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
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
      _initializeCamera(widget.cameras[selectedCameraIndex]);
    }
    isCameraOn = !isCameraOn;
    setState(() {});
  }

  Future<void> _captureImage() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        capturedImage = await _controller!.takePicture();
        if (capturedImage != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageDisplayScreen(imagePath: capturedImage!.path),
            ),
          );
        }
      } catch (e) {
        print('Error capturing image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Camera Preview or Placeholder with 3:4 Aspect Ratio
          AspectRatio(
            aspectRatio: 3 / 4, // 3:4 Aspect Ratio
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
          // Buttons at the bottom
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _toggleCamera,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(isCameraOn ? 'Turn Off' : 'Turn On', style: const TextStyle(fontSize: 28)),
                ),
                ElevatedButton(
                  onPressed: _captureImage, // Shutter Button
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.camera_alt, size: 48,),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Text(
            '!Click photo to try OCR!',
            style: GoogleFonts.nunito(
              textStyle: const TextStyle(
                fontSize: 32,           // Make the text big
                fontWeight: FontWeight.bold,  // Bold text
                color: Colors.white,     // Fancy color
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// diff age
class ImageDisplayScreen extends StatelessWidget {
  final String imagePath;

  const ImageDisplayScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Captured Image"),
      ),
      body: Column(
        children: [
          // display in top half

          AspectRatio(
            aspectRatio: 3 / 4, // 3:4 Aspect Ratio
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),

          //code for ocr
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'OCR detected:',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
