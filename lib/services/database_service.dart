import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/debt.dart';

class DatabaseService {
  static const _kProducts = 'rs_products';
  static const _kSales = 'rs_sales';
  static const _kDebts = 'rs_debts';
  static const _kPin = 'rs_admin_pin';

  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  // ── Products ─────────────────────────────────────────────────────────────────
  Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProducts);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Product.fromJson(e)).toList();
  }

  Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProducts, jsonEncode(products.map((p) => p.toJson()).toList()));
    await _autoBackup();
  }

  // ── Sales ─────────────────────────────────────────────────────────────────────
  Future<List<Sale>> loadSales() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSales);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Sale.fromJson(e)).toList();
  }

  Future<void> saveSales(List<Sale> sales) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSales, jsonEncode(sales.map((s) => s.toJson()).toList()));
    await _autoBackup();
  }

  // ── Debts ─────────────────────────────────────────────────────────────────────
  Future<List<Debt>> loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDebts);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Debt.fromJson(e)).toList();
  }

  Future<void> saveDebts(List<Debt> debts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDebts, jsonEncode(debts.map((d) => d.toJson()).toList()));
    await _autoBackup();
  }

  // ── PIN ───────────────────────────────────────────────────────────────────────
  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPin, pin);
  }

  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPin);
  }

  Future<bool> verifyPin(String input) async {
    final stored = await getPin();
    return stored == input;
  }

  Future<bool> hasPin() async {
    final stored = await getPin();
    return stored != null && stored.isNotEmpty;
  }

  // ── Auto Backup ───────────────────────────────────────────────────────────────
  Future<void> _autoBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final products = prefs.getString(_kProducts) ?? '[]';
      final sales = prefs.getString(_kSales) ?? '[]';
      final debts = prefs.getString(_kDebts) ?? '[]';
      final json = jsonEncode({
        'products': jsonDecode(products),
        'sales': jsonDecode(sales),
        'debts': jsonDecode(debts),
        'backupTime': DateTime.now().toIso8601String(),
      });
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/reshelve_backup.json');
      await file.writeAsString(json);
    } catch (_) {
      // Silently fail — don't crash the app over backup
    }
  }

  // ── Export / Clear ────────────────────────────────────────────────────────────
  Future<String> exportJson() async {
    final products = await loadProducts();
    final sales = await loadSales();
    final debts = await loadDebts();
    return jsonEncode({
      'exportTime': DateTime.now().toIso8601String(),
      'products': products.map((p) => p.toJson()).toList(),
      'sales': sales.map((s) => s.toJson()).toList(),
      'debts': debts.map((d) => d.toJson()).toList(),
    });
  }

  Future<String> getBackupPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/reshelve_backup.json';
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProducts);
    await prefs.remove(_kSales);
    await prefs.remove(_kDebts);
    await _autoBackup();
  }
}
