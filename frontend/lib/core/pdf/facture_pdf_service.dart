import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/client.dart';
import '../../models/facture.dart';
import 'nombre_en_lettres.dart';
import 'pdf_brand.dart';

class FacturePdfService {
  static Future<void> printFacture({
    required Facture facture,
    required Client client,
    Map<String, dynamic>? resume,
  }) async {
    final document = await _buildDocument(
      facture: facture,
      client: client,
      resume: resume,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => document.save(),
      name: '${facture.numero.replaceAll('/', '-')}.pdf',
    );
  }

  static Future<pw.Document> _buildDocument({
    required Facture facture,
    required Client client,
    Map<String, dynamic>? resume,
  }) async {
    final document = pw.Document();

    final montantHt = facture.montantHt;
    final montantTva = facture.montantTva ?? (montantHt * facture.tauxTva / 100);
    final montantTtc = facture.montantTtc ?? (montantHt + montantTva);

    final totalPaye = (resume?['total_paye'] as num?)?.toDouble() ?? 0;
    final resteAPayer =
        (resume?['reste_a_payer'] as num?)?.toDouble() ?? montantTtc;

    final designation = (facture.notes == null || facture.notes!.trim().isEmpty)
        ? 'Prestations SS Consulting'
        : facture.notes!.trim();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
        build: (context) {
          return [
            _entete(),
            pw.SizedBox(height: 22),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Garoua, ${PdfBrand.date(facture.dateEmission)}',
                style: const pw.TextStyle(
                  color: PdfBrand.dark,
                  fontSize: 10,
                ),
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Center(
              child: pw.Text(
                'FACTURE N° ${facture.numero}',
                style: pw.TextStyle(
                  color: PdfBrand.dark,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
            pw.SizedBox(height: 22),
            pw.Text(
              'DOIT : ${client.nomComplet}',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Objet : $designation',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            _tableauLignes(designation: designation, montantHt: montantHt),
            pw.SizedBox(height: 4),
            _totaux(
              montantHt: montantHt,
              tauxTva: facture.tauxTva,
              montantTva: montantTva,
              montantTtc: montantTtc,
            ),
            if (totalPaye > 0 && resteAPayer > 0) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'NB : AVANCE = ${PdfBrand.money(totalPaye)}',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'RESTE = ${PdfBrand.money(resteAPayer)}',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ],
            pw.SizedBox(height: 20),
            pw.Text(
              'Arrêté cette facture à un montant Total TTC de '
              '${_montantEnLettres(montantTtc)} Francs CFA.',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 40),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'LE DIRECTEUR GENERAL,',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    PdfBrand.directeurGeneral,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.grey400),
            pw.Center(
              child: pw.Text(
                'RIB ${PdfBrand.rib}',
                style: const pw.TextStyle(fontSize: 9, color: PdfBrand.grey),
              ),
            ),
          ];
        },
      ),
    );

    return document;
  }

  static String _montantEnLettres(double montant) {
    final entier = montant.round();
    final mots = nombreEnLettres(entier);

    return mots[0].toUpperCase() + mots.substring(1);
  }

  static pw.Widget _entete() {
    return pw.Column(
      children: [
        pw.Text(
          PdfBrand.denominationLegale,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfBrand.teal,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          PdfBrand.activiteLegale,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 8, color: PdfBrand.grey),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'N°${PdfBrand.rcNumber}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'CONT N° ${PdfBrand.niu}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Tél : ${PdfBrand.telephoneLegal}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfBrand.tealLight, thickness: 1.2),
      ],
    );
  }

  static pw.Widget _tableauLignes({
    required String designation,
    required double montantHt,
  }) {
    final headers = ['N°', 'Réf', 'Désignation', 'P.U. EN FCFA', 'Qté', 'P.T.'];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.6),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(3.4),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1.6),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfBrand.teal),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: pw.Text(
                    h,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        pw.TableRow(
          children: [
            _cell('1', center: true),
            _cell('REF', center: true),
            _cell(designation),
            _cell(PdfBrand.money(montantHt), center: true),
            _cell('1', center: true),
            _cell(PdfBrand.money(montantHt), center: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  static pw.Widget _totaux({
    required double montantHt,
    required double tauxTva,
    required double montantTva,
    required double montantTtc,
  }) {
    pw.Widget ligne(String label, double montant, {bool total = false}) {
      return pw.Container(
        width: 260,
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: total ? PdfBrand.teal : PdfBrand.lightGrey,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        margin: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: total ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: total ? PdfColors.white : PdfBrand.dark,
              ),
            ),
            pw.Text(
              PdfBrand.money(montant),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: total ? PdfColors.white : PdfBrand.dark,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          ligne('Montant Total HT', montantHt),
          ligne('TVA (${tauxTva.toStringAsFixed(2)}%)', montantTva),
          ligne('Montant Total TTC', montantTtc, total: true),
        ],
      ),
    );
  }
}
