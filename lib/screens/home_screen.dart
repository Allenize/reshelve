import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_store.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/add_edit_product_sheet.dart';
import '../widgets/add_debt_sheet.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) goTo;

  const HomeScreen({super.key, required this.goTo});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _dateStr() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
    return '${days[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final recent = store.sales.reversed.take(3).toList();

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top Bar — Reshelve wordmark
        AppTopBar(
          wordmark: 'Reshelve',
          title: _greeting(),
          subtitle: _dateStr(),
          actions: [
            AppIconBtn(icon: Icons.notifications_outlined, onTap: () => _showNotifs(context, store)),
          ],
        ),

        // Stat cards — 3 key metrics
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            StatCard(
              value: '₱${store.todayRevenue.toStringAsFixed(0)}',
              label: "Today's Sales",
              icon: Icons.trending_up,
            ),
            const SizedBox(width: 10),
            StatCard(
              value: '₱${store.totalUtang.toStringAsFixed(0)}',
              label: 'Total Utang',
              icon: Icons.receipt_long_outlined,
              valueColor: AppColors.warn,
            ),
            const SizedBox(width: 10),
            StatCard(
              value: '${store.lowStockCount}',
              label: 'Low Stock',
              icon: Icons.warning_amber_outlined,
              valueColor: store.lowStockCount > 0 ? AppColors.danger : null,
            ),
          ]),
        ),

        // Inventory value banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent.withOpacity(0.12), AppColors.primary.withOpacity(0.08)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.store_outlined, color: AppColors.accent, size: 18),
              const SizedBox(width: 10),
              const Text('Total Inventory Value', style: TextStyle(color: AppColors.muted2, fontSize: 13)),
              const Spacer(),
              Text(
                '₱${store.totalInventoryValue.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.accent),
              ),
            ]),
          ),
        ),

        // Quick Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _QuickBtn(icon: Icons.shopping_cart_outlined, label: 'New Sale', sub: 'Start selling', color: AppColors.accent, onTap: () => goTo(2)),
                _QuickBtn(icon: Icons.qr_code_scanner, label: 'Scan Item', sub: 'Via Stock page', color: AppColors.info, onTap: () => goTo(1)),
                _QuickBtn(icon: Icons.add_box_outlined, label: 'Add Stock', sub: 'New product', color: AppColors.warn,
                    onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                        builder: (_) => const AddEditProductSheet())),
                _QuickBtn(icon: Icons.receipt_long_outlined, label: 'Add Utang', sub: 'Record debt', color: AppColors.danger,
                    onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                        builder: (_) => const AddDebtSheet())),
              ],
            ),
          ]),
        ),

        // Recent Sales
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Recent Sales'),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No sales yet today', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  children: recent.map((s) => ListTile(
                    leading: Icon(
                      s.isUtang ? Icons.receipt_long_outlined : Icons.check_circle_outline,
                      color: s.isUtang ? AppColors.warn : AppColors.accent,
                      size: 20,
                    ),
                    title: Text(s.items.map((i) => '${i.emoji}${i.name.split(' ').first}').join(', '),
                        style: const TextStyle(fontSize: 13, color: AppColors.textColor),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      s.isUtang ? '⚠️ Utang${s.customerName != null ? " — ${s.customerName}" : ""}' : '✓ Paid',
                      style: TextStyle(fontSize: 11, color: s.isUtang ? AppColors.warn : AppColors.accent),
                    ),
                    trailing: Text('₱${s.total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textColor)),
                  )).toList(),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  void _showNotifs(BuildContext context, AppStore store) {
    final outOfStock = store.products.where((p) => p.isOut).toList();
    final lowStock = store.products.where((p) => p.isLow).toList();
    final unpaidUtang = store.totalUtang;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.dark2,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2))),
            const Row(children: [
              Icon(Icons.notifications_outlined, color: AppColors.accent, size: 22),
              SizedBox(width: 10),
              Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textColor)),
            ]),
            const SizedBox(height: 16),
            if (outOfStock.isEmpty && lowStock.isEmpty && unpaidUtang == 0)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('All clear ✓', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
              ))
            else ...[ 
              ...outOfStock.map((p) => _notifItem('🔴', '${p.emoji} ${p.name} is out of stock', 'Inventory')),
              ...lowStock.map((p) => _notifItem('🟡', '${p.emoji} ${p.name} is running low (${p.stock} left)', 'Inventory')),
              if (unpaidUtang > 0) _notifItem('🟠', 'Total unpaid debts: ₱${unpaidUtang.toStringAsFixed(0)}', 'Debts'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _notifItem(String dot, String msg, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(dot, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(msg, style: const TextStyle(fontSize: 13, color: AppColors.textColor, height: 1.4)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ])),
      ]),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textColor)),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      ),
    );
  }
}
