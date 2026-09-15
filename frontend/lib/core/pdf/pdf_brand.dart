import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfBrand {
  static const PdfColor teal = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor tealLight = PdfColor.fromInt(0xFF14B8A6);
  static const PdfColor dark = PdfColor.fromInt(0xFF17202A);
  static const PdfColor grey = PdfColor.fromInt(0xFF667085);
  static const PdfColor lightGrey = PdfColor.fromInt(0xFFF4F7F8);

  // Informations légales du cabinet, telles qu'elles figurent sur son
  // en-tête officiel (facture, courrier...).
  static const String denominationLegale = 'ETS SS CONSULTING';
  static const String activiteLegale =
      'PRESTATION DE SERVICE- BATIMENTS ET TP - COMMERCE GENERAL- '
      'IMPORT-EXPORT- TRANSIT';
  static const String rcNumber = 'RC/GOU/2023/A/108';
  static const String niu = 'P039617919118S';
  static const String telephoneLegal = '698 57 57 23/659 59 47 47';
  static const String rib = '10005 00008 08409601001 30';
  static const String directeurGeneral = 'SOUAIBOU SADAT';

  static pw.MemoryImage? _logoImage;

  /// Charge (et met en cache) le logo officiel depuis les assets, pour
  /// l'insérer dans les PDF générés côté client (pw.Document).
  static Future<pw.MemoryImage> loadLogo() async {
    if (_logoImage != null) return _logoImage!;

    final data = await rootBundle.load('assets/images/logo.png');
    _logoImage = pw.MemoryImage(data.buffer.asUint8List());

    return _logoImage!;
  }

  static pw.Widget logo({
    double scale = 1,
    bool showTagline = true,
    pw.ImageProvider? image,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        image != null
            ? pw.SizedBox(
                width: 52 * scale,
                height: 52 * scale,
                child: pw.Image(image, fit: pw.BoxFit.contain),
              )
            : pw.Container(
                width: 52 * scale,
                height: 52 * scale,
                decoration: pw.BoxDecoration(
                  color: teal,
                  borderRadius: pw.BorderRadius.circular(12 * scale),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'SS',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18 * scale,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
        pw.SizedBox(width: 12 * scale),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'SS CONSULTING',
              style: pw.TextStyle(
                color: dark,
                fontSize: 19 * scale,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            if (showTagline) ...[
              pw.SizedBox(height: 3 * scale),
              pw.Text(
                'CONSEIL • FISCALITÉ • COMPTABILITÉ',
                style: pw.TextStyle(
                  color: grey,
                  fontSize: 7.5 * scale,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget header({
    required String title,
    String? subtitle,
    pw.ImageProvider? image,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            logo(image: image),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    color: teal,
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(
                      color: grey,
                      fontSize: 8,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Divider(
          color: tealLight,
          thickness: 1.2,
        ),
      ],
    );
  }

  static pw.Widget footer(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'SS CONSULTING',
              style: pw.TextStyle(
                color: teal,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Document généré automatiquement',
              style: const pw.TextStyle(
                color: grey,
                fontSize: 7,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(
                color: grey,
                fontSize: 7,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget sectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: pw.BoxDecoration(
        color: lightGrey,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          color: teal,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  static pw.Widget infoRow(
    String label,
    String value, {
    bool boldValue = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 125,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                color: grey,
                fontSize: 9,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '—' : value,
              style: pw.TextStyle(
                color: dark,
                fontSize: 9,
                fontWeight:
                    boldValue ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String money(double value) {
    final formatted = value
        .round()
        .toString()
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ' ',
        );

    return '$formatted FCFA';
  }

  static String date(DateTime? value) {
    if (value == null) return '—';

    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');

    return '$d/$m/${value.year}';
  }
}
