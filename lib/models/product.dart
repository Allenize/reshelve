
class Product {
  final String id;
  String name;
  String emoji;
  double price;
  double capital;
  int stock;
  int lowAt;
  String cat;
  int sold;
  String? barcode;
  String? imagePath;

  Product({
    required this.id,
    required this.name,
    this.emoji = '📦',
    required this.price,
    this.capital = 0,
    required this.stock,
    this.lowAt = 5,
    this.cat = 'Others',
    this.sold = 0,
    this.barcode,
    this.imagePath,
  });

  bool get isOut => stock == 0;
  bool get isLow => stock > 0 && stock <= lowAt;
  double get profit => price - capital;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'price': price,
        'capital': capital,
        'stock': stock,
        'lowAt': lowAt,
        'cat': cat,
        'sold': sold,
        'barcode': barcode,
        'imagePath': imagePath,
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        emoji: j['emoji'] ?? '📦',
        price: (j['price'] ?? 0).toDouble(),
        capital: (j['capital'] ?? 0).toDouble(),
        stock: j['stock'] ?? 0,
        lowAt: j['lowAt'] ?? 5,
        cat: j['cat'] ?? 'Others',
        sold: j['sold'] ?? 0,
        barcode: j['barcode'],
        imagePath: j['imagePath'],
      );

  Product copyWith({
    String? name,
    String? emoji,
    double? price,
    double? capital,
    int? stock,
    int? lowAt,
    String? cat,
    int? sold,
    String? barcode,
    String? imagePath,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        price: price ?? this.price,
        capital: capital ?? this.capital,
        stock: stock ?? this.stock,
        lowAt: lowAt ?? this.lowAt,
        cat: cat ?? this.cat,
        sold: sold ?? this.sold,
        barcode: barcode ?? this.barcode,
        imagePath: imagePath ?? this.imagePath,
      );
}
