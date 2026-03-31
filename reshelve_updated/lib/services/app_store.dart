import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/debt.dart';
import '../models/debt_item.dart';
import '../models/cart_item.dart';
import '../services/database_service.dart';

class AppStore extends ChangeNotifier {
  List<Product> products = [];
  List<Sale> sales = [];
  List<Debt> debts = [];
  List<CartItem> cart = [];

  bool _loaded = false;
  final _uuid = const Uuid();

  Future<void> init() async {
    if (_loaded) return;
    products = await DatabaseService.instance.loadProducts();
    sales = await DatabaseService.instance.loadSales();
    debts = await DatabaseService.instance.loadDebts();
    _loaded = true;
    notifyListeners();
  }

  // ── Persistence ───────────────────────────────────────────────────────────────
  Future<void> _persist() async {
    await DatabaseService.instance.saveProducts(products);
    await DatabaseService.instance.saveSales(sales);
    await DatabaseService.instance.saveDebts(debts);
  }

  // ── Products ──────────────────────────────────────────────────────────────────
  bool productNameExists(String name, {String? excludeId}) {
    final lower = name.toLowerCase().trim();
    return products.any((p) => p.name.toLowerCase().trim() == lower && p.id != excludeId);
  }

  void addProduct(Product p) {
    products.add(p);
    _persist();
    notifyListeners();
  }

  void updateProduct(Product updated) {
    final idx = products.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      products[idx] = updated;
      _persist();
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    products.removeWhere((p) => p.id == id);
    _persist();
    notifyListeners();
  }

  Product? findByBarcode(String barcode) {
    try {
      return products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  // ── Cart ──────────────────────────────────────────────────────────────────────
  void addToCart(Product product) {
    final idx = cart.indexWhere((c) => c.product.id == product.id);
    if (idx != -1) {
      if (cart[idx].qty < product.stock) cart[idx].qty++;
    } else {
      if (product.stock > 0) cart.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    cart.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  void updateCartQty(String productId, int qty) {
    final idx = cart.indexWhere((c) => c.product.id == productId);
    if (idx != -1) {
      if (qty <= 0) cart.removeAt(idx);
      else cart[idx].qty = qty;
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  double get cartTotal => cart.fold(0, (s, c) => s + c.subtotal);
  int get cartCount => cart.fold(0, (s, c) => s + c.qty);

  // ── Checkout ──────────────────────────────────────────────────────────────────
  Sale checkout({bool isUtang = false, String? customerName}) {
    final saleItems = cart.map((c) => SaleItem(
      productId: c.product.id,
      name: c.product.name,
      emoji: c.product.emoji,
      price: c.product.price,
      qty: c.qty,
    )).toList();

    final sale = Sale(
      id: _uuid.v4(),
      items: saleItems,
      total: cartTotal,
      isUtang: isUtang,
      customerName: customerName,
      date: DateTime.now(),
    );

    // Deduct stock for all items
    for (final item in cart) {
      final idx = products.indexWhere((p) => p.id == item.product.id);
      if (idx != -1) {
        products[idx].stock -= item.qty;
        products[idx].sold = products[idx].sold + item.qty;
      }
    }

    // If utang — accumulate into existing customer or create new
    if (isUtang && customerName != null && customerName.isNotEmpty) {
      final newDebtItems = cart.map((c) => DebtItem(
        productId: c.product.id,
        name: c.product.name,
        price: c.product.price,
        quantity: c.qty,
      )).toList();

      final existingIdx = debts.indexWhere(
        (d) => !d.paid && d.customerName.toLowerCase().trim() == customerName.toLowerCase().trim(),
      );
      if (existingIdx != -1) {
        debts[existingIdx].amount += cartTotal;
        debts[existingIdx].debtItems.addAll(newDebtItems);
      } else {
        debts.add(Debt(
          id: _uuid.v4(),
          customerName: customerName,
          amount: cartTotal,
          debtItems: newDebtItems,
          date: DateTime.now(),
        ));
      }
    }

    sales.add(sale);
    cart.clear();
    _persist();
    notifyListeners();
    return sale;
  }

  // ── Debts ─────────────────────────────────────────────────────────────────────
  bool customerDebtExists(String name) {
    final lower = name.toLowerCase().trim();
    return debts.any((d) => !d.paid && d.customerName.toLowerCase().trim() == lower);
  }

  /// Add or accumulate a manual debt entry (no product link)
  void addDebt(Debt debt) {
    final existingIdx = debts.indexWhere(
      (d) => !d.paid && d.customerName.toLowerCase().trim() == debt.customerName.toLowerCase().trim(),
    );
    if (existingIdx != -1) {
      debts[existingIdx].amount += debt.amount;
      debts[existingIdx].debtItems.addAll(debt.debtItems);
    } else {
      debts.add(debt);
    }
    _persist();
    notifyListeners();
  }

  /// Add specific inventory items to a customer's debt AND deduct stock
  void addProductsToDebt(String customerName, List<DebtItem> items) {
    double total = items.fold(0, (s, i) => s + i.total);

    // Deduct stock for each product
    for (final item in items) {
      if (item.productId.isNotEmpty) {
        final idx = products.indexWhere((p) => p.id == item.productId);
        if (idx != -1) {
          products[idx].stock = (products[idx].stock - item.quantity).clamp(0, 999999);
          products[idx].sold += item.quantity;
        }
      }
    }

    // Add to or create debt
    final existingIdx = debts.indexWhere(
      (d) => !d.paid && d.customerName.toLowerCase().trim() == customerName.toLowerCase().trim(),
    );
    if (existingIdx != -1) {
      debts[existingIdx].amount += total;
      debts[existingIdx].debtItems.addAll(items);
    } else {
      debts.add(Debt(
        id: _uuid.v4(),
        customerName: customerName,
        amount: total,
        debtItems: items,
        date: DateTime.now(),
      ));
    }

    _persist();
    notifyListeners();
  }

  void markDebtPaid(String id) {
    final idx = debts.indexWhere((d) => d.id == id);
    if (idx != -1) {
      debts[idx].paid = true;
      debts[idx].paidAmount = debts[idx].amount;
      debts[idx].paidDate = DateTime.now();
      _persist();
      notifyListeners();
    }
  }

  bool payPartialDebt(String id, double amount) {
    final idx = debts.indexWhere((d) => d.id == id);
    if (idx == -1) return false;
    debts[idx].paidAmount = (debts[idx].paidAmount + amount).clamp(0, debts[idx].amount);
    if (debts[idx].paidAmount >= debts[idx].amount) {
      debts[idx].paid = true;
      debts[idx].paidDate = DateTime.now();
    }
    _persist();
    notifyListeners();
    return debts[idx].paid;
  }

  void deleteDebt(String id) {
    debts.removeWhere((d) => d.id == id);
    _persist();
    notifyListeners();
  }

  // ── Analytics ─────────────────────────────────────────────────────────────────
  List<Sale> get todaySales {
    final today = DateTime.now();
    return sales.where((s) =>
        s.date.day == today.day &&
        s.date.month == today.month &&
        s.date.year == today.year).toList();
  }

  double get todayRevenue => todaySales.fold(0, (s, sale) => s + sale.total);
  double get totalRevenue => sales.where((s) => !s.isUtang).fold(0, (s, sale) => s + sale.total);
  double get totalUtang => debts.where((d) => !d.paid).fold(0, (s, d) => s + d.remaining);
  double get totalInventoryValue =>
      products.fold(0, (s, p) => s + (p.capital > 0 ? p.capital * p.stock : p.price * p.stock));
  int get lowStockCount => products.where((p) => p.isLow || p.isOut).length;

  Product? get topSeller {
    if (products.isEmpty) return null;
    return products.reduce((a, b) => a.sold > b.sold ? a : b);
  }

  // ── Export / Clear ────────────────────────────────────────────────────────────
  Future<String> exportJson() => DatabaseService.instance.exportJson();

  Future<void> clearAll() async {
    products.clear();
    sales.clear();
    debts.clear();
    cart.clear();
    await DatabaseService.instance.clearAll();
    notifyListeners();
  }

  String newId() => _uuid.v4();
}
