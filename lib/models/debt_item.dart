class DebtItem {
  final String productId; // empty string if manually entered
  final String name;
  final double price;
  int quantity;

  DebtItem({
    this.productId = '',
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  factory DebtItem.fromJson(Map<String, dynamic> j) => DebtItem(
        productId: j['productId'] ?? '',
        name: j['name'] ?? '',
        price: (j['price'] ?? 0).toDouble(),
        quantity: j['quantity'] ?? 1,
      );
}
