import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/paiement.dart';
import 'pdf_brand.dart';

class PaiementPdfService {
  static Future<void> printReceipt({
    required Paiement paiement,
    String clientName = '',
    String invoiceNumber = '',
    Map<String, dynamic>? resume,
  }) async {
    final document = pw.Document();

    final logoImage = await PdfBrand.loadLogo();

    final montantTtc =
        (resume?['montant_ttc'] as num?)?.toDouble() ?? 0;

    final totalPaye =
        (resume?['total_paye'] as num?)?.toDouble() ??
            paiement.montant;

    final reste =
        (resume?['reste_a_payer'] as num?)?.toDouble() ??
            0;

    final statutFacture =
        resume?['statut']?.toString() ?? '';

    final receiptNumber =
        'REC-${paiement.createdAt.year}-${paiement.id.toString().padLeft(5, '0')}';

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          45,
          40,
          45,
          45,
        ),
        footer: PdfBrand.footer,
        build: (context) {
          return [
            PdfBrand.header(
              title: 'REÇU DE PAIEMENT',
              subtitle: receiptNumber,
              image: logoImage,
            ),

            pw.SizedBox(height: 22),

            // Référence
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfBrand.lightGrey,
                borderRadius: pw.BorderRadius.circular(7),
              ),
              child: pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'N° DU REÇU',
                        style: const pw.TextStyle(
                          color: PdfBrand.grey,
                          fontSize: 7,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        receiptNumber,
                        style: pw.TextStyle(
                          color: PdfBrand.dark,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'DATE',
                        style: const pw.TextStyle(
                          color: PdfBrand.grey,
                          fontSize: 7,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        PdfBrand.date(
                          paiement.datePaiement ??
                              paiement.createdAt,
                        ),
                        style: pw.TextStyle(
                          color: PdfBrand.dark,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            PdfBrand.sectionTitle(
              'Informations du paiement',
            ),

            pw.SizedBox(height: 8),

            PdfBrand.infoRow(
              'Client',
              clientName.isEmpty
                  ? 'Client non renseigné'
                  : clientName,
              boldValue: true,
            ),

            PdfBrand.infoRow(
              'Facture',
              invoiceNumber.isEmpty
                  ? 'Facture #${paiement.factureId}'
                  : invoiceNumber,
              boldValue: true,
            ),

            PdfBrand.infoRow(
              'Mode de paiement',
              paiement.modePaiement,
            ),

            if (paiement.operateur != null)
              PdfBrand.infoRow(
                'Opérateur',
                paiement.operateur!,
              ),

            if (paiement.numeroClient != null)
              PdfBrand.infoRow(
                'N° client',
                paiement.numeroClient!,
              ),

            if (paiement.transactionId != null)
              PdfBrand.infoRow(
                'Transaction',
                paiement.transactionId!,
              ),

            if (paiement.reference != null)
              PdfBrand.infoRow(
                'Référence',
                paiement.reference!,
              ),

            pw.SizedBox(height: 18),

            // Montant principal
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                vertical: 22,
                horizontal: 18,
              ),
              decoration: pw.BoxDecoration(
                color: PdfBrand.teal,
                borderRadius: pw.BorderRadius.circular(9),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'MONTANT ENCAISSÉ',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                    ),
                  ),
                  pw.SizedBox(height: 7),
                  pw.Text(
                    PdfBrand.money(paiement.montant),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            PdfBrand.sectionTitle(
              'Détail financier',
            ),

            pw.SizedBox(height: 8),

            _amountRow(
              'Montant du paiement',
              paiement.montant,
            ),

            _amountRow(
              'Frais',
              paiement.frais,
            ),

            _amountRow(
              'Commission',
              paiement.montantCommission,
            ),

            pw.Divider(color: PdfColors.grey300),

            _amountRow(
              'Montant total',
              paiement.montantTotal,
              bold: true,
            ),

            pw.SizedBox(height: 18),

            PdfBrand.sectionTitle(
              'Situation de la facture',
            ),

            pw.SizedBox(height: 8),

            _amountRow(
              'Montant facture TTC',
              montantTtc,
            ),

            _amountRow(
              'Total payé',
              totalPaye,
            ),

            _amountRow(
              'Reste à payer',
              reste,
              highlight: reste > 0,
            ),

            pw.SizedBox(height: 12),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(11),
              decoration: pw.BoxDecoration(
                color: reste <= 0
                    ? PdfColors.green50
                    : PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(7),
              ),
              child: pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    reste <= 0
                        ? 'PAIEMENT COMPLET'
                        : 'PAIEMENT PARTIEL',
                    style: pw.TextStyle(
                      color: reste <= 0
                          ? PdfColors.green800
                          : PdfColors.orange800,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (statutFacture.isNotEmpty)
                    pw.Text(
                      statutFacture,
                      style: const pw.TextStyle(
                        color: PdfBrand.grey,
                        fontSize: 8,
                      ),
                    ),
                ],
              ),
            ),

            if (paiement.notes != null &&
                paiement.notes!.trim().isNotEmpty) ...[
              pw.SizedBox(height: 18),

              PdfBrand.sectionTitle('Notes'),

              pw.SizedBox(height: 8),

              pw.Text(
                paiement.notes!,
                style: const pw.TextStyle(
                  color: PdfBrand.dark,
                  fontSize: 9,
                ),
              ),
            ],

            pw.SizedBox(height: 25),

            pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment:
                  pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Reçu établi par',
                      style: const pw.TextStyle(
                        color: PdfBrand.grey,
                        fontSize: 8,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'SS CONSULTING',
                      style: pw.TextStyle(
                        color: PdfBrand.teal,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  width: 110,
                  height: 55,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.grey400,
                    ),
                    borderRadius:
                        pw.BorderRadius.circular(5),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Cachet / Signature',
                      style: const pw.TextStyle(
                        color: PdfBrand.grey,
                        fontSize: 7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => document.save(),
      name: '$receiptNumber.pdf',
    );
  }

  static pw.Widget _amountRow(
    String label,
    double value, {
    bool bold = false,
    bool highlight = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 5,
        horizontal: 4,
      ),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: highlight
                  ? PdfColors.orange800
                  : PdfBrand.grey,
              fontSize: 9,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            PdfBrand.money(value),
            style: pw.TextStyle(
              color: highlight
                  ? PdfColors.orange800
                  : PdfBrand.dark,
              fontSize: 9,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
