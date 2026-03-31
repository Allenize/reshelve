class SaleItem {
  final String productId;
  final String name;
  final String emoji;
  final double price;
  final int qty;

  SaleItem({
    required this.productId,
    required this.name,
    required this.emoji,
    required this.price,
    required this.qty,
  });

  double get subtotal => price * qty;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'emoji': emoji,
        'price': price,
        'qty': qty,
      };

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
        productId: j['productId'] ?? '',
        name: j['name'] ?? '',
        emoji: j['emoji'] ?? '📦',
        price: (j['price'] ?? 0).toDouble(),
        qty: j['qty'] ?? 1,
      );
}

class Sale {
  final String id;
  final List<SaleItem> items;
  final double total;
  final bool isUtang;
  final String? customerName;
  final DateTime date;

  Sale({
    required this.id,
    required this.items,
    required this.total,
    this.isUtang = false,
    this.customerName,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((i) => i.toJson()).toList(),
        'total': total,
        'isUtang': isUtang,
        'customerName': customerName,
        'date': date.toIso8601String(),
      };

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
        id: j['id'] ?? '',
        items: (j['items'] as List? ?? [])
            .map((i) => SaleItem.fromJson(i))
            .toList(),
        total: (j['total'] ?? 0).toDouble(),
        isUtang: j['isUtang'] ?? false,
        customerName: j['customerName'],
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      );
}
