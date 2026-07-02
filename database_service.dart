import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'supermarche.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT UNIQUE,
        category TEXT,
        purchasePrice REAL NOT NULL,
        sellPrice REAL NOT NULL,
        stockQuantity INTEGER NOT NULL,
        lowStockThreshold INTEGER DEFAULT 5,
        expiryDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        amountPaid REAL NOT NULL,
        total REAL NOT NULL,
        cashierName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        unitPrice REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (saleId) REFERENCES sales (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE employees(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        pin TEXT NOT NULL
      )
    ''');

    // Produits d'exemple pour démarrer
    await db.insert('products', {
      'name': 'Riz 5lb',
      'barcode': '7501234567890',
      'category': 'Épicerie',
      'purchasePrice': 150.0,
      'sellPrice': 200.0,
      'stockQuantity': 50,
      'lowStockThreshold': 10,
    });
    await db.insert('products', {
      'name': 'Huile végétale 1L',
      'barcode': '7501234567891',
      'category': 'Épicerie',
      'purchasePrice': 180.0,
      'sellPrice': 250.0,
      'stockQuantity': 30,
      'lowStockThreshold': 8,
    });
  }

  // ---- PRODUITS ----
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap()..remove('id'));
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> updateStock(int productId, int newQuantity) async {
    final db = await database;
    await db.update(
      'products',
      {'stockQuantity': newQuantity},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ---- VENTES ----
  Future<int> insertSale(Sale sale) async {
    final db = await database;
    return await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap()..remove('id'));

      for (final item in sale.items) {
        await txn.insert('sale_items', item.toMap(saleId));
        // Décrémenter le stock
        final product = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        if (product.isNotEmpty) {
          final currentStock = product.first['stockQuantity'] as int;
          await txn.update(
            'products',
            {'stockQuantity': currentStock - item.quantity},
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }
      return saleId;
    });
  }

  Future<List<Map<String, dynamic>>> getSalesReport(
      DateTime start, DateTime end) async {
    final db = await database;
    return await db.query(
      'sales',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
  }
}
