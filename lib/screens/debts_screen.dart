import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_store.dart';
import '../models/debt.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/add_debt_sheet.dart';
import '../widgets/toast.dart';
import '../services/database_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final unpaid = store.debts
        .where((d) => !d.paid && (_search.isEmpty || d.customerName.toLowerCase().contains(_search.toLowerCase())))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final paid = store.debts
        .where((d) => d.paid && (_search.isEmpty || d.customerName.toLowerCase().contains(_search.toLowerCase())))
        .toList()
      ..sort((a, b) => (b.paidDate ?? b.date).compareTo(a.paidDate ?? a.date));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppTopBar(
        wordmark: 'Utang',
        title: 'Debts',
        subtitle: '${unpaid.length} unpaid · ₱${store.totalUtang.toStringAsFixed(2)} total',
        actions: [
          AppIconBtn(
            icon: Icons.add,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddDebtSheet(),
            ),
          ),
        ],
      ),

      // Summary banner
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.warn.withOpacity(0.15), AppColors.danger.withOpacity(0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warn.withOpacity(0.25)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.warn.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined, color: AppColors.warn, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('₱${store.totalUtang.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.warn)),
              Text('${unpaid.length} customer${unpaid.length != 1 ? "s" : ""} with outstanding balance',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted2)),
            ])),
            GestureDetector(
              onTap: () => showModalBottomSheet(context: context, isScrollControlled: true,
                  backgroundColor: Colors.transparent, builder: (_) => const AddDebtSheet()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warn.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warn.withOpacity(0.4)),
                ),
                child: const Text('+Utang',
                    style: TextStyle(color: AppColors.warn, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),

      // Search
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
            Expanded(child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: AppColors.textColor, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search customer…',
                border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            )),
          ]),
        ),
      ),

      // Tabs
      Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.muted,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'Unpaid (${unpaid.length})'),
            Tab(text: 'Paid (${paid.length})'),
          ],
        ),
      ),

      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: [
            _DebtList(debts: unpaid, isPaidTab: false),
            _DebtList(debts: paid, isPaidTab: true),
          ],
        ),
      ),
    ]);
  }
}

// ── Debt List ─────────────────────────────────────────────────────────────────
class _DebtList extends StatelessWidget {
  final List<Debt> debts;
  final bool isPaidTab;

  const _DebtList({required this.debts, required this.isPaidTab});

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(isPaidTab ? Icons.check_circle_outline : Icons.receipt_long_outlined,
            size: 54, color: AppColors.muted.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text(isPaidTab ? 'No paid debts yet' : 'No unpaid debts 🎉',
            style: const TextStyle(color: AppColors.muted, fontSize: 15, fontWeight: FontWeight.w600)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: debts.length,
      itemBuilder: (_, i) => _DebtCard(debt: debts[i]),
    );
  }
}

// ── Debt Card ─────────────────────────────────────────────────────────────────
class _DebtCard extends StatelessWidget {
  final Debt debt;
  const _DebtCard({required this.debt});

  String _fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final isPaid = debt.paid;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPaid ? AppColors.accent.withOpacity(0.2) : AppColors.warn.withOpacity(0.2)),
      ),
      child: Column(children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: (isPaid ? AppColors.accent : AppColors.warn).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(isPaid ? Icons.check_circle_outline : Icons.person_outline,
                  color: isPaid ? AppColors.accent : AppColors.warn, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(debt.customerName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textColor)),
              Text('Since ${_fmt(debt.date)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₱${debt.amount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: isPaid ? AppColors.accent : AppColors.warn)),
              if (debt.isPartiallyPaid)
                Text('₱${debt.remaining.toStringAsFixed(2)} left',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
          ]),
        ),

        // ── Receipt-style items ──────────────────────────────────────────────
        if (debt.debtItems.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(children: [
              // Column headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: const [
                  Expanded(child: Text('ITEM', style: TextStyle(fontSize: 10, color: AppColors.muted,
                      fontWeight: FontWeight.w700, letterSpacing: 0.8))),
                  Text('QTY', style: TextStyle(fontSize: 10, color: AppColors.muted,
                      fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  SizedBox(width: 14),
                  SizedBox(width: 72, child: Text('AMOUNT', textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 10, color: AppColors.muted,
                          fontWeight: FontWeight.w700, letterSpacing: 0.8))),
                ]),
              ),
              ...debt.debtItems.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.glassBorder))),
                child: Row(children: [
                  Expanded(child: Text(item.name,
                      style: const TextStyle(fontSize: 13, color: AppColors.textColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text('×${item.quantity}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(width: 14),
                  SizedBox(width: 72,
                    child: Text('₱${item.total.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textColor)),
                  ),
                ]),
              )),
            ]),
          ),
        ],

        // ── Partial progress bar ─────────────────────────────────────────────
        if (debt.isPartiallyPaid)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Paid: ₱${debt.paidAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.accent)),
                Text('Left: ₱${debt.remaining.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.warn)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: debt.paidAmount / debt.amount,
                  backgroundColor: AppColors.warn.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  minHeight: 6,
                ),
              ),
            ]),
          ),

        // ── Action buttons ───────────────────────────────────────────────────
        if (!isPaid)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              // Print receipt
              GestureDetector(
                onTap: () => _printReceipt(context, debt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.info.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.print_outlined, color: AppColors.info, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              // Partial pay
              Expanded(child: GestureDetector(
                onTap: () => _showPaymentDialog(context, store, debt),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.payments_outlined, color: AppColors.info, size: 15),
                    SizedBox(width: 6),
                    Text('Pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.info)),
                  ]),
                ),
              )),
              const SizedBox(width: 8),
              // Full paid
              Expanded(child: GestureDetector(
                onTap: () => _confirmMarkPaid(context, store, debt),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check, color: AppColors.accent, size: 15),
                    SizedBox(width: 6),
                    Text('Fully Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  ]),
                ),
              )),
              const SizedBox(width: 8),
              // Delete
              GestureDetector(
                onTap: () => _confirmDelete(context, store, debt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 16),
                ),
              ),
            ]),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              GestureDetector(
                onTap: () => _printReceipt(context, debt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.info.withOpacity(0.25)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.print_outlined, color: AppColors.info, size: 14),
                    SizedBox(width: 6),
                    Text('Print', style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.check_circle, color: AppColors.accent, size: 14),
              const SizedBox(width: 6),
              Text('Paid on ${_fmt(debt.paidDate ?? debt.date)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
            ]),
          ),
      ]),
    );
  }

  // ── Print Receipt (PDF) ────────────────────────────────────────────────────
  Future<void> _printReceipt(BuildContext context, Debt debt) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('RESHELVE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text('Utang / Debt Receipt', style: const pw.TextStyle(fontSize: 13))),
              pw.Divider(thickness: 1),
              pw.Text('Customer: ${debt.customerName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: ${debt.date.month}/${debt.date.day}/${debt.date.year}'),
              pw.SizedBox(height: 8),
              pw.Divider(),
              // Header row
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('ITEM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text('QTY × PRICE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text('AMOUNT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              ]),
              pw.Divider(),
              if (debt.debtItems.isNotEmpty)
                ...debt.debtItems.map((item) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                        pw.Expanded(child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 12))),
                        pw.Text('${item.quantity} × ₱${item.price.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 12)),
                        pw.SizedBox(width: 8),
                        pw.Text('₱${item.total.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      ]),
                    ))
              else
                pw.Text('(no itemized list)', style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(thickness: 1.5),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text('₱${debt.amount.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ]),
              if (debt.paidAmount > 0) ...[
                pw.SizedBox(height: 4),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('Paid:', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('₱${debt.paidAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 12)),
                ]),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('Balance:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text('₱${debt.remaining.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ]),
              ],
              pw.SizedBox(height: 16),
              pw.Center(child: pw.Text('Thank you!', style: const pw.TextStyle(fontSize: 12))),
            ],
          ),
        ),
      );
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (e) {
      if (context.mounted) showToast(context, '⚠️ Could not print receipt', color: AppColors.warn);
    }
  }

  void _showPaymentDialog(BuildContext context, AppStore store, Debt debt) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.dark2,
        title: Text('Payment — ${debt.customerName}',
            style: const TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Remaining: ₱${debt.remaining.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.warn, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true,
              style: const TextStyle(color: AppColors.textColor),
              decoration: const InputDecoration(hintText: 'Amount paid', prefixText: '₱ ')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text);
              if (amount == null || amount <= 0) return;
              final fullyPaid = store.payPartialDebt(debt.id, amount);
              Navigator.pop(context);
              showToast(context,
                  fullyPaid ? '✅ Fully paid!' : '💳 ₱${amount.toStringAsFixed(0)} recorded',
                  color: fullyPaid ? AppColors.accent : AppColors.info);
            },
            child: const Text('Record', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmMarkPaid(BuildContext context, AppStore store, Debt debt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.dark2,
        title: const Text('Mark as Fully Paid?',
            style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700)),
        content: Text('Mark ₱${debt.remaining.toStringAsFixed(2)} from ${debt.customerName} as paid?',
            style: const TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          TextButton(
            onPressed: () {
              store.markDebtPaid(debt.id);
              Navigator.pop(context);
              showToast(context, '✅ Debt marked as paid!');
            },
            child: const Text('Confirm', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppStore store, Debt debt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.dark2,
        title: const Text('Delete Debt?',
            style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700)),
        content: Text('Delete ₱${debt.amount.toStringAsFixed(0)} debt from ${debt.customerName}?',
            style: const TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          TextButton(
            onPressed: () async {
              // PIN protect delete
              final pinSet = await DatabaseService.instance.hasPin();
              if (context.mounted) Navigator.pop(context);
              if (pinSet && context.mounted) {
                final ok = await _promptPin(context);
                if (!ok) {
                  if (context.mounted) showToast(context, '🔐 Incorrect PIN', color: AppColors.danger);
                  return;
                }
              }
              store.deleteDebt(debt.id);
              if (context.mounted) showToast(context, 'Debt deleted', color: AppColors.danger);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<bool> _promptPin(BuildContext context) async {
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.dark2,
        title: const Text('Enter PIN', style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          autofocus: true,
          maxLength: 6,
          style: const TextStyle(color: AppColors.textColor, fontSize: 22, letterSpacing: 8),
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          TextButton(
            onPressed: () async {
              final ok = await DatabaseService.instance.verifyPin(ctrl.text);
              if (context.mounted) Navigator.pop(context, ok);
            },
            child: const Text('Confirm', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
