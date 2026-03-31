import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/app_store.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/add_edit_product_sheet.dart';
import '../widgets/toast.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final top = store.topSeller;

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppTopBar(
          wordmark: 'Overview',
          title: 'Analytics & Tools',
          subtitle: 'Stats, history & settings',
        ),

        // ── Dashboard Analytics ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: "Today's Dashboard"),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _AnCard(
                  icon: Icons.trending_up,
                  label: "Today's Revenue",
                  value: '₱${store.todayRevenue.toStringAsFixed(0)}',
                  color: AppColors.accent,
                ),
                _AnCard(
                  icon: Icons.receipt_outlined,
                  label: 'Transactions',
                  value: '${store.todaySales.length}',
                  color: AppColors.info,
                ),
                _AnCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'Total Utang',
                  value: '₱${store.totalUtang.toStringAsFixed(0)}',
                  color: AppColors.warn,
                ),
                _AnCard(
                  icon: Icons.store_outlined,
                  label: 'Inventory Value',
                  value: '₱${store.totalInventoryValue.toStringAsFixed(0)}',
                  color: AppColors.accent2,
                ),
              ],
            ),
            if (top != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.warn.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.star_outline, color: AppColors.warn, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Top Seller', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    Text('${top.emoji} ${top.name}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textColor)),
                  ]),
                  const Spacer(),
                  Text('${top.sold} sold',
                      style: const TextStyle(fontSize: 13, color: AppColors.warn, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ]),
        ),

        // ── Low Stock Alert ────────────────────────────────────────────────────
        if (store.lowStockCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_outlined, color: AppColors.danger, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${store.lowStockCount} product${store.lowStockCount != 1 ? "s" : ""} running low or out of stock.',
                    style: const TextStyle(fontSize: 13, color: AppColors.danger),
                  ),
                ),
              ]),
            ),
          ),

        // ── Tools ─────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Tools'),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.inventory_2_outlined,
              iconColor: AppColors.accent,
              label: 'Add Product',
              sub: 'Add new inventory item',
              onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddEditProductSheet()),
            ),
            _MenuTile(
              icon: Icons.history_outlined,
              iconColor: AppColors.info,
              label: 'Sales History',
              sub: '${store.sales.length} total transactions',
              onTap: () => _showSalesHistory(context, store),
            ),
            _MenuTile(
              icon: Icons.download_outlined,
              iconColor: AppColors.info,
              label: 'Export Backup',
              sub: 'Download JSON backup of all data',
              onTap: () async {
                final json = await store.exportJson();
                final dir = await getTemporaryDirectory();
                final file = File(
                    '${dir.path}/reshelve_backup_${DateTime.now().millisecondsSinceEpoch}.json');
                await file.writeAsString(json);
                await Share.shareXFiles([XFile(file.path)], text: 'Reshelve POS Backup');
              },
            ),
          ]),
        ),

        // ── Danger Zone ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Danger Zone'),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.delete_forever_outlined,
              iconColor: AppColors.danger,
              label: 'Clear All Data',
              sub: 'Permanently reset everything',
              onTap: () => _confirmClear(context, store),
            ),
          ]),
        ),
      ]),
    );
  }

  void _showSalesHistory(BuildContext context, AppStore store) {
    final allSales = store.sales.reversed.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.dark2,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 14, bottom: 14),
                decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2))),
            const Text('Sales History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textColor)),
            const SizedBox(height: 12),
            Expanded(
              child: allSales.isEmpty
                  ? const Center(child: Text('No sales yet', style: TextStyle(color: AppColors.muted)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: allSales.length,
                      itemBuilder: (_, i) {
                        final s = allSales[i];
                        final d = s.date;
                        return ListTile(
                          leading: Icon(
                              s.isUtang ? Icons.receipt_long_outlined : Icons.check_circle_outline,
                              color: s.isUtang ? AppColors.warn : AppColors.accent,
                              size: 20),
                          title: Text(
                              s.items.map((x) => '${x.emoji}${x.name.split(' ').first}').join(', '),
                              style: const TextStyle(fontSize: 13, color: AppColors.textColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              '${d.month}/${d.day}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'
                              '${s.isUtang ? ' · ${s.customerName}' : ''}',
                              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          trailing: Text('₱${s.total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textColor)),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, AppStore store) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.dark2,
        title: const Text('Clear All Data?',
            style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700)),
        content: const Text(
            'This will permanently delete all products, sales, and debts. This cannot be undone.',
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          TextButton(
            onPressed: () {
              store.clearAll();
              Navigator.pop(context);
              showToast(context, 'All data cleared', color: AppColors.danger);
            },
            child: const Text('Clear All',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Analytics Card ─────────────────────────────────────────────────────────────
class _AnCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AnCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Menu Tile ──────────────────────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sub;
  final VoidCallback onTap;

  const _MenuTile(
      {required this.icon, required this.iconColor, required this.label, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textColor)),
            Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
        ]),
      ),
    );
  }
}
