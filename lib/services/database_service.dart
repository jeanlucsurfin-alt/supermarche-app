import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/supplier.dart';
import '../models/stock_movement.dart';

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
    final path = join(await getDatabasesPath(), 'fafoutt_store.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS sale_items');
        await db.execute('DROP TABLE IF EXISTS sales');
        await db.execute('DROP TABLE IF EXISTS products');
        await db.execute('DROP TABLE IF EXISTS employees');
        await db.execute('DROP TABLE IF EXISTS suppliers');
        await db.execute('DROP TABLE IF EXISTS stock_movements');
        await _onCreate(db, newVersion);
      },
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

    await db.execute('''
      CREATE TABLE suppliers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        supplierId INTEGER,
        date TEXT NOT NULL
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
    await db.insert('products', {
      'name': 'Farine 2lb',
      'barcode': '7501234567892',
      'category': 'Épicerie',
      'purchasePrice': 90.0,
      'sellPrice': 130.0,
      'stockQuantity': 40,
      'lowStockThreshold': 10,
    });

    // Cosmétique
    await db.insert('products', {
      'name': 'Savon corporel',
      'barcode': '7501234567893',
      'category': 'Cosmétique',
      'purchasePrice': 80.0,
      'sellPrice': 120.0,
      'stockQuantity': 25,
      'lowStockThreshold': 6,
    });
    await db.insert('products', {
      'name': 'Lotion hydratante',
      'barcode': '7501234567894',
      'category': 'Cosmétique',
      'purchasePrice': 250.0,
      'sellPrice': 350.0,
      'stockQuantity': 15,
      'lowStockThreshold': 5,
    });
    await db.insert('products', {
      'name': 'Parfum femme 50ml',
      'barcode': '7501234567895',
      'category': 'Cosmétique',
      'purchasePrice': 800.0,
      'sellPrice': 1200.0,
      'stockQuantity': 8,
      'lowStockThreshold': 3,
    });

    // Vêtements
    await db.insert('products', {
      'name': 'T-shirt uni',
      'barcode': '7501234567896',
      'category': 'Vêtements',
      'purchasePrice': 300.0,
      'sellPrice': 500.0,
      'stockQuantity': 20,
      'lowStockThreshold': 5,
    });
    await db.insert('products', {
      'name': 'Jean homme',
      'barcode': '7501234567897',
      'category': 'Vêtements',
      'purchasePrice': 900.0,
      'sellPrice': 1400.0,
      'stockQuantity': 12,
      'lowStockThreshold': 4,
    });

    // Électronique
    await db.insert('products', {
      'name': 'Chargeur USB-C',
      'barcode': '7501234567898',
      'category': 'Électronique',
      'purchasePrice': 350.0,
      'sellPrice': 550.0,
      'stockQuantity': 18,
      'lowStockThreshold': 5,
    });
    await db.insert('products', {
      'name': 'Écouteurs filaires',
      'barcode': '7501234567899',
      'category': 'Électronique',
      'purchasePrice': 450.0,
      'sellPrice': 700.0,
      'stockQuantity': 10,
      'lowStockThreshold': 4,
    });

    // Home Decor
    await db.insert('products', {
      'name': 'Bougie parfumée',
      'barcode': '7501234567900',
      'category': 'Home Decor',
      'purchasePrice': 150.0,
      'sellPrice': 250.0,
      'stockQuantity': 22,
      'lowStockThreshold': 6,
    });
    await db.insert('products', {
      'name': 'Cadre photo',
      'barcode': '7501234567901',
      'category': 'Home Decor',
      'purchasePrice': 200.0,
      'sellPrice': 320.0,
      'stockQuantity': 14,
      'lowStockThreshold': 5,
    });

    // Fournisseurs d'exemple
    await db.insert('suppliers', {
      'name': 'Distributions Caraïbes',
      'phone': '+509 3456 7890',
      'address': 'Delmas 33, Port-au-Prince',
    });
    await db.insert('suppliers', {
      'name': 'Import Export Fafoutt',
      'phone': '+509 4321 0987',
      'address': 'Pétion-Ville',
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

  // ---- FOURNISSEURS ----
  Future<List<Supplier>> getAllSuppliers() async {
    final db = await database;
    final maps = await db.query('suppliers', orderBy: 'name');
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    return await db.insert('suppliers', supplier.toMap()..remove('id'));
  }

  Future<void> deleteSupplier(int id) async {
    final db = await database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // ---- MOUVEMENTS DE STOCK ----
  Future<List<StockMovement>> getAllMovements() async {
    final db = await database;
    final maps = await db.query('stock_movements', orderBy: 'date DESC');
    return maps.map((m) => StockMovement.fromMap(m)).toList();
  }

  Future<List<StockMovement>> getMovementsForProduct(int productId) async {
    final db = await database;
    final maps = await db.query(
      'stock_movements',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => StockMovement.fromMap(m)).toList();
  }

  /// Enregistre un mouvement de stock (entrée/sortie/ajustement)
  /// et met à jour la quantité du produit en conséquence.
  Future<void> recordMovement(StockMovement movement) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('stock_movements', movement.toMap()..remove('id'));

      final rows = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [movement.productId],
      );
      if (rows.isEmpty) return;
      final currentStock = rows.first['stockQuantity'] as int;

      int newStock;
      switch (movement.type) {
        case MovementType.entry:
          newStock = currentStock + movement.quantity;
          break;
        case MovementType.exit:
          newStock = currentStock - movement.quantity;
          break;
        case MovementType.adjustment:
          newStock = movement.quantity;
          break;
      }
      if (newStock < 0) newStock = 0;

      await txn.update(
        'products',
        {'stockQuantity': newStock},
        where: 'id = ?',
        whereArgs: [movement.productId],
      );
    });
  }
}
