import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';

import '../../db/app_db.dart';
import '../../models/product.dart';

class ScannerPage extends StatefulWidget {
  final AppDB db;

  const ScannerPage({
    super.key,
    required this.db,
  });

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _cameraController;
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isInitializing = true;
  bool _isProcessing = false;

  String? _lastCode;
  String? _savedImagePath;
  String? _message;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _message = 'Nem található kamera.';
          _isInitializing = false;
        });
        return;
      }

      final backCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _cameraController = controller;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Kamera inicializálási hiba: $e';
        _isInitializing = false;
      });
    }
  }

  Future<File> _saveAsPng(XFile photo) async {
    final bytes = await photo.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('A kép nem dekódolható.');
    }

    final pngBytes = img.encodePng(decoded);
    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/scan_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(pngBytes, flush: true);
    return file;
  }

  Future<void> _captureAndScan() async {
    if (_isProcessing) return;

    final camera = _cameraController;

    if (camera == null || !camera.value.isInitialized) {
      setState(() {
        _message = 'A kamera még nem áll készen.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _message = 'Kép készítése...';
      _lastCode = null;
      _savedImagePath = null;
    });

    try {
      final photo = await camera.takePicture();

      setState(() {
        _message = 'Kép PNG-vé alakítása...';
      });

      final pngFile = await _saveAsPng(photo);

      setState(() {
        _savedImagePath = pngFile.path;
        _message = 'Kód keresése a képen...';
      });

      final result = await _scannerController.analyzeImage(pngFile.path);

      if (result == null || result.barcodes.isEmpty) {
        setState(() {
          _message = 'Nem található QR-kód vagy vonalkód a képen.';
        });
        return;
      }

      final code = result.barcodes
          .map((barcode) => barcode.rawValue)
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .firstOrNull;

      if (code == null) {
        setState(() {
          _message = 'A kód felismerődött, de nincs kiolvasható értéke.';
        });
        return;
      }

      final product = Product(
        code: code,
        name: 'Ismeretlen termék',
        createdAt: DateTime.now(),
      );

      await widget.db.insertProduct(product);

      if (!mounted) return;

      setState(() {
        _lastCode = code;
        _message = 'Sikeres beolvasás és mentés.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mentve: $code')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Hiba történt: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = _cameraController;

    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: camera != null && camera.value.isInitialized
                ? CameraPreview(camera)
                : const Center(
              child: Text('Kamera nem elérhető.'),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_message != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                if (_lastCode != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Beolvasott kód: $_lastCode',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _captureAndScan,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    _isProcessing
                        ? 'Feldolgozás...'
                        : 'Kép készítése és beolvasása',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}