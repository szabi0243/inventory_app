import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../db/app_db.dart';
import '../../models/product.dart';

class ScannerPage extends StatefulWidget {
  final AppDB db;

  const ScannerPage({super.key, required this.db});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool isProcessing = false;

  void handleScan(String code) async {
    if (isProcessing) return;
    isProcessing = true;

    final product = Product(
      code: code,
      name: "Ismeretlen termék", // később API-ból jön
      createdAt: DateTime.now(),
    );

    await widget.db.insertProduct(product);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mentve: $code")),
      );
    }

    await Future.delayed(const Duration(seconds: 2));
    isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        final barcodes = capture.barcodes;

        for (final barcode in barcodes) {
          final code = barcode.rawValue;

          if (code != null) {
            handleScan(code);
          }
        }
      },
    );
  }
}