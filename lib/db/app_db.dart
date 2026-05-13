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
      version: 2, // VERZIÓ FELEMELVE 2-RE
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT,
            name TEXT,
            createdAt TEXT,
            quantity INTEGER DEFAULT 1 -- ÚJ OSZLOP
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Ha korábban telepítve volt a V1, hozzáadja az új oszlopot törlés nélkül!
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE products ADD COLUMN quantity INTEGER DEFAULT 1');
        }
      },
    );

    return _db!;
  }

  // Okos beszúrás: Ha már van ilyen vonalkód, növeli a számot, ha nincs, létrehozza
  Future<void> addOrUpdateProduct(Product product) async {
    final db = await database;

    // Keresés vonalkód (code) alapján
    final List<Map<String, dynamic>> existing = await db.query(
      'products',
      where: 'code = ?',
      whereArgs: [product.code],
    );

    if (existing.isNotEmpty) {
      // Ha létezik, lekérjük a jelenlegi mennyiséget és növeljük 1-gyel
      int currentQuantity = existing.first['quantity'] as int? ?? 1;
      await db.update(
        'products',
        {
          'quantity': currentQuantity + 1,
          'createdAt': product.createdAt.toIso8601String() // Frissítjük a dátumot is a legutóbbira
        },
        where: 'code = ?',
        whereArgs: [product.code],
      );
    } else {
      // Ha új termék, simán beszúrjuk
      await db.insert('products', product.toMap());
    }
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'createdAt DESC');

    return maps.map((e) => Product.fromMap(e)).toList();
  }
}