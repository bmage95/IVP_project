import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
  bool isCameraOn = true; // To track camera on/off state

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
      // Handle any errors during initialization
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _flipCamera() {
    if (isCameraOn) {
      selectedCameraIndex = (selectedCameraIndex + 1) % widget.cameras.length;
      _initializeCamera(widget.cameras[selectedCameraIndex]);
    }
  }

  void _toggleCamera() async {
    if (isCameraOn) {
      await _controller?.dispose();
      _controller = null; // Set controller to null after disposing
    } else {
      _initializeCamera(widget.cameras[selectedCameraIndex]);
    }
    isCameraOn = !isCameraOn;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Camera Preview or Placeholder
          Expanded(
            flex: 2,
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: _controller == null || !_controller!.value.isInitialized
                  ? Center(
                child: Text(
                  isCameraOn ? 'Initializing Camera...' : 'Camera is Off',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              )
                  : CameraPreview(_controller!),
            ),
          ),
          // Buttons at the bottom
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _flipCamera,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Flip Camera'),
                ),
                SizedBox(width: 20), // Space between buttons
                ElevatedButton(
                  onPressed: _toggleCamera,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(isCameraOn ? 'Turn Off' : 'Turn On'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
