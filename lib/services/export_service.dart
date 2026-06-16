import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/app_models.dart';

class ExportService {
  Future<void> exportNotebookToPdf(List<NotebookCard> cards) async {
    final pdf = pw.Document();

    // Use "Noto Sans Devanagari" for robust Hindi rendering (sanyutakshar) in PDF
    final hindiFont = await PdfGoogleFonts.notoSansDevanagariRegular();
    final hindiFontBold = await PdfGoogleFonts.notoSansDevanagariBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: hindiFont,
          bold: hindiFontBold,
        ),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Sudarshan Notebook - Smart Revision Cards',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            ...cards.map((card) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(card.subject, style: pw.TextStyle(color: PdfColors.blue, fontWeight: pw.FontWeight.bold)),
                      pw.Text(card.chapter, style: const pw.TextStyle(color: PdfColors.grey)),
                    ],
                  ),
                  pw.Divider(),
                  pw.Text('Question:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(card.question),
                  pw.SizedBox(height: 10),
                  pw.Text('Answer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                  pw.Text(card.answer),
                ],
              ),
            )),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Sudarshan_Notebook.pdf',
    );
  }
}
