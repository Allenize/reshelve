import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_store.dart';
import '../models/product.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/product_card.dart';
import '../widgets/product_detail_sheet.dart';
import '../widgets/toast.dart';
import 'receipt_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _cat = 'all';

  List<Product> _filtered(List<Product> products) {
    if (_cat == 'all') return products;
    return products.where((p) => p.cat == _cat).toList();
  }

  void _checkout(BuildContext context, AppStore store, bool isUtang) async {
    if (store.cart.isEmpty) return;

    if (isUtang) {
      final ctrl = TextEditingController();
      final name = await showDialog<String>(
        context: context,
        builder: (_) => _UtangNameDialog(store: store),
      );
      if (name == null || name.isEmpty) return;
      final sale = store.checkout(isUtang: true, customerName: name);
      if (mounted) {
        showToast(context, '📋 Utang recorded for $name', color: AppColors.warn);
        Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(sale: sale)));
      }
    } else {
      final sale = store.checkout();
      if (mounted) {
        showToast(context, '✅ Sale complete!');
        Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(sale: sale)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final filtered = _filtered(store.products);
    final hasCart = store.cart.isNotEmpty;

    return Stack(children: [
      Column(children: [
        // Top Bar
        AppTopBar(
          wordmark: 'Point of Sale',
          title: 'New Sale',
          subtitle: 'Tap a product to add',
          actions: [
            if (hasCart)
              AppIconBtn(icon: Icons.delete_outline, onTap: () {
                store.clearCart();
                showToast(context, '🗑 Cart cleared');
              }),
          ],
        ),

        // Category chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            CategoryChip(label: 'All', selected: _cat == 'all', onTap: () => setState(() => _cat = 'all')),
            const SizedBox(width: 8),
            ...kCategories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(label: c, selected: _cat == c, onTap: () => setState(() => _cat = c)),
                )),
          ]),
        ),

        // Products + Cart
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, hasCart ? 160 : 100),
            children: [
              // Products section
              const SectionHeader(title: 'Products'),
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No products', style: TextStyle(color: AppColors.muted))),
                )
              else
                ...filtered.map((p) => ProductCard(
                      product: p,
                      onTap: () {
                        if (p.stock == 0) {
                          showToast(context, '⚠️ Out of stock', color: AppColors.warn);
                          return;
                        }
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => ProductDetailSheet(product: p, showAddToCart: true),
                        );
                      },
                      trailing: GestureDetector(
                        onTap: () {
                          if (p.stock == 0) {
                            showToast(context, '⚠️ Out of stock', color: AppColors.warn);
                            return;
                          }
                          store.addToCart(p);
                          showToast(context, '🛒 ${p.name} added');
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    )),

              // Cart section
              if (hasCart) ...[
                const SizedBox(height: 20),
                const SectionHeader(title: 'Cart'),
                const SizedBox(height: 10),
                ...store.cart.map((item) => _CartItem(
                      item: item,
                      onInc: () => store.updateCartQty(item.product.id, item.qty + 1),
                      onDec: () => store.updateCartQty(item.product.id, item.qty - 1),
                    )),
              ],
            ],
          ),
        ),
      ]),

      // Cart Footer
      if (hasCart)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _CartFooter(
            total: store.cartTotal,
            count: store.cartCount,
            onPaid: () => _checkout(context, store, false),
            onUtang: () => _checkout(context, store, true),
          ),
        ),
    ]);
  }
}

// ── Cart Item ─────────────────────────────────────────────────────────────────
class _CartItem extends StatelessWidget {
  final dynamic item;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _CartItem({required this.item, required this.onInc, required this.onDec});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Center(child: Text(item.product.emoji, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.product.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textColor),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('₱${item.product.price.toStringAsFixed(0)} each',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₱${item.subtotal.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent)),
          const SizedBox(height: 6),
          QtyStepper(value: item.qty, onInc: onInc, onDec: onDec),
        ]),
      ]),
    );
  }
}

// ── Cart Footer ───────────────────────────────────────────────────────────────
class _CartFooter extends StatelessWidget {
  final double total;
  final int count;
  final VoidCallback onPaid;
  final VoidCallback onUtang;

  const _CartFooter({required this.total, required this.count, required this.onPaid, required this.onUtang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: const Color(0xF20B101C),
        border: const Border(top: BorderSide(color: AppColors.glassBorder)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.8)),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('₱${total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.accent)),
            const SizedBox(width: 8),
            Text('$count item${count != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onPaid,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                  SizedBox(width: 7),
                  Text('Mark as Paid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: onUtang,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.warn.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warn.withOpacity(0.35), width: 1.5),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.receipt_long_outlined, color: AppColors.warn, size: 16),
                  SizedBox(width: 7),
                  Text('Utang', style: TextStyle(color: AppColors.warn, fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Utang Name Dialog with existing-debt awareness ────────────────────────────
class _UtangNameDialog extends StatefulWidget {
  final AppStore store;
  const _UtangNameDialog({required this.store});

  @override
  State<_UtangNameDialog> createState() => _UtangNameDialogState();
}

class _UtangNameDialogState extends State<_UtangNameDialog> {
  final _ctrl = TextEditingController();
  bool _hasExistingDebt = false;
  double _existingAmount = 0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_checkExisting);
  }

  void _checkExisting() {
    final lower = _ctrl.text.toLowerCase().trim();
    final existing = widget.store.debts.where(
      (d) => !d.paid && d.customerName.toLowerCase().trim() == lower,
    );
    setState(() {
      _hasExistingDebt = existing.isNotEmpty;
      _existingAmount = existing.isEmpty ? 0 : existing.first.remaining;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.dark2,
      title: const Text('Customer Name',
          style: TextStyle(color: AppColors.textColor, fontSize: 18, fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textColor),
          decoration: const InputDecoration(hintText: 'e.g. Aling Nena'),
        ),
        if (_hasExistingDebt) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warn.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warn.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppColors.warn, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Has ₱${_existingAmount.toStringAsFixed(0)} existing debt. Amount will be added.',
                  style: const TextStyle(color: AppColors.warn, fontSize: 11),
                ),
              ),
            ]),
          ),
        ],
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('Record Utang',
              style: TextStyle(color: AppColors.warn, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
