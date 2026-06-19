import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrderInvoiceScreen extends StatelessWidget {
  const OrderInvoiceScreen({super.key});

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    "MEPUPOIN",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(height: 10),

                pw.Center(
                  child: pw.Text(
                    "Struk Pembelian",
                    style: const pw.TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),

                pw.Divider(),

                pw.Text("Order ID : ORD-001"),
                pw.Text("Tanggal : 19 Juni 2026"),
                pw.Text("Customer : Budi Santoso"),

                pw.SizedBox(height: 20),

                pw.Text(
                  "Detail Pesanan",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 10),

                pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Beras Premium x2"),
                    pw.Text("Rp130.000"),
                  ],
                ),

                pw.SizedBox(height: 5),

                pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Gula Pasir x1"),
                    pw.Text("Rp18.000"),
                  ],
                ),

                pw.Divider(),

                pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Subtotal"),
                    pw.Text("Rp148.000"),
                  ],
                ),

                pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Ongkir"),
                    pw.Text("Rp10.000"),
                  ],
                ),

                pw.Divider(),

                pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "TOTAL",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "Rp158.000",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                pw.Center(
                  child: pw.Text(
                    "Terima Kasih Telah Berbelanja",
                  ),
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
      appBar: AppBar(
        title: const Text("Invoice Pesanan"),
      ),
      body: PdfPreview(
        build: (format) async =>
            (await _generatePdf()).save(),
      ),
    );
  }
}