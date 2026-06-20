import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'admin_order_models.dart';

class OrderInvoiceScreen extends StatelessWidget {
  const OrderInvoiceScreen({
    super.key,
    required this.order,
  });

  final AdminOrder order;

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'KDMP Retail',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Center(child: pw.Text('Invoice Pesanan Cabang')),
                pw.SizedBox(height: 18),
                pw.Divider(),
                pw.Text('Order No: ${order.orderNo}'),
                pw.Text('Tanggal: ${formatShortDate(order.placedAt)}'),
                pw.Text('Pelanggan: ${order.customerName}'),
                pw.Text('Tipe Pesanan: ${order.typeLabel}'),
                pw.Text('Status: ${order.statusLabel}'),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Detail Produk',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                ...order.items.map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text('${item.productName} x${item.qty}'),
                        ),
                        pw.Text(formatCurrency(item.subtotal)),
                      ],
                    ),
                  ),
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal'),
                    pw.Text(formatCurrency(order.subtotal)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Ongkir'),
                    pw.Text(formatCurrency(order.deliveryFee)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Diskon'),
                    pw.Text(formatCurrency(-order.discountTotal)),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      formatCurrency(order.grandTotal),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text('Tujuan: ${order.destinationLabel}'),
                if ((order.courierName ?? '').isNotEmpty)
                  pw.Text(
                    'Kurir: ${order.courierName} ${order.courierPhone == null ? '' : '(${order.courierPhone})'}',
                  ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Pesanan')),
      body: PdfPreview(
        build: (format) async => (await _generatePdf()).save(),
      ),
    );
  }
}
