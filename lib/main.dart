import 'package:flutter/material.dart';
import 'db/app_db.dart';
import 'features/scanner/scanner_page.dart';
import 'features/inventory/inventory_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDB();
  runApp(MyApp(db: db));
}

class MyApp extends StatefulWidget {
  final AppDB db;

  const MyApp({super.key, required this.db});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ScannerPage(db: widget.db),
      InventoryPage(db: widget.db),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: pages[index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: "Scan",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: "Inventory",
            ),
          ],
        ),
      ),
    );
  }
}