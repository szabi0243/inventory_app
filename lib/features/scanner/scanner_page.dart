import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';

import '../../db/app_db.dart';
import '../../models/product.dart';

class ScannerPage extends StatefulWidget {
  final AppDB db;

  const ScannerPage({super.key, required this.db});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _cameraController;
  final MobileScannerController _barcodeReader = MobileScannerController();

  bool _isLoading = true;
  bool _isProcessing = false;

  String? _message;
  String? _lastCode;
  String? _lastProductName;
  String? _lastImagePath;

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
          _isLoading = false;
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
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Kamera hiba: $e';
        _isLoading = false;
      });
    }
  }

  Future<File> _convertToPng(XFile photo) async {
    final bytes = await photo.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw Exception('A kép nem feldolgozható.');
    }

    final pngBytes = img.encodePng(decodedImage);
    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/scan_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(pngBytes, flush: true);
    return file;
  }

  String? _firstReadableCode(BarcodeCapture result) {
    for (final barcode in result.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<String> _findProductName(String code) async {
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$code.json',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        return 'Ismeretlen termék';
      }

      final data = jsonDecode(response.body);

      if (data['status'] != 1) {
        return 'Ismeretlen termék';
      }

      final product = data['product'];

      final name = product['product_name'] ??
          product['product_name_hu'] ??
          product['generic_name'] ??
          product['brands'];

      if (name == null || name.toString().trim().isEmpty) {
        return 'Ismeretlen termék';
      }

      return name.toString().trim();
    } catch (_) {
      return 'Ismeretlen termék';
    }
  }

  Future<void> _takePhotoAndScan() async {
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
      _lastProductName = null;
      _lastImagePath = null;
    });

    try {
      final photo = await camera.takePicture();

      setState(() {
        _message = 'Kép mentése PNG formátumban...';
      });

      final pngFile = await _convertToPng(photo);

      setState(() {
        _lastImagePath = pngFile.path;
        _message = 'QR-kód / vonalkód keresése a képen...';
      });

      final result = await _barcodeReader.analyzeImage(pngFile.path);

      if (result == null || result.barcodes.isEmpty) {
        setState(() {
          _message = 'Nem található QR-kód vagy vonalkód a képen.';
        });
        return;
      }

      final code = _firstReadableCode(result);

      if (code == null) {
        setState(() {
          _message = 'A kód felismerődött, de nem olvasható ki.';
        });
        return;
      }

      setState(() {
        _message = 'Termék keresése...';
      });

      final productName = await _findProductName(code);

      final product = Product(
        code: code,
        name: productName,
        createdAt: DateTime.now(),
      );

      await widget.db.insertProduct(product);

      if (!mounted) return;

      setState(() {
        _lastCode = code;
        _lastProductName = productName;
        _message = 'Sikeres beolvasás és mentés.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mentve: $productName ($code)'),
        ),
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
    _barcodeReader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = _cameraController;

    if (_isLoading) {
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

                if (_lastCode != null && _lastProductName != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Termék: $_lastProductName\nKód: $_lastCode',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _takePhotoAndScan,
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