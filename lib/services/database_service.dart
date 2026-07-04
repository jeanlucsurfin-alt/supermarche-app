import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/supplier.dart';
import '../models/stock_movement.dart';
import '../models/category.dart';
import '../models/employee.dart';
import '../models/employee_shift.dart';
import '../models/customer.dart';
import '../models/credit_payment.dart';
import '../models/cash_closing.dart';

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
      version: 10,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS sale_items');
        await db.execute('DROP TABLE IF EXISTS sales');
        await db.execute('DROP TABLE IF EXISTS products');
        await db.execute('DROP TABLE IF EXISTS employees');
        await db.execute('DROP TABLE IF EXISTS suppliers');
        await db.execute('DROP TABLE IF EXISTS stock_movements');
        await db.execute('DROP TABLE IF EXISTS categories');
        await db.execute('DROP TABLE IF EXISTS employee_shifts');
        await db.execute('DROP TABLE IF EXISTS customers');
        await db.execute('DROP TABLE IF EXISTS credit_payments');
        await db.execute('DROP TABLE IF EXISTS app_settings');
        await db.execute('DROP TABLE IF EXISTS cash_closings');
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
        purchasePriceUSD REAL NOT NULL DEFAULT 0,
        sellPriceUSD REAL NOT NULL DEFAULT 0,
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
        cashierName TEXT,
        customerId INTEGER,
        currency TEXT NOT NULL DEFAULT 'HTG'
      )
    ''');

    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        loyaltyPoints INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE credit_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cash_closings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER NOT NULL,
        employeeName TEXT NOT NULL,
        expectedCash REAL NOT NULL,
        countedCash REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.insert('app_settings', {'key': 'storeName', 'value': 'Fafoutt Store'});
    await db.insert('app_settings', {'key': 'storeAddress', 'value': ''});
    await db.insert('app_settings', {'key': 'storePhone', 'value': ''});
    await db.insert('app_settings', {'key': 'exchangeRate', 'value': '130'});
    await db.insert('app_settings', {'key': 'loyaltyEnabled', 'value': 'true'});
    await db.insert('app_settings', {'key': 'lastBackupDate', 'value': ''});

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

    // Compte administrateur par défaut, pour pouvoir se connecter dès
    // la première installation (à modifier ensuite dans Employés).
    await db.insert('employees', {
      'name': 'Administrateur',
      'role': 'admin',
      'pin': '0000',
    });

    await db.execute('''
      CREATE TABLE employee_shifts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER NOT NULL,
        employeeName TEXT NOT NULL,
        clockIn TEXT NOT NULL,
        clockOut TEXT
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

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        iconKey TEXT NOT NULL,
        colorValue INTEGER NOT NULL
      )
    ''');

    // Catégories de départ
    await db.insert('categories', {
      'name': 'Épicerie',
      'iconKey': 'grocery',
      'colorValue': 0xFF1F9D55,
    });
    await db.insert('categories', {
      'name': 'Cosmétique',
      'iconKey': 'spa',
      'colorValue': 0xFFD6559D,
    });
    await db.insert('categories', {
      'name': 'Vêtements',
      'iconKey': 'clothing',
      'colorValue': 0xFF2F6FED,
    });
    await db.insert('categories', {
      'name': 'Électronique',
      'iconKey': 'electronics',
      'colorValue': 0xFF6B5CE0,
    });
    await db.insert('categories', {
      'name': 'Home Decor',
      'iconKey': 'home',
      'colorValue': 0xFFC97A3D,
    });

    // Produits d'exemple pour démarrer
    await db.insert('products', {
      'name': 'Riz 5lb',
      'barcode': '7501234567890',
      'category': 'Épicerie',
      'purchasePrice': 150.0,
      'sellPrice': 200.0,
      'purchasePriceUSD': 1.15,
      'sellPriceUSD': 1.54,
      'stockQuantity': 50,
      'lowStockThreshold': 10,
    });
    await db.insert('products', {
      'name': 'Huile végétale 1L',
      'barcode': '7501234567891',
      'category': 'Épicerie',
      'purchasePrice': 180.0,
      'sellPrice': 250.0,
      'purchasePriceUSD': 1.38,
      'sellPriceUSD': 1.92,
      'stockQuantity': 30,
      'lowStockThreshold': 8,
    });
    await db.insert('products', {
      'name': 'Farine 2lb',
      'barcode': '7501234567892',
      'category': 'Épicerie',
      'purchasePrice': 90.0,
      'sellPrice': 130.0,
      'purchasePriceUSD': 0.69,
      'sellPriceUSD': 1.0,
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
      'purchasePriceUSD': 0.62,
      'sellPriceUSD': 0.92,
      'stockQuantity': 25,
      'lowStockThreshold': 6,
    });
    await db.insert('products', {
      'name': 'Lotion hydratante',
      'barcode': '7501234567894',
      'category': 'Cosmétique',
      'purchasePrice': 250.0,
      'sellPrice': 350.0,
      'purchasePriceUSD': 1.92,
      'sellPriceUSD': 2.69,
      'stockQuantity': 15,
      'lowStockThreshold': 5,
    });
    await db.insert('products', {
      'name': 'Parfum femme 50ml',
      'barcode': '7501234567895',
      'category': 'Cosmétique',
      'purchasePrice': 800.0,
      'sellPrice': 1200.0,
      'purchasePriceUSD': 6.15,
      'sellPriceUSD': 9.23,
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
      'purchasePriceUSD': 2.31,
      'sellPriceUSD': 3.85,
      'stockQuantity': 20,
      'lowStockThreshold': 5,
    });
    await db.insert('products', {
      'name': 'Jean homme',
      'barcode': '7501234567897',
      'category': 'Vêtements',
      'purchasePrice': 900.0,
      'sellPrice': 1400.0,
      'purchasePriceUSD': 6.92,
      'sellPriceUSD': 10.77,
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
      'purchasePriceUSD': 2.69,
      'sellPriceUSD': 4.23,
      'stockQuantity': 18,
      'lowStockThreshold': 5,
    });
    await db.insert('products', {
      'name': 'Écouteurs filaires',
      'barcode': '7501234567899',
      'category': 'Électronique',
      'purchasePrice': 450.0,
      'sellPrice': 700.0,
      'purchasePriceUSD': 3.46,
      'sellPriceUSD': 5.38,
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
      'purchasePriceUSD': 1.15,
      'sellPriceUSD': 1.92,
      'stockQuantity': 22,
      'lowStockThreshold': 6,
    });
    await db.insert('products', {
      'name': 'Cadre photo',
      'barcode': '7501234567901',
      'category': 'Home Decor',
      'purchasePrice': 200.0,
      'sellPrice': 320.0,
      'purchasePriceUSD': 1.54,
      'sellPriceUSD': 2.46,
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

      // Attribution de points de fidélité : 1 point par 100 HTG dépensés,
      // seulement si le programme est activé dans les paramètres.
      final loyaltySetting = await txn.query('app_settings',
          where: 'key = ?', whereArgs: ['loyaltyEnabled']);
      final loyaltyEnabled = loyaltySetting.isEmpty ||
          loyaltySetting.first['value'] == 'true';

      if (sale.customerId != null && loyaltyEnabled) {
        final earnedPoints = (sale.total / 100).floor();
        if (earnedPoints > 0) {
          final customerRows = await txn.query(
            'customers',
            where: 'id = ?',
            whereArgs: [sale.customerId],
          );
          if (customerRows.isNotEmpty) {
            final currentPoints =
                customerRows.first['loyaltyPoints'] as int;
            await txn.update(
              'customers',
              {'loyaltyPoints': currentPoints + earnedPoints},
              where: 'id = ?',
              whereArgs: [sale.customerId],
            );
          }
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

  /// Résumé des ventes sur une période : chiffre d'affaires, bénéfice
  /// réalisé (encaissé) vs en attente (crédit non remboursé), nombre
  /// de transactions.
  Future<Map<String, double>> getSalesSummary(
      DateTime start, DateTime end) async {
    final db = await database;

    final revenueResult = await db.rawQuery('''
      SELECT COUNT(*) as cnt, COALESCE(SUM(total), 0) as revenue
      FROM sales
      WHERE date BETWEEN ? AND ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final transactionCount =
        (revenueResult.first['cnt'] as int?)?.toDouble() ?? 0;
    final revenue =
        (revenueResult.first['revenue'] as num?)?.toDouble() ?? 0;

    // Détail par vente pour calculer le coût et répartir le bénéfice
    // entre "réalisé" (encaissé) et "en attente" (solde à crédit).
    final saleRows = await db.rawQuery('''
      SELECT s.id, s.total, s.amountPaid, s.paymentMethod, s.customerId,
             COALESCE(SUM(p.purchasePrice * si.quantity), 0) as cost
      FROM sales s
      LEFT JOIN sale_items si ON si.saleId = s.id
      LEFT JOIN products p ON p.id = si.productId
      WHERE s.date BETWEEN ? AND ?
      GROUP BY s.id
    ''', [start.toIso8601String(), end.toIso8601String()]);

    // Pour chaque client concerné par une vente à crédit dans la période,
    // on calcule quelle proportion de sa dette d'origine a depuis été
    // remboursée, afin de répartir correctement les remboursements
    // (qui ne sont pas liés à une vente précise) sur chacune de ses ventes.
    final creditCustomerIds = saleRows
        .where((r) => r['paymentMethod'] == 'credit' && r['customerId'] != null)
        .map((r) => r['customerId'] as int)
        .toSet();

    final Map<int, double> repaidRatioByCustomer = {};
    for (final customerId in creditCustomerIds) {
      final owedResult = await db.rawQuery('''
        SELECT COALESCE(SUM(total - amountPaid), 0) as owed
        FROM sales WHERE paymentMethod = 'credit' AND customerId = ?
      ''', [customerId]);
      final repaidResult = await db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) as repaid
        FROM credit_payments WHERE customerId = ?
      ''', [customerId]);
      final owed = (owedResult.first['owed'] as num?)?.toDouble() ?? 0;
      final repaid = (repaidResult.first['repaid'] as num?)?.toDouble() ?? 0;
      repaidRatioByCustomer[customerId] =
          owed > 0 ? (repaid / owed).clamp(0.0, 1.0) : 0.0;
    }

    double realizedProfit = 0;
    double pendingProfit = 0;
    double pendingCreditAmount = 0;

    for (final row in saleRows) {
      final saleTotal = (row['total'] as num?)?.toDouble() ?? 0;
      final amountPaid = (row['amountPaid'] as num?)?.toDouble() ?? 0;
      final cost = (row['cost'] as num?)?.toDouble() ?? 0;
      final profit = saleTotal - cost;
      final method = row['paymentMethod'] as String?;
      final customerId = row['customerId'] as int?;

      if (method == 'credit' && saleTotal > 0) {
        final unpaidAtOrigin = saleTotal - amountPaid;
        final repaidRatio = customerId != null
            ? (repaidRatioByCustomer[customerId] ?? 0.0)
            : 0.0;
        final stillOwed = unpaidAtOrigin * (1 - repaidRatio);
        final totalPaidNow = saleTotal - stillOwed;
        final paidRatio = (totalPaidNow / saleTotal).clamp(0.0, 1.0);

        realizedProfit += profit * paidRatio;
        pendingProfit += profit * (1 - paidRatio);
        pendingCreditAmount += stillOwed;
      } else {
        realizedProfit += profit;
      }
    }

    return {
      'transactionCount': transactionCount,
      'revenue': revenue,
      'profit': realizedProfit + pendingProfit,
      'realizedProfit': realizedProfit,
      'pendingProfit': pendingProfit,
      'pendingCreditAmount': pendingCreditAmount,
      'averageBasket': transactionCount > 0 ? revenue / transactionCount : 0,
    };
  }

  /// Solde total actuellement dû (toutes périodes confondues), tous
  /// clients confondus.
  Future<double> getTotalOutstandingCredit() async {
    final db = await database;
    final result = await db.rawQuery('''
      WITH credit_totals AS (
        SELECT customerId, SUM(total - amountPaid) as owed
        FROM sales
        WHERE paymentMethod = 'credit' AND customerId IS NOT NULL
        GROUP BY customerId
      ),
      repayments AS (
        SELECT customerId, SUM(amount) as repaid
        FROM credit_payments
        GROUP BY customerId
      )
      SELECT COALESCE(SUM(
        COALESCE(ct.owed, 0) - COALESCE(r.repaid, 0)
      ), 0) as total
      FROM credit_totals ct
      LEFT JOIN repayments r ON r.customerId = ct.customerId
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Liste des clients ayant un solde à crédit non remboursé.
  Future<List<Map<String, dynamic>>> getCustomersWithOutstandingBalance() async {
    final db = await database;
    return await db.rawQuery('''
      WITH credit_totals AS (
        SELECT customerId, SUM(total - amountPaid) as owed
        FROM sales
        WHERE paymentMethod = 'credit' AND customerId IS NOT NULL
        GROUP BY customerId
      ),
      repayments AS (
        SELECT customerId, SUM(amount) as repaid
        FROM credit_payments
        GROUP BY customerId
      )
      SELECT c.id, c.name, c.phone,
             (COALESCE(ct.owed, 0) - COALESCE(r.repaid, 0)) as balance
      FROM customers c
      JOIN credit_totals ct ON ct.customerId = c.id
      LEFT JOIN repayments r ON r.customerId = c.id
      WHERE (COALESCE(ct.owed, 0) - COALESCE(r.repaid, 0)) > 0.01
      ORDER BY balance DESC
    ''');
  }

  /// Solde actuellement dû par un client précis.
  Future<double> getOutstandingBalanceForCustomer(int customerId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE((SELECT SUM(total - amountPaid) FROM sales
                  WHERE paymentMethod = 'credit' AND customerId = ?), 0)
        -
        COALESCE((SELECT SUM(amount) FROM credit_payments
                  WHERE customerId = ?), 0) as balance
    ''', [customerId, customerId]);
    final balance = (result.first['balance'] as num?)?.toDouble() ?? 0;
    return balance < 0 ? 0 : balance;
  }

  Future<int> insertCreditPayment(CreditPayment payment) async {
    final db = await database;
    return await db.insert('credit_payments', payment.toMap()..remove('id'));
  }

  Future<List<CreditPayment>> getCreditPaymentsForCustomer(
      int customerId) async {
    final db = await database;
    final maps = await db.query(
      'credit_payments',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => CreditPayment.fromMap(m)).toList();
  }

  /// Ventes à crédit (non entièrement payées) d'un client.
  Future<List<Map<String, dynamic>>> getCreditSalesForCustomer(
      int customerId) async {
    final db = await database;
    return await db.query(
      'sales',
      where: 'customerId = ? AND paymentMethod = ?',
      whereArgs: [customerId, 'credit'],
      orderBy: 'date DESC',
    );
  }

  /// Produits les plus vendus sur une période.
  Future<List<Map<String, dynamic>>> getTopProducts(
      DateTime start, DateTime end, {int limit = 5}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT si.productName as name,
             SUM(si.quantity) as quantity,
             SUM(si.unitPrice * si.quantity) as revenue
      FROM sale_items si
      JOIN sales s ON s.id = si.saleId
      WHERE s.date BETWEEN ? AND ?
      GROUP BY si.productName
      ORDER BY quantity DESC
      LIMIT ?
    ''', [start.toIso8601String(), end.toIso8601String(), limit]);
  }

  /// Ventes groupées par mode de paiement sur une période.
  Future<List<Map<String, dynamic>>> getSalesByPaymentMethod(
      DateTime start, DateTime end) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT paymentMethod, COUNT(*) as cnt, COALESCE(SUM(total), 0) as revenue
      FROM sales
      WHERE date BETWEEN ? AND ?
      GROUP BY paymentMethod
    ''', [start.toIso8601String(), end.toIso8601String()]);
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

  // ---- CATÉGORIES ----
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap()..remove('id'));
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ---- EMPLOYÉS ----
  Future<List<Employee>> getAllEmployees() async {
    final db = await database;
    final maps = await db.query('employees', orderBy: 'name');
    return maps.map((m) => Employee.fromMap(m)).toList();
  }

  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    return await db.insert('employees', employee.toMap()..remove('id'));
  }

  Future<void> updateEmployee(Employee employee) async {
    final db = await database;
    await db.update('employees', employee.toMap(),
        where: 'id = ?', whereArgs: [employee.id]);
  }

  Future<void> deleteEmployee(int id) async {
    final db = await database;
    await db.delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  // ---- POINTAGES (suivi des heures) ----
  Future<EmployeeShift?> getActiveShift(int employeeId) async {
    final db = await database;
    final maps = await db.query(
      'employee_shifts',
      where: 'employeeId = ? AND clockOut IS NULL',
      whereArgs: [employeeId],
      orderBy: 'clockIn DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return EmployeeShift.fromMap(maps.first);
  }

  Future<List<EmployeeShift>> getShiftsForEmployee(int employeeId) async {
    final db = await database;
    final maps = await db.query(
      'employee_shifts',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      orderBy: 'clockIn DESC',
      limit: 30,
    );
    return maps.map((m) => EmployeeShift.fromMap(m)).toList();
  }

  Future<void> clockIn(int employeeId, String employeeName) async {
    final db = await database;
    await db.insert('employee_shifts', {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'clockIn': DateTime.now().toIso8601String(),
      'clockOut': null,
    });
  }

  Future<void> clockOut(int shiftId) async {
    final db = await database;
    await db.update(
      'employee_shifts',
      {'clockOut': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [shiftId],
    );
  }

  // ---- CLIENTS ----
  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'name');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap()..remove('id'));
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update('customers', customer.toMap(),
        where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  /// Historique des ventes liées à un client, du plus récent au plus ancien.
  Future<List<Map<String, dynamic>>> getSalesForCustomer(
      int customerId) async {
    final db = await database;
    return await db.query(
      'sales',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
  }

  // ---- PARAMÈTRES ----
  Future<String?> getSetting(String key) async {
    final db = await database;
    final result =
        await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final rows = await db.query('app_settings');
    return {
      for (final row in rows) row['key'] as String: (row['value'] as String?) ?? ''
    };
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Chemin du fichier de base de données, utilisé pour la sauvegarde
  /// et la restauration.
  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'fafoutt_store.db');
  }

  /// Ferme la connexion actuelle à la base de données (nécessaire avant
  /// de remplacer le fichier lors d'une restauration).
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // ---- CLÔTURE DE CAISSE ----

  /// Date/heure de la dernière clôture enregistrée (toutes caisses/employés
  /// confondus), ou null si aucune clôture n'a encore été faite.
  Future<DateTime?> getLastClosingDate() async {
    final db = await database;
    final result = await db.query('cash_closings',
        orderBy: 'date DESC', limit: 1);
    if (result.isEmpty) return null;
    return DateTime.parse(result.first['date'] as String);
  }

  /// Montant de cash attendu en caisse depuis la dernière clôture
  /// (ou depuis minuit s'il n'y a jamais eu de clôture).
  Future<double> getExpectedCashSinceLastClosing() async {
    final lastClosing = await getLastClosingDate();
    final start = lastClosing ??
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total
      FROM sales
      WHERE paymentMethod = 'cash' AND date >= ?
    ''', [start.toIso8601String()]);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> insertCashClosing(CashClosing closing) async {
    final db = await database;
    return await db.insert('cash_closings', closing.toMap()..remove('id'));
  }

  Future<List<CashClosing>> getCashClosingHistory({int limit = 30}) async {
    final db = await database;
    final maps = await db.query('cash_closings',
        orderBy: 'date DESC', limit: limit);
    return maps.map((m) => CashClosing.fromMap(m)).toList();
  }
}
