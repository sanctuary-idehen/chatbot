import 'dart:typed_data';
import 'package:chatbot_app/chatbotpage.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

import 'dart:async';




class FaceRecognitionPage extends StatefulWidget {
  const FaceRecognitionPage({Key? key}) : super(key: key);

  @override
  _FaceRecognitionPageState createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isDetecting = false;
  final String apiKey = '1eFbH1Nhf3OCPOhH6460Yc4YmkoU-ama';
  final String apiSecret = 'uPkjzw92nqGPkwggKr401mq7pIiTIHyV';
  List<FaceData> _faces = [];
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    print("Starting");
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      _controller = CameraController(cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      print("Before Mounted");

      if (!mounted) return;
      setState(() {});

      // Automatically capture image at intervals
      _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
        print(_isDetecting);
        if (!_isDetecting) {
          await captureImage();
        }
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> captureImage() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        setState(() {
          _isDetecting = true; // Prevent concurrent captures
        });
        final XFile image = await _controller!.takePicture();
        final Uint8List imageData = await image.readAsBytes();
        await compareFaces(imageData);
      } catch (e) {
        print('Error capturing image: $e');
        setState(() {
          _isDetecting = false; // Reset detecting flag on error
        });
      }
    }
  }

  Future<void> compareFaces(Uint8List capturedImageData) async {
    // Load the pre-existing image from assets
    final ByteData byteData =
        await rootBundle.load('assets/pre_existing_image.jpg');
    final Uint8List preExistingImageData = byteData.buffer.asUint8List();

    final url = 'https://api-us.faceplusplus.com/facepp/v3/compare';
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['api_key'] = apiKey
      ..fields['api_secret'] = apiSecret
      ..files.add(http.MultipartFile.fromBytes(
          'image_file1', preExistingImageData,
          filename: 'pre_existing_image.jpg'))
      ..files.add(http.MultipartFile.fromBytes('image_file2', capturedImageData,
          filename: 'captured_image.jpg'));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('API Response: $responseBody'); // Log the API response
        final Map<String, dynamic> result = jsonDecode(responseBody);

        // Check if 'confidence' is present and not null
        if (result.containsKey('confidence') && result['confidence'] is double) {
          final double confidence = result['confidence'];
          print('Confidence: $confidence'); // Log the confidence value
          if (confidence > 30.0) {
            // Adjust the confidence threshold as needed
            showSuccessPopup();
          } else {
            showMismatchPopup();
          }
        } else {
          print('Confidence value is missing or not a double');
          showMismatchPopup(); // Show popup for missing confidence value
        }
      } else {
        print('Failed to compare faces: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error comparing faces: $e');
    } finally {
      print('Is Detecting after compareFaces: $_isDetecting');
    }
  }

  void showSuccessPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Recognition Successful'),
          content: Text('The face has been successfully recognized.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                navigateToChatbot();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showMismatchPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Recognition Failed'),
          content: Text('The face does not match the pre-existing image.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isDetecting = false; // Reset detecting flag after mismatch
                });
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void navigateToChatbot() {
    _timer?.cancel(); // Stop the timer to prevent further captures
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatbotPage()),
    ).then((_) {
      // Restart the timer and detecting flag when coming back from P
      _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
        if (!_isDetecting) {
          await captureImage();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition')),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          if (_faces.isNotEmpty)
            CustomPaint(
              painter: FacePainter(_faces, _controller!),
            ),
        ],
      ),
    );
  }
}

class FaceData {
  final double left;
  final double top;
  final double right;
  final double bottom;

  FaceData({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory FaceData.fromJson(Map<String, dynamic> json) {
    final rect = json['face_rectangle'];
    return FaceData(
      left: rect['left'].toDouble(),
      top: rect['top'].toDouble(),
      right: (rect['left'] + rect['width']).toDouble(),
      bottom: (rect['top'] + rect['height']).toDouble(),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<FaceData> faces;
  final CameraController controller;

  FacePainter(this.faces, this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / controller.value.previewSize!.height;
    final double scaleY = size.height / controller.value.previewSize!.width;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.red;

    for (final FaceData face in faces) {
      final rect = Rect.fromLTRB(
        face.left * scaleX,
        face.top * scaleY,
        face.right * scaleX,
        face.bottom * scaleY,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}