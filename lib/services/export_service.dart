import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/app_models.dart';

class ExportService {
  Future<void> exportNotebookToPdf(List<NotebookCard> cards) async {
    final pdf = pw.Document();

    // Hind renders Devanagari a bit cleaner in this notebook layout.
    final bodyFont = await PdfGoogleFonts.hindRegular();
    final boldFont = await PdfGoogleFonts.hindBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: bodyFont,
          bold: boldFont,
        ),
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(14),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Sudarshan Notebook',
                    style: pw.TextStyle(
                      fontSize: 24,
                      font: boldFont,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Smart revision cards for quick recap',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            ...cards.map((card) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        card.subject,
                        style: pw.TextStyle(
                          color: PdfColors.blue800,
                          font: boldFont,
                          fontSize: 12,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            card.chapter,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 10),
                  pw.Text('Question', style: pw.TextStyle(font: boldFont, fontSize: 11)),
                  pw.SizedBox(height: 4),
                  pw.Text(card.question, style: const pw.TextStyle(fontSize: 12, height: 1.35)),
                  pw.SizedBox(height: 12),
                  pw.Text('Answer', style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.green800)),
                  pw.SizedBox(height: 4),
                  pw.Text(card.answer, style: const pw.TextStyle(fontSize: 12, height: 1.35)),
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
