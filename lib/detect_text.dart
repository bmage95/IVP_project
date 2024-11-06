import 'dart:io';
import 'image_processing.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

Future<String> detectTextFromImage(String imagePath) async {
  // Preprocess the image and save it to a temporary file
  final processedImageData = await preprocessImage(imagePath);
  final processedImagePath = '${Directory.systemTemp.path}/processed_image.jpg';
  await File(processedImagePath).writeAsBytes(processedImageData);

  // Load the processed image with Google ML Kit
  final inputImage = InputImage.fromFilePath(processedImagePath);
  final textRecognizer = GoogleMlKit.vision.textRecognizer();

  // Perform text recognition
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

  // Collect the detected text
  final buffer = StringBuffer();
  for (TextBlock block in recognizedText.blocks) {
    for (TextLine line in block.lines) {
      buffer.writeln(line.text);
    }
  }

  // Release resources
  textRecognizer.close();

  return buffer.toString();
}
