import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/client.dart';
import 'pdf_brand.dart';

class ClientPdfService {
  static Future<void> printClientSheet({
    required Client client,
    Map<String, dynamic>? situation,
  }) async {
    final document = await _buildDocument(
      client: client,
      situation: situation,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => document.save(),
      name: 'Fiche_Client_${client.id}_${client.nomComplet}.pdf',
    );
  }

  static Future<pw.Document> _buildDocument({
    required Client client,
    Map<String, dynamic>? situation,
  }) async {
    final document = pw.Document();

    final logoImage = await PdfBrand.loadLogo();

    final statistiques =
        situation?['statistiques'] as Map<String, dynamic>? ?? {};

    final factures =
        situation?['factures'] as Map<String, dynamic>? ?? {};

    final nombreDossiers =
        (statistiques['nombre_dossiers'] as num?)?.toInt() ?? 0;

    final nombreFactures =
        (statistiques['nombre_factures'] as num?)?.toInt() ?? 0;

    final nombrePaiements =
        (statistiques['nombre_paiements'] as num?)?.toInt() ?? 0;

    final totalTtc =
        (factures['total_ttc'] as num?)?.toDouble() ?? 0;

    final totalPaye =
        (factures['total_paye'] as num?)?.toDouble() ?? 0;

    final creance =
        (factures['creance'] as num?)?.toDouble() ?? 0;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          38,
          35,
          38,
          40,
        ),
        footer: PdfBrand.footer,
        build: (context) {
          return [
            PdfBrand.header(
              title: 'FICHE CLIENT',
              subtitle:
                  'Établie le ${PdfBrand.date(DateTime.now())}',
              image: logoImage,
            ),

            pw.SizedBox(height: 20),

            // Identité
            PdfBrand.sectionTitle('Identité du client'),

            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.grey300,
                ),
                borderRadius: pw.BorderRadius.circular(7),
              ),
              child: pw.Row(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 54,
                    height: 54,
                    decoration: pw.BoxDecoration(
                      color: PdfBrand.teal,
                      borderRadius:
                          pw.BorderRadius.circular(27),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        client.initiales,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 17,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          client.nomComplet,
                          style: pw.TextStyle(
                            color: PdfBrand.dark,
                            fontSize: 15,
                            fontWeight:
                                pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          client.typeClient,
                          style: const pw.TextStyle(
                            color: PdfBrand.grey,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding:
                        const pw.EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      color: client.actif
                          ? PdfColors.green50
                          : PdfColors.red50,
                      borderRadius:
                          pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      client.actif ? 'ACTIF' : 'INACTIF',
                      style: pw.TextStyle(
                        color: client.actif
                            ? PdfColors.green800
                            : PdfColors.red800,
                        fontSize: 7,
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            // Contact
            PdfBrand.sectionTitle(
              'Coordonnées et contact',
            ),

            pw.SizedBox(height: 7),

            PdfBrand.infoRow(
              'Nom / raison sociale',
              client.nomComplet,
              boldValue: true,
            ),
            PdfBrand.infoRow(
              'Téléphone',
              client.telephone,
            ),
            PdfBrand.infoRow(
              'Email',
              client.email ?? '',
            ),
            PdfBrand.infoRow(
              'Adresse',
              client.adresse ?? '',
            ),
            PdfBrand.infoRow(
              'Ville',
              client.ville ?? '',
            ),

            pw.SizedBox(height: 14),

            // Administratif
            PdfBrand.sectionTitle(
              'Informations administratives',
            ),

            pw.SizedBox(height: 7),

            PdfBrand.infoRow(
              'N° contribuable',
              client.numeroContribuable ?? '',
            ),
            PdfBrand.infoRow(
              'RCCM',
              client.registreCommerce ?? '',
            ),
            PdfBrand.infoRow(
              'Type de client',
              client.typeClient,
            ),

            pw.SizedBox(height: 14),

            // Statistiques
            PdfBrand.sectionTitle(
              'Activité du client',
            ),

            pw.SizedBox(height: 9),

            pw.Row(
              children: [
                _statBox(
                  'Dossiers',
                  '$nombreDossiers',
                ),
                pw.SizedBox(width: 8),
                _statBox(
                  'Factures',
                  '$nombreFactures',
                ),
                pw.SizedBox(width: 8),
                _statBox(
                  'Paiements',
                  '$nombrePaiements',
                ),
              ],
            ),

            pw.SizedBox(height: 14),

            // Finances
            PdfBrand.sectionTitle(
              'Situation financière',
            ),

            pw.SizedBox(height: 8),

            _financialBox(
              'Total facturé',
              totalTtc,
            ),
            pw.SizedBox(height: 6),
            _financialBox(
              'Total payé',
              totalPaye,
            ),
            pw.SizedBox(height: 6),
            _financialBox(
              'Créance restante',
              creance,
              highlight: creance > 0,
            ),

            if (client.notes != null &&
                client.notes!.trim().isNotEmpty) ...[
              pw.SizedBox(height: 14),

              PdfBrand.sectionTitle('Notes'),

              pw.SizedBox(height: 8),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                      pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  client.notes!,
                  style: const pw.TextStyle(
                    color: PdfBrand.dark,
                    fontSize: 9,
                  ),
                ),
              ),
            ],

            pw.SizedBox(height: 20),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Document officiel • SS CONSULTING',
                style: const pw.TextStyle(
                  color: PdfBrand.grey,
                  fontSize: 7,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return document;
  }

  static pw.Widget _statBox(
    String label,
    String value,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 8,
        ),
        decoration: pw.BoxDecoration(
          color: PdfBrand.lightGrey,
          borderRadius: pw.BorderRadius.circular(7),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                color: PdfBrand.teal,
                fontSize: 17,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              label,
              style: const pw.TextStyle(
                color: PdfBrand.grey,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _financialBox(
    String label,
    double value, {
    bool highlight = false,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: pw.BoxDecoration(
        color: highlight
            ? PdfColors.orange50
            : PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              color: PdfBrand.grey,
              fontSize: 9,
            ),
          ),
          pw.Text(
            PdfBrand.money(value),
            style: pw.TextStyle(
              color: highlight
                  ? PdfColors.orange800
                  : PdfBrand.dark,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
