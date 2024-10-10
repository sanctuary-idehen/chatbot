import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraView extends StatefulWidget {
  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  bool loading = true;
  late List<CameraDescription> _cameras;
  late CameraController? controller;

  @override
  void initState() {
    availableCameras().then((cameras) {
      _cameras = cameras;

      CameraDescription frontFacingCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);

      controller = CameraController(frontFacingCamera, ResolutionPreset.medium);
      controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          loading = false;
        });
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (controller != null && !controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(body: CameraPreview(controller!));
  }
}