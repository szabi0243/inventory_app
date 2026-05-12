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
  MobileScannerController? _scannerController;

  bool _isInitializing = true;
  bool _isProcessing = false;

  String? _lastCode;
  String? _lastPngPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'Nem található kamera az eszközön.';
          _isInitializing = false;
        });
        return;
      }

      final backCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await cameraController.initialize();

      _cameraController = cameraController;
      _scannerController = MobileScannerController();

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Kamera inicializálási hiba: $e';
        _isInitializing = false;
      });
    }
  }

  Future<File> _convertCapturedImageToPng(XFile capturedImage) async {
    final bytes = await capturedImage.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw Exception('A kép nem dekódolható.');
    }

    final pngBytes = img.encodePng(decodedImage);

    final directory = await getTemporaryDirectory();
    final pngPath =
        '${directory.path}/scan_${DateTime.now().millisecondsSinceEpoch}.png';

    final pngFile = File(pngPath);
    await pngFile.writeAsBytes(pngBytes, flush: true);

    return pngFile;
  }

  Future<void> _scanFromPhoto() async {
    if (_isProcessing) return;

    final camera = _cameraController;
    final scanner = _scannerController;

    if (camera == null || scanner == null || !camera.value.isInitialized) {
      setState(() {
        _errorMessage = 'A kamera még nem áll készen.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _lastCode = null;
      _lastPngPath = null;
    });

    try {
      final capturedImage = await camera.takePicture();
      final pngFile = await _convertCapturedImageToPng(capturedImage);

      final BarcodeCapture? result = await scanner.analyzeImage(pngFile.path);

      if (result == null || result.barcodes.isEmpty) {
        setState(() {
          _errorMessage =
          'Nem találtam QR-kódot vagy vonalkódot a képen. Próbáld közelebbről, jobb fénynél.';
          _lastPngPath = pngFile.path;
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
          _errorMessage = 'A kód felismerődött, de nincs kiolvasható értéke.';
          _lastPngPath = pngFile.path;
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
        _lastPngPath = pngFile.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mentve: $code')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Beolvasási hiba: $e';
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
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = _cameraController;

    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null && camera == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scanner'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kép alapú scanner'),
      ),
      body: Column(
        children: [
          Expanded(
            child: camera != null && camera.value.isInitialized
                ? CameraPreview(camera)
                : const Center(
              child: Text('Kamera nem elérhető.'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_lastCode != null)
                  Text(
                    'Utolsó beolvasott kód: $_lastCode',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                if (_lastPngPath != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'PNG fájl: $_lastPngPath',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _scanFromPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      _isProcessing
                          ? 'Kép feldolgozása...'
                          : 'Kép készítése és beolvasása',
                    ),
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