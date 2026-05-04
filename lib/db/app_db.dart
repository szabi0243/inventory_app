import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class AppDB {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'inventory.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT,
            name TEXT,
            createdAt TEXT
          )
        ''');
      },
    );

    return _db!;
  }

  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'createdAt DESC');

    return maps.map((e) => Product.fromMap(e)).toList();
  }
}