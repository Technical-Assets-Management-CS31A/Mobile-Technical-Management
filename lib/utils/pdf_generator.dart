import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/entities/item.dart';

class PdfGenerator {
  static Future<void> generateBarcodePdf(List<Item> items) async {
    final doc = pw.Document();
    
    // Filter items with barcodes
    final itemsWithBarcodes = items.where((item) => item.barcode != null && item.barcode!.isNotEmpty).toList();

    if (itemsWithBarcodes.isEmpty) {
      return;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Item Barcodes', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Wrap(
              spacing: 20,
              runSpacing: 20,
              children: itemsWithBarcodes.map((item) {
                return pw.Container(
                  width: 160,
                  height: 100,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        item.itemName,
                        style: pw.TextStyle(
                          fontSize: 10, 
                          fontWeight: pw.FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 5),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.code128(),
                        data: item.barcode!,
                        width: 140,
                        height: 50,
                        drawText: true,
                        textStyle: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ];
        },
      ),
    );

    // Save using FilePicker instead of Printing plugin to avoid restart requirement
    // and to align with "Download" functionality
    final Uint8List bytes = await doc.save();

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Barcodes PDF',
      fileName: 'item_barcodes.pdf',
      allowedExtensions: ['pdf'],
      type: FileType.custom,
      bytes: bytes,
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsBytes(bytes);
    }
  }
}
