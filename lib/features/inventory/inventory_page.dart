import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../models/product.dart';

class InventoryPage extends StatefulWidget {
  final AppDB db;

  const InventoryPage({super.key, required this.db});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await widget.db.getProducts();
    setState(() => products = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory")),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];

          return ListTile(
            title: Text(p.name),
            subtitle: Text(p.code),
            trailing: Text(
              p.createdAt.toLocal().toString().split('.')[0],
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}