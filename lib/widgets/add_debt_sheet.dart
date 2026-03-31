import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/debt.dart';
import '../models/debt_item.dart';
import '../models/product.dart';
import '../services/app_store.dart';
import '../theme.dart';
import 'shared_widgets.dart';
import 'app_sheet.dart';
import 'toast.dart';

class AddDebtSheet extends StatefulWidget {
  final double? prefillAmount;
  final String? prefillCustomer;

  const AddDebtSheet({super.key, this.prefillAmount, this.prefillCustomer});

  @override
  State<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<AddDebtSheet> {
  final _nameCtrl = TextEditingController();
  final _manualNameCtrl = TextEditingController();
  final _manualPriceCtrl = TextEditingController();
  final _manualQtyCtrl = TextEditingController();

  List<DebtItem> _items = [];
  bool _hasExistingDebt = false;
  double _existingAmount = 0;

  double get _total => _items.fold(0, (s, i) => s + i.total);

  @override
  void initState() {
    super.initState();
    if (widget.prefillCustomer != null) {
      _nameCtrl.text = widget.prefillCustomer!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkExisting(widget.prefillCustomer!));
    }
    _nameCtrl.addListener(() => _checkExisting(_nameCtrl.text));
  }

  void _checkExisting(String name) {
    if (!mounted) return;
    final store = context.read<AppStore>();
    final lower = name.toLowerCase().trim();
    final existing = store.debts.where((d) => !d.paid && d.customerName.toLowerCase().trim() == lower);
    setState(() {
      _hasExistingDebt = existing.isNotEmpty;
      _existingAmount = existing.isEmpty ? 0 : existing.first.remaining;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manualNameCtrl.dispose();
    _manualPriceCtrl.dispose();
    _manualQtyCtrl.dispose();
    super.dispose();
  }

  void _addFromInventory(BuildContext context) async {
    final store = context.read<AppStore>();
    final available = store.products.where((p) => p.stock > 0).toList();

    final selected = await showModalBottomSheet<Product>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.dark2,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 14, bottom: 14),
                decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2))),
            const Text('Select from Stock',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textColor)),
            const SizedBox(height: 8),
            Expanded(child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              itemCount: available.length,
              itemBuilder: (_, i) {
                final p = available[i];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, p),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: const TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w600)),
                        Text('Stock: ${p.stock}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ])),
                      Text('₱${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 16)),
                    ]),
                  ),
                );
              },
            )),
          ]),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        final idx = _items.indexWhere((i) => i.productId == selected.id);
        if (idx != -1) {
          _items[idx].quantity++;
        } else {
          _items.add(DebtItem(
            productId: selected.id,
            name: selected.name,
            price: selected.price,
            quantity: 1,
          ));
        }
      });
    }
  }

  void _addManualItem() {
    final name = _manualNameCtrl.text.trim();
    final price = double.tryParse(_manualPriceCtrl.text) ?? 0;
    final qty = int.tryParse(_manualQtyCtrl.text) ?? 1;
    if (name.isEmpty) return;
    setState(() {
      _items.add(DebtItem(name: name, price: price, quantity: qty));
      _manualNameCtrl.clear();
      _manualPriceCtrl.clear();
      _manualQtyCtrl.clear();
    });
  }

  void _save(BuildContext context) {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showToast(context, '⚠️ Enter a customer name', color: AppColors.warn);
      return;
    }
    if (_items.isEmpty) {
      showToast(context, '⚠️ Add at least one item', color: AppColors.warn);
      return;
    }

    final store = context.read<AppStore>();

    // Use addProductsToDebt so inventory is auto-deducted for linked products
    store.addProductsToDebt(name, _items);

    showToast(context,
        _hasExistingDebt
            ? '📋 Added ₱${_total.toStringAsFixed(0)} to ${name}\'s debt'
            : '📋 Debt recorded for $name',
        color: AppColors.warn);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          // Header
          const Row(children: [
            Icon(Icons.receipt_long_outlined, color: AppColors.accent, size: 22),
            SizedBox(width: 10),
            Text('Record Utang', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textColor)),
          ]),
          const SizedBox(height: 20),

          // Customer name
          AppFormField(
            label: 'Customer Name',
            child: TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textColor, fontSize: 15),
              decoration: const InputDecoration(hintText: 'e.g. Aling Nena'),
            ),
          ),

          if (_hasExistingDebt) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warn.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warn.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: AppColors.warn, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Has existing debt of ₱${_existingAmount.toStringAsFixed(0)}. Will be added.',
                  style: const TextStyle(color: AppColors.warn, fontSize: 12),
                )),
              ]),
            ),
          ],

          const SizedBox(height: 18),
          const Text('Items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: AppColors.muted, letterSpacing: 0.8)),
          const SizedBox(height: 10),

          // ── Item list (receipt style) ────────────────────────────────────────
          if (_items.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(children: [
                ..._items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return _ReceiptRow(
                    item: item,
                    onRemove: () => setState(() => _items.removeAt(i)),
                    onQtyChange: (q) => setState(() {
                      if (q <= 0) _items.removeAt(i);
                      else _items[i].quantity = q;
                    }),
                  );
                }),
                // Divider + Total
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.glassBorder)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                          color: AppColors.muted, letterSpacing: 1)),
                      Text('₱${_total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
          ],

          // ── Add from inventory ───────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _addFromInventory(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.inventory_2_outlined, color: AppColors.accent, size: 16),
                    SizedBox(width: 7),
                    Text('From Stock', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 10),

          // ── Manual item entry ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Add Item Manually', style: TextStyle(fontSize: 11, color: AppColors.muted,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              TextField(
                controller: _manualNameCtrl,
                style: const TextStyle(color: AppColors.textColor, fontSize: 14),
                decoration: const InputDecoration(hintText: 'Item name', isDense: true),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(
                  controller: _manualPriceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textColor, fontSize: 14),
                  decoration: const InputDecoration(hintText: 'Price ₱', isDense: true),
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                  controller: _manualQtyCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textColor, fontSize: 14),
                  decoration: const InputDecoration(hintText: 'Qty', isDense: true),
                )),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addManualItem,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 20),
          if (_items.isNotEmpty)
            GradientButton(
              label: 'Record ₱${_total.toStringAsFixed(2)} Debt',
              icon: Icons.receipt_long_outlined,
              onTap: () => _save(context),
              width: double.infinity,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Center(child: Text('Add items above to record debt',
                  style: TextStyle(color: AppColors.muted, fontSize: 13))),
            ),
        ]),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final DebtItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChange;

  const _ReceiptRow({required this.item, required this.onRemove, required this.onQtyChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name,
              style: const TextStyle(color: AppColors.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
          if (item.price > 0)
            Text('₱${item.price.toStringAsFixed(2)} × ${item.quantity}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ])),
        // Qty controls
        Row(children: [
          GestureDetector(
            onTap: () => onQtyChange(item.quantity - 1),
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.glassBorder)),
              child: const Icon(Icons.remove, size: 14, color: AppColors.muted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('${item.quantity}',
                style: const TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700)),
          ),
          GestureDetector(
            onTap: () => onQtyChange(item.quantity + 1),
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.glassBorder)),
              child: const Icon(Icons.add, size: 14, color: AppColors.accent),
            ),
          ),
        ]),
        const SizedBox(width: 10),
        // Total for this row
        SizedBox(
          width: 64,
          child: Text('₱${item.total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close, size: 16, color: AppColors.muted),
        ),
      ]),
    );
  }
}
