import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quicksplit/core/router/router.dart';

/// Camera screen for capturing receipt photos
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  late CameraController _cameraController;
  late Future<void> _initializeCameraFuture;
  FlashMode _flashMode = FlashMode.auto;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available')),
          );
        }
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController.initialize();
      await _cameraController.setFlashMode(_flashMode);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera initialization error: $e')),
        );
      }
    }
  }

  Future<void> _captureAndProcess() async {
    try {
      if (!_cameraController.value.isInitialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera not ready')),
          );
        }
        return;
      }

      final image = await _cameraController.takePicture();

      if (mounted) {
        context.pushNamed(
          RouteNames.ocrPreview,
          extra: image.path,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture error: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        context.pushNamed(
          RouteNames.ocrPreview,
          extra: pickedFile.path,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      final modes = [FlashMode.auto, FlashMode.always, FlashMode.off];
      final currentIndex = modes.indexOf(_flashMode);
      final nextMode = modes[(currentIndex + 1) % modes.length];

      await _cameraController.setFlashMode(nextMode);

      setState(() {
        _flashMode = nextMode;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flash toggle error: $e')),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCameraInitialized || !_cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  String _getFlashLabel() {
    switch (_flashMode) {
      case FlashMode.auto:
        return 'Flash: Auto';
      case FlashMode.always:
        return 'Flash: On';
      case FlashMode.off:
        return 'Flash: Off';
      default:
        return 'Flash: Auto';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        elevation: 0,
      ),
      body: FutureBuilder<void>(
        future: _initializeCameraFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (!_isCameraInitialized) {
              return const Center(
                child: Text('Camera initialization failed'),
              );
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FloatingActionButton(
                            heroTag: 'gallery',
                            onPressed: _pickFromGallery,
                            tooltip: 'Pick from gallery',
                            child: const Icon(Icons.image),
                          ),
                          FloatingActionButton(
                            heroTag: 'capture',
                            onPressed: _captureAndProcess,
                            tooltip: 'Capture receipt',
                            child: const Icon(Icons.camera),
                          ),
                          FloatingActionButton(
                            heroTag: 'flash',
                            onPressed: _toggleFlash,
                            tooltip: _getFlashLabel(),
                            child: Icon(
                              _flashMode == FlashMode.auto
                                  ? Icons.flash_auto
                                  : _flashMode == FlashMode.always
                                      ? Icons.flash_on
                                      : Icons.flash_off,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getFlashLabel(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
