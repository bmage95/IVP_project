// preprocess.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart';

Future<Uint8List> preprocessImage(String path) async {
  final image = decodeImage(File(path).readAsBytesSync());
  if (image == null) throw Exception("Failed to load image");

  // Step 1: Convert to grayscale
  final grayImage = grayscale(image);

  // Step 2: Apply Gaussian blur to reduce noise
  final blurredImage = gaussianBlur(grayImage, 3);

  // Step 3: Adaptive thresholding
  final thresholdedImage = adaptiveThreshold(blurredImage, 15, 10);

  // Step 4: Light Dilation
  final dilatedImage = lightDilation(thresholdedImage);

  // Step 5: Light Erosion
  final erodedImage = lightErosion(dilatedImage);

  // Resize to 3:4 aspect ratio (e.g., 480x640)
  final resizedImage = copyResize(erodedImage, width: 480, height: 640);

  return Uint8List.fromList(encodeJpg(resizedImage));
}

// Additional helper functions
Image adaptiveThreshold(Image image, int blockSize, int offset) {
  final result = image.clone();
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      int sum = 0, count = 0;
      for (int j = -blockSize ~/ 2; j <= blockSize ~/ 2; j++) {
        for (int i = -blockSize ~/ 2; i <= blockSize ~/ 2; i++) {
          int nx = x + i, ny = y + j;
          if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
            sum += getLuminance(image.getPixel(nx, ny));
            count++;
          }
        }
      }
      int average = sum ~/ count;
      int intensity = getLuminance(image.getPixel(x, y));
      result.setPixel(x, y, intensity < average - offset ? 0xFF000000 : 0xFFFFFFFF);
    }
  }
  return result;
}

Image lightDilation(Image image) {
  final result = image.clone();
  for (int y = 1; y < image.height - 1; y++) {
    for (int x = 1; x < image.width - 1; x++) {
      if (image.getPixel(x, y) == 0xFF000000) {
        if (result.getPixel(x - 1, y) == 0xFFFFFFFF) result.setPixel(x - 1, y, 0xFF000000);
        if (result.getPixel(x + 1, y) == 0xFFFFFFFF) result.setPixel(x + 1, y, 0xFF000000);
        if (result.getPixel(x, y - 1) == 0xFFFFFFFF) result.setPixel(x, y - 1, 0xFF000000);
        if (result.getPixel(x, y + 1) == 0xFFFFFFFF) result.setPixel(x, y + 1, 0xFF000000);
      }
    }
  }
  return result;
}

Image lightErosion(Image image) {
  final result = image.clone();
  for (int y = 1; y < image.height - 1; y++) {
    for (int x = 1; x < image.width - 1; x++) {
      if (image.getPixel(x, y) == 0xFFFFFFFF &&
          (image.getPixel(x - 1, y) == 0xFF000000 ||
              image.getPixel(x + 1, y) == 0xFF000000 ||
              image.getPixel(x, y - 1) == 0xFF000000 ||
              image.getPixel(x, y + 1) == 0xFF000000)) {
        result.setPixel(x, y, 0xFF000000);
      }
    }
  }
  return result;
}
