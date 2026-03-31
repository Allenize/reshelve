import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_store.dart';
import '../models/product.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/product_card.dart';
import '../widgets/add_edit_product_sheet.dart';
import '../widgets/product_detail_sheet.dart';
import 'scan_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _cat = 'all';
  String _search = '';
  String _sort = 'name'; // name | stock | price

  List<Product> _filtered(List<Product> products) {
    var list = products.where((p) {
      final matchCat = _cat == 'all' || p.cat == _cat;
      final matchSearch =
          _search.isEmpty || p.name.toLowerCase().contains(_search.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
    switch (_sort) {
      case 'stock':
        list.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'price':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final filtered = _filtered(store.products);
    final activeCats =
        kCategories.where((c) => store.products.any((p) => p.cat == c)).toList();

    return Stack(children: [
      // ── Main column ──────────────────────────────────────────────────────────
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppTopBar(
          wordmark: 'Inventory',
          title: 'Products',
          subtitle: '${store.products.length} items · ${store.lowStockCount} low',
          actions: [
            AppIconBtn(icon: Icons.sort_outlined, onTap: () => _showSortSheet(context)),
            AppIconBtn(
              icon: Icons.add,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddEditProductSheet(),
              ),
            ),
          ],
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(children: [
              const Icon(Icons.search, size: 16, color: AppColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: AppColors.textColor, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search products…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ]),
          ),
        ),

        // Category chips with emoji
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            _CatChip(
              label: 'All',
              emoji: '🏪',
              selected: _cat == 'all',
              onTap: () => setState(() => _cat = 'all'),
            ),
            const SizedBox(width: 8),
            ...activeCats.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CatChip(
                    label: c,
                    emoji: categoryEmoji(c),
                    selected: _cat == c,
                    onTap: () => setState(() => _cat = c),
                  ),
                )),
            ...kCategories.where((c) => !activeCats.contains(c)).map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CatChip(
                    label: c,
                    emoji: categoryEmoji(c),
                    selected: _cat == c,
                    dimmed: true,
                    onTap: () => setState(() => _cat = c),
                  ),
                )),
          ]),
        ),

        // Product list
        Expanded(
          child: filtered.isEmpty
              ? _EmptyInventory(searching: _search.isNotEmpty || _cat != 'all')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => ProductCard(
                    product: filtered[i],
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ProductDetailSheet(product: filtered[i]),
                    ),
                  ),
                ),
        ),
      ]),

      // ── Scan FAB (bottom-right) ───────────────────────────────────────────────
      Positioned(
        bottom: 100,
        right: 20,
        child: GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ScanScreen())),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.info.withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
          ),
        ),
      ),
    ]);
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.dark2,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2))),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Sort by',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColor)),
          ),
          const SizedBox(height: 12),
          ...[
            ('name', Icons.sort_by_alpha_outlined, 'Name (A–Z)'),
            ('stock', Icons.inventory_2_outlined, 'Stock (Low first)'),
            ('price', Icons.attach_money_outlined, 'Price (High first)'),
          ].map((opt) => GestureDetector(
                onTap: () {
                  setState(() => _sort = opt.$1);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _sort == opt.$1
                        ? AppColors.accent.withOpacity(0.1)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _sort == opt.$1
                          ? AppColors.accent.withOpacity(0.4)
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Row(children: [
                    Icon(opt.$2,
                        color: _sort == opt.$1 ? AppColors.accent : AppColors.muted,
                        size: 18),
                    const SizedBox(width: 12),
                    Text(opt.$3,
                        style: TextStyle(
                            color: _sort == opt.$1
                                ? AppColors.accent
                                : AppColors.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const Spacer(),
                    if (_sort == opt.$1)
                      const Icon(Icons.check, color: AppColors.accent, size: 16),
                  ]),
                ),
              )),
        ]),
      ),
    );
  }
}

// ── Category Chip ─────────────────────────────────────────────────────────────
class _CatChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.card,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : dimmed
                    ? AppColors.glassBorder.withOpacity(0.5)
                    : AppColors.glassBorder,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji,
              style: TextStyle(
                  fontSize: 13,
                  color: dimmed && !selected ? const Color(0x55FFFFFF) : null)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : dimmed
                        ? AppColors.muted.withOpacity(0.5)
                        : AppColors.muted2,
              )),
        ]),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyInventory extends StatelessWidget {
  final bool searching;
  const _EmptyInventory({this.searching = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          searching ? Icons.search_off_outlined : Icons.inventory_2_outlined,
          size: 56,
          color: AppColors.glassBorder.withOpacity(0.4),
        ),
        const SizedBox(height: 12),
        Text(
          searching ? 'No products match' : 'No products yet',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        const SizedBox(height: 4),
        Text(
          searching
              ? 'Try a different search or category'
              : 'Tap + to add your first product',
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      ]),
    );
  }
}
