import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';

class ReceiptScreen extends StatelessWidget {
  final Sale sale;

  const ReceiptScreen({super.key, required this.sale});

  Future<void> _printReceipt() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(child: pw.Text('RESHELVE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.Center(child: pw.Text('Official Receipt', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 6),
          ...sale.items.map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${item.name} x${item.qty}', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text('₱${item.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 11)),
                ],
              )),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('₱${sale.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          if (sale.isUtang && sale.customerName != null) ...[
            pw.SizedBox(height: 4),
            pw.Text('Utang – ${sale.customerName}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.orange)),
          ],
          pw.SizedBox(height: 12),
          pw.Center(child: pw.Text('Thank you for shopping!', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500))),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${sale.date.month}/${sale.date.day}/${sale.date.year} '
        '${sale.date.hour.toString().padLeft(2, '0')}:${sale.date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Receipt', style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Receipt card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Center(
                child: Text('RESHELVE', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
              ),
              const Center(
                child: Text('Official Receipt', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ),
              const SizedBox(height: 8),
              Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              if (sale.isUtang && sale.customerName != null)
                Text('Customer: ${sale.customerName}', style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
              const Divider(color: Color(0xFFCCCCCC)),
              ...sale.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(
                          child: Text('${item.name} x${item.qty}',
                              style: const TextStyle(color: Colors.black87, fontSize: 13))),
                      Text('₱${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.black87, fontSize: 13)),
                    ]),
                  )),
              const Divider(color: Color(0xFFCCCCCC)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('TOTAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16)),
                Text('₱${sale.total.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
              const SizedBox(height: 12),
              const Center(child: Text('Thank you for shopping!', style: TextStyle(color: Colors.grey, fontSize: 11))),
            ]),
          ),

          const SizedBox(height: 20),

          // Print button
          GradientButton(
            label: 'Print Receipt',
            icon: Icons.print_outlined,
            onTap: _printReceipt,
            width: double.infinity,
          ),

          const SizedBox(height: 12),

          // Done button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Center(
                child: Text('Done', style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
