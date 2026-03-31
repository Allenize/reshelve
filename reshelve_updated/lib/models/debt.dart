import 'debt_item.dart';

class Debt {
  final String id;
  String customerName;
  double amount;
  double paidAmount;
  List<DebtItem> debtItems; // structured itemized list
  bool paid;
  final DateTime date;
  DateTime? paidDate;

  Debt({
    required this.id,
    required this.customerName,
    required this.amount,
    this.paidAmount = 0,
    List<DebtItem>? debtItems,
    this.paid = false,
    required this.date,
    this.paidDate,
  }) : debtItems = debtItems ?? [];

  double get remaining => amount - paidAmount;
  bool get isPartiallyPaid => paidAmount > 0 && !paid;

  // Legacy plain-text items field for backward compat display
  String get itemsSummary => debtItems.isNotEmpty
      ? debtItems.map((i) => '${i.name} x${i.quantity}').join(', ')
      : '';

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'amount': amount,
        'paidAmount': paidAmount,
        'debtItems': debtItems.map((i) => i.toJson()).toList(),
        'paid': paid,
        'date': date.toIso8601String(),
        'paidDate': paidDate?.toIso8601String(),
      };

  factory Debt.fromJson(Map<String, dynamic> j) {
    List<DebtItem> items = [];
    if (j['debtItems'] != null) {
      items = (j['debtItems'] as List).map((e) => DebtItem.fromJson(e)).toList();
    } else if (j['items'] != null && j['items'] is String) {
      // Migrate legacy plain-text items
      final raw = j['items'] as String;
      for (final part in raw.split(', ')) {
        items.add(DebtItem(name: part, price: 0));
      }
    }
    return Debt(
      id: j['id'] ?? '',
      customerName: j['customerName'] ?? j['name'] ?? '',
      amount: (j['amount'] ?? 0).toDouble(),
      paidAmount: (j['paidAmount'] ?? 0).toDouble(),
      debtItems: items,
      paid: j['paid'] ?? false,
      date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      paidDate: j['paidDate'] != null ? DateTime.tryParse(j['paidDate']) : null,
    );
  }
}
