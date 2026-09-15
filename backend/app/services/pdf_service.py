from io import BytesIO

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)

from app.models.facture import Facture


def format_fcfa(montant):
    return f"{montant:,.0f} FCFA".replace(",", " ")


def generer_facture_pdf(db, facture_id: int):

    facture = (
        db.query(Facture)
        .filter(
            Facture.id == facture_id,
            Facture.actif.is_(True),
        )
        .first()
    )

    if facture is None:
        raise ValueError("Facture introuvable")

    buffer = BytesIO()

    document = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=18 * mm,
        bottomMargin=18 * mm,
        title=f"Facture {facture.numero}",
    )

    styles = getSampleStyleSheet()

    styles.add(
        ParagraphStyle(
            name="Company",
            parent=styles["Heading1"],
            fontSize=18,
            leading=22,
            alignment=TA_CENTER,
            spaceAfter=4 * mm,
        )
    )

    styles.add(
        ParagraphStyle(
            name="InvoiceTitle",
            parent=styles["Heading1"],
            fontSize=16,
            leading=20,
            alignment=TA_RIGHT,
        )
    )

    styles.add(
        ParagraphStyle(
            name="Small",
            parent=styles["Normal"],
            fontSize=9,
            leading=12,
        )
    )

    elements = []

    # ========================================================
    # EN-TÊTE
    # ========================================================

    elements.append(
        Paragraph(
            "SS CONSULTING",
            styles["Company"],
        )
    )

    elements.append(
        Paragraph(
            "Cabinet de conseil & services",
            styles["Normal"],
        )
    )

    elements.append(Spacer(1, 8 * mm))

    header_data = [
        [
            Paragraph(
                "<b>FACTURE</b>",
                styles["InvoiceTitle"],
            ),
            Paragraph(
                f"<b>N° :</b> {facture.numero}<br/>"
                f"<b>Date :</b> "
                f"{facture.date_emission.strftime('%d/%m/%Y')}",
                styles["Small"],
            ),
        ]
    ]

    header_table = Table(
        header_data,
        colWidths=[90 * mm, 70 * mm],
    )

    header_table.setStyle(
        TableStyle(
            [
                (
                    "VALIGN",
                    (0, 0),
                    (-1, -1),
                    "TOP",
                ),
                (
                    "ALIGN",
                    (0, 0),
                    (0, 0),
                    "LEFT",
                ),
                (
                    "ALIGN",
                    (1, 0),
                    (1, 0),
                    "RIGHT",
                ),
            ]
        )
    )

    elements.append(header_table)
    elements.append(Spacer(1, 8 * mm))

    # ========================================================
    # CLIENT
    # ========================================================

    client = facture.client

    nom_client = (
        client.raison_sociale
        or f"{client.nom} {client.prenom or ''}".strip()
    )

    client_data = [
        [
            Paragraph(
                "<b>CLIENT</b>",
                styles["Normal"],
            ),
            Paragraph(
                "<b>INFORMATIONS FACTURE</b>",
                styles["Normal"],
            ),
        ],
        [
            Paragraph(
                f"{nom_client}<br/>"
                f"Téléphone : {client.telephone}<br/>"
                f"Email : {client.email or '-'}<br/>"
                f"Adresse : {client.adresse or '-'}",
                styles["Small"],
            ),
            Paragraph(
                f"Échéance : "
                f"{facture.date_echeance.strftime('%d/%m/%Y') if facture.date_echeance else '-'}"
                f"<br/>"
                f"Mode de paiement : "
                f"{facture.mode_paiement or '-'}"
                f"<br/>"
                f"Statut : {facture.statut}",
                styles["Small"],
            ),
        ],
    ]

    client_table = Table(
        client_data,
        colWidths=[90 * mm, 70 * mm],
    )

    client_table.setStyle(
        TableStyle(
            [
                (
                    "BACKGROUND",
                    (0, 0),
                    (-1, 0),
                    colors.HexColor("#eeeeee"),
                ),
                (
                    "BOX",
                    (0, 0),
                    (-1, -1),
                    0.5,
                    colors.grey,
                ),
                (
                    "INNERGRID",
                    (0, 0),
                    (-1, -1),
                    0.25,
                    colors.lightgrey,
                ),
                (
                    "VALIGN",
                    (0, 0),
                    (-1, -1),
                    "TOP",
                ),
                (
                    "LEFTPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
                (
                    "RIGHTPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
                (
                    "TOPPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
                (
                    "BOTTOMPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
            ]
        )
    )

    elements.append(client_table)
    elements.append(Spacer(1, 10 * mm))

    # ========================================================
    # MONTANTS
    # ========================================================

    montant_ht = facture.montant_ht or 0
    montant_tva = facture.montant_tva or 0
    montant_ttc = facture.montant_ttc or 0

    data = [
        [
            Paragraph("<b>DÉSIGNATION</b>", styles["Normal"]),
            Paragraph("<b>MONTANT</b>", styles["Normal"]),
        ],
        [
            Paragraph(
                "Prestations de conseil et services",
                styles["Small"],
            ),
            Paragraph(
                format_fcfa(montant_ht),
                styles["Small"],
            ),
        ],
    ]

    table = Table(
        data,
        colWidths=[120 * mm, 40 * mm],
    )

    table.setStyle(
        TableStyle(
            [
                (
                    "BACKGROUND",
                    (0, 0),
                    (-1, 0),
                    colors.HexColor("#eeeeee"),
                ),
                (
                    "BOX",
                    (0, 0),
                    (-1, -1),
                    0.5,
                    colors.grey,
                ),
                (
                    "INNERGRID",
                    (0, 0),
                    (-1, -1),
                    0.25,
                    colors.lightgrey,
                ),
                (
                    "ALIGN",
                    (1, 1),
                    (1, -1),
                    "RIGHT",
                ),
                (
                    "VALIGN",
                    (0, 0),
                    (-1, -1),
                    "MIDDLE",
                ),
                (
                    "LEFTPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
                (
                    "RIGHTPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
                (
                    "TOPPADDING",
                    (0, 0),
                    (-1, -1),
                    7,
                ),
                (
                    "BOTTOMPADDING",
                    (0, 0),
                    (-1, -1),
                    7,
                ),
            ]
        )
    )

    elements.append(table)
    elements.append(Spacer(1, 6 * mm))

    # ========================================================
    # TOTAUX
    # ========================================================

    totals = [
        ["Total HT", format_fcfa(montant_ht)],
        [
            f"TVA ({facture.taux_tva or 0} %)",
            format_fcfa(montant_tva),
        ],
        [
            "TOTAL TTC",
            format_fcfa(montant_ttc),
        ],
    ]

    totals_table = Table(
        totals,
        colWidths=[120 * mm, 40 * mm],
    )

    totals_table.setStyle(
        TableStyle(
            [
                (
                    "ALIGN",
                    (1, 0),
                    (1, -1),
                    "RIGHT",
                ),
                (
                    "LINEABOVE",
                    (0, -1),
                    (-1, -1),
                    1,
                    colors.black,
                ),
                (
                    "FONTNAME",
                    (0, -1),
                    (-1, -1),
                    "Helvetica-Bold",
                ),
                (
                    "FONTSIZE",
                    (0, 0),
                    (-1, -1),
                    10,
                ),
                (
                    "TOPPADDING",
                    (0, 0),
                    (-1, -1),
                    5,
                ),
                (
                    "BOTTOMPADDING",
                    (0, 0),
                    (-1, -1),
                    5,
                ),
            ]
        )
    )

    elements.append(totals_table)
    elements.append(Spacer(1, 12 * mm))

    # ========================================================
    # NOTES
    # ========================================================

    if facture.notes:
        elements.append(
            Paragraph(
                f"<b>Notes :</b> {facture.notes}",
                styles["Small"],
            )
        )

        elements.append(Spacer(1, 8 * mm))

    elements.append(
        Paragraph(
            "Merci pour votre confiance.",
            ParagraphStyle(
                "Footer",
                parent=styles["Normal"],
                alignment=TA_CENTER,
                fontSize=9,
            ),
        )
    )

    document.build(elements)

    buffer.seek(0)

    return buffer


def generer_recu_paiement_pdf(db, paiement_id: int):

    from app.models.paiement import Paiement

    paiement = (
        db.query(Paiement)
        .filter(
            Paiement.id == paiement_id,
            Paiement.actif.is_(True),
        )
        .first()
    )

    if paiement is None:
        raise ValueError("Paiement introuvable")

    facture = paiement.facture

    if facture is None:
        raise ValueError("Facture associée introuvable")

    buffer = BytesIO()

    document = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=18 * mm,
        bottomMargin=18 * mm,
        title=f"Reçu paiement {paiement.id}",
    )

    styles = getSampleStyleSheet()

    styles.add(
        ParagraphStyle(
            name="ReceiptCompany",
            parent=styles["Heading1"],
            fontSize=18,
            leading=22,
            alignment=TA_CENTER,
        )
    )

    styles.add(
        ParagraphStyle(
            name="ReceiptTitle",
            parent=styles["Heading1"],
            fontSize=16,
            leading=20,
            alignment=TA_CENTER,
            spaceAfter=8 * mm,
        )
    )

    styles.add(
        ParagraphStyle(
            name="ReceiptSmall",
            parent=styles["Normal"],
            fontSize=9,
            leading=12,
        )
    )

    elements = []

    # ========================================================
    # ENTREPRISE
    # ========================================================

    elements.append(
        Paragraph(
            "SS CONSULTING",
            styles["ReceiptCompany"],
        )
    )

    elements.append(
        Paragraph(
            "Cabinet de conseil & services",
            styles["Normal"],
        )
    )

    elements.append(Spacer(1, 8 * mm))

    elements.append(
        Paragraph(
            "REÇU DE PAIEMENT",
            styles["ReceiptTitle"],
        )
    )

    # ========================================================
    # INFORMATIONS
    # ========================================================

    client = facture.client

    nom_client = (
        client.raison_sociale
        or f"{client.nom} {client.prenom or ''}".strip()
    )

    date_paiement = paiement.date_paiement

    informations = [
        [
            Paragraph("<b>Référence du reçu</b>", styles["ReceiptSmall"]),
            Paragraph(
                str(
                    paiement.reference
                    or paiement.transaction_id
                    or f"PAY-{paiement.id:06d}"
                ),
                styles["ReceiptSmall"],
            ),
        ],
        [
            Paragraph("<b>Facture</b>", styles["ReceiptSmall"]),
            Paragraph(
                facture.numero,
                styles["ReceiptSmall"],
            ),
        ],
        [
            Paragraph("<b>Date du paiement</b>", styles["ReceiptSmall"]),
            Paragraph(
                date_paiement.strftime("%d/%m/%Y %H:%M"),
                styles["ReceiptSmall"],
            ),
        ],
        [
            Paragraph("<b>Client</b>", styles["ReceiptSmall"]),
            Paragraph(
                nom_client,
                styles["ReceiptSmall"],
            ),
        ],
    ]

    informations_table = Table(
        informations,
        colWidths=[55 * mm, 105 * mm],
    )

    informations_table.setStyle(
        TableStyle(
            [
                (
                    "BOX",
                    (0, 0),
                    (-1, -1),
                    0.5,
                    colors.grey,
                ),
                (
                    "INNERGRID",
                    (0, 0),
                    (-1, -1),
                    0.25,
                    colors.lightgrey,
                ),
                (
                    "VALIGN",
                    (0, 0),
                    (-1, -1),
                    "TOP",
                ),
                (
                    "BACKGROUND",
                    (0, 0),
                    (0, -1),
                    colors.HexColor("#eeeeee"),
                ),
                (
                    "LEFTPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
                (
                    "RIGHTPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
                (
                    "TOPPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
                (
                    "BOTTOMPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
            ]
        )
    )

    elements.append(informations_table)
    elements.append(Spacer(1, 10 * mm))

    # ========================================================
    # MONTANT
    # ========================================================

    montant = paiement.montant or 0
    commission = paiement.montant_commission or 0
    total = paiement.montant_total or montant

    montant_data = [
        [
            Paragraph(
                "<b>MONTANT DU PAIEMENT</b>",
                styles["ReceiptSmall"],
            ),
            Paragraph(
                f"<b>{format_fcfa(montant)}</b>",
                styles["ReceiptSmall"],
            ),
        ],
        [
            Paragraph(
                "Commission",
                styles["ReceiptSmall"],
            ),
            Paragraph(
                format_fcfa(commission),
                styles["ReceiptSmall"],
            ),
        ],
        [
            Paragraph(
                "<b>TOTAL</b>",
                styles["ReceiptSmall"],
            ),
            Paragraph(
                f"<b>{format_fcfa(total)}</b>",
                styles["ReceiptSmall"],
            ),
        ],
    ]

    montant_table = Table(
        montant_data,
        colWidths=[120 * mm, 40 * mm],
    )

    montant_table.setStyle(
        TableStyle(
            [
                (
                    "BOX",
                    (0, 0),
                    (-1, -1),
                    0.5,
                    colors.grey,
                ),
                (
                    "INNERGRID",
                    (0, 0),
                    (-1, -1),
                    0.25,
                    colors.lightgrey,
                ),
                (
                    "ALIGN",
                    (1, 0),
                    (1, -1),
                    "RIGHT",
                ),
                (
                    "BACKGROUND",
                    (0, -1),
                    (-1, -1),
                    colors.HexColor("#eeeeee"),
                ),
                (
                    "TOPPADDING",
                    (0, 0),
                    (-1, -1),
                    7,
                ),
                (
                    "BOTTOMPADDING",
                    (0, 0),
                    (-1, -1),
                    7,
                ),
            ]
        )
    )

    elements.append(montant_table)
    elements.append(Spacer(1, 10 * mm))

    # ========================================================
    # PAIEMENT
    # ========================================================

    paiement_data = [
        [
            Paragraph("<b>Mode de paiement</b>", styles["ReceiptSmall"]),
            Paragraph(
                paiement.mode_paiement or "-",
                styles["ReceiptSmall"],
            ),
        ],
        [
            Paragraph("<b>Opérateur</b>", styles["ReceiptSmall"]),
            Paragraph(
                paiement.operateur or "-",
                styles["ReceiptSmall"],
            ),
        ],
        [
            Paragraph("<b>N° client</b>", styles["ReceiptSmall"]),
            Paragraph(
                paiement.numero_client or "-",
                styles["ReceiptSmall"],
            ),
        ],
        [
            Paragraph("<b>Transaction</b>", styles["ReceiptSmall"]),
            Paragraph(
                paiement.transaction_id or "-",
                styles["ReceiptSmall"],
            ),
        ],
        [
            Paragraph("<b>Statut</b>", styles["ReceiptSmall"]),
            Paragraph(
                paiement.statut,
                styles["ReceiptSmall"],
            ),
        ],
    ]

    paiement_table = Table(
        paiement_data,
        colWidths=[55 * mm, 105 * mm],
    )

    paiement_table.setStyle(
        TableStyle(
            [
                (
                    "BOX",
                    (0, 0),
                    (-1, -1),
                    0.5,
                    colors.grey,
                ),
                (
                    "INNERGRID",
                    (0, 0),
                    (-1, -1),
                    0.25,
                    colors.lightgrey,
                ),
                (
                    "BACKGROUND",
                    (0, 0),
                    (0, -1),
                    colors.HexColor("#eeeeee"),
                ),
                (
                    "LEFTPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
                (
                    "RIGHTPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
                (
                    "TOPPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
                (
                    "BOTTOMPADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
            ]
        )
    )

    elements.append(paiement_table)
    elements.append(Spacer(1, 12 * mm))

    # ========================================================
    # NOTES
    # ========================================================

    if paiement.notes:
        elements.append(
            Paragraph(
                f"<b>Notes :</b> {paiement.notes}",
                styles["ReceiptSmall"],
            )
        )

        elements.append(Spacer(1, 8 * mm))

    elements.append(
        Paragraph(
            "Paiement enregistré par SS Consulting.",
            ParagraphStyle(
                "ReceiptFooter",
                parent=styles["Normal"],
                alignment=TA_CENTER,
                fontSize=9,
            ),
        )
    )

    document.build(elements)

    buffer.seek(0)

    return buffer


# ============================================================
# PDF DEPENSE
# ============================================================

def generer_depense_pdf(db, depense_id: int):

    from app.models.depense import Depense

    depense = (
        db.query(Depense)
        .filter(
            Depense.id == depense_id,
            Depense.actif.is_(True),
        )
        .first()
    )

    if depense is None:
        raise ValueError("Dépense introuvable")

    buffer = BytesIO()

    document = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=18 * mm,
        bottomMargin=18 * mm,
        title=f"Dépense {depense.id}",
    )

    styles = getSampleStyleSheet()

    elements = []

    elements.append(
        Paragraph("SS CONSULTING", styles["Title"])
    )

    elements.append(
        Paragraph("JUSTIFICATIF DE DÉPENSE", styles["Heading1"])
    )

    elements.append(Spacer(1, 10 * mm))

    date_depense = depense.date_depense.strftime("%d/%m/%Y %H:%M")

    data = [
        ["Référence", depense.reference or f"DEP-{depense.id:06d}"],
        ["Date", date_depense],
        ["Fournisseur", depense.fournisseur or "-"],
        ["Catégorie", depense.categorie],
        ["Description", depense.description],
        ["Mode de paiement", depense.mode_paiement or "-"],
        ["Statut", depense.statut],
        ["Montant HT", format_fcfa(depense.montant_ht)],
        ["TVA", format_fcfa(depense.montant_tva)],
        ["Montant TTC", format_fcfa(depense.montant_ttc)],
    ]

    table = Table(
        data,
        colWidths=[55 * mm, 105 * mm],
    )

    table.setStyle(
        TableStyle(
            [
                ("BOX", (0, 0), (-1, -1), 0.5, colors.grey),
                ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.lightgrey),
                ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#eeeeee")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )

    elements.append(table)

    if depense.notes:
        elements.append(Spacer(1, 8 * mm))
        elements.append(
            Paragraph(
                f"<b>Notes :</b> {depense.notes}",
                styles["Normal"],
            )
        )

    elements.append(Spacer(1, 15 * mm))

    elements.append(
        Paragraph(
            "Document généré automatiquement par SS Consulting.",
            styles["Normal"],
        )
    )

    document.build(elements)

    buffer.seek(0)

    return buffer


# ============================================================
# PDF CLIENT
# ============================================================

def generer_client_pdf(db, client_id: int):

    from app.models.client import Client

    client = (
        db.query(Client)
        .filter(
            Client.id == client_id,
            Client.actif.is_(True),
        )
        .first()
    )

    if client is None:
        raise ValueError("Client introuvable")

    buffer = BytesIO()

    document = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=18 * mm,
        bottomMargin=18 * mm,
        title=f"Fiche client {client.id}",
    )

    styles = getSampleStyleSheet()

    elements = []

    elements.append(
        Paragraph("SS CONSULTING", styles["Title"])
    )

    elements.append(
        Paragraph("FICHE CLIENT", styles["Heading1"])
    )

    elements.append(Spacer(1, 10 * mm))

    nom = (
        client.raison_sociale
        or f"{client.nom} {client.prenom or ''}".strip()
    )

    data = [
        ["Identifiant", str(client.id)],
        ["Nom / Société", nom],
        ["Email", client.email or "-"],
        ["Téléphone", client.telephone or "-"],
        ["Adresse", client.adresse or "-"],
        ["Ville", client.ville or "-"],
        ["Type de client", client.type_client],
        [
            "N° contribuable",
            client.numero_contribuable or "-",
        ],
        [
            "Registre commerce",
            client.registre_commerce or "-",
        ],
    ]

    table = Table(
        data,
        colWidths=[55 * mm, 105 * mm],
    )

    table.setStyle(
        TableStyle(
            [
                ("BOX", (0, 0), (-1, -1), 0.5, colors.grey),
                ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.lightgrey),
                ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#eeeeee")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )

    elements.append(table)

    if client.notes:
        elements.append(Spacer(1, 8 * mm))
        elements.append(
            Paragraph(
                f"<b>Notes :</b> {client.notes}",
                styles["Normal"],
            )
        )

    document.build(elements)

    buffer.seek(0)

    return buffer


# ============================================================
# PDF DOSSIER
# ============================================================

def generer_dossier_pdf(db, dossier_id: int):

    from app.models.dossier import Dossier

    dossier = (
        db.query(Dossier)
        .filter(
            Dossier.id == dossier_id,
        )
        .first()
    )

    if dossier is None:
        raise ValueError("Dossier introuvable")

    buffer = BytesIO()

    document = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=18 * mm,
        bottomMargin=18 * mm,
        title=f"Dossier {dossier.id}",
    )

    styles = getSampleStyleSheet()

    elements = []

    elements.append(
        Paragraph("SS CONSULTING", styles["Title"])
    )

    elements.append(
        Paragraph("FICHE DOSSIER", styles["Heading1"])
    )

    elements.append(Spacer(1, 10 * mm))

    data = [
        ["Identifiant", str(dossier.id)],
        ["Référence", getattr(dossier, "reference", None) or "-"],
        ["Nom", getattr(dossier, "nom", None) or "-"],
        ["Description", getattr(dossier, "description", None) or "-"],
        ["Statut", getattr(dossier, "statut", None) or "-"],
    ]

    table = Table(
        data,
        colWidths=[55 * mm, 105 * mm],
    )

    table.setStyle(
        TableStyle(
            [
                ("BOX", (0, 0), (-1, -1), 0.5, colors.grey),
                ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.lightgrey),
                ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#eeeeee")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )

    elements.append(table)

    document.build(elements)

    buffer.seek(0)

    return buffer


# ============================================================
# PDF RAPPORT COMPTABLE
# ============================================================

def generer_comptabilite_pdf(
    db,
    annee: int,
):

    from app.services.comptabilite_service import dashboard_financier

    dashboard = dashboard_financier(
        db,
        annee=annee,
    )

    buffer = BytesIO()

    document = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=15 * mm,
        leftMargin=15 * mm,
        topMargin=15 * mm,
        bottomMargin=15 * mm,
        title=f"Rapport comptable {annee}",
    )

    styles = getSampleStyleSheet()

    elements = []

    elements.append(
        Paragraph(
            "SS CONSULTING",
            styles["Title"],
        )
    )

    elements.append(
        Paragraph(
            f"RAPPORT COMPTABLE - {annee}",
            styles["Heading1"],
        )
    )

    elements.append(Spacer(1, 8 * mm))

    factures = dashboard["factures"]
    paiements = dashboard["paiements"]
    depenses = dashboard["depenses"]
    resultats = dashboard["resultats"]

    data = [
        ["INDICATEUR", "MONTANT"],
        [
            "Chiffre d'affaires HT",
            format_fcfa(factures["chiffre_affaires_ht"]),
        ],
        [
            "TVA collectée",
            format_fcfa(factures["tva_collectee"]),
        ],
        [
            "Factures TTC",
            format_fcfa(factures["total_ttc"]),
        ],
        [
            "Total encaissé",
            format_fcfa(paiements["total_encaisse"]),
        ],
        [
            "Dépenses HT",
            format_fcfa(depenses["total_ht"]),
        ],
        [
            "Dépenses TTC",
            format_fcfa(depenses["total_ttc"]),
        ],
        [
            "TVA déductible",
            format_fcfa(depenses["total_tva"]),
        ],
        [
            "Bénéfice",
            format_fcfa(resultats["benefice"]),
        ],
        [
            "Créances clients",
            format_fcfa(resultats["creances_clients"]),
        ],
        [
            "TVA à payer",
            format_fcfa(resultats["tva_a_payer"]),
        ],
        [
            "Solde de trésorerie",
            format_fcfa(resultats["solde_tresorerie"]),
        ],
    ]

    table = Table(
        data,
        colWidths=[105 * mm, 65 * mm],
    )

    table.setStyle(
        TableStyle(
            [
                ("BOX", (0, 0), (-1, -1), 0.5, colors.grey),
                ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.lightgrey),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#dddddd")),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("ALIGN", (1, 1), (1, -1), "RIGHT"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
            ]
        )
    )

    elements.append(table)

    elements.append(Spacer(1, 10 * mm))

    elements.append(
        Paragraph(
            f"Nombre de factures : {factures['nombre']}",
            styles["Normal"],
        )
    )

    elements.append(
        Paragraph(
            f"Nombre de paiements : {paiements['nombre']}",
            styles["Normal"],
        )
    )

    elements.append(
        Paragraph(
            f"Nombre de dépenses : {depenses['nombre']}",
            styles["Normal"],
        )
    )

    elements.append(Spacer(1, 10 * mm))

    elements.append(
        Paragraph(
            "Rapport généré automatiquement par SS Consulting.",
            styles["Normal"],
        )
    )

    document.build(elements)

    buffer.seek(0)

    return buffer


NOMS_MOIS = [
    "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
    "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre",
]


def generer_dsf_pdf(db, client_id: int, annee: int):
    """
    Génère, côté admin, une synthèse au format DSF (Déclaration
    Statistique et Fiscale, système SYSCOHADA) pour un client donné,
    à partir de ses déclarations mensuelles réellement saisies dans
    l'application. Le formulaire côté client reste volontairement
    simple ; c'est cette génération qui restitue le niveau de détail
    attendu d'une DSF.
    """

    from app.models.client import Client
    from app.models.declaration import Declaration

    client = db.query(Client).filter(Client.id == client_id).first()

    if client is None:
        raise ValueError("Client introuvable")

    declarations = (
        db.query(Declaration)
        .filter(
            Declaration.client_id == client_id,
            Declaration.annee == annee,
        )
        .order_by(Declaration.mois)
        .all()
    )

    buffer = BytesIO()

    document = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=15 * mm,
        leftMargin=15 * mm,
        topMargin=15 * mm,
        bottomMargin=15 * mm,
        title=f"DSF {annee} - {client.raison_sociale or client.nom}",
    )

    styles = getSampleStyleSheet()

    styles.add(
        ParagraphStyle(
            name="DsfSection",
            parent=styles["Heading2"],
            fontSize=12,
            leading=15,
            spaceBefore=6 * mm,
            spaceAfter=3 * mm,
            textColor=colors.HexColor("#1a3d6d"),
        )
    )

    styles.add(
        ParagraphStyle(
            name="DsfFootnote",
            parent=styles["Normal"],
            fontSize=8,
            leading=11,
            textColor=colors.grey,
        )
    )

    elements = []

    elements.append(Paragraph("SS CONSULTING", styles["Title"]))

    elements.append(
        Paragraph(
            "DÉCLARATION STATISTIQUE ET FISCALE (DSF)",
            styles["Heading1"],
        )
    )

    elements.append(
        Paragraph(
            f"Système Normal SYSCOHADA — Exercice {annee}",
            styles["Normal"],
        )
    )

    elements.append(Spacer(1, 8 * mm))

    # ========================================================
    # FICHE D'IDENTIFICATION
    # ========================================================

    elements.append(Paragraph("FICHE D'IDENTIFICATION", styles["DsfSection"]))

    nom_complet = client.raison_sociale or (
        f"{client.nom} {client.prenom or ''}".strip()
    )

    adresse_complete = ", ".join(
        filter(
            None,
            [client.quartier, client.commune or client.ville, client.adresse],
        )
    ) or "Non renseignée"

    ident_data = [
        ["Raison sociale / Nom", nom_complet],
        ["N° contribuable (NIU)", client.numero_contribuable or "Non renseigné"],
        ["Registre de commerce", client.registre_commerce or "Non renseigné"],
        ["Régime fiscal", client.regime_fiscal or "Non renseigné"],
        ["Secteur d'activité", client.secteur_activite or "Non renseigné"],
        ["Adresse", adresse_complete],
        ["Ville", client.ville or "Non renseignée"],
        ["Téléphone", client.telephone],
        ["Email", client.email or "Non renseigné"],
        ["Assujetti à la TVA", "Oui" if client.assujetti_tva else "Non"],
    ]

    ident_table = Table(ident_data, colWidths=[55 * mm, 115 * mm])

    ident_table.setStyle(
        TableStyle(
            [
                ("BOX", (0, 0), (-1, -1), 0.5, colors.grey),
                ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.lightgrey),
                ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#eef2f7")),
                ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )

    elements.append(ident_table)
    elements.append(Spacer(1, 8 * mm))

    # ========================================================
    # SYNTHESE MENSUELLE DE L'EXERCICE
    # ========================================================

    elements.append(
        Paragraph("SYNTHÈSE MENSUELLE DE L'EXERCICE", styles["DsfSection"])
    )

    total_ca = 0.0
    total_ventes = 0.0
    total_achats = 0.0

    if not declarations:
        elements.append(
            Paragraph(
                "Aucune déclaration mensuelle saisie pour cet exercice.",
                styles["Normal"],
            )
        )
    else:
        mensuel_data = [
            ["Mois", "Statut", "Chiffre d'affaires", "Ventes", "Achats", "Employés"]
        ]

        for decl in declarations:
            total_ca += float(decl.chiffre_affaires)
            total_ventes += float(decl.total_ventes)
            total_achats += float(decl.total_achats)

            mensuel_data.append(
                [
                    NOMS_MOIS[decl.mois - 1] if 1 <= decl.mois <= 12 else str(decl.mois),
                    decl.statut,
                    format_fcfa(decl.chiffre_affaires),
                    format_fcfa(decl.total_ventes),
                    format_fcfa(decl.total_achats),
                    str(decl.nombre_employes),
                ]
            )

        mensuel_data.append(
            [
                "TOTAL EXERCICE",
                "",
                format_fcfa(total_ca),
                format_fcfa(total_ventes),
                format_fcfa(total_achats),
                str(declarations[-1].nombre_employes),
            ]
        )

        mensuel_table = Table(
            mensuel_data,
            colWidths=[25 * mm, 25 * mm, 35 * mm, 30 * mm, 30 * mm, 25 * mm],
        )

        mensuel_table.setStyle(
            TableStyle(
                [
                    ("BOX", (0, 0), (-1, -1), 0.5, colors.grey),
                    ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.lightgrey),
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#dddddd")),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
                    ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef2f7")),
                    ("ALIGN", (2, 1), (-1, -1), "RIGHT"),
                    ("FONTSIZE", (0, 0), (-1, -1), 8),
                    ("LEFTPADDING", (0, 0), (-1, -1), 4),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                    ("TOPPADDING", (0, 0), (-1, -1), 5),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ]
            )
        )

        elements.append(mensuel_table)
        elements.append(Spacer(1, 8 * mm))

        # ========================================================
        # COMPTE DE RESULTAT SIMPLIFIE
        # ========================================================

        elements.append(
            Paragraph("COMPTE DE RÉSULTAT SIMPLIFIÉ", styles["DsfSection"])
        )

        resultat_data = [
            ["Poste", "Montant"],
            ["Produits (chiffre d'affaires)", format_fcfa(total_ca)],
            ["Charges (achats)", format_fcfa(total_achats)],
            ["Résultat brut estimé", format_fcfa(total_ca - total_achats)],
        ]

        resultat_table = Table(resultat_data, colWidths=[105 * mm, 65 * mm])

        resultat_table.setStyle(
            TableStyle(
                [
                    ("BOX", (0, 0), (-1, -1), 0.5, colors.grey),
                    ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.lightgrey),
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#dddddd")),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
                    ("ALIGN", (1, 1), (1, -1), "RIGHT"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 6),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                    ("TOPPADDING", (0, 0), (-1, -1), 6),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
                ]
            )
        )

        elements.append(resultat_table)
        elements.append(Spacer(1, 8 * mm))

    # ========================================================
    # OBSERVATIONS
    # ========================================================

    observations = [
        (decl.mois, decl.observations, decl.commentaire_admin)
        for decl in declarations
        if decl.observations or decl.commentaire_admin
    ]

    if observations:
        elements.append(Paragraph("OBSERVATIONS", styles["DsfSection"]))

        for mois, obs, commentaire in observations:
            libelle_mois = (
                NOMS_MOIS[mois - 1] if 1 <= mois <= 12 else str(mois)
            )

            if obs:
                elements.append(
                    Paragraph(
                        f"<b>{libelle_mois} :</b> {obs}",
                        styles["Normal"],
                    )
                )

            if commentaire:
                elements.append(
                    Paragraph(
                        f"<b>{libelle_mois} (cabinet) :</b> {commentaire}",
                        styles["Normal"],
                    )
                )

            elements.append(Spacer(1, 2 * mm))

        elements.append(Spacer(1, 4 * mm))

    elements.append(Spacer(1, 6 * mm))

    elements.append(
        Paragraph(
            "Document généré automatiquement par SS Consulting à partir des "
            "déclarations mensuelles saisies par le client et validées par "
            "le cabinet. Cette synthèse restitue les informations "
            "disponibles dans l'application et ne remplace pas une DSF "
            "certifiée par un expert-comptable.",
            styles["DsfFootnote"],
        )
    )

    document.build(elements)

    buffer.seek(0)

    return buffer
